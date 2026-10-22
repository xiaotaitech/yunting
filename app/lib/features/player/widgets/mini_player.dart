import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yun_audiobook/app/providers.dart';
import 'package:yun_audiobook/app/routes.dart';
import 'package:yun_audiobook/domain/continue_listening.dart';
import 'package:yun_audiobook/domain/entities.dart';
import 'package:yun_audiobook/features/common/error_text.dart';
import 'package:yun_audiobook/features/common/format.dart';
import 'package:yun_audiobook/features/common/widgets/series_cover.dart';
import 'package:yun_audiobook/features/player/playback_controller.dart';
import 'package:yun_audiobook/features/shelf/widgets/resume_action.dart';
import 'package:yun_audiobook/l10n/l10n.dart';
import 'package:yun_audiobook/playback/playback_session.dart';

/// 底部迷你播放条：任何页面都能一眼看到在听什么、并快速控制。
///
/// 数据源是会话的 PlaybackSnapshot 流——它在每次换章时更新，
/// 因此播放一开始这条就会自己出现，换章也会自己刷新。
///
/// 还没有播放会话时（刚打开 App），这条显示上次听的那本、停在断点上
/// （listening-progress 规格「首页续听入口」）：点 ▶ 从断点接着播，
/// 但**不会**自动播放——启动就出声在耳机与车载上是惊吓。
/// 续听和正在播用同一条，点了播放不会出现「卡片消失、换成另一个组件」的跳变。
class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.read(playbackSessionProvider);
    // 流的首帧到达前先用同步快照兜底，免得先闪一下续听状态再换成正在播
    final snap = ref.watch(playbackProvider).value ?? session.current;
    final series = snap.series;
    final episode = snap.episode;
    if (series == null || episode == null) return const _ResumeBar();

    final l = context.l10n;
    return _Bar(
      series: series,
      title: episode.title,
      subtitle: series.title,
      progress: _ChapterProgress(snap: snap),
      onTap: () => context.push(Routes.player),
      actions: [
        // 与播放页同一套判定：准备中显示的是"加载完会不会播"
        // （snap.playing 已按这条规则取值）。
        IconButton(
          tooltip: snap.playing ? l.playerPause : l.playerPlay,
          icon: Icon(snap.playing ? Icons.pause : Icons.play_arrow),
          onPressed: () {
            unawaited(HapticFeedback.selectionClick());
            unawaited(
              snap.playing ? session.pause() : session.play(),
            );
          },
        ),
        IconButton(
          tooltip: l.playerNext(l.unit(series.kind)),
          icon: const Icon(Icons.skip_next),
          onPressed: session.next,
        ),
      ],
    );
  }
}

/// 没有播放会话时的续听状态。一本都没播过时什么都不画。
///
/// 只读本地库，冷启动时网盘不可达也照常显示。
class _ResumeBar extends ConsumerWidget {
  const _ResumeBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 它自己在转圈或出错时直接让位，不挡任何页面
    final entry = ref.watch(continueListeningProvider).value;
    if (entry == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final l = context.l10n;
    final series = entry.series;
    final reason = entry.notReadyReason;

    // 有条目时长就画条目内进度（「这一章听到哪了」），没有就退回全合集进度。
    // 时长要等播放器加载后才回填，新加的书一开始是空的。
    final durationMs = entry.episode?.durationMs;
    final progress = durationMs != null && durationMs > 0
        ? (series.currentPositionMs / durationMs).clamp(0.0, 1.0)
        : entry.progress;

    return _Bar(
      series: series,
      title: entry.episode?.title ?? series.title,
      // 不能播的原因摆在条上，让用户点之前就知道，而不是点了才发现
      subtitle: reason == null ? _subtitle(l, entry) : l.notReady(reason),
      subtitleColor: reason == null ? null : theme.colorScheme.error,
      progress: LinearProgressIndicator(
        value: progress,
        minHeight: 2,
        backgroundColor: Colors.transparent,
      ),
      // 点条子：能播就接着播并打开播放页；不能播就进详情页——那里能重新扫章节、
      // 也能看到源的状态，比点了没反应好
      onTap: entry.canPlay
          ? () => resumeSeries(context, ref, series)
          : () => context.push(Routes.series(series.id)),
      actions: [
        // 点 ▶ 原地接着播，和正在播时的 ▶ 一样不跳页
        IconButton(
          tooltip: reason == null ? l.shelfContinue : l.notReady(reason),
          icon: const Icon(Icons.play_arrow),
          onPressed: entry.canPlay
              ? () async {
                  unawaited(HapticFeedback.selectionClick());
                  final messenger = ScaffoldMessenger.of(context);
                  final result = await ref
                      .read(playbackControllerProvider.notifier)
                      .resume(series);
                  if (result case OpenNotReady(:final reason)) {
                    messenger.showSnackBar(
                      SnackBar(content: Text(l.notReady(reason))),
                    );
                  }
                }
              : null,
        ),
      ],
    );
  }

  /// 副标题：书名 + 断点位置。
  ///
  /// 已听完的合集点下去会从第一集重新开始（PlaybackSession.start 的既有规则），
  /// 这件事得写在点击之前。
  static String _subtitle(AppLocalizations l, ContinueListening entry) {
    if (entry.restartsFromBeginning) {
      return l.shelfContinueRestart(l.unit(entry.series.kind));
    }
    final position = formatDuration(entry.position);
    final total = entry.episode?.duration;
    return total == null
        ? l.shelfContinueListenedTo(entry.series.title, position)
        : l.shelfContinueProgress(
            entry.series.title,
            position,
            formatDuration(total),
          );
  }
}

/// 播放条的骨架：顶边细进度 + 封面 + 两行字 + 右侧按钮。
class _Bar extends StatelessWidget {
  const _Bar({
    required this.series,
    required this.title,
    required this.subtitle,
    required this.progress,
    required this.onTap,
    required this.actions,
    this.subtitleColor,
  });

  final Series series;
  final String title;
  final String subtitle;
  final Color? subtitleColor;
  final Widget progress;
  final VoidCallback onTap;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHigh,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 顶边一条细进度：不点开播放页也知道这一章听到哪了
            progress,
            // 底部安全区放在条子里面，手势条下方也是播放条的底色
            SafeArea(
              top: false,
              minimum: const EdgeInsets.fromLTRB(12, 6, 4, 6),
              child: Row(
                children: [
                  SeriesCover(
                    title: series.title,
                    coverFsId: series.coverFsId,
                    localPath: series.coverLocalPath,
                    width: 40,
                    height: 40,
                    radius: 6,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium,
                        ),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: subtitleColor ?? theme.hintColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...actions,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChapterProgress extends StatelessWidget {
  const _ChapterProgress({required this.snap});

  final PlaybackSnapshot snap;

  @override
  Widget build(BuildContext context) {
    final total = snap.duration?.inMilliseconds ?? 0;
    final value = total == 0
        ? 0.0
        : (snap.position.inMilliseconds / total).clamp(0, 1).toDouble();
    // 准备中显示流动的进度条，表示正在加载
    return LinearProgressIndicator(
      value: snap.preparing ? null : value,
      minHeight: 2,
      backgroundColor: Colors.transparent,
    );
  }
}
