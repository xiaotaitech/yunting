import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/services.dart';
import '../domain/models.dart';
import 'player_screen.dart';
import 'widgets/book_cover.dart';
import 'widgets/empty_state.dart';
import 'widgets/format.dart';

/// 播放历史（play-history）。
///
/// 只读本机记录，按天分组。点一条跳回那一章的断点继续听。
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('播放历史'),
        actions: [
          if ((history.value ?? const []).isNotEmpty)
            IconButton(
              tooltip: '清空历史',
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: () => _confirmClear(context, ref),
            ),
        ],
      ),
      body: history.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (entries) => entries.isEmpty
            ? const EmptyState(
                icon: Icons.history,
                title: '还没有收听记录',
                description: '听过的章节会按时间记在这里，随时能回来接着听。'
                    '记录只存在这台设备上，不会同步到网盘。',
              )
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(historyProvider),
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: entries.length,
                  itemBuilder: (context, i) {
                    final entry = entries[i];
                    // 与上一条不同一天时插一个日期小标题
                    final showHeader = i == 0 ||
                        formatHistoryDay(entries[i - 1].lastAt) !=
                            formatHistoryDay(entry.lastAt);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (showHeader) _DayHeader(at: entry.lastAt),
                        _HistoryTile(entry: entry),
                      ],
                    );
                  },
                ),
              ),
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('清空播放历史'),
        content: const Text('只清除收听记录。书架、收听进度与离线缓存都不受影响。'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('清空')),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(servicesProvider).history.clear();
    ref.invalidate(historyProvider);
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.at});

  final DateTime at;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
      child: Text(
        formatHistoryDay(at),
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _HistoryTile extends ConsumerWidget {
  const _HistoryTile({required this.entry});

  final PlayHistoryEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return ListTile(
      leading: BookCover(
        title: entry.bookTitle,
        coverFsId: entry.coverFsId,
        width: 40,
        height: 54,
        radius: 6,
      ),
      title: Text(entry.chapterTitle,
          maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Row(
        children: [
          Flexible(
            child: Text(entry.bookTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.hintColor)),
          ),
          Text(' · ',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.hintColor)),
          Text(
            entry.finished ? '听完' : formatListened(entry.listenedMs),
            style: theme.textTheme.bodySmall?.copyWith(
              color: entry.finished
                  ? theme.colorScheme.primary
                  : theme.hintColor,
            ),
          ),
        ],
      ),
      trailing: Text(formatClock(entry.lastAt),
          style: theme.textTheme.labelSmall?.copyWith(color: theme.hintColor)),
      onTap: () => _resume(context, ref),
    );
  }

  /// 跳回那一章接着听。
  ///
  /// 历史里的章节序号是当时的；书可能已被移出书架，也可能刷新后章节变少，
  /// 所以跳转前要重新取书与章节并校验范围，而不是直接拿序号去索引。
  Future<void> _resume(BuildContext context, WidgetRef ref) async {
    final services = ref.read(servicesProvider);
    final messenger = ScaffoldMessenger.of(context);

    // 从书架里找，而不是 dao.bookById——后者不过滤软删除，
    // 移出书架的书照样能查到，那就会让历史点进去播一本已经删掉的书。
    // shelf() 走的是 allBooks()，默认只返回 deleted = 0 的。
    final onShelf =
        (await services.library.shelf()).where((b) => b.id == entry.bookId);
    if (onShelf.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('这本书已不在书架，无法继续播放')),
      );
      return;
    }
    final book = onShelf.first;

    final chapters = await services.library.chapters(entry.bookId);
    if (entry.chapterIndex >= chapters.length) {
      messenger.showSnackBar(
        const SnackBar(content: Text('这一章在网盘里已经找不到了')),
      );
      return;
    }

    await services.handler.openBook(book, chapters);
    await services.handler.playChapterAt(
      entry.chapterIndex,
      position: Duration(milliseconds: entry.lastPositionMs),
    );
    if (!context.mounted) return;
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const PlayerScreen()));
  }
}
