import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/services.dart';
import '../update/app_installer.dart';
import '../update/app_updater.dart';
import 'help_screen.dart';

/// 启动后静默检查一次新版本：同一版本只自动提示一次，检查失败不提示。
Future<void> checkUpdateOnLaunch(BuildContext context, WidgetRef ref) async {
  if (!AppInstaller.supported) return;
  final services = ref.read(servicesProvider);
  final current = await AppInstaller.version();
  if (current.isEmpty) return;
  final AppRelease latest;
  try {
    latest = await ref.read(appUpdaterProvider).latest();
  } catch (_) {
    return;
  }
  if (!AppUpdater.isNewer(latest.version, current)) return;
  if (await services.database.meta(updateSeenMetaKey) == latest.version) {
    return;
  }
  if (!context.mounted) return;
  await showUpdateDialog(context, latest, current);
  await services.database.setMeta(updateSeenMetaKey, latest.version);
}

/// 「我的 → 检查更新」：手动检查并显示结果。
Future<void> checkUpdateManually(BuildContext context, WidgetRef ref) async {
  final messenger = ScaffoldMessenger.of(context);
  final current = await AppInstaller.version();
  try {
    final latest = await ref.read(appUpdaterProvider).latest();
    if (!context.mounted) return;
    if (AppUpdater.isNewer(latest.version, current)) {
      await showUpdateDialog(context, latest, current);
    } else {
      messenger.showSnackBar(const SnackBar(content: Text('已是最新版本')));
    }
  } on UpdateException catch (e) {
    messenger.showSnackBar(SnackBar(
        content: Text(e.message.contains('还没有') ? e.message : '检查失败：$e')));
  } catch (_) {
    messenger.showSnackBar(const SnackBar(content: Text('检查失败：网络错误')));
  }
}

Future<void> showUpdateDialog(
        BuildContext context, AppRelease release, String current) =>
    showDialog<void>(
      context: context,
      builder: (_) => _UpdateDialog(release: release, current: current),
    );

/// 发现新版本：显示更新说明，下载完成后自动打开安装界面。
class _UpdateDialog extends StatefulWidget {
  const _UpdateDialog({required this.release, required this.current});

  final AppRelease release;
  final String current;

  @override
  State<_UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<_UpdateDialog> {
  bool _downloading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final r = widget.release;
    return AlertDialog(
      title: Text('发现新版本 ${r.version}'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 360),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('当前版本 ${widget.current}',
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
              if (r.notes.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(r.notes, style: theme.textTheme.bodySmall),
              ],
              if (_downloading) ...[
                const SizedBox(height: 8),
                Text('正在下载，可在通知栏查看进度；下载完成后会自动打开安装界面。',
                    style: TextStyle(color: theme.colorScheme.primary)),
              ],
              // 各品牌手机安装时会有不同的确认步骤（如小米的增强防护、华为的纯净模式）
              TextButton(
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                onPressed: () {
                  // 弹窗关掉后它的 context 就失效了，先拿到 Navigator
                  final nav = Navigator.of(context)..pop();
                  nav.push(MaterialPageRoute(
                      builder: (_) =>
                          const HelpScreen(section: HelpSections.install)));
                },
                child: const Text('安装被拦截？查看各品牌手机的安装说明'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(_downloading ? '后台下载' : '以后再说'),
        ),
        if (r.apkUrls.isNotEmpty && !_downloading)
          FilledButton(
            onPressed: () async {
              setState(() => _downloading = true);
              try {
                await AppInstaller.download(r.apkUrls, r.version);
              } catch (_) {
                if (!context.mounted) return;
                setState(() => _downloading = false);
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('无法开始下载，请稍后重试')));
              }
            },
            child: const Text('下载更新'),
          ),
      ],
    );
  }
}
