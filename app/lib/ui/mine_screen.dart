import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/services.dart';
import '../core/config.dart';
import '../core/logging.dart';
import '../domain/models.dart';
import '../update/app_installer.dart';
import 'help_screen.dart';
import 'offline_screen.dart';
import 'update_dialog.dart';
import 'widgets/format.dart';

/// 「我的」（app-layout 规格）：原来的设置页平铺了播放开关、离线、同步、
/// 隐私说明、诊断信息和退出登录，没有层次。现在按「收听 / 播放 / 关于 / 账号」分组。
/// 隐私承诺挪进了帮助的「隐私」一节，这里留一个入口。
class MineScreen extends ConsumerStatefulWidget {
  const MineScreen({super.key});

  @override
  ConsumerState<MineScreen> createState() => _MineScreenState();
}

class _MineScreenState extends ConsumerState<MineScreen> {
  bool _checking = false;

  @override
  Widget build(BuildContext context) {
    final services = ref.watch(servicesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('我的')),
      body: FutureBuilder<String>(
        future: AppInstaller.version(),
        builder: (context, version) {
          final v = version.data ?? '';
          return ListView(
            children: [
              const _Group('收听'),
              // 用量直接显示在副标题上，不用点进去就能知道占了多少
              _OfflineEntry(),
              FutureBuilder<DateTime?>(
                future: services.sync.lastSyncAt(),
                builder: (context, snap) => ListTile(
                  leading: const Icon(Icons.sync),
                  title: const Text('立即同步'),
                  subtitle: Text(snap.data == null
                      ? '尚未同步过 · 状态存于网盘 ${AppConfig.syncDir}'
                      : '上次同步：${formatSyncTime(snap.data!)}'),
                  onTap: () async {
                    final ok = await services.sync.syncNow();
                    if (!context.mounted) return;
                    setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(ok ? '同步完成' : '同步失败，稍后会自动重试')),
                    );
                  },
                ),
              ),
              const _Group('播放'),
              SwitchListTile(
                secondary: const Icon(Icons.phone_callback_outlined),
                title: const Text('中断后自动恢复播放'),
                subtitle: const Text('来电等打断结束后自动继续，关闭则保持暂停'),
                value: services.handler.resumeAfterInterruption,
                onChanged: (v) => setState(
                    () => services.handler.resumeAfterInterruption = v),
              ),
              const _Group('关于'),
              // iOS 不允许侧载安装，没有应用内更新
              if (AppInstaller.supported)
                ListTile(
                  leading: const Icon(Icons.system_update_outlined),
                  title: const Text('检查更新'),
                  subtitle: Text(_checking ? '正在检查…' : '当前版本 $v'),
                  enabled: !_checking,
                  onTap: () async {
                    setState(() => _checking = true);
                    await checkUpdateManually(context, ref);
                    if (mounted) setState(() => _checking = false);
                  },
                ),
              _Entry(
                  Icons.help_outline, '使用帮助', () => HelpScreen.open(context)),
              _Entry(
                  Icons.privacy_tip_outlined,
                  '隐私说明',
                  () =>
                      HelpScreen.open(context, section: HelpSections.privacy)),
              // OAuth 代理与 AppKey 是排查问题用的，正常使用根本不需要看见
              ExpansionTile(
                leading: const Icon(Icons.bug_report_outlined),
                title: const Text('诊断信息'),
                subtitle: const Text('排查连接问题时才需要'),
                children: [
                  ListTile(
                    dense: true,
                    title: const Text('OAuth 代理'),
                    subtitle: Text(AppConfig.oauthProxyBase.isEmpty
                        ? '未配置'
                        : AppConfig.oauthProxyBase),
                  ),
                  ListTile(
                    dense: true,
                    title: const Text('AppKey'),
                    subtitle: Text(Log.redact(AppConfig.baiduAppKey)),
                  ),
                  const ListTile(
                    dense: true,
                    title: Text('更新来源'),
                    subtitle: Text(AppConfig.releaseRepo),
                  ),
                ],
              ),
              // 演示模式没有百度账号，不存在"退出"
              if (!AppConfig.demoMode) ...[
                const _Group('账号'),
                const _SignOutTile(),
              ],
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                child: Text(
                  '云听书${v.isEmpty ? '' : ' $v'} · 只访问你本人网盘中的文件',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
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
          child: Text(title,
              style: theme.textTheme.labelLarge
                  ?.copyWith(color: theme.colorScheme.primary)),
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

class _SignOutTile extends ConsumerWidget {
  const _SignOutTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final services = ref.watch(servicesProvider);
    return ListTile(
      // 不用错误色：它不是破坏性操作，书架与收听进度会保留。
      // 真正需要确认的那一步在下面的对话框里。
      leading: const Icon(Icons.logout),
      title: const Text('退出登录'),
      subtitle: const Text('本地书架与收听进度会保留'),
      onTap: () async {
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('退出登录'),
            content: const Text('将清除本机保存的网盘授权。'
                '书架与收听进度会保留，重新登录后即可继续。'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('取消')),
              FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('退出')),
            ],
          ),
        );
        if (ok != true) return;
        // 退出登录必须一并清掉 dlink 缓存——旧令牌拼出的地址已无意义
        services.resolver.clear();
        await services.handler.stop();
        await services.auth.signOut();
      },
    );
  }
}

/// 「离线管理」入口。
class _OfflineEntry extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final services = ref.watch(servicesProvider);
    final usage = ref.watch(cacheUsageProvider);
    final quotaGb =
        ref.watch(offlineQuotaGbProvider).value ?? offlineQuotaDefaultGb;
    final used = (usage.value ?? const {}).values.fold<int>(0, (a, b) => a + b);

    return ListTile(
      leading: const Icon(Icons.download_outlined),
      title: const Text('离线管理'),
      subtitle: StreamBuilder<Chapter>(
        stream: services.downloads.events,
        builder: (context, _) {
          final queued = services.downloads.queuedCount;
          return Text(queued > 0
              ? '下载中 · 队列 $queued 章'
              : '已用 ${formatBytes(used)} / 上限 $quotaGb GB');
        },
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () async {
        await Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const OfflineScreen()));
        // 从离线页回来可能清过缓存或改过配额，用量要重算
        ref.invalidate(cacheUsageProvider);
      },
    );
  }
}
