import 'dart:async';

import 'package:clock/clock.dart';
import 'package:yun_audiobook/core/errors.dart';
import 'package:yun_audiobook/core/logging.dart';
import 'package:yun_audiobook/domain/entities.dart';
import 'package:yun_audiobook/playback/media_engine.dart';
import 'package:yun_audiobook/playback/playback_url_resolver.dart';
import 'package:yun_audiobook/playback/sleep_timer.dart';

/// 播放会话对外上报的出口。由 app 层用真实 DAO / 同步实现，
/// 测试里换成记录调用的假实现。原来这些是 bootstrap 里的内联闭包。
abstract interface class PlaybackSink {
  /// 进度上报（约 5 秒一次，以及暂停、切章、播完时各一次）。
  /// [episodeFinished] 表示这一集自然播完；[finished] 表示整个合集播完。
  Future<void> progress({
    required String seriesId,
    required int episodeIndex,
    required int positionMs,
    bool? finished,
    bool episodeFinished = false,
  });

  /// 播放器报出了真实时长。存下来：通知栏的进度条要靠它，而 ID3 解析拿不到时长。
  Future<void> duration(String episodeId, int durationMs);

  /// 播放链路上遇到鉴权失败：清地址缓存、退出登录。
  Future<void> authFailed();
}

/// 播放中断恢复失败时对外的通知。
class PlaybackFailure {
  const PlaybackFailure({required this.kind, required this.canRetry});

  /// 失败分类；为 null 表示多次退避重试后仍取不到地址。
  final DriveErrorKind? kind;
  final bool canRetry;
}

/// 非致命的体验提示。文案在 l10n 里按枚举取。
enum PlaybackHint {
  /// 网络较慢，反复缓冲。建议先下载再听。
  slowNetwork,
}

/// 会话某一时刻的完整状态，界面与系统媒体通知都从这里取。
class PlaybackSnapshot {
  const PlaybackSnapshot({
    this.series,
    this.episodes = const [],
    this.index = 0,
    this.preparing = false,
    this.playAfterLoad = false,
    this.pendingPosition = Duration.zero,
    this.engine = EngineSnapshot.initial,
  });

  final Series? series;
  final List<Episode> episodes;
  final int index;

  /// 正在准备一集（取播放地址 + 加载）。这期间播放器里还是上一段，
  /// 它的位置与时长都不属于当前集，界面要换成"准备中"来显示。
  final bool preparing;

  /// 准备好之后是否自动开始播放。准备期间按暂停只是把它置 false，
  /// 不会等加载完又自己响起来。
  final bool playAfterLoad;

  /// 准备中的那一集要从哪里开始，给进度条在加载完成前显示。
  final Duration pendingPosition;

  final EngineSnapshot engine;

  static const empty = PlaybackSnapshot();

  bool get hasMedia => series != null && episode != null;

  Episode? get episode =>
      index >= 0 && index < episodes.length ? episodes[index] : null;

  /// 界面该显示的位置：准备中显示续播点，否则是播放器位置。
  Duration get position => preparing ? pendingPosition : engine.position;

  /// 界面该显示的时长：库里存的优先（准备中也有刻度），否则取播放器报的。
  Duration? get duration =>
      episode?.duration ?? (preparing ? null : engine.duration);

  /// 「看起来在播」：准备中且打算播，或播放器在播。
  bool get playing => preparing ? playAfterLoad : engine.playing;

  bool get hasNext => index + 1 < episodes.length;

  bool get hasPrevious => index > 0;
}

