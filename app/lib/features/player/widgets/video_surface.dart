import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:yun_audiobook/app/providers.dart';
import 'package:yun_audiobook/features/player/video_fullscreen_page.dart';
import 'package:yun_audiobook/l10n/l10n.dart';

/// 播放页上的视频画面（课程条目替代封面）。右下角进全屏。
class VideoSurface extends ConsumerWidget {
  const VideoSurface({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(videoControllerProvider).value;
    final preparing =
        ref.watch(playbackProvider.select((a) => a.value?.preparing ?? false));
    final ready =
        !preparing && controller != null && controller.value.isInitialized;

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: ColoredBox(
        color: Colors.black,
        child: AspectRatio(
          aspectRatio: ready ? controller.value.aspectRatio : 16 / 9,
          child: ready
              ? Stack(
                  children: [
                    Positioned.fill(child: VideoPlayer(controller)),
                    Positioned(
                      right: 4,
                      bottom: 4,
                      child: IconButton(
                        color: Colors.white,
                        tooltip: context.l10n.playerFullscreen,
                        icon: const Icon(Icons.fullscreen),
                        onPressed: () =>
                            Navigator.of(context, rootNavigator: true)
                                .push(VideoFullscreenPage.route()),
                      ),
                    ),
                  ],
                )
              : const _Preparing(),
        ),
      ),
    );
  }
}

/// 取流中。非会员每次要等百度约 8 秒的广告时间，明说出来，免得以为卡死了。
class _Preparing extends StatelessWidget {
  const _Preparing();

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Colors.white70),
            const SizedBox(height: 12),
            Text(
              context.l10n.playerPreparingVideo,
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
}

/// 只画画面、不带控件，全屏页用。
class BareVideo extends ConsumerWidget {
  const BareVideo({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(videoControllerProvider).value;
    if (c == null || !c.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white70),
      );
    }
    return Center(
      child: AspectRatio(
        aspectRatio: c.value.aspectRatio,
        child: VideoPlayer(c),
      ),
    );
  }
}
