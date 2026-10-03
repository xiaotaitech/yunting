import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yun_audiobook/app/providers.dart';
import 'package:yun_audiobook/features/player/widgets/position_bar.dart';
import 'package:yun_audiobook/features/player/widgets/transport_controls.dart';
import 'package:yun_audiobook/features/player/widgets/video_surface.dart';
import 'package:yun_audiobook/l10n/l10n.dart';
import 'package:yun_audiobook/playback/playback_session.dart';

/// 横屏全屏看课。点画面显示 / 隐藏控件，3 秒不动自动隐藏。
class VideoFullscreenPage extends ConsumerStatefulWidget {
  const VideoFullscreenPage({super.key});

  static Route<void> route() => PageRouteBuilder<void>(
        pageBuilder: (_, __, ___) => const VideoFullscreenPage(),
        transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: a, child: child),
      );

  @override
  ConsumerState<VideoFullscreenPage> createState() =>
      _VideoFullscreenPageState();
}

class _VideoFullscreenPageState extends ConsumerState<VideoFullscreenPage> {
  bool _controlsVisible = true;
  Timer? _hide;

  @override
  void initState() {
    super.initState();
    unawaited(
      SystemChrome.setPreferredOrientations(const [
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]),
    );
    unawaited(
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky),
    );
    _scheduleHide();
  }

  @override
  void dispose() {
    _hide?.cancel();
    // 退出全屏：恢复竖屏与系统栏
    unawaited(SystemChrome.setPreferredOrientations(const []));
    unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
    super.dispose();
  }

  void _scheduleHide() {
    _hide?.cancel();
    _hide = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _controlsVisible = false);
    });
  }

  void _toggle() {
    setState(() => _controlsVisible = !_controlsVisible);
    if (_controlsVisible) _scheduleHide();
  }

  @override
  Widget build(BuildContext context) {
    final title = ref.watch(
      playbackProvider.select((a) => a.value?.episode?.title ?? ''),
    );
    // 自动续下一课时全屏保持；整个会话都没有视频了（比如切到了音频）就退出
    ref.listen<AsyncValue<PlaybackSnapshot>>(playbackProvider, (_, next) {
      if (next.value?.hasMedia == false) Navigator.of(context).maybePop();
    });

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _toggle,
        child: Stack(
          children: [
            const Positioned.fill(child: BareVideo()),
            AnimatedOpacity(
              opacity: _controlsVisible ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: IgnorePointer(
                ignoring: !_controlsVisible,
                child: _Overlay(title: title, onInteract: _scheduleHide),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Overlay extends StatelessWidget {
  const _Overlay({required this.title, required this.onInteract});

  final String title;
  final VoidCallback onInteract;

  @override
  Widget build(BuildContext context) => Theme(
        // 控件画在视频上：统一用暗色主题，白字白图标
        data: ThemeData(
          brightness: Brightness.dark,
          colorSchemeSeed: Theme.of(context).colorScheme.primary,
        ),
        // Builder：下面的 Theme.of 要取到上面这层暗色主题，不能用外面的 context
        child: Builder(
          builder: (context) => Listener(
            onPointerDown: (_) => onInteract(),
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black54, Colors.transparent, Colors.black87],
                  stops: [0, 0.4, 1],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          IconButton(
                            tooltip: context.l10n.playerExitFullscreen,
                            icon: const Icon(Icons.fullscreen_exit),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      const PositionBar(),
                      const TransportControls(),
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}
