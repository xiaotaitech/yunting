import 'package:flutter/material.dart';

/// 主题。本变更只把原来写在 main 里的配置搬过来；视觉改版在 ③。
abstract final class AppTheme {
  static const _seed = Color(0xFF3F6B4F);

  static ThemeData light() => ThemeData(
        colorSchemeSeed: _seed,
        brightness: Brightness.light,
      );

  static ThemeData dark() => ThemeData(
        colorSchemeSeed: _seed,
        brightness: Brightness.dark,
      );
}
