import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app/services.dart';
import '../core/errors.dart';
import '../data/auth/auth_repository.dart';
import 'widgets/brand_mark.dart';

/// 设备码授权页。
///
/// 选设备码而不是网页回调，是因为它不需要备案域名和回调地址配置，
/// 对个人开发者和本地联调都最省事。
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  DeviceAuthSession? _session;
  bool _busy = false;
  String? _error;

  Future<void> _start() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final auth = ref.read(servicesProvider).auth;
    try {
      final session = await auth.startDeviceAuth();
      if (!mounted) return;
      setState(() => _session = session);

      await auth.awaitDeviceAuth(session);
      if (!mounted) return;

      // 新设备首次授权：从网盘拉回书架与进度
      final messenger = ScaffoldMessenger.of(context);
      await ref.read(servicesProvider).sync.restoreFromCloud();
      if (!mounted) return;
      // 同上：用 refresh 强制重算并等结果，invalidate 只标记失效，
      // 恢复回来的书可能要等到下次重建才显示出来。
      final books = await ref.refresh(shelfProvider.future);
      if (books.isNotEmpty) {
        messenger.showSnackBar(
          SnackBar(content: Text('已从网盘恢复 ${books.length} 本书')),
        );
      }
    } on DriveException catch (e) {
      // 这里的错误都是设备码流程内部抛的、写给人看的具体原因
      // （码过期 / 用户拒绝 / 等待超时）。用按 kind 归类的 userMessage 会变成
      // 笼统的「网盘授权已失效，请重新登录」，反而说不清到底发生了什么。
      if (mounted) {
        setState(() {
          _error = e.message;
          // 同时丢掉那张卡片：继续显示一个已经失效的用户码只会让人白输一次
          _session = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '$e';
          _session = null;
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
              Text('云听书',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(
                '把你自己百度网盘里的有声书\n变成一个真正好用的听书 App',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.hintColor),
              ),
              const SizedBox(height: 40),

              if (session != null) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Text('请在浏览器完成授权'),
                        const SizedBox(height: 12),
                        SelectableText(
                          session.userCode,
                          style: theme.textTheme.headlineSmall?.copyWith(
                              letterSpacing: 4, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Text(session.verificationUrl,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall),
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
                              label: const Text('打开授权页'),
                            ),
                            TextButton.icon(
                              onPressed: () => Clipboard.setData(
                                  ClipboardData(text: session.userCode)),
                              icon: const Icon(Icons.copy),
                              label: const Text('复制用户码'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const LinearProgressIndicator(),
                        const SizedBox(height: 8),
                        Text('等待授权中…',
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: theme.hintColor)),
                      ],
                    ),
                  ),
                ),
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
                label: Text(_busy ? '授权进行中…' : '授权百度网盘'),
              ),
              const SizedBox(height: 16),
              Text(
                '本应用只读取你本人网盘中的文件，不会上传音频，'
                '也不提供任何分享或他人资源访问功能。',
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
