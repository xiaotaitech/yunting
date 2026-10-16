import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yun_audiobook/app/providers.dart';
import 'package:yun_audiobook/app/routes.dart';
import 'package:yun_audiobook/core/errors.dart';
import 'package:yun_audiobook/data/auth/auth_repository.dart';
import 'package:yun_audiobook/features/account/web_login_page.dart';
import 'package:yun_audiobook/features/common/error_text.dart';
import 'package:yun_audiobook/features/common/widgets/brand_mark.dart';
import 'package:yun_audiobook/l10n/l10n.dart';

/// 登录页（in-app-baidu-login）。
///
/// 主路径是 App 内登录：百度授权页在 WebView 里打开，登录、授权、回到 App
/// 一气呵成，不用切到浏览器、也不用抄用户码。授权码模式用 redirect_uri=oob，
/// 同样不需要备案域名和回调地址配置。
/// 设备码授权留作备用：WebView 里登录不上（验证码异常等）时，改在浏览器
/// 或另一台设备上授权。
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  DeviceAuthSession? _session;
  bool _busy = false;
  String? _error;

  /// App 内登录：打开授权页 → 拿回 code → 经代理换令牌。
  /// 成功后本页自己关掉（见 build 里的 ref.listen）。
  Future<void> _signInInApp() async {
    final l = context.l10n;
    final auth = ref.read(authRepositoryProvider);
    setState(() {
      _busy = true;
      _error = null;
      _session = null;
    });
    try {
      final url = await auth.authorizeUrl();
      if (!mounted) return;
      final result = await WebLoginPage.open(
        context,
        login: auth,
        authorizeUrl: url,
        title: l.loginWebTitle,
      );
      switch (result) {
        case null:
          break; // 用户关掉了登录页，什么都不用说
        case OAuthDenied():
          if (mounted) setState(() => _error = l.loginDenied);
        case OAuthCode(:final code):
          await auth.exchangeCode(code);
      }
    } on DriveException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } on Object catch (e) {
      if (mounted) setState(() => _error = l.anyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// 设备码授权（备用）：在浏览器或另一台设备上输入用户码。
  Future<void> _start() async {
    final l = context.l10n;
    // 授权一成功本页就会关掉（State 随之 dispose，ref 失效），
    // 所以后面要用到的都在这里先取好。
    final auth = ref.read(authRepositoryProvider);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final session = await auth.startDeviceAuth();
      if (!mounted) return;
      setState(() => _session = session);

      await auth.awaitDeviceAuth(session);
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
    // 登录成功：回到打开登录页的地方（书架、我的、添加书籍）
    ref.listen(authStateProvider, (_, next) {
      if (next.value != AuthState.signedIn) return;
      context.canPop() ? context.pop() : context.go(Routes.shelf);
    });

    return Scaffold(
      // 登录页是从书架、我的等处按需打开的，留一个返回
      appBar: AppBar(),
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
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: _busy ? null : _signInInApp,
                icon: const Icon(Icons.cloud_outlined),
                label: Text(_busy ? l.loginBusy : l.loginAuthorize),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: _busy ? null : _start,
                child: Text(l.loginOtherDevice),
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
