import 'package:flutter/material.dart';

/// 快退/快进 15 秒的图标。
///
/// Material 只有 replay_5 / replay_10 / replay_30，没有 15 秒那一款。
/// 之前拿 replay_10 顶着，结果按钮上印着「10」、按下去跳 15 秒
/// （规格 audio-playback 要求 15 秒），真机上一眼就能看出对不上。
/// 改成不带数字的圆形箭头叠一个「15」；快进方向做水平镜像，两边对称。
class SkipIcon extends StatelessWidget {
  const SkipIcon({required this.forward, super.key});

  final bool forward;

  @override
  Widget build(BuildContext context) {
    final iconTheme = IconTheme.of(context);
    final size = iconTheme.size ?? 24;
    return Stack(
      alignment: Alignment.center,
      children: [
        Transform.scale(
          scaleX: forward ? -1 : 1,
          child: const Icon(Icons.replay),
        ),
        // 数字压在圆环中间，比例照着 replay_10 的观感来。
        Padding(
          padding: EdgeInsets.only(top: size * 0.06),
          child: Text(
            '15',
            style: TextStyle(
              fontSize: size * 0.34,
              fontWeight: FontWeight.w600,
              color: iconTheme.color,
              height: 1,
            ),
          ),
        ),
      ],
    );
  }
}
