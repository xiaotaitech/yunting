import 'package:flutter/material.dart';

/// 主题（local-first-drawer-ui）：参考 Claude App 的克制风格——
/// 暖色米白底、陶土橙强调色、无阴影的描边卡片、衬线标题。
///
/// 不打包字体（安装包离 jsDelivr 20MiB 上限只剩约 1.6MiB）：
/// 标题用系统的 serif 族，Android 上中文落到思源宋体。
abstract final class AppTheme {
  static ThemeData light() => _build(
        ColorScheme.fromSeed(
          seedColor: const Color(0xFFC96442),
        ).copyWith(
          primary: const Color(0xFFC96442),
          onPrimary: Colors.white,
          primaryContainer: const Color(0xFFF5DDD2),
          onPrimaryContainer: const Color(0xFF5A2A18),
          secondaryContainer: const Color(0xFFECE6DA),
          onSecondaryContainer: const Color(0xFF2E2A25),
          surface: const Color(0xFFFAF9F5),
          onSurface: const Color(0xFF1F1E1D),
          onSurfaceVariant: const Color(0xFF6B6A65),
          surfaceContainerLowest: Colors.white,
          surfaceContainerLow: const Color(0xFFF4F2EB),
          surfaceContainer: const Color(0xFFEFECE4),
          surfaceContainerHigh: const Color(0xFFE9E5DB),
          surfaceContainerHighest: const Color(0xFFE2DED2),
          outline: const Color(0xFFB4B0A5),
          outlineVariant: const Color(0xFFE3DFD5),
        ),
        card: Colors.white,
      );

  static ThemeData dark() => _build(
        ColorScheme.fromSeed(
          seedColor: const Color(0xFFD97757),
          brightness: Brightness.dark,
        ).copyWith(
          primary: const Color(0xFFD97757),
          onPrimary: const Color(0xFF2B1409),
          primaryContainer: const Color(0xFF5A2C1C),
          onPrimaryContainer: const Color(0xFFF6D6C8),
          secondaryContainer: const Color(0xFF3B3934),
          onSecondaryContainer: const Color(0xFFEDE9DF),
          surface: const Color(0xFF262624),
          onSurface: const Color(0xFFEEECE6),
          onSurfaceVariant: const Color(0xFFA8A59C),
          surfaceContainerLowest: const Color(0xFF1F1E1D),
          surfaceContainerLow: const Color(0xFF2B2A27),
          surfaceContainer: const Color(0xFF30302E),
          surfaceContainerHigh: const Color(0xFF393936),
          surfaceContainerHighest: const Color(0xFF42413D),
          outline: const Color(0xFF6E6C66),
          outlineVariant: const Color(0xFF3E3D39),
        ),
        card: const Color(0xFF30302E),
      );

  static ThemeData _build(ColorScheme scheme, {required Color card}) {
    final base = ThemeData(colorScheme: scheme, useMaterial3: true);
    final text = base.textTheme;
    TextStyle? serif(TextStyle? s) =>
        s?.copyWith(fontFamily: 'serif', fontWeight: FontWeight.w600);
    final rounded12 = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    );

    return base.copyWith(
      scaffoldBackgroundColor: scheme.surface,
      textTheme: text.copyWith(
        headlineSmall: serif(text.headlineSmall),
        titleLarge: serif(text.titleLarge),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: serif(text.titleLarge)
            ?.copyWith(fontSize: 19, color: scheme.onSurface),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        width: 308,
        shape: const RoundedRectangleBorder(),
      ),
      listTileTheme: ListTileThemeData(shape: rounded12),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(shape: rounded12),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(shape: rounded12),
      ),
      searchBarTheme: SearchBarThemeData(
        elevation: const WidgetStatePropertyAll(0),
        backgroundColor: WidgetStatePropertyAll(scheme.surfaceContainer),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        side: BorderSide(color: scheme.outlineVariant),
        shape: const StadiumBorder(),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: rounded12,
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        },
      ),
    );
  }
}