/// 播放会话（refactor-app-foundation D6）。
///
/// 原 AudiobookHandler 里与系统媒体通知无关的全部逻辑：选集、加载、恢复、
/// 卡死看门狗、弱网提示、进度、睡眠定时。纯 Dart，经 [MediaEngine] 驱动播放器。
///
/// 关键点：
///   - 链接过期导致的中断由本类自动恢复，并 seek 回中断位置，
///     用户只感知一次缓冲，绝不从头开始
///   - 引擎的 play() 一律不 await（见 [MediaEngine.play]）
class PlaybackSession {
  PlaybackSession({
    required MediaEngine engine,
    required PlaybackUrlResolver resolver,
    required PlaybackSink sink,
  })  : _engine = engine,
        _resolver = resolver,
        _sink = sink {
    _sleepTimer = SleepTimer(() => unawaited(pause()));
    _subs.addAll([
      _engine.snapshots.listen(_onEngine),
      _engine.completed.listen((_) => unawaited(_onEpisodeCompleted())),
      _engine.errors.listen((e) {
        Log.e('player', '播放事件流报错', e);
        unawaited(_handlePlaybackError(e));
      }),
    ]);
  }

  static const Duration skipStep = Duration(seconds: 15);
  static const int maxRecoveryAttempts = 4;
  static const Duration progressSaveInterval = Duration(seconds: 5);

  /// 加载的超时。
  ///
  /// just_audio 的 `setAudioSource` 要等到能确定时长才返回，流迟迟不给数据
  /// 它会**永久挂住**——真机上就这么卡过：音源从未就绪（processingState 停在
  /// idle），而用户按了播放键把 playWhenReady 置真，界面于是显示成「正在
  /// 播放」，实际一个字节都没进来，也不抛异常，三层兜底全部漏过。
  /// HTTP 那一层每个调用都有超时（BaiduApiClient），这一层原来没有。
  static const Duration loadTimeout = Duration(seconds: 30);

  /// 看门狗的检查间隔与判定卡死的阈值。
  ///
  /// 光有超时不够：也可能加载成功了、播到中途流断掉，ExoPlayer 内部
  /// 无限重试而不抛错。判据是「自称在播，但缓冲位置一直不涨」。
  static const Duration watchdogTick = Duration(seconds: 5);
  static const Duration stallTimeout = Duration(seconds: 25);

  /// 一分钟内缓冲超过阈值就认为流播撑不住，提示改用离线下载
  /// （audio-playback 规格「速率不足提示」）。
  static const int stallThreshold = 4;
  static const Duration stallWindow = Duration(minutes: 1);

  final MediaEngine _engine;
  final PlaybackUrlResolver _resolver;
  final PlaybackSink _sink;
  final _subs = <StreamSubscription<Object?>>[];

  late final SleepTimer _sleepTimer;
  SleepTimer get sleepTimer => _sleepTimer;

  PlaybackSnapshot _state = PlaybackSnapshot.empty;
  PlaybackSnapshot get current => _state;
  final _states = StreamController<PlaybackSnapshot>.broadcast();

  /// 会话状态。订阅时不会重放当前值，需要的话先读 [current]。
  Stream<PlaybackSnapshot> get states => _states.stream;

  final _failures = StreamController<PlaybackFailure>.broadcast();
  Stream<PlaybackFailure> get failures => _failures.stream;

  final _hints = StreamController<PlaybackHint>.broadcast();
  Stream<PlaybackHint> get hints => _hints.stream;

  bool _recovering = false;
  int _recoveryAttempt = 0;

  Timer? _watchdog;
  Duration _lastBuffered = Duration.zero;
  DateTime? _stuckSince;
  DateTime _lastProgressSave = DateTime.fromMillisecondsSinceEpoch(0);
  EngineState _lastEngineState = EngineState.idle;
  bool _lastPlaying = false;

  /// 反复缓冲的时间戳。用来判断"网速撑不住流播"，
  /// 而不是去测瞬时带宽——用户体感的是卡顿次数，不是 KB/s。
  final List<DateTime> _stalls = [];
  bool _slowNetworkNotified = false;

  /// 每次开始播放一个合集都加一。连着点两个时，前一次的加载晚到或失败
  /// 都要作废，不能把后一个的状态冲掉。
  int _startGen = 0;

