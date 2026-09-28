import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../app/services.dart';
import '../../playback/audiobook_handler.dart';
import '../player_screen.dart';
import 'book_cover.dart';

/// 底部迷你播放条：任何页面都能一眼看到在听什么、并快速控制。
///
/// 数据源是 audio_service 的 `mediaItem` 流——它在每次换章时更新，
/// 因此播放一开始这条就会自己出现，换章也会自己刷新。
/// （直接读 handler 的字段是非响应式的，那样点了播放这里不会有反应。）
class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final handler = ref.watch(servicesProvider).handler;
    final theme = Theme.of(context);

    return StreamBuilder<MediaItem?>(
      stream: handler.mediaItem,
      builder: (context, snapshot) {
        final item = snapshot.data;
        if (item == null) return const SizedBox.shrink();

        return Material(
          color: theme.colorScheme.surfaceContainerHigh,
          child: InkWell(
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const PlayerScreen())),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 顶边一条细进度：不点开播放页也知道这一章听到哪了
                _ChapterProgress(handler: handler),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
                  child: Row(
                    children: [
                      BookCover(
                        title: item.album ?? item.title,
                        coverFsId: handler.currentBook?.coverFsId,
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
                            Text(item.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium),
                            Text(item.album ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(color: theme.hintColor)),
                          ],
                        ),
                      ),
                      _PlayPause(handler: handler),
                      IconButton(
                        tooltip: '下一章',
                        icon: const Icon(Icons.skip_next),
                        onPressed: handler.skipToNext,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ChapterProgress extends StatelessWidget {
  const _ChapterProgress({required this.handler});

  final AudiobookHandler handler;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: handler.preparing,
      builder: (context, preparing, _) => StreamBuilder<Duration>(
        stream: handler.player.positionStream,
        builder: (context, snap) {
          final total = handler.player.duration?.inMilliseconds ?? 0;
          final value = preparing || total == 0
              ? null
              : ((snap.data?.inMilliseconds ?? 0) / total).clamp(0.0, 1.0);
          // 准备中显示流动的进度条，表示正在加载
          return LinearProgressIndicator(
            value: preparing ? null : value ?? 0,
            minHeight: 2,
            backgroundColor: Colors.transparent,
          );
        },
      ),
    );
  }
}

/// 与播放页同一套判定：准备中显示的是"加载完会不会播"。
class _PlayPause extends StatelessWidget {
  const _PlayPause({required this.handler});

  final AudiobookHandler handler;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([handler.preparing, handler.playAfterLoad]),
      builder: (context, _) => StreamBuilder<PlayerState>(
        stream: handler.player.playerStateStream,
        builder: (context, snap) {
          final playing = handler.preparing.value
              ? handler.playAfterLoad.value
              : snap.data?.playing ?? false;
          return IconButton(
            tooltip: playing ? '暂停' : '播放',
            icon: Icon(playing ? Icons.pause : Icons.play_arrow),
            onPressed: playing ? handler.pause : handler.play,
          );
        },
      ),
    );
  }
}
