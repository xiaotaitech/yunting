import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yun_audiobook/app/providers.dart';
import 'package:yun_audiobook/app/routes.dart';
import 'package:yun_audiobook/data/local/settings_dao.dart';
import 'package:yun_audiobook/features/help/help_page.dart';
import 'package:yun_audiobook/features/update/app_installer.dart';
import 'package:yun_audiobook/features/update/app_updater.dart';
import 'package:yun_audiobook/l10n/l10n.dart';

/// 启动后静默检查一次新版本：同一版本只自动提示一次，检查失败不提示。
Future<void> checkUpdateOnLaunch(BuildContext context, WidgetRef ref) async {
  if (!AppInstaller.supported) return;
  final settings = ref.read(databaseProvider).settingsDao;
  final current = await AppInstaller.version();
  if (current.isEmpty) return;
  final AppRelease latest;
  try {
    latest = await ref.read(appUpdaterProvider).latest();
  } on Object {
    return;
  }
  if (!AppUpdater.isNewer(latest.version, current)) return;
  if (await settings.read(SettingsDao.updateSeenKey) == latest.version) {
    return;
  }
  if (!context.mounted) return;
  await showUpdateDialog(context, latest, current);
  await settings.write(SettingsDao.updateSeenKey, latest.version);
}

/// 「我的 → 检查更新」：手动检查并显示结果。
Future<void> checkUpdateManually(BuildContext context, WidgetRef ref) async {
  final l = context.l10n;
  final messenger = ScaffoldMessenger.of(context);
  final current = await AppInstaller.version();
  try {
    final latest = await ref.read(appUpdaterProvider).latest();
    if (!context.mounted) return;
    if (AppUpdater.isNewer(latest.version, current)) {
      await showUpdateDialog(context, latest, current);
    } else {
      messenger.showSnackBar(SnackBar(content: Text(l.updateLatest)));
    }
  } on UpdateException catch (e) {
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          e.message.contains('还没有') ? e.message : l.updateCheckFailed('$e'),
        ),
      ),
    );
  } on Object {
    messenger.showSnackBar(SnackBar(content: Text(l.updateCheckFailedNetwork)));
  }
}

Future<void> showUpdateDialog(
  BuildContext context,
  AppRelease release,
  String current,
) =>
    showDialog<void>(
      context: context,
      builder: (_) => _UpdateDialog(release: release, current: current),
    );

/// 发现新版本：显示更新说明，下载完成后自动打开安装界面。
class _UpdateDialog extends ConsumerStatefulWidget {
  const _UpdateDialog({required this.release, required this.current});

  final AppRelease release;
  final String current;

  @override
  ConsumerState<_UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends ConsumerState<_UpdateDialog> {
  bool _downloading = false;

  /// 正在测速（下载前那几秒）。
  bool _probing = false;

  /// 实际用的线路（测速后排第一的主机名）。
  String? _line;

  /// 先测速排好线路，再交给系统下载器；一条失败它会自动换下一条。
  Future<void> _download() async {
    final l = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _downloading = true;
      _probing = true;
    });
    try {
      final urls = await ref
          .read(appUpdaterProvider)
          .fastestFirst(widget.release.apkUrls);
      if (mounted) {
        setState(() {
          _probing = false;
          _line = AppUpdater.hostOf(urls.first);
        });
      }
      await AppInstaller.download(urls, widget.release.version);
    } on Object {
      if (!mounted) return;
      setState(() {
        _downloading = false;
        _probing = false;
      });
      messenger.showSnackBar(SnackBar(content: Text(l.updateDownloadFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final r = widget.release;
    return AlertDialog(
      title: Text(l.updateFound(r.version)),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 360),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l.updateCurrent(widget.current),
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
              if (r.notes.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(r.notes, style: theme.textTheme.bodySmall),
              ],
              if (_downloading) ...[
                const SizedBox(height: 8),
                Text(
                  _probing ? l.updateProbing : l.updateDownloading,
                  style: TextStyle(color: theme.colorScheme.primary),
                ),
                if (_line != null)
                  Text(
                    l.updateLine(_line!),
                    style: theme.textTheme.bodySmall,
                  ),
              ],
              // 各品牌手机安装时会有不同的确认步骤（如小米的增强防护、华为的纯净模式）
              TextButton(
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                onPressed: () {
                  // 弹窗关掉后它的 context 就失效了，先拿到 router
                  final router = GoRouter.of(context);
                  Navigator.of(context).pop();
                  unawaited(
                    router.push<void>(Routes.help(HelpSections.install)),
                  );
                },
                child: Text(l.updateBlocked),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(_downloading ? l.updateBackground : l.updateLater),
        ),
        if (r.apkUrls.isNotEmpty && !_downloading)
          FilledButton(
            onPressed: _download,
            child: Text(l.updateDownload),
          ),
      ],
    );
  }
}