  void _set(PlaybackSnapshot next) {
    _state = next;
    if (!_states.isClosed) _states.add(next);
  }

  PlaybackSnapshot _with({
    Series? series,
    List<Episode>? episodes,
    int? index,
    bool? preparing,
    bool? playAfterLoad,
    Duration? pendingPosition,
    EngineSnapshot? engine,
  }) =>
      PlaybackSnapshot(
        series: series ?? _state.series,
        episodes: episodes ?? _state.episodes,
        index: index ?? _state.index,
        preparing: preparing ?? _state.preparing,
        playAfterLoad: playAfterLoad ?? _state.playAfterLoad,
        pendingPosition: pendingPosition ?? _state.pendingPosition,
        engine: engine ?? _state.engine,
      );

  // ------------------------------------------------------ 引擎事件

  void _onEngine(EngineSnapshot e) {
    _set(_with(engine: e));

    if (e.state == EngineState.buffering &&
        _lastEngineState != EngineState.buffering) {
      _noteStall();
    }
    _lastEngineState = e.state;

    // 只在播放期间开看门狗，暂停或没在播时不留定时器
    if (e.playing != _lastPlaying) {
      _lastPlaying = e.playing;
      e.playing ? _startWatchdog() : _stopWatchdog();
    }

    _maybeRecordDuration(e);
    _maybeSaveProgress();
  }

  /// 真实时长要等播放器加载后才知道。拿到就记进会话里的条目（通知栏的
  /// 进度条要它，否则两端都显示 00:00、滑块钉在最左边——真机上就是这个表现），
  /// 同时写回库，下次播这一集立刻就有刻度。
  ///
  /// 准备期间播放器里还是上一段，它报的时长不属于当前集，不能记。
  void _maybeRecordDuration(EngineSnapshot e) {
    final d = e.duration;
    final episode = _state.episode;
    if (_state.preparing || d == null || d <= Duration.zero) return;
    if (episode == null || episode.durationMs == d.inMilliseconds) return;

    final episodes = [..._state.episodes];
    episodes[_state.index] = episode.copyWith(durationMs: d.inMilliseconds);
    _set(_with(episodes: episodes));
    unawaited(_sink.duration(episode.id, d.inMilliseconds));
  }

  // ------------------------------------------------------ 卡死看门狗

  void _startWatchdog() {
    if (_watchdog != null) return;
    _lastBuffered = _engine.current.buffered;
    _stuckSince = null;
    _watchdog = Timer.periodic(watchdogTick, (_) => unawaited(_checkStuck()));
  }

  void _stopWatchdog() {
    _watchdog?.cancel();
    _watchdog = null;
    _stuckSince = null;
  }

  /// 「自称在播但其实什么都没发生」的兜底。
  ///
  /// 判据不是 processingState 本身——卡死可以停在 idle（从未就绪）
  /// 也可以停在 buffering（流中断），两种都不抛异常。真正可靠的信号是
  /// **缓冲位置不再增长**：数据在进来就一定会涨，涨了就不算卡死，
  /// 只是慢（慢有 _noteStall 那条提示管）。
  Future<void> _checkStuck() async {
    final e = _engine.current;
    if (_recovering || !e.playing) {
      _stuckSince = null;
      return;
    }
    // 已就绪且在推进：正常播放
    if (e.state == EngineState.ready) {
      _stuckSince = null;
      _lastBuffered = e.buffered;
      return;
    }
    // 离线条目不走重取地址那条恢复路径，本地文件卡住是另一类问题
    if (_state.episode?.isCached ?? false) return;

    if (e.buffered > _lastBuffered) {
      _lastBuffered = e.buffered;
      _stuckSince = null;
      return;
    }

    final now = clock.now();
    _stuckSince ??= now;
    if (now.difference(_stuckSince!) < stallTimeout) return;

    Log.d(
      'player',
      '自称在播但缓冲位置 ${e.buffered.inSeconds}s 已停滞 '
          '${stallTimeout.inSeconds}s，走恢复流程',
    );
    _stuckSince = null;
    await _handlePlaybackError(StateError('播放卡死：state=${e.state}'));
  }

