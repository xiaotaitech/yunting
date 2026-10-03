import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yun_audiobook/app/providers.dart';
import 'package:yun_audiobook/app/routes.dart';
import 'package:yun_audiobook/core/config.dart';
import 'package:yun_audiobook/core/logging.dart';
import 'package:yun_audiobook/data/local/settings_dao.dart';
import 'package:yun_audiobook/domain/entities.dart';
import 'package:yun_audiobook/features/account/account_controller.dart';
import 'package:yun_audiobook/features/common/error_text.dart';
import 'package:yun_audiobook/features/common/format.dart';
import 'package:yun_audiobook/features/help/help_page.dart';
import 'package:yun_audiobook/features/shelf/sync_controller.dart';
import 'package:yun_audiobook/features/update/app_installer.dart';
import 'package:yun_audiobook/features/update/update_dialog.dart';
import 'package:yun_audiobook/l10n/l10n.dart';

/// 「我的」（app-layout 规格）：原来的设置页平铺了播放开关、离线、同步、
/// 隐私说明、诊断信息和退出登录，没有层次。现在按「收听 / 播放 / 关于 / 账号」分组。
/// 隐私承诺挪进了帮助的「隐私」一节，这里留一个入口。
class MinePage extends ConsumerWidget {
  const MinePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l.navMine)),
      body: FutureBuilder<String>(
        future: AppInstaller.version(),
        builder: (context, version) {
          final v = version.data ?? '';
          return ListView(
            children: [
              _Group(l.mineGroupListen),
              // 用量直接显示在副标题上，不用点进去就能知道占了多少
              const _OfflineEntry(),
              const _SyncTile(),
              _Group(l.mineGroupPlayback),
              const _ResumeSwitch(),
              _Group(l.mineGroupAbout),
              // iOS 不允许侧载安装，没有应用内更新
              if (AppInstaller.supported) _UpdateTile(version: v),
              _Entry(
                Icons.help_outline,
                l.mineHelp,
                () => context.push(Routes.help()),
              ),
              _Entry(
                Icons.privacy_tip_outlined,
                l.minePrivacy,
                () => context.push(Routes.help(HelpSections.privacy)),
              ),
              const _Diagnostics(),
              // 演示模式没有百度账号，不存在"退出"
              if (!AppConfig.demoMode) ...[
                _Group(l.mineGroupAccount),
                const _SignOutTile(),
              ],
              _Footer(version: v),
            ],
          );
        },
      ),
    );
  }
}

/// 组标题：主色小字 + 分隔线。
class _Group extends StatelessWidget {
  const _Group(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(
            title,
            style: theme.textTheme.labelLarge
                ?.copyWith(color: theme.colorScheme.primary),
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }
}

class _Entry extends StatelessWidget {
  const _Entry(this.icon, this.title, this.onTap);

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      );
}

class _SyncTile extends ConsumerWidget {
  const _SyncTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final lastSync = ref.watch(lastSyncAtProvider).value;
    final syncing = ref.watch(syncControllerProvider);

    return ListTile(
      leading: const Icon(Icons.sync),
      title: Text(l.mineSyncNow),
      subtitle: Text(
        lastSync == null
            ? l.mineNeverSynced(AppConfig.syncDir)
            : l.mineLastSync(formatSyncTime(l, lastSync)),
      ),
      onTap: syncing
          ? null
          : () async {
              final messenger = ScaffoldMessenger.of(context);
              final ok =
                  await ref.read(syncControllerProvider.notifier).syncNow();
              messenger.showSnackBar(
                SnackBar(
                  content: Text(ok ? l.mineSyncDone : l.mineSyncFailed),
                ),
              );
            },
    );
  }
}

