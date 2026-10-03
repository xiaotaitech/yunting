import 'package:flutter/material.dart';

/// 云听书的标志：一朵云，里面是四根音频条——「网盘里的书，拿来听」。
///
/// 这是图标的唯一来源：应用内（登录页）直接画它，启动图标的 PNG 也由
/// `tool/generate_icons_test.dart` 用它渲染。Android 自适应图标的矢量 XML
/// （res/drawable/ic_launcher_foreground.xml 等）用的是同一套坐标，改这里要一起改。
///
/// 坐标系是自适应图标的 108×108，内容落在中心直径 66 的安全区内。
abstract final class BrandMark {
  static const green = Color(0xFF3F6B4F);
  static const white = Color(0xFFFFFFFF);

  /// 云的外轮廓：底边一条直线，右、上、左三段圆弧。
  static Path cloud() => Path()
    ..moveTo(38, 74)
    ..lineTo(70, 74)
    ..arcToPoint(const Offset(68.96, 52.05),
        radius: const Radius.circular(11), largeArc: true, clockwise: false,)
    ..arcToPoint(const Offset(39.03, 50.04),
        radius: const Radius.circular(15), largeArc: true, clockwise: false,)
    ..arcToPoint(const Offset(38, 74),
        radius: const Radius.circular(12), largeArc: true, clockwise: false,)
    ..close();

  /// 四根音频条（左起 x、上沿、下沿），宽 4，两端圆头。
  static const bars = [
    (41.5, 58.0, 66.0),
    (48.5, 53.0, 71.0),
    (55.5, 56.0, 68.0),
    (62.5, 59.0, 65.0),
  ];

  static Path barsPath() {
    final p = Path();
    for (final (x, top, bottom) in bars) {
      p.addRRect(
          RRect.fromLTRBR(x, top, x + 4, bottom, const Radius.circular(2)),);
    }
    return p;
  }

  /// 在 [size] 的方形画布上画完整图标。
  /// [background] 为 false 时只画前景（透明底，登录页用）；
  /// [contentScale] 是前景占画布的比例：自适应图标 1.0，传统方形图标放大一些才不显小。
  static void paint(Canvas canvas, Size size,
      {bool background = true, double contentScale = 1.0, Color? tint,}) {
    if (background) {
      canvas.drawRect(Offset.zero & size, Paint()..color = green);
    }
    final s = size.shortestSide / 108 * contentScale;
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(s);
    canvas.translate(-54, -55);
    canvas.drawPath(cloud(), Paint()..color = tint ?? white);
    canvas.drawPath(
        barsPath(), Paint()..color = background ? green : (tint ?? green),);
    canvas.restore();
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