  // ------------------------------------------------------------ 播放入口

  /// 开始播放一个合集：先同步切到新的一集（标题、封面、条目立刻可见），
  /// 再在后台取地址、加载并播放。调用方不用等它——界面可以先跳到播放页，
  /// 加载失败走和播放中断一样的恢复流程，由 [failures] 报给界面。
  ///
  /// 不传 [episodeIndex] 时从合集的断点续播；已听完的合集从第一集重来。
  Future<void> start(
    Series series,
    List<Episode> episodes, {
    int? episodeIndex,
    Duration? position,
  }) async {
    if (episodes.isEmpty) return;
    var index = episodeIndex ?? series.currentEpisodeIndex;
    var at = position ?? series.position;
    // 已听完的合集重新播放时从头开始（listening-progress 规格）
    if (series.finished && episodeIndex == null) {
      index = 0;
      at = Duration.zero;
    }
    final gen = ++_startGen;
    // 下面到 _loadCurrent 第一次 await 之前都是同步的：调用方紧接着打开播放页时，
    // 新合集的标题、条目和"准备中"状态已经就位，不会先闪一下上一个。
    // 上一个的断点在切换前同步取走（_saveProgress 在第一个 await 前读完字段）。
    unawaited(_saveProgress(force: true));
    // 停下正在放的上一段，免得新合集准备期间旧的还在响
    if (_engine.current.playing) unawaited(_engine.pause());
    _set(
      _with(
        series: series,
        episodes: episodes,
        index: index.clamp(0, episodes.length - 1),
        playAfterLoad: true,
      ),
    );
    try {
      await _loadCurrent(initialPosition: at);
    } on Object catch (e) {
      if (gen != _startGen) return;
      Log.e('player', '开始播放时加载失败，进入恢复流程', e);
      await _handlePlaybackError(e, resumeAt: at);
      return;
    }
    if (gen != _startGen) return;
    if (_state.playAfterLoad) unawaited(_engine.play());
  }

  /// 切到会话里的第 [index] 集。
  Future<void> playAt(int index, {Duration? position}) async {
    if (index < 0 || index >= _state.episodes.length) return;
    _set(_with(index: index));
    try {
      await _loadCurrent(initialPosition: position ?? Duration.zero);
    } on Object catch (e) {
      // 加载失败（含 30 秒超时）不能就这么算了：原来这里异常往上抛，
      // play() 不再执行，界面既没声音也没提示；用户再按一次播放键只是把
      // playWhenReady 置真，于是显示成「正在播放」而底层没有音源。
      Log.e('player', '加载失败，进入恢复流程', e);
      await _handlePlaybackError(e, resumeAt: position ?? Duration.zero);
      return;
    }
    // play() 要到暂停才返回，调用方（切集、自动续播）不该被它挂住
    unawaited(play());
  }

  Future<void> _loadCurrent({Duration initialPosition = Duration.zero}) async {
    final episode = _state.episode;
    if (episode == null || _state.series == null) return;

    // 先切状态再去取地址：标题、封面立刻换过来，取地址那一两秒
    // 界面显示"准备中"，而不是停在上一集不动。
    _set(_with(pendingPosition: initialPosition, preparing: true));
    try {
      final media = await _resolver.resolve(episode);
      // 超时后当作播放失败抛出去，由调用方走恢复流程。
      // 没有这个超时的话，流不给数据就永久挂在这一行。
      await _engine
          .load(media, initialPosition: initialPosition)
          .timeout(loadTimeout);
    } finally {
      _set(_with(preparing: false));
    }
    _recoveryAttempt = 0;
    _stalls.clear();

    // 预取下一集地址，压缩切换的静默间隙
    final next = _state.hasNext ? _state.episodes[_state.index + 1] : null;
    unawaited(_resolver.prefetch(next));
  }

