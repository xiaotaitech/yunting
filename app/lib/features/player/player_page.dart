import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yun_audiobook/app/providers.dart';
import 'package:yun_audiobook/domain/entities.dart';
import 'package:yun_audiobook/features/common/error_text.dart';
import 'package:yun_audiobook/features/common/widgets/series_cover.dart';
import 'package:yun_audiobook/features/library/library_controller.dart';
import 'package:yun_audiobook/features/player/widgets/player_actions.dart';
import 'package:yun_audiobook/features/player/widgets/position_bar.dart';
import 'package:yun_audiobook/features/player/widgets/transport_controls.dart';
import 'package:yun_audiobook/features/player/widgets/video_surface.dart';
import 'package:yun_audiobook/l10n/l10n.dart';
import 'package:yun_audiobook/playback/playback_session.dart';

/// 播放页（audio-playback 规格）。
class PlayerPage extends ConsumerStatefulWidget {
  const PlayerPage({super.key});

  @override
  ConsumerState<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends ConsumerState<PlayerPage> {
  // 原来这两个订阅从不取消：每进一次播放页就多挂一个监听，页面关掉后还在
  StreamSubscription<PlaybackHint>? _hintSub;
  StreamSubscription<PlaybackFailure>? _failureSub;

  @override
  void dispose() {
    unawaited(_hintSub?.cancel());
    unawaited(_failureSub?.cancel());
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final session = ref.read(playbackSessionProvider);

    // 反复缓冲时提示改用离线下载，并直接给出一键下载入口
    // （规格「速率不足提示」）
    _hintSub = session.hints.listen((hint) {
      if (!mounted) return;
      final l = context.l10n;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.playbackHint(hint)),
          duration: const Duration(seconds: 8),
          action: SnackBarAction(
            label: l.playerDownloadSeries,
            onPressed: _downloadCurrent,
          ),
        ),
      );
    });

    // 恢复失败达到上限时给出可重试的提示（规格「连续失败后报错」）
    _failureSub = session.failures.listen((f) {
      if (!mounted) return;
      final l = context.l10n;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.playbackFailure(f)),
          action: f.canRetry
              ? SnackBarAction(
                  label: l.actionRetry,
                  onPressed: () => unawaited(session.retry()),
                )
              : null,
          duration: const Duration(seconds: 6),
        ),
      );
    });
  }

  Future<void> _downloadCurrent() async {
    final snap = ref.read(playbackSessionProvider).current;
    final series = snap.series;
    if (series == null) return;
    // 先取 messenger 与文案，避免跨 await 后再碰 context
    final messenger = ScaffoldMessenger.of(context);
    final l = context.l10n;
    await ref.read(libraryControllerProvider.notifier).downloadAll(series);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          l.playerDownloadQueued(snap.episodes.length, l.unit(series.kind)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 用快照流驱动，换章时页面会自己刷新；
    // 自动续播后标题不会停在上一章。只取标题相关字段，
    // 避免 200ms 一次的位置更新重建整页。
    final (series, episode, index, count) = ref.watch(
      playbackProvider.select((a) {
        final s = a.value;
        return (s?.series, s?.episode, s?.index ?? 0, s?.episodes.length ?? 0);
      }),
    );

    if (series == null || episode == null) {
      return Scaffold(
        body: Center(child: Text(context.l10n.playerNothingPlaying)),
      );
    }
    return _PlayerBody(
      series: series,
      episode: episode,
      index: index,
      count: count,
    );
  }
}

class _PlayerBody extends StatelessWidget {
  const _PlayerBody({
    required this.series,
    required this.episode,
    required this.index,
    required this.count,
  });

  final Series series;
  final Episode episode;
  final int index;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(series.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          children: [
            // 封面撑到可用宽度的六成多。原来固定 200px 吊在一大片空白正中，
            // 上下留白远大于内容本身，整屏没有重心。上限 300 防止在平板或
            // 横屏上糊成一整块。
            Expanded(
              child: Center(
                // 课程条目显示画面（可全屏）；有声书显示封面
                child: episode.mediaKind == MediaKind.video
                    ? const VideoSurface()
                    : LayoutBuilder(
                        builder: (context, box) {
                          final side = math.min<double>(
                            math.min<double>(
                              box.maxWidth * 0.64,
                              box.maxHeight,
                            ),
                            300,
                          );
                          return SeriesCover(
                            title: series.title,
                            coverFsId: series.coverFsId,
                            width: side,
                            height: side,
                            radius: 18,
                          );
                        },
                      ),
              ),
            ),
            Text(
              episode.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  l.episodeOfTotal(index + 1, count, l.unit(series.kind)),
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.hintColor),
                ),
                // 「已离线」原来只是句灰色小字，混在章节计数里根本看不见。
                // 它是「这章断网也能听」的承诺，值得一个标识。
                if (episode.isCached) ...[
                  const SizedBox(width: 8),
                  Icon(
                    Icons.offline_pin,
                    size: 14,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    l.playerOffline,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.primary),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            const PositionBar(),
            const SizedBox(height: 8),
            const TransportControls(),
            const SizedBox(height: 16),
            PlayerActions(kind: series.kind),
          ],
        ),
      ),
    );
  }
}
