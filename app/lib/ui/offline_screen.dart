import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/services.dart';
import '../domain/models.dart';
import 'widgets/book_cover.dart';
import 'widgets/empty_state.dart';
import 'widgets/format.dart';

/// 离线管理（offline-cache 规格「缓存配额与清理」）。
class OfflineScreen extends ConsumerStatefulWidget {
  const OfflineScreen({super.key});

  @override
  ConsumerState<OfflineScreen> createState() => _OfflineScreenState();
}

class _OfflineScreenState extends ConsumerState<OfflineScreen> {
  static const List<int> _quotaOptionsGb = [1, 2, 5, 10, 20];

  @override
  Widget build(BuildContext context) {
    final services = ref.watch(servicesProvider);
    final usage = ref.watch(cacheUsageProvider);
    final shelf = ref.watch(shelfProvider);
    final theme = Theme.of(context);
    // 配额以持久化的值为唯一来源，不再另存一份局部状态
    final quotaGb =
        ref.watch(offlineQuotaGbProvider).value ?? offlineQuotaDefaultGb;

    return Scaffold(
      appBar: AppBar(
        title: const Text('离线管理'),
        actions: [
          StreamBuilder<Chapter>(
            stream: services.downloads.events,
            builder: (context, _) {
              final queued = services.downloads.queuedCount;
              if (queued == 0) return const SizedBox.shrink();
              return Center(
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Text('队列 $queued'),
                ),
              );
            },
          ),
          IconButton(
            tooltip: services.downloads.isPaused ? '继续下载' : '暂停下载',
            icon: Icon(services.downloads.isPaused
                ? Icons.play_arrow
                : Icons.pause),
            onPressed: () {
              setState(() {
                services.downloads.isPaused
                    ? services.downloads.resume()
                    : services.downloads.pause();
              });
            },
          ),
        ],
      ),
      body: usage.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (byBook) {
          final total = byBook.values.fold<int>(0, (a, b) => a + b);
          final quotaRatio =
              (total / (quotaGb * 1024 * 1024 * 1024)).clamp(0.0, 1.0);
          final books = shelf.value ?? const <Book>[];
          final withCache =
              books.where((b) => (byBook[b.id] ?? 0) > 0).toList();

          return ListView(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(formatBytes(total),
                            style: theme.textTheme.headlineSmall),
                        const SizedBox(width: 6),
                        Text('/ $quotaGb GB',
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(color: theme.hintColor)),
                        const Spacer(),
                        Text('${(quotaRatio * 100).round()}%',
                            style: theme.textTheme.labelMedium
                                ?.copyWith(color: theme.hintColor)),
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
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text('缓存上限',
                              style: theme.textTheme.titleSmall),
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
                              DropdownMenuEntry(value: g, label: '$g GB'),
                          ],
                          onSelected: (v) async {
                            if (v == null) return;
                            // 先落盘再执行清理：不存的话下次进来又回到默认值
                            await services.database
                                .setMeta(offlineQuotaMetaKey, '$v');
                            ref.invalidate(offlineQuotaGbProvider);
                            await services.downloads.enforceQuota(
                              v * 1024 * 1024 * 1024,
                              protectedBookId:
                                  services.handler.currentBook?.id,
                            );
                            ref.invalidate(cacheUsageProvider);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text('超出后按最近最少收听自动清理，正在播放的书不会被清',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.hintColor, height: 1.4)),
                  ],
                ),
              ),
              const Divider(height: 1),
              if (withCache.isEmpty)
                // 和书架空态同一套外观（图标 + 结论 + 怎么办）。
                // 原来这里只有一行居中小字，两处空态像两个人做的。
                const Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: EmptyState(
                    icon: Icons.cloud_download_outlined,
                    title: '还没有下载任何章节',
                    description: '在书籍详情页菜单里选「下载本书」，'
                        '或点单章右侧的下载按钮，之后断网也能听。',
                  ),
                )
              else
                for (final b in withCache)
                  ListTile(
                    leading: BookCover(
                      title: b.title,
                      coverFsId: b.coverFsId,
                      width: 40,
                      height: 54,
                      radius: 6,
                    ),
                    title: Text(b.title,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(formatBytes(byBook[b.id] ?? 0)),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      tooltip: '清理这本书的缓存',
                      onPressed: () async {
                        await services.downloads.clearBookCache(b.id);
                        ref.invalidate(cacheUsageProvider);
                        ref.invalidate(chaptersProvider(b.id));
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('缓存已清理，收听进度保留')),
                        );
                      },
                    ),
                  ),
            ],
          );
        },
      ),
    );
  }
}
