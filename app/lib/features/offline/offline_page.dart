import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yun_audiobook/app/providers.dart';
import 'package:yun_audiobook/data/local/settings_dao.dart';
import 'package:yun_audiobook/domain/entities.dart';
import 'package:yun_audiobook/features/common/error_text.dart';
import 'package:yun_audiobook/features/common/format.dart';
import 'package:yun_audiobook/features/common/widgets/empty_state.dart';
import 'package:yun_audiobook/features/common/widgets/series_cover.dart';
import 'package:yun_audiobook/features/offline/offline_controller.dart';
import 'package:yun_audiobook/l10n/l10n.dart';

/// 离线管理（offline-cache 规格「缓存配额与清理」）。
class OfflinePage extends ConsumerStatefulWidget {
  const OfflinePage({super.key});

  @override
  ConsumerState<OfflinePage> createState() => _OfflinePageState();
}

class _OfflinePageState extends ConsumerState<OfflinePage> {
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final usage = ref.watch(cacheUsageProvider);
    final shelf = ref.watch(shelfProvider);
    // 配额以持久化的值为唯一来源，不再另存一份局部状态
    final quotaGb = ref.watch(offlineQuotaGbProvider).value ??
        SettingsDao.offlineQuotaDefaultGb;
    // 下载队列没有流，随用量（下载进度写库）一起重算
    final downloads = ref.watch(downloadManagerProvider);
    final queued = downloads.queuedCount;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.offlineTitle),
        actions: [
          if (queued > 0)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Text(l.offlineQueue(queued)),
              ),
            ),
          IconButton(
            tooltip: downloads.isPaused
                ? l.offlineResumeDownloads
                : l.offlinePauseDownloads,
            icon: Icon(downloads.isPaused ? Icons.play_arrow : Icons.pause),
            onPressed: () => setState(() {
              downloads.isPaused ? downloads.resume() : downloads.pause();
            }),
          ),
        ],
      ),
      body: usage.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l.anyError(e))),
        data: (bySeries) {
          final total = bySeries.values.fold<int>(0, (a, b) => a + b);
          final withCache = (shelf.value ?? const <Series>[])
              .where((s) => (bySeries[s.id] ?? 0) > 0)
              .toList();
          return ListView(
            children: [
              _UsageHeader(total: total, quotaGb: quotaGb),
              _QuotaPicker(quotaGb: quotaGb),
              const Divider(height: 1),
              if (withCache.isEmpty)
                // 和书架空态同一套外观（图标 + 结论 + 怎么办）。
                // 原来这里只有一行居中小字，两处空态像两个人做的。
                Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: EmptyState(
                    icon: Icons.cloud_download_outlined,
                    title: l.offlineEmptyTitle,
                    description: l.offlineEmptyDescription,
                  ),
                )
              else
                for (final s in withCache)
                  _CachedSeriesTile(series: s, bytes: bySeries[s.id] ?? 0),
            ],
          );
        },
      ),
    );
  }
}

class _UsageHeader extends StatelessWidget {
  const _UsageHeader({required this.total, required this.quotaGb});

  final int total;
  final int quotaGb;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final quotaRatio = (total / (quotaGb * 1024 * 1024 * 1024)).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(formatBytes(total), style: theme.textTheme.headlineSmall),
              const SizedBox(width: 6),
              Text(
                l.offlineQuotaOf(quotaGb),
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.hintColor),
              ),
              const Spacer(),
              Text(
                '${(quotaRatio * 100).round()}%',
                style: theme.textTheme.labelMedium
                    ?.copyWith(color: theme.hintColor),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // 原来 0% 时整条是浅绿轨道色，看着像已经填满了。
          // 给轨道一个明显更暗的底色，空的就是空的。
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: quotaRatio,
              minHeight: 8,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuotaPicker extends ConsumerWidget {
  const _QuotaPicker({required this.quotaGb});

  static const List<int> _quotaOptionsGb = [1, 2, 5, 10, 20];

  final int quotaGb;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l.offlineQuotaTitle,
                  style: theme.textTheme.titleSmall,
                ),
              ),
              // 原来是带下划线的 DropdownButton（M2 风格），和页面里
              // 其他 M3 组件不是一套；而且说明文字换行后把它挤成
              // 垂直居中，视觉重心是歪的。现在说明独占一行。
              DropdownMenu<int>(
                initialSelection: quotaGb,
                width: 128,
                // 不让它变成可输入的文本框，否则点一下弹键盘
                requestFocusOnTap: false,
                dropdownMenuEntries: [
                  for (final g in _quotaOptionsGb)
                    DropdownMenuEntry(value: g, label: l.offlineGb(g)),
                ],
                onSelected: (v) {
                  if (v == null) return;
                  // 先落盘再执行清理：不存的话下次进来又回到默认值（controller 里）
                  unawaited(
                    ref.read(offlineControllerProvider.notifier).setQuotaGb(v),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            l.offlineQuotaHint,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.hintColor, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _CachedSeriesTile extends ConsumerWidget {
  const _CachedSeriesTile({required this.series, required this.bytes});

  final Series series;
  final int bytes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    return ListTile(
      leading: SeriesCover(
        title: series.title,
        coverFsId: series.coverFsId,
        localPath: series.coverLocalPath,
        width: 40,
        height: 54,
        radius: 6,
      ),
      title: Text(series.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(formatBytes(bytes)),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        tooltip: l.offlineClearTooltip,
        onPressed: () async {
          final messenger = ScaffoldMessenger.of(context);
          await ref
              .read(offlineControllerProvider.notifier)
              .clearSeries(series.id);
          messenger.showSnackBar(SnackBar(content: Text(l.offlineCleared)));
        },
      ),
    );
  }
}