class _ResumeSwitch extends ConsumerWidget {
  const _ResumeSwitch();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    return SwitchListTile(
      secondary: const Icon(Icons.phone_callback_outlined),
      title: Text(l.mineResumeTitle),
      subtitle: Text(l.mineResumeSubtitle),
      value: ref.watch(resumeAfterInterruptionProvider),
      onChanged: (v) =>
          ref.read(resumeAfterInterruptionProvider.notifier).set(value: v),
    );
  }
}

class _UpdateTile extends StatefulWidget {
  const _UpdateTile({required this.version});

  final String version;

  @override
  State<_UpdateTile> createState() => _UpdateTileState();
}

class _UpdateTileState extends State<_UpdateTile> {
  bool _checking = false;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    // Consumer 只为拿到 ref 去检查更新，状态只在这里
    return Consumer(
      builder: (context, ref, _) => ListTile(
        leading: const Icon(Icons.system_update_outlined),
        title: Text(l.mineCheckUpdate),
        subtitle: Text(
          _checking ? l.mineChecking : l.mineCurrentVersion(widget.version),
        ),
        enabled: !_checking,
        onTap: () async {
          setState(() => _checking = true);
          await checkUpdateManually(context, ref);
          if (mounted) setState(() => _checking = false);
        },
      ),
    );
  }
}

/// OAuth 代理与 AppKey 是排查问题用的，正常使用根本不需要看见
class _Diagnostics extends StatelessWidget {
  const _Diagnostics();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return ExpansionTile(
      leading: const Icon(Icons.bug_report_outlined),
      title: Text(l.mineDiagnostics),
      subtitle: Text(l.mineDiagnosticsSubtitle),
      children: [
        ListTile(
          dense: true,
          title: Text(l.mineOAuthProxy),
          subtitle: Text(
            AppConfig.oauthProxyBase.isEmpty
                ? l.mineNotConfigured
                : AppConfig.oauthProxyBase,
          ),
        ),
        ListTile(
          dense: true,
          title: Text(l.mineAppKey),
          subtitle: Text(Log.redact(AppConfig.baiduAppKey)),
        ),
        ListTile(
          dense: true,
          title: Text(l.mineUpdateSource),
          subtitle: const Text(AppConfig.releaseRepo),
        ),
      ],
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.version});

  final String version;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      child: Text(
        l.mineFooter(l.appName, version.isEmpty ? '' : ' $version'),
        style: theme.textTheme.bodySmall
            ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      ),
    );
  }
}

class _SignOutTile extends ConsumerWidget {
  const _SignOutTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    return ListTile(
      // 不用错误色：它不是破坏性操作，书架与收听进度会保留。
      // 真正需要确认的那一步在下面的对话框里。
      leading: const Icon(Icons.logout),
      title: Text(l.mineSignOut),
      subtitle: Text(l.mineSignOutSubtitle),
      onTap: () async {
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l.mineSignOut),
            content: Text(l.mineSignOutBody),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l.actionCancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l.mineSignOutConfirm),
              ),
            ],
          ),
        );
        if (ok != true) return;
        // 清 dlink 缓存、停播放、清授权都在 controller 里
        await ref.read(accountControllerProvider.notifier).signOut();
      },
    );
  }
}

/// 「离线管理」入口。
class _OfflineEntry extends ConsumerWidget {
  const _OfflineEntry();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final usage = ref.watch(cacheUsageProvider);
    final quotaGb = ref.watch(offlineQuotaGbProvider).value ??
        SettingsDao.offlineQuotaDefaultGb;
    final used = (usage.value ?? const {}).values.fold<int>(0, (a, b) => a + b);
    // 下载队列没有流，随用量（下载进度写库）一起重算
    final queued = ref.watch(downloadManagerProvider).queuedCount;

    return ListTile(
      leading: const Icon(Icons.download_outlined),
      title: Text(l.mineOffline),
      subtitle: Text(
        queued > 0
            ? l.mineOfflineQueued(queued, l.unit(SeriesKind.audiobook))
            : l.mineOfflineUsage(formatBytes(used), quotaGb),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.push(Routes.offline),
    );
  }
}