  // ------------------------------------------------------------ 传输控制

  Future<void> play() {
    // 准备中按播放：记下意图，加载完成后开始。不能直接 engine.play()，
    // 那会先把还留在播放器里的上一段放出来。
    if (_state.preparing) {
      _set(_with(playAfterLoad: true));
      return Future.value();
    }
    unawaited(_engine.play());
    return Future.value();
  }

  Future<void> pause() async {
    _set(_with(playAfterLoad: false));
    await _engine.pause();
    await _saveProgress(force: true);
  }

  Future<void> stop() async {
    await _saveProgress(force: true);
    await _engine.stop();
  }

  /// 结束整个会话：停下播放器并清空状态（迷你播放条随之消失）。
  /// 正在播的书被移出书架时用——不能只暂停，界面上还会挂着一本已经不在书架上的书。
  Future<void> reset() async {
    _startGen++;
    _stopWatchdog();
    _sleepTimer.cancel();
    await _engine.stop();
    _set(PlaybackSnapshot.empty);
  }

  Future<void> seek(Duration position) => _engine.seek(position);

  /// 规格要求 0.5x–3.0x。
  Future<void> setSpeed(double speed) =>
      _engine.setSpeed(speed.clamp(0.5, 3.0));

  Future<void> next() async {
    if (!_state.hasNext) return;
    await playAt(_state.index + 1);
  }

  Future<void> previous() async {
    if (!_state.hasPrevious) return;
    await playAt(_state.index - 1);
  }

  /// 快退 15 秒；不足 15 秒则回到本集开头（规格「快进快退」）。
  Future<void> rewind() async {
    final target = _engine.current.position - skipStep;
    await _engine.seek(target < Duration.zero ? Duration.zero : target);
  }

  Future<void> forward() async {
    final duration = _engine.current.duration;
    var target = _engine.current.position + skipStep;
    if (duration != null && target > duration) target = duration;
    await _engine.seek(target);
  }

  // ------------------------------------------------------ 弱网检测

  void _noteStall() {
    if (_state.episode?.isCached ?? true) return;
    if (!_engine.current.playing) return;

    final now = clock.now();
    _stalls
      ..add(now)
      ..removeWhere((t) => now.difference(t) > stallWindow);

    if (_stalls.length >= stallThreshold && !_slowNetworkNotified) {
      _slowNetworkNotified = true;
      _hints.add(PlaybackHint.slowNetwork);
    }
  }

  // ------------------------------------------------------------ 一集结束

  Future<void> _onEpisodeCompleted() async {
    // 本集确实播完了，先补一笔带「播完」标记的上报（播放历史要用）。
    // 放在最前面：下面三条分支（定时停止 / 自动续播 / 全部结束）
    // 都是「本集已播完」，漏掉任何一条历史里就会少一个「听完」。
    final series = _state.series;
    if (series == null) return;
    await _sink.progress(
      seriesId: series.id,
      episodeIndex: _state.index,
      positionMs: _engine.current.position.inMilliseconds,
      episodeFinished: true,
    );

    // 「播完本集后停止」优先于自动续播（规格「播完本章停止」）
    if (_sleepTimer.consumeChapterEnd()) {
      await _engine.pause();
      await _saveProgress(force: true);
      return;
    }

    if (_state.hasNext) {
      await playAt(_state.index + 1);
      return;
    }

    // 全部结束：停止并标记已听完（规格「全书结束」）
    await _sink.progress(
      seriesId: series.id,
      episodeIndex: _state.index,
      positionMs: 0,
      finished: true,
    );
    await _engine.pause();
  }

  // ------------------------------------------------------------ 中断恢复

