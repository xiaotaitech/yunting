import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yun_audiobook/app/providers.dart';
import 'package:yun_audiobook/domain/continue_listening.dart';
import 'package:yun_audiobook/domain/entities.dart';
import 'package:yun_audiobook/features/library/library_controller.dart';

part 'playback_controller.g.dart';

/// 开播请求的结果。界面据此决定进播放页还是给提示。
sealed class OpenResult {
  const OpenResult();
}

/// 已在后台开始准备，界面应立即进入播放页。
class OpenStarted extends OpenResult {
  const OpenStarted();
}

/// 点的正是在播的那一个：直接回播放页，不重新加载。
class OpenAlreadyPlaying extends OpenResult {
  const OpenAlreadyPlaying();
}

/// 不能播，原因给界面展示。
class OpenNotReady extends OpenResult {
  const OpenNotReady(this.reason);
  final NotReadyReason reason;
}

/// 所有「开始听」的入口（书架、续听卡片、详情、历史、离线）共用这一条路径。
/// 原来这段判断在三个页面里各写一份，迟早会对同一种异常给出三种反应。
/// keepAlive：这是无状态的命令入口，没有人 watch 它。自动释放的话，
/// 方法里第一个 await 之后 provider 就已被回收，再 ref.read 会直接抛错
/// （真机上「加入书架」就这样静默失败过）。
@Riverpod(keepAlive: true)
class PlaybackController extends _$PlaybackController {
  @override
  void build() {}

  /// 从合集的断点续播（书架播放键、续听卡片）。
  Future<OpenResult> resume(Series series) async {
    if (_isCurrent(series.id)) return const OpenAlreadyPlaying();
    final episodes = await ref
        .read(libraryControllerProvider.notifier)
        .episodesOf(series.id);
    final card = ContinueListening.from(series, episodes);
    if (!card.canPlay) return OpenNotReady(card.notReadyReason!);
    _start(series, episodes);
    return const OpenStarted();
  }

  /// 播指定的一集（详情页条目、历史、离线列表）。
  ///
  /// [position] 不传时：点的是断点所在那一集就从断点接着听，点别的从头开始。
  Future<OpenResult> playEpisode(
    Series series,
    int index, {
    Duration? position,
  }) async {
    // 点的正是在播的那一集：别重新加载把位置冲回断点
    if (_isCurrent(series.id, index: index)) return const OpenAlreadyPlaying();
    if (series.sourceMissing) {
      return const OpenNotReady(NotReadyReason.sourceMissing);
    }
    final episodes = await ref
        .read(libraryControllerProvider.notifier)
        .episodesOf(series.id);
    if (episodes.isEmpty) {
      return const OpenNotReady(NotReadyReason.episodesPending);
    }
    if (index < 0 || index >= episodes.length) {
      return const OpenNotReady(NotReadyReason.episodeGone);
    }
    final resumeHere = index == series.currentEpisodeIndex && !series.finished;
    _start(
      series,
      episodes,
      index: index,
      position: position ?? (resumeHere ? series.position : Duration.zero),
    );
    return const OpenStarted();
  }

  /// App 只是切后台又回来时，播放器里还装着这一个。此时再 start 会重新加载，
  /// 把正在播的位置冲回库里的断点——那是 5 秒节流之前的位置，
  /// 听感就是「点一下倒退几秒」。
  bool _isCurrent(String seriesId, {int? index}) {
    final s = ref.read(playbackSessionProvider).current;
    if (!s.hasMedia || s.series!.id != seriesId) return false;
    return index == null || s.index == index;
  }

  /// 立刻返回，取地址和加载在后台进行，播放页显示"准备中"。原来是等
  /// 加载完、再 `await play()` 之后才跳转——而 just_audio 的 play() 要到暂停才返回，
  /// 于是点了播放要么干等几秒没反应，要么声音出来了页面却不动。
  /// 加载失败由播放页的 failures 提示接住，带重试。
  void _start(
    Series series,
    List<Episode> episodes, {
    int? index,
    Duration? position,
  }) =>
      unawaited(
        ref
            .read(playbackSessionProvider)
            .start(series, episodes, episodeIndex: index, position: position),
      );
}
