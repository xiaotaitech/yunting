import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/services.dart';
import 'core/config.dart';
import 'ui/setup_required_screen.dart';
import 'ui/root_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 未配置 AppKey / OAuth 代理时，直接给出可执行的指引，
  // 而不是让用户面对一个点什么都没反应的登录页。
  if (!AppConfig.isConfigured) {
    runApp(const _App(child: SetupRequiredScreen()));
    return;
  }

  final services = await AppServices.bootstrap();
  runApp(ProviderScope(
    overrides: [servicesProvider.overrideWithValue(services)],
    child: const _App(child: RootScreen()),
  ));
}

class _App extends StatelessWidget {
  const _App({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '云听书',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF3F6B4F),
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: const Color(0xFF3F6B4F),
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      home: child,
    );
  }
}
