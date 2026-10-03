import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yun_audiobook/app/providers.dart';
import 'package:yun_audiobook/features/common/format.dart';
import 'package:yun_audiobook/playback/playback_session.dart';

/// 进度条。
///
/// 拖动时只改本地的值、松手才 seek：原来 onChanged 里直接 seek，拖一下就是
/// 几十次 seek，网络流上每次都要重新缓冲，拖动一卡一卡，圆点还会被
/// 晚到的播放位置拽回去。拖动中两侧时间显示的是手指所在的位置。
///
/// 准备新章期间播放器里还是上一段音频，这时显示新章的续播点和库里记的时长，
/// 并禁止拖动（这些规则都已封装在 PlaybackSnapshot 的 position / duration 里）。
class PositionBar extends ConsumerStatefulWidget {
  const PositionBar({super.key});

  @override
  ConsumerState<PositionBar> createState() => _PositionBarState();
}

class _PositionBarState extends ConsumerState<PositionBar> {
  double? _dragMs;

  @override
  Widget build(BuildContext context) {
    final snap = ref.watch(playbackProvider).value ?? PlaybackSnapshot.empty;
    final duration = snap.duration ?? Duration.zero;
    final max = duration.inMilliseconds.toDouble();
    final position = _dragMs != null
        ? Duration(milliseconds: _dragMs!.round())
        : snap.position;
    final value =
        position.inMilliseconds.clamp(0, duration.inMilliseconds).toDouble();
    final canSeek = !snap.preparing && max > 0;
    final session = ref.read(playbackSessionProvider);

    final theme = Theme.of(context);
    // 默认 Slider 的 thumb 半径 10，在一条听书进度上像个旋钮。
    // 收细轨道、缩小圆点。时间用等宽数字，免得秒数跳动时整行左右抖。
    final timeStyle = theme.textTheme.bodySmall?.copyWith(
      color: _dragMs != null ? theme.colorScheme.primary : theme.hintColor,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            inactiveTrackColor: theme.colorScheme.surfaceContainerHighest,
          ),
          child: Slider(
            value: max == 0 ? 0 : value,
            max: max == 0 ? 1 : max,
            onChangeStart: canSeek ? (v) => setState(() => _dragMs = v) : null,
            onChanged: canSeek ? (v) => setState(() => _dragMs = v) : null,
            onChangeEnd: canSeek
                ? (v) async {
                    await session.seek(Duration(milliseconds: v.round()));
                    // seek 完成后播放位置才跟上，这之前继续显示松手的位置，
                    // 免得圆点先弹回旧位置再跳过去
                    if (mounted) setState(() => _dragMs = null);
                  }
                : null,
          ),
        ),
        Padding(
          // 与 Slider 自带的左右内边距对齐，免得时间比轨道更靠外
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(formatDuration(position), style: timeStyle),
              Text(
                max == 0 ? '--:--' : formatDuration(duration),
                style: timeStyle,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
