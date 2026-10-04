import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yun_audiobook/app/providers.dart';
import 'package:yun_audiobook/app/routes.dart';
import 'package:yun_audiobook/domain/continue_listening.dart';
import 'package:yun_audiobook/features/common/error_text.dart';
import 'package:yun_audiobook/features/common/format.dart';
import 'package:yun_audiobook/features/common/widgets/series_cover.dart';
import 'package:yun_audiobook/features/shelf/widgets/resume_action.dart';
import 'package:yun_audiobook/l10n/l10n.dart';

/// 首页「继续收听」卡片，位置在书架列表下方——手指够得着的那一头。
///
/// 只读本地库，冷启动时网盘不可达也照常显示；点一下从断点开始播放，
/// 但**不会**自动播放——启动就出声在耳机与车载上是惊吓。
class ContinueListeningCard extends ConsumerWidget {
  const ContinueListeningCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 底部的迷你播放条一出现，卡片就让位：同一本书在一屏上出现两次已经多余，
    // 何况卡片读的是 5 秒节流之前的断点，和播放条的实时位置还对不上。
    // 卡片要解决的是「刚打开 App，还没有播放会话」那一刻的事。
    //
    // 流的首帧到达前先用同步快照兜底，免得卡片闪一下再消失。
    final hasMedia = ref.watch(playbackProvider).value?.hasMedia ??
        ref.read(playbackSessionProvider).current.hasMedia;
    if (hasMedia) return const SizedBox.shrink();

    final entry = ref.watch(continueListeningProvider);

    // 卡片是首屏的加分项，不是书架的前置条件：它自己在转圈或出错时
    // 让位给下面的列表，而不是把整页挡住。一本都没播过时同样什么都不画。
    final data = entry.value;
    if (data == null) return const SizedBox.shrink();

    // 卡片里的书在上面的列表里还会出现一次。不把它从列表里剔掉：那会让
    // 「书架有几本」变得可疑，也会在卡片禁用时让这本书无处可点。两者形态
    // 差得够远，加上这里的留白，不会看成重复渲染。
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: _ContinueCard(entry: data),
    );
  }
}

class _ContinueCard extends ConsumerWidget {
  const _ContinueCard({required this.entry});

  final ContinueListening entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l = context.l10n;
    final series = entry.series;
    final reason = entry.notReadyReason;

    return Card(
      elevation: 0,
      color: theme.colorScheme.primaryContainer,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        // 不能播的时候点卡片进详情页——那里能重新扫章节、也能看到源的状态，
        // 比给一个点了没反应的卡片好。播放动作本身在下面禁用掉。
        onTap: entry.canPlay
            ? () => resumeSeries(context, ref, series)
            : () => context.push(Routes.series(series.id)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.headphones,
                    size: 16,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    l.shelfContinue,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _CardBody(entry: entry),
              // 不能播的原因摆在卡片上，让用户点之前就知道，而不是点了才发现
              if (reason != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 14,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          l.notReady(reason),
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: theme.colorScheme.error),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardBody extends ConsumerWidget {
  const _CardBody({required this.entry});

  final ContinueListening entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SeriesCover(
          title: series.title,
          coverFsId: series.coverFsId,
          localPath: series.coverLocalPath,
          width: 64,
          height: 86,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                series.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _subtitle(l, entry),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer
                      .withValues(alpha: 0.75),
                ),
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 5,
                  backgroundColor: theme.colorScheme.onPrimaryContainer
                      .withValues(alpha: 0.15),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        IconButton.filled(
          tooltip: reason == null ? l.shelfContinue : l.notReady(reason),
          iconSize: 30,
          icon: const Icon(Icons.play_arrow),
          onPressed:
              entry.canPlay ? () => resumeSeries(context, ref, series) : null,
        ),
      ],
    );
  }

  /// 卡片副标题：条目名 + 断点位置。
  ///
  /// 已听完的合集点下去会从第一集重新开始（PlaybackSession.start 的既有规则），
  /// 这件事得写在点击之前。
  static String _subtitle(AppLocalizations l, ContinueListening entry) {
    if (entry.restartsFromBeginning) {
      return l.shelfContinueRestart(l.unit(entry.series.kind));
    }

    final episode = entry.episode;
    if (episode == null) {
      final reason = entry.notReadyReason;
      return reason == null ? '' : l.notReady(reason);
    }

    final position = formatDuration(entry.position);
    final total = episode.duration;
    return total == null
        ? l.shelfContinueListenedTo(episode.title, position)
        : l.shelfContinueProgress(
            episode.title,
            position,
            formatDuration(total),
          );
  }
}
