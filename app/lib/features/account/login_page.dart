import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yun_audiobook/app/providers.dart';
import 'package:yun_audiobook/core/errors.dart';
import 'package:yun_audiobook/data/auth/auth_repository.dart';
import 'package:yun_audiobook/features/common/error_text.dart';
import 'package:yun_audiobook/features/common/widgets/brand_mark.dart';
import 'package:yun_audiobook/l10n/l10n.dart';

/// 设备码授权页。
///
/// 选设备码而不是网页回调，是因为它不需要备案域名和回调地址配置，
/// 对个人开发者和本地联调都最省事。
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  DeviceAuthSession? _session;
  bool _busy = false;
  String? _error;

  Future<void> _start() async {
    final l = context.l10n;
    // 授权一成功，router 的 redirect 就会把本页换掉（State 随之 dispose，
    // ref 失效），所以后面要用到的都在这里先取好。
    final auth = ref.read(authRepositoryProvider);
    final sync = ref.read(librarySyncProvider);
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final session = await auth.startDeviceAuth();
      if (!mounted) return;
      setState(() => _session = session);

      await auth.awaitDeviceAuth(session);

      // 新设备首次授权：从网盘拉回书架与进度。
      // 不判断 mounted：此时页面多半已经被路由换走了，恢复仍要做完。
      final restored = await sync.restoreFromCloud();
      if (restored > 0) {
        messenger.showSnackBar(
          SnackBar(content: Text(l.loginRestored(restored))),
        );
      }
    } on DriveException catch (e) {
      // 这里的错误都是设备码流程内部抛的、写给人看的具体原因
      // （码过期 / 用户拒绝 / 等待超时）。用按 kind 归类的 driveError 会变成
      // 笼统的「网盘授权已失效，请重新登录」，反而说不清到底发生了什么。
      if (mounted) {
        setState(() {
          _error = e.message;
          // 同时丢掉那张卡片：继续显示一个已经失效的用户码只会让人白输一次
          _session = null;
        });
      }
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          _error = l.anyError(e);
          _session = null;
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final session = _session;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 与桌面图标同一个标志，授权前后看到的是同一个应用
              const Center(child: BrandMarkView(size: 88)),
              const SizedBox(height: 16),
              Text(
                l.appName,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                l.loginTagline,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.hintColor),
              ),
              const SizedBox(height: 40),
              if (session != null) ...[
                _CodeCard(session: session),
                const SizedBox(height: 16),
              ],
              if (_error != null) ...[
                Card(
                  color: theme.colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(_error!),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              FilledButton.icon(
                onPressed: _busy ? null : _start,
                icon: const Icon(Icons.cloud_outlined),
                label: Text(_busy ? l.loginBusy : l.loginAuthorize),
              ),
              const SizedBox(height: 16),
              Text(
                l.loginPrivacy,
                textAlign: TextAlign.center,
                style:
                    theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 授权码卡片：用户码、授权页地址与两个快捷操作。
class _CodeCard extends StatelessWidget {
  const _CodeCard({required this.session});

  final DeviceAuthSession session;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(l.loginPrompt),
            const SizedBox(height: 12),
            SelectableText(
              session.userCode,
              style: theme.textTheme.headlineSmall?.copyWith(
                letterSpacing: 4,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              session.verificationUrl,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton.icon(
                  onPressed: () => launchUrl(
                    Uri.parse(session.verificationUrl),
                    mode: LaunchMode.externalApplication,
                  ),
                  icon: const Icon(Icons.open_in_browser),
                  label: Text(l.loginOpenBrowser),
                ),
                TextButton.icon(
                  onPressed: () => Clipboard.setData(
                    ClipboardData(text: session.userCode),
                  ),
                  icon: const Icon(Icons.copy),
                  label: Text(l.loginCopyCode),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const LinearProgressIndicator(),
            const SizedBox(height: 8),
            Text(
              l.loginWaiting,
              style:
                  theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
            ),
          ],
        ),
      ),
    );
  }
}