  /// 链接过期 / 失效导致的中断，在这里无感恢复：
  /// 作废地址缓存 → 重新解析 → 重新加载 → seek 回中断位置。
  Future<void> _handlePlaybackError(Object error, {Duration? resumeAt}) async {
    if (_recovering) return;
    final episode = _state.episode;
    if (episode == null) return;

    _recovering = true;
    // 首次加载就失败时播放器里还没有这一集，它的 position 不是断点，
    // 由调用方把要续播的位置传进来
    final at = resumeAt ?? _engine.current.position;

    try {
      while (_recoveryAttempt < maxRecoveryAttempts) {
        _recoveryAttempt++;
        // 指数退避（规格「连续失败后报错」）
        final backoff =
            Duration(milliseconds: 400 * (1 << (_recoveryAttempt - 1)));
        await Future<void>.delayed(backoff);

        try {
          _resolver.invalidate(episode.fsId);
          final media = await _resolver.resolve(episode, forceRefresh: true);
          // 这里同样必须有超时：恢复流程一旦挂在这一行，_recovering 会永久
          // 停在 true，之后所有播放错误都被那个守卫吞掉，再也无法恢复。
          await _engine.load(media, initialPosition: at).timeout(loadTimeout);
          // 不能 await：just_audio 的 play() 要等到暂停或播完才返回，
          // await 的话恢复流程一直不结束，_recovering 卡在 true，之后的错误全被吞掉
          unawaited(_engine.play());
          Log.d(
            'player',
            '播放已恢复，位置 ${at.inSeconds}s（第 $_recoveryAttempt 次尝试）',
          );
          _recoveryAttempt = 0;
          return;
        } on DriveException catch (e) {
          // 鉴权失败走刷新/重新授权，而不是无意义重试（规格「区分鉴权失败与网络失败」）
          if (e.isAuthProblem) {
            Log.e('player', '恢复失败：授权问题', e);
            await _sink.authFailed();
            _failures.add(PlaybackFailure(kind: e.kind, canRetry: false));
            return;
          }
          if (!e.isRetryable) {
            _failures.add(PlaybackFailure(kind: e.kind, canRetry: true));
            return;
          }
          Log.d('player', '恢复第 $_recoveryAttempt 次失败，继续退避重试：${e.message}');
        } on Object catch (e) {
          Log.d('player', '恢复第 $_recoveryAttempt 次失败：$e');
        }
      }

      // 达到上限：暂停并保留播放位置，交给用户手动重试
      await _engine.pause();
      _failures.add(const PlaybackFailure(kind: null, canRetry: true));
    } finally {
      _recovering = false;
    }
  }

  /// 用户手动重试。
  Future<void> retry() async {
    _recoveryAttempt = 0;
    final position = _engine.current.position;
    try {
      await _loadCurrent(initialPosition: position);
    } on Object catch (e) {
      await _handlePlaybackError(e, resumeAt: position);
      return;
    }
    unawaited(play());
  }

  // ------------------------------------------------------------ 进度

  void _maybeSaveProgress() {
    if (clock.now().difference(_lastProgressSave) < progressSaveInterval) {
      return;
    }
    unawaited(_saveProgress());
  }

  Future<void> _saveProgress({bool force = false}) async {
    final series = _state.series;
    if (series == null) return;
    // 准备期间播放器的位置还是上一段的，写进去会把新合集的断点冲掉
    if (_state.preparing) return;
    if (!force &&
        clock.now().difference(_lastProgressSave) < progressSaveInterval) {
      return;
    }
    _lastProgressSave = clock.now();
    await _sink.progress(
      seriesId: series.id,
      episodeIndex: _state.index,
      positionMs: _engine.current.position.inMilliseconds,
    );
  }

  Future<void> dispose() async {
    _stopWatchdog();
    _sleepTimer.dispose();
    for (final s in _subs) {
      await s.cancel();
    }
    await _states.close();
    await _failures.close();
    await _hints.close();
    await _engine.dispose();
  }
}
