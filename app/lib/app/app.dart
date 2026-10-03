import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yun_audiobook/app/providers.dart';
import 'package:yun_audiobook/app/router.dart';
import 'package:yun_audiobook/app/theme.dart';
import 'package:yun_audiobook/features/common/error_text.dart';
import 'package:yun_audiobook/features/common/widgets/brand_mark.dart';
import 'package:yun_audiobook/l10n/l10n.dart';

const _locales = [Locale('zh')];
const List<LocalizationsDelegate<Object>> _delegates = [
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

/// 根组件：装配完成前显示启动页，失败显示原因与重试，完成后交给路由。
class YunApp extends ConsumerWidget {
  const YunApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boot = ref.watch(bootstrapProvider);
    if (!boot.hasValue) {
      return _plain(
        boot.hasError ? _BootError(error: boot.error!) : const _Splash(),
      );
    }
    return MaterialApp.router(
      onGenerateTitle: (c) => c.l10n.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      localizationsDelegates: _delegates,
      supportedLocales: _locales,
      routerConfig: ref.watch(routerProvider),
    );
  }
}

/// 不带路由的壳：启动页、出错页、配置引导页用。
Widget _plain(Widget home) => MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      localizationsDelegates: _delegates,
      supportedLocales: _locales,
      home: home,
    );

/// 未配置 AppKey / OAuth 代理时的根组件。
class SetupApp extends StatelessWidget {
  const SetupApp({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => _plain(child);
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const BrandMarkView(size: 72),
              const SizedBox(height: 24),
              Text(context.l10n.splashLoading),
            ],
          ),
        ),
      );
}

class _BootError extends ConsumerWidget {
  const _BootError({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l.bootstrapFailed(l.anyError(error))),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.invalidate(bootstrapProvider),
                child: Text(l.actionRetry),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
