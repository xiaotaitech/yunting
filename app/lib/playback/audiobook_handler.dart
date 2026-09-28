import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../core/config.dart';
import '../core/errors.dart';
import '../core/logging.dart';
import '../domain/models.dart';
import 'playback_url_resolver.dart';
import 'sleep_timer.dart';

/// 播放中断恢复失败时对外的通知。
class PlaybackFailure {
  const PlaybackFailure(this.message, {required this.canRetry});

  final String message;
  final bool canRetry;
}

/// 听书播放核心（audio-playback 规格）。
///
/// 关键点：
///   - `userAgent: pan.baidu.com`，且 just_audio 会在 302 跳转后保留它
///   - dlink 过期导致的中断由本类自动恢复，并 seek 回中断位置，
///     用户只感知一次缓冲，绝不从头开始
class AudiobookHandler extends BaseAudioHandler with SeekHandler {
  AudiobookHandler({
    required PlaybackUrlResolver resolver,
    required Future<void> Function(
            String bookId, int chapterIndex, int positionMs,
            {bool? finished, bool? chapterFinished})
        onProgress,
    required Future<void> Function() onAuthFailure,
    required Future<void> Function(String chapterId, int durationMs) onDuration,
  })  : _resolver = resolver,
        _onProgress = onProgress,
        _onAuthFailure = onAuthFailure,
        _onDuration = onDuration {
    // UA 在这里设一次就够，而且必须在这里设：
    // 百度对 dlink 的 Range 请求校验 UA，而流播全程都是 Range。
    //
    // 刻意不给 AudioSource 传 headers——那会让 just_audio 起一个本地回环 HTTP
    // 代理来注入请求头，而 Android 9+ 默认禁明文，直接报
    // 「Cleartext HTTP traffic not permitted」播不出声。
    // UA 已经由 userAgent 参数走 ExoPlayer 原生通道设好了，headers 是多余的。
    _player = AudioPlayer(userAgent: AppConfig.panUserAgent);
    _sleepTimer = SleepTimer(() => pause());
    _wire();
  }

  static const Duration skipStep = Duration(seconds: 15);
  static const int _maxRecoveryAttempts = 4;
  static const Duration _progressSaveInterval = Duration(seconds: 5);

  /// 加载音频源的超时。
  ///
  /// just_audio 的 `setAudioSource` 要等到能确定时长才返回，流迟迟不给数据
  /// 它会**永久挂住**——真机上就这么卡过：音源从未就绪（processingState 停在
  /// idle），而用户按了播放键把 playWhenReady 置真，界面于是显示成「正在
  /// 播放」，实际一个字节都没进来，也不抛异常，三层兜底全部漏过。
  /// HTTP 那一层每个调用都有超时（BaiduApiClient），这一层原来没有。
  static const Duration _loadTimeout = Duration(seconds: 30);

  /// 看门狗的检查间隔与判定卡死的阈值。
  ///
  /// 光有超时不够：也可能音源加载成功了、播到中途流断掉，ExoPlayer 内部
  /// 无限重试而不抛错。判据是「自称在播，但缓冲位置一直不涨」。
  static const Duration _watchdogTick = Duration(seconds: 5);
  static const Duration _stallTimeout = Duration(seconds: 25);

  final PlaybackUrlResolver _resolver;
  final Future<void> Function(String, int, int,
      {bool? finished, bool? chapterFinished}) _onProgress;
  final Future<void> Function() _onAuthFailure;
  final Future<void> Function(String, int) _onDuration;

  late final AudioPlayer _player;
  late final SleepTimer _sleepTimer;

  Book? _book;
  List<Chapter> _chapters = const [];
  int _index = 0;

  bool _recovering = false;
  int _recoveryAttempt = 0;

  Timer? _watchdog;
  Duration _lastBuffered = Duration.zero;
  DateTime? _stuckSince;
  DateTime _lastProgressSave = DateTime.fromMillisecondsSinceEpoch(0);

  final _failures = StreamController<PlaybackFailure>.broadcast();
  Stream<PlaybackFailure> get failures => _failures.stream;

  /// 反复缓冲的时间戳。用来判断"网速撑不住流播"，
  /// 而不是去测瞬时带宽——用户体感的是卡顿次数，不是 KB/s。
  final List<DateTime> _stalls = [];
  bool _slowNetworkNotified = false;

  final _hints = StreamController<String>.broadcast();

  /// 非致命的体验提示，例如「网络较慢，建议先下载」。
  Stream<String> get hints => _hints.stream;

