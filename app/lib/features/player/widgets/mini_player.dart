import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yun_audiobook/app/providers.dart';
import 'package:yun_audiobook/app/routes.dart';
import 'package:yun_audiobook/features/common/error_text.dart';
import 'package:yun_audiobook/features/common/widgets/series_cover.dart';
import 'package:yun_audiobook/l10n/l10n.dart';
import 'package:yun_audiobook/playback/playback_session.dart';

/// 底部迷你播放条：任何页面都能一眼看到在听什么、并快速控制。
///
/// 数据源是会话的 PlaybackSnapshot 流——它在每次换章时更新，
/// 因此播放一开始这条就会自己出现，换章也会自己刷新。
class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snap = ref.watch(playbackProvider).value ?? PlaybackSnapshot.empty;
    final series = snap.series;
    final episode = snap.episode;
    if (series == null || episode == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final l = context.l10n;
    final session = ref.read(playbackSessionProvider);

    return Material(
      color: theme.colorScheme.surfaceContainerHigh,
      child: InkWell(
        onTap: () => context.push(Routes.player),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 顶边一条细进度：不点开播放页也知道这一章听到哪了
            _ChapterProgress(snap: snap),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
              child: Row(
                children: [
                  SeriesCover(
                    title: series.title,
                    coverFsId: series.coverFsId,
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
                          episode.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium,
                        ),
                        Text(
                          series.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: theme.hintColor),
                        ),
                      ],
                    ),
                  ),
                  // 与播放页同一套判定：准备中显示的是"加载完会不会播"
                  // （snap.playing 已按这条规则取值）。
                  IconButton(
                    tooltip: snap.playing ? l.playerPause : l.playerPlay,
                    icon: Icon(snap.playing ? Icons.pause : Icons.play_arrow),
                    onPressed: snap.playing ? session.pause : session.play,
                  ),
                  IconButton(
                    tooltip: l.playerNext(l.unit(series.kind)),
                    icon: const Icon(Icons.skip_next),
                    onPressed: session.next,
                  ),
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
