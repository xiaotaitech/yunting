import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yun_audiobook/core/config.dart';
import 'package:yun_audiobook/l10n/l10n.dart';

/// 凭证未配置时的引导页。
///
/// 百度网盘开放平台的 AppKey 必须由使用者自己注册申请（需实名认证），
/// 这是外部前置条件，不是可以内置的东西——所以这里把步骤直接摆出来。
///
/// 它跑在没有 ProviderScope、没有路由的壳（SetupApp）里，所以保持
/// StatelessWidget，不碰 ref 与 go_router。
class SetupRequiredPage extends StatelessWidget {
  const SetupRequiredPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.setupTitle)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            color: theme.colorScheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                l.setupMissing,
                style: const TextStyle(fontWeight: FontWeight.w600),
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
              const ClipboardData(text: AppConfig.setupHint),
            ),
            icon: const Icon(Icons.copy),
            label: Text(l.setupCopy),
          ),
        ],
      ),
    );
  }
}