  /// 正在准备一章（取播放地址 + 加载音源）。这期间播放器里还是上一段音频，
  /// 它的位置与时长都不属于当前章，界面要换成"准备中"来显示。
  final preparing = ValueNotifier<bool>(false);

  /// 准备好之后是否自动开始播放。准备期间按暂停只是把它置 false，
  /// 不会等加载完又自己响起来。
  final playAfterLoad = ValueNotifier<bool>(false);

  /// 准备中的章要从哪里开始，给进度条在加载完成前显示。
  Duration pendingPosition = Duration.zero;

  /// 每次开始播放一本书都加一。连着点两本书时，前一次的加载晚到或失败
  /// 都要作废，不能把后一本的状态冲掉。
  int _startGen = 0;

  SleepTimer get sleepTimer => _sleepTimer;
  AudioPlayer get player => _player;
  Book? get currentBook => _book;
  List<Chapter> get currentChapters => _chapters;
  int get currentIndex => _index;
  Chapter? get currentChapter =>
      _index >= 0 && _index < _chapters.length ? _chapters[_index] : null;

  Future<void> configureSession() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.speech());

    // 耳机拔出 / 蓝牙断开自动暂停（规格「耳机拔出」）
    session.becomingNoisyEventStream.listen((_) {
      Log.d('player', '音频输出被拔出，自动暂停');
      pause();
    });

    // 音频焦点：来电等场景暂停，归还后恢复（规格「音频焦点处理」）
    session.interruptionEventStream.listen((event) {
      if (event.begin) {
        if (_player.playing) {
          _pausedByInterruption = true;
          pause();
        }
      } else if (_pausedByInterruption) {
        _pausedByInterruption = false;
        if (resumeAfterInterruption) play();
      }
    });
  }

  bool _pausedByInterruption = false;

  /// 中断结束后是否自动恢复播放，由设置页控制。
  bool resumeAfterInterruption = true;

  void _wire() {
    _player.playbackEventStream.listen(
      (event) {
        playbackState.add(_transformState(event));
        _maybeSaveProgress();
      },
      onError: (Object error, StackTrace _) {
        Log.e('player', '播放事件流报错', error);
        _handlePlaybackError(error);
      },
    );

    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) _onChapterCompleted();
      if (state == ProcessingState.buffering) _noteStall();
    });

    _player.positionStream.listen((_) => _maybeSaveProgress());

    // 真实时长要等播放器加载后才知道。拿到就回填给 mediaItem，
    // 否则系统媒体通知的 MediaItem.duration 一直是 null，
    // 进度条两端都显示 00:00、滑块钉在最左边（真机上就是这个表现）。
    // 同时写回库，下次播这一章立刻就有刻度。
    _player.durationStream.listen((d) {
      if (d == null || d <= Duration.zero) return;
      final chapter = currentChapter;
      final book = _book;
      if (chapter == null || book == null) return;
      if (chapter.id != mediaItem.valueOrNull?.id) return;
      if (mediaItem.valueOrNull?.duration == d) return;

      mediaItem.add(_mediaItemFor(chapter, book, d));
      if (chapter.durationMs != d.inMilliseconds) {
        unawaited(_onDuration(chapter.id, d.inMilliseconds));
      }
    });

    // 只在播放期间开看门狗，暂停或没在播时不留定时器
    _player.playingStream.listen((playing) {
      if (playing) {
        _startWatchdog();
      } else {
        _stopWatchdog();
      }
    });
  }

  // ------------------------------------------------------ 卡死看门狗

  void _startWatchdog() {
    if (_watchdog != null) return;
    _lastBuffered = _player.bufferedPosition;
    _stuckSince = null;
    _watchdog = Timer.periodic(_watchdogTick, (_) => unawaited(_checkStuck()));
  }

  void _stopWatchdog() {
    _watchdog?.cancel();
    _watchdog = null;
    _stuckSince = null;
  }

  /// 「自称在播但其实什么都没发生」的兜底。
  ///
  /// 判据不是 processingState 本身——卡死可以停在 idle（音源从未就绪）
  /// 也可以停在 buffering（流中断），两种都不抛异常。真正可靠的信号是
  /// **缓冲位置不再增长**：数据在进来就一定会涨，涨了就不算卡死，
  /// 只是慢（慢有 _noteStall 那条提示管）。
  Future<void> _checkStuck() async {
    if (_recovering || !_player.playing) {
      _stuckSince = null;
      return;
    }
    // 已就绪且在推进：正常播放
    if (_player.processingState == ProcessingState.ready) {
      _stuckSince = null;
      _lastBuffered = _player.bufferedPosition;
      return;
    }
    // 离线章节不走重取 dlink 那条恢复路径，本地文件卡住是另一类问题
    if (currentChapter?.isCached ?? false) return;

    final buffered = _player.bufferedPosition;
    if (buffered > _lastBuffered) {
      _lastBuffered = buffered;
      _stuckSince = null;
      return;
    }

    _stuckSince ??= DateTime.now();
    if (DateTime.now().difference(_stuckSince!) < _stallTimeout) return;

    Log.d('player',
        '自称在播但缓冲位置 ${buffered.inSeconds}s 已停滞 ${_stallTimeout.inSeconds}s，走恢复流程');
    _stuckSince = null;
    await _handlePlaybackError(
        StateError('播放卡死：processingState=${_player.processingState}'));
  }

  PlaybackState _transformState(PlaybackEvent event) {
    final playing = _player.playing;
    return PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        if (playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
        MediaAction.setSpeed,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: switch (_player.processingState) {
        ProcessingState.idle => AudioProcessingState.idle,
        ProcessingState.loading => AudioProcessingState.loading,
        ProcessingState.buffering => AudioProcessingState.buffering,
        ProcessingState.ready => AudioProcessingState.ready,
        ProcessingState.completed => AudioProcessingState.completed,
      },
      playing: playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: _index,
    );
  }

  // ------------------------------------------------------------ 播放入口

  /// 打开一本书并从指定位置开始。默认沿用书上记录的断点。
  /// 从界面开始播放一本书：先同步切到新章（标题、封面、章节立刻可见），
  /// 再在后台取地址、加载并播放。调用方不用等它——界面可以先跳到播放页，
  /// 加载失败走和播放中断一样的恢复流程，由 [failures] 报给界面。
  ///
  /// 不传 [chapterIndex] 时从书的断点续播；已听完的书从第一章重来。
  Future<void> start(
    Book book,
    List<Chapter> chapters, {
    int? chapterIndex,
    Duration? position,
  }) async {
    if (chapters.isEmpty) return;
    var index = chapterIndex ?? book.currentChapterIndex;
    var at = position ?? Duration(milliseconds: book.currentPositionMs);
    // 已听完的书重新播放时从头开始（listening-progress 规格）
    if (book.finished && chapterIndex == null) {
      index = 0;
      at = Duration.zero;
    }
    final gen = ++_startGen;
    // 下面到 _loadCurrent 第一次 await 之前都是同步的：调用方紧接着打开播放页时，
    // 新书的标题、章节和"准备中"状态已经就位，不会先闪一下上一本。
    // 上一本的断点在切换前同步取走（_saveProgress 在第一个 await 前读完字段）。
    unawaited(_saveProgress(force: true));
    // 停下正在放的上一段，免得新书准备期间旧书还在响
    if (_player.playing) unawaited(_player.pause());
    _book = book;
    _chapters = chapters;
    _index = index.clamp(0, chapters.length - 1);
    playAfterLoad.value = true;
    try {
      await _loadCurrent(initialPosition: at);
    } catch (e) {
      if (gen != _startGen || e is PlayerInterruptedException) return;
      Log.e('player', '开始播放时加载失败，进入恢复流程', e);
      await _handlePlaybackError(e, resumeAt: at);
      return;
    }
    if (gen != _startGen) return;
    if (playAfterLoad.value) unawaited(_player.play());
  }

  Future<void> playChapterAt(int index, {Duration? position}) async {
    if (index < 0 || index >= _chapters.length) return;
    _index = index;
    try {
      await _loadCurrent(initialPosition: position ?? Duration.zero);
    } catch (e) {
      // 加载失败（含上面那个 30 秒超时）不能就这么算了：原来这里异常往上抛，
      // play() 不再执行，界面既没声音也没提示；用户再按一次播放键只是把
      // playWhenReady 置真，于是显示成「正在播放」而底层没有音源。
      Log.e('player', '章节加载失败，进入恢复流程', e);
      await _handlePlaybackError(e, resumeAt: position ?? Duration.zero);
      return;
    }
    // play() 要到暂停才返回，调用方（切章、自动续播）不该被它挂住
    unawaited(play());
  }

  /// 通知栏与锁屏展示的媒体条目。
  ///
  /// 抽出来是因为它要在两个时机发出：加载章节时（可能还不知道时长），
  /// 以及播放器报出真实时长后回填。两处必须构造出一致的条目，
  /// 否则通知栏会闪一下标题或丢掉封面。
  MediaItem _mediaItemFor(Chapter chapter, Book book, Duration? duration) =>
      MediaItem(
        id: chapter.id,
        album: book.title,
        title: chapter.title,
        artist: book.author,
        duration: duration,
        artUri:
            book.coverLocalPath == null ? null : Uri.file(book.coverLocalPath!),
        extras: {'bookId': book.id, 'chapterIndex': _index},
      );

  Future<void> _loadCurrent({Duration initialPosition = Duration.zero}) async {
    final chapter = currentChapter;
    final book = _book;
    if (chapter == null || book == null) return;

    // 先发出新章的条目再去取地址：标题、封面立刻换过来，取地址那一两秒
    // 界面显示"准备中"，而不是停在上一章不动。
    // 库里存过时长就先用上，通知栏的进度条不用等加载完才出现。
    mediaItem.add(_mediaItemFor(
      chapter,
      book,
      chapter.durationMs == null
          ? null
          : Duration(milliseconds: chapter.durationMs!),
    ));
    pendingPosition = initialPosition;
    preparing.value = true;
    try {
      final media = await _resolver.resolve(chapter);
      // 超时后当作播放失败抛出去，由调用方或 onError 走恢复流程。
      // 没有这个超时的话，流不给数据就永久挂在这一行。
      await _player
          .setAudioSource(
            AudioSource.uri(Uri.parse(media.url)),
            initialPosition: initialPosition,
          )
          .timeout(_loadTimeout);
    } finally {
      preparing.value = false;
    }
    _recoveryAttempt = 0;
    _stalls.clear();

    // 预取下一章地址，压缩章节切换的静默间隙
    unawaited(_resolver.prefetch(
        _index + 1 < _chapters.length ? _chapters[_index + 1] : null));
  }

  // ------------------------------------------------------------ 传输控制

  @override
  Future<void> play() {
    // 准备中按播放：记下意图，加载完成后开始。不能直接 _player.play()，
    // 那会先把还留在播放器里的上一段音频放出来。
    if (preparing.value) {
      playAfterLoad.value = true;
      return Future.value();
    }
    return _player.play();
  }

  @override
  Future<void> pause() async {
    playAfterLoad.value = false;
    await _player.pause();
    await _saveProgress(force: true);
  }

  @override
  Future<void> stop() async {
    await _saveProgress(force: true);
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> setSpeed(double speed) async {
    // 规格要求 0.5x–3.0x
    await _player.setSpeed(speed.clamp(0.5, 3.0));
  }

  @override
  Future<void> skipToNext() async {
    if (_index + 1 >= _chapters.length) return;
    await playChapterAt(_index + 1);
  }

  @override
  Future<void> skipToPrevious() async {
    if (_index - 1 < 0) return;
    await playChapterAt(_index - 1);
  }

  /// 快退 15 秒；不足 15 秒则回到本章开头（规格「快进快退」）。
  Future<void> rewind15() async {
    final target = _player.position - skipStep;
    await _player.seek(target < Duration.zero ? Duration.zero : target);
  }

  Future<void> forward15() async {
    final duration = _player.duration;
    var target = _player.position + skipStep;
    if (duration != null && target > duration) target = duration;
    await _player.seek(target);
  }

  // ------------------------------------------------------ 弱网检测

  /// 一分钟内缓冲超过阈值就认为流播撑不住，提示改用离线下载
  /// （audio-playback 规格「速率不足提示」）。已缓存的章节不参与判断。
  static const int _stallThreshold = 4;
  static const Duration _stallWindow = Duration(minutes: 1);

  void _noteStall() {
    if (currentChapter?.isCached ?? true) return;
    if (!_player.playing) return;

    final now = DateTime.now();
    _stalls.add(now);
    _stalls.removeWhere((t) => now.difference(t) > _stallWindow);

    if (_stalls.length >= _stallThreshold && !_slowNetworkNotified) {
      _slowNetworkNotified = true;
      _hints.add('网络较慢，反复缓冲。建议先下载本书再听。');
    }
  }

  // ------------------------------------------------------------ 章节结束

  Future<void> _onChapterCompleted() async {
    // 本章确实播完了，先补一笔带「听完」标记的上报（播放历史要用）。
    // 放在最前面：下面三条分支（定时停止 / 自动续播 / 全书结束）
    // 都是「本章已听完」，漏掉任何一条历史里就会少一个「听完」。
    final completed = _book;
    if (completed != null) {
      await _onProgress(
        completed.id,
        _index,
        _player.position.inMilliseconds,
        chapterFinished: true,
      );
    }

    // 「播完本章后停止」优先于自动续播（规格「播完本章停止」）
    if (_sleepTimer.consumeChapterEnd()) {
      await _player.pause();
      await _saveProgress(force: true);
      return;
    }

    if (_index + 1 < _chapters.length) {
      await playChapterAt(_index + 1);
      return;
    }

    // 全书结束：停止并标记已听完（规格「全书结束」）
    final book = _book;
    if (book != null) {
      await _onProgress(book.id, _index, 0, finished: true);
    }
    await _player.pause();
  }

  // ------------------------------------------------------------ 中断恢复

  /// dlink 过期 / 链接失效导致的中断，在这里无感恢复：
  /// 作废地址缓存 → 重新解析 → 重新加载 → seek 回中断位置。
  Future<void> _handlePlaybackError(Object error, {Duration? resumeAt}) async {
    if (_recovering) return;
    final chapter = currentChapter;
    if (chapter == null) return;

    _recovering = true;
    // 首次加载就失败时播放器里还没有这一章，它的 position 不是断点，
    // 由调用方把要续播的位置传进来
    final at = resumeAt ?? _player.position;

    try {
      while (_recoveryAttempt < _maxRecoveryAttempts) {
        _recoveryAttempt++;
        // 指数退避（规格「连续失败后报错」）
        final backoff =
            Duration(milliseconds: 400 * (1 << (_recoveryAttempt - 1)));
        await Future<void>.delayed(backoff);

        try {
          _resolver.invalidate(chapter.fsId);
          final media = await _resolver.resolve(chapter, forceRefresh: true);
          // 这里同样必须有超时：恢复流程一旦挂在这一行，_recovering 会永久
          // 停在 true，之后所有播放错误都被那个守卫吞掉，再也无法恢复。
          await _player
              .setAudioSource(
                AudioSource.uri(Uri.parse(media.url)),
                initialPosition: at,
              )
              .timeout(_loadTimeout);
          // 不能 await：just_audio 的 play() 要等到暂停或播完才返回，
          // await 的话恢复流程一直不结束，_recovering 卡在 true，之后的错误全被吞掉
          unawaited(_player.play());
          Log.d('player', '播放已恢复，位置 ${at.inSeconds}s（第 $_recoveryAttempt 次尝试）');
          _recoveryAttempt = 0;
          return;
        } on DriveException catch (e) {
          // 鉴权失败走刷新/重新授权，而不是无意义重试（规格「区分鉴权失败与网络失败」）
          if (e.isAuthProblem) {
            Log.e('player', '恢复失败：授权问题', e);
            await _onAuthFailure();
            _failures.add(PlaybackFailure(e.userMessage, canRetry: false));
            return;
          }
          if (!e.isRetryable) {
            _failures.add(PlaybackFailure(e.userMessage, canRetry: true));
            return;
          }
          Log.d('player', '恢复第 $_recoveryAttempt 次失败，继续退避重试：${e.message}');
        } catch (e) {
          Log.d('player', '恢复第 $_recoveryAttempt 次失败：$e');
        }
      }

      // 达到上限：暂停并保留播放位置，交给用户手动重试
      await _player.pause();
      _failures
          .add(const PlaybackFailure('播放地址反复获取失败，请检查网络后重试', canRetry: true));
    } finally {
      _recovering = false;
    }
  }

  /// 用户手动重试。
  Future<void> retry() async {
    _recoveryAttempt = 0;
    final position = _player.position;
    await _loadCurrent(initialPosition: position);
    unawaited(play());
  }

  // ------------------------------------------------------------ 进度

  void _maybeSaveProgress() {
    if (DateTime.now().difference(_lastProgressSave) < _progressSaveInterval) {
      return;
    }
    unawaited(_saveProgress());
  }

  Future<void> _saveProgress({bool force = false}) async {
    final book = _book;
    if (book == null) return;
    // 准备期间播放器的位置还是上一段音频的，写进去会把新书的断点冲掉
    if (preparing.value) return;
    if (!force &&
        DateTime.now().difference(_lastProgressSave) < _progressSaveInterval) {
      return;
    }
    _lastProgressSave = DateTime.now();
    await _onProgress(book.id, _index, _player.position.inMilliseconds);
  }

  Future<void> disposeHandler() async {
    _stopWatchdog();
    _sleepTimer.dispose();
    preparing.dispose();
    playAfterLoad.dispose();
    await _failures.close();
    await _hints.close();
    await _player.dispose();
  }
}
