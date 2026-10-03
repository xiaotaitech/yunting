import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yun_audiobook/app/providers.dart';
import 'package:yun_audiobook/app/routes.dart';
import 'package:yun_audiobook/domain/entities.dart';
import 'package:yun_audiobook/features/common/error_text.dart';
import 'package:yun_audiobook/features/common/widgets/series_cover.dart';
import 'package:yun_audiobook/features/shelf/widgets/resume_action.dart';
import 'package:yun_audiobook/l10n/l10n.dart';

class ShelfTile extends ConsumerWidget {
  const ShelfTile({required this.series, super.key});

  final Series series;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l = context.l10n;
    // 正在播的这本按播放器的实时条目显示：库里的进度每 5 秒才写一次，
    // 自动续到下一章后书架还停在上一章，和底下的播放条对不上
    final snap = ref.watch(playbackProvider).value;
    final liveIndex =
        snap != null && snap.series?.id == series.id ? snap.index : null;
    final episodeIndex = liveIndex ?? series.currentEpisodeIndex;
    // 一次都没播过的书：原来显示成「第 1 / 3 章 · 33%」，像是听过了
    final notStarted = liveIndex == null &&
        series.lastPlayedAt == null &&
        series.currentEpisodeIndex == 0 &&
        series.currentPositionMs == 0;
    final progress = series.episodeCount == 0 || notStarted
        ? 0.0
        : (episodeIndex + 1) / series.episodeCount;
    final unit = l.unit(series.kind);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(Routes.series(series.id)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              SeriesCover(
                title: series.title,
                coverFsId: series.coverFsId,
                width: 60,
                height: 80,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(series.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium,),
                    if (series.author != null)
                      Text(series.author!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: theme.hintColor),),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            // 从网盘同步回来的书章节还没解析（library_sync 先
                            // 把 chapter_count 置 0，打开详情页时会自动补扫），
                            // 这时「已听至第 1 章 / 共 0 章」是自相矛盾的。
                            series.episodeCount == 0
                                ? l.shelfPendingEpisodes
                                : series.finished && liveIndex == null
                                    ? l.shelfFinished(series.episodeCount, unit)
                                    : notStarted
                                        ? l.shelfNotStarted(
                                            series.episodeCount, unit,)
                                        : l.episodeOfTotal(episodeIndex + 1,
                                            series.episodeCount, unit,),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: theme.hintColor),
                          ),
                        ),
                        // 光有进度条读不出「听到哪了」，补一个百分比。
                        // 等宽数字，免得百分比变化时这一行左右抖。
                        if (series.episodeCount > 0 && !notStarted)
                          Text('${(progress * 100).round()}%',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.hintColor,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // 细一点、带圆角，别像个未打磨的控件
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: progress.clamp(0.0, 1.0),
                        minHeight: 5,
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                      ),
                    ),
                    // 网盘路径消失时保留条目与进度，只做提示（规格要求）
                    if (series.sourceMissing)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Row(
                          children: [
                            Icon(Icons.warning_amber_rounded,
                                size: 14, color: theme.colorScheme.error,),
                            const SizedBox(width: 4),
                            Text(l.shelfSourceMissing,
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(color: theme.colorScheme.error),),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                tooltip: l.shelfContinue,
                icon: const Icon(Icons.play_circle_fill, size: 36),
                onPressed: series.sourceMissing
                    ? null
                    : () => resumeSeries(context, ref, series),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
