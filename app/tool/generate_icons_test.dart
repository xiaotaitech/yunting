// 从 BrandMark 渲染启动图标 PNG（Android 旧版方形图标与 iOS AppIcon）。
// 改了 lib/ui/widgets/brand_mark.dart 之后运行：
//
//   cd app && flutter test tool/generate_icons_test.dart
//
// Android 8.0 起用的是 res/drawable 下的矢量自适应图标，不经过这里。
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yun_audiobook/ui/widgets/brand_mark.dart';

Future<void> _write(String path, int px, {required bool rounded}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final size = Size.square(px.toDouble());
  if (rounded) {
    // Android 旧版图标：圆角方形，四角透明
    canvas.clipRRect(
        RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(px * 0.2)));
  }
  // 方形图标没有自适应图标那圈留白，前景放大一些才不显小
  BrandMark.paint(canvas, size, contentScale: 1.35);
  final image = await recorder.endRecording().toImage(px, px);
  final png = await image.toByteData(format: ui.ImageByteFormat.png);
  File(path)
    ..parent.createSync(recursive: true)
    ..writeAsBytesSync(png!.buffer.asUint8List());
}

void main() {
  testWidgets('生成启动图标', (tester) async {
    await tester.runAsync(() async {
      const res = 'android/app/src/main/res';
      const android = {
        'mdpi': 48,
        'hdpi': 72,
        'xhdpi': 96,
        'xxhdpi': 144,
        'xxxhdpi': 192
      };
      for (final e in android.entries) {
        await _write('$res/mipmap-${e.key}/ic_launcher.png', e.value,
            rounded: true);
      }

      // iOS 要求不透明的方形图，圆角由系统加
      const ios = 'ios/Runner/Assets.xcassets/AppIcon.appiconset';
      final names = RegExp(r'Icon-App-([\d.]+)x[\d.]+@(\d)x\.png');
      for (final f in Directory(ios).listSync().whereType<File>()) {
        final m = names.firstMatch(f.uri.pathSegments.last);
        if (m == null) continue;
        final px = (double.parse(m.group(1)!) * int.parse(m.group(2)!)).round();
        await _write(f.path, px, rounded: false);
      }
    });
  });
}
