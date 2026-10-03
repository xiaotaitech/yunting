import 'package:flutter/material.dart';

/// 云听书的标志：一副耳机，两只耳罩之间一个播放键——「听」，也能「看」。
///
/// 这是图标的唯一来源：应用内（启动页、登录页）直接画它，启动图标的 PNG
/// 也由 `tool/generate_icons_test.dart` 用它渲染。Android 自适应图标、单色图标
/// 与通知栏图标的矢量 XML（res/drawable/ic_launcher_*.xml、ic_stat_yun.xml）
/// 用的是同一套坐标，改这里要一起改。
///
/// 坐标系是自适应图标的 108×108，内容（x 29–79，y 34–74）落在中心直径 66 的
/// 安全区内，任何形状的遮罩都裁不到。
abstract final class BrandMark {
  /// 背景渐变：左上暖橙到右下朱红。
  static const gradientStart = Color(0xFFFF8A4C);
  static const gradientEnd = Color(0xFFE2543B);
  static const white = Color(0xFFFFFFFF);

  /// 头梁：圆心 (54,56)、半径 19 的上半圆弧，线宽 6，圆头。
  static const bandCenter = Offset(54, 56);
  static const bandRadius = 19.0;
  static const bandWidth = 6.0;

  /// 耳罩：正好落在头梁两端的正下方，左右对称。
  static final cups = [
    RRect.fromLTRBR(29, 55, 41, 74, const Radius.circular(5)),
    RRect.fromLTRBR(67, 55, 79, 74, const Radius.circular(5)),
  ];

  /// 播放键：几何重心与耳罩的垂直中线对齐；描一圈同色圆角边让三个角变圆。
  static Path play() => Path()
    ..moveTo(50, 57.5)
    ..lineTo(50, 71.5)
    ..lineTo(61.5, 64.5)
    ..close();
  static const playCornerStroke = 3.0;

  /// 在 [size] 的方形画布上画完整图标。
  /// [background] 为 false 时只画前景（透明底）；
  /// [contentScale] 是前景占画布的比例：自适应图标 1.0，传统方形图标放大一些才不显小。
  static void paint(
    Canvas canvas,
    Size size, {
    bool background = true,
    double contentScale = 1.0,
    Color? tint,
  }) {
    if (background) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [gradientStart, gradientEnd],
          ).createShader(Offset.zero & size),
      );
    }
    final fg = tint ?? white;
    final s = size.shortestSide / 108 * contentScale;
    canvas
      ..save()
      ..translate(size.width / 2, size.height / 2)
      ..scale(s)
      ..translate(-54, -54)
      ..drawArc(
        Rect.fromCircle(center: bandCenter, radius: bandRadius),
        3.141592653589793,
        3.141592653589793,
        false,
        Paint()
          ..color = fg
          ..style = PaintingStyle.stroke
          ..strokeWidth = bandWidth
          ..strokeCap = StrokeCap.round,
      );
    for (final cup in cups) {
      canvas.drawRRect(cup, Paint()..color = fg);
    }
    canvas
      ..drawPath(
        play(),
        Paint()
          ..color = fg
          ..style = PaintingStyle.fill,
      )
      ..drawPath(
        play(),
        Paint()
          ..color = fg
          ..style = PaintingStyle.stroke
          ..strokeWidth = playCornerStroke
          ..strokeJoin = StrokeJoin.round,
      )
      ..restore();
  }
}

/// 应用内显示的标志。
class BrandMarkView extends StatelessWidget {
  const BrandMarkView({super.key, this.size = 96});

  final double size;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.23),
        child: CustomPaint(size: Size.square(size), painter: _Painter()),
      );
}

class _Painter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) =>
      BrandMark.paint(canvas, size, contentScale: 1.35);

  @override
  bool shouldRepaint(_Painter oldDelegate) => false;
}
