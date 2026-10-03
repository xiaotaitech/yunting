import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yun_audiobook/app/app.dart';
import 'package:yun_audiobook/core/config.dart';
import 'package:yun_audiobook/features/account/setup_required_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // 未配置 AppKey / OAuth 代理时，直接给出可执行的指引，
  // 而不是让用户面对一个点什么都没反应的登录页。
  if (!AppConfig.isConfigured) {
    runApp(const SetupApp(child: SetupRequiredPage()));
    return;
  }

  // 装配（令牌恢复、开库、AudioService.init）在 YunApp 里异步进行，
  // 期间显示启动页，而不是在 runApp 之前白屏等待。
  runApp(const ProviderScope(child: YunApp()));
}
