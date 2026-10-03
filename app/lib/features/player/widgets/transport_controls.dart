import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yun_audiobook/app/providers.dart';
import 'package:yun_audiobook/features/player/widgets/skip_icon.dart';
import 'package:yun_audiobook/l10n/l10n.dart';
import 'package:yun_audiobook/playback/media_engine.dart';
import 'package:yun_audiobook/playback/playback_session.dart';

class TransportControls extends ConsumerWidget {
  const TransportControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final snap = ref.watch(playbackProvider).value ?? PlaybackSnapshot.empty;
    final session = ref.read(playbackSessionProvider);
    // 准备中显示的是"加载完会不会播"：点了播放就显示暂停键，按下去就取消自动播放
    // （snap.playing 已按这条规则取值）
    final playing = snap.playing;
    final loading = snap.preparing ||
        snap.engine.state == EngineState.loading ||
        snap.engine.state == EngineState.buffering;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          iconSize: 32,
          icon: const Icon(Icons.skip_previous),
          onPressed: session.previous,
        ),
        IconButton(
          iconSize: 32,
          tooltip: l.playerRewind,
          // 准备中没有可以 seek 的音源
          icon: const SkipIcon(forward: false),
          onPressed: snap.preparing ? null : session.rewind,
        ),
        // 加载、缓冲时不再把播放键换成转圈：原来那几秒里按不了暂停，
        // 按钮还会忽隐忽现。现在按钮一直在，外面套一圈进度表示在加载。
        SizedBox(
          width: 72,
          height: 72,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (loading)
                const SizedBox(
                  width: 72,
                  height: 72,
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
              SizedBox(
                width: 62,
                height: 62,
                child: IconButton.filled(
                  iconSize: 40,
                  tooltip: playing ? l.playerPause : l.playerPlay,
                  icon: Icon(playing ? Icons.pause : Icons.play_arrow),
                  onPressed: playing ? session.pause : session.play,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          iconSize: 32,
          tooltip: l.playerForward,
          icon: const SkipIcon(forward: true),
          onPressed: snap.preparing ? null : session.forward,
        ),
        IconButton(
          iconSize: 32,
          icon: const Icon(Icons.skip_next),
          onPressed: session.next,
        ),
      ],
    );
  }
}
