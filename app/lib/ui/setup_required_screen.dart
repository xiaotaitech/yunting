import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/config.dart';

/// 凭证未配置时的引导页。
///
/// 百度网盘开放平台的 AppKey 必须由使用者自己注册申请（需实名认证），
/// 这是外部前置条件，不是可以内置的东西——所以这里把步骤直接摆出来。
class SetupRequiredScreen extends StatelessWidget {
  const SetupRequiredScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('需要先完成配置')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            color: theme.colorScheme.errorContainer,
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                '尚未注入百度网盘 AppKey 与 OAuth 代理地址，应用无法访问网盘。',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const SelectableText(
            AppConfig.setupHint,
            style: TextStyle(fontFamily: 'monospace', height: 1.6),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => Clipboard.setData(
                const ClipboardData(text: AppConfig.setupHint)),
            icon: const Icon(Icons.copy),
            label: const Text('复制配置步骤'),
          ),
        ],
      ),
    );
  }
}
