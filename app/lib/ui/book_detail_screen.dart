import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/services.dart';
import '../domain/models.dart';
import 'player_screen.dart';
import 'widgets/book_cover.dart';
import 'widgets/format.dart';

/// 书籍详情：章节列表、下载、编辑信息、手动排序。
class BookDetailScreen extends ConsumerStatefulWidget {
  const BookDetailScreen({super.key, required this.bookId});

  final String bookId;

  @override
  ConsumerState<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends ConsumerState<BookDetailScreen> {
  bool _reordering = false;
  bool _autoRefreshed = false;

  /// 从网盘同步回来的书只有元数据和进度，章节要重新从网盘解析。
  /// 第一次打开时自动补齐，别让用户自己去菜单里点「刷新章节」。
  Future<void> _autoRefreshIfEmpty(Book book, List<Chapter> chapters) async {
    if (_autoRefreshed || chapters.isNotEmpty || book.sourceMissing) return;
    _autoRefreshed = true;
    try {
      await ref.read(servicesProvider).library.refreshBook(book);
    } finally {
      if (mounted) {
        ref.invalidate(chaptersProvider(book.id));
        // 书架读的是 books.chapter_count，补扫把它从 0 改成了真实章节数，
        // 不刷新的话退回书架还显示「章节待解析」，得手动下拉一次才对。
        // 手动「刷新章节」那条一直是两个都刷的，这里漏了。
        ref.invalidate(shelfProvider);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final services = ref.watch(servicesProvider);
    final chapters = ref.watch(chaptersProvider(widget.bookId));

    return FutureBuilder<Book?>(
      future: services.dao.bookById(widget.bookId),
      builder: (context, snap) {
        final book = snap.data;
        if (book == null) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        return Scaffold(
          appBar: AppBar(
            title: Text(book.title, maxLines: 1, overflow: TextOverflow.ellipsis),
            actions: [
              IconButton(
                tooltip: _reordering ? '完成排序' : '手动排序',
                icon: Icon(_reordering ? Icons.check : Icons.swap_vert),
                onPressed: () => setState(() => _reordering = !_reordering),
              ),
              PopupMenuButton<String>(
                onSelected: (v) => _onMenu(v, book),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('编辑书籍信息')),
                  PopupMenuItem(value: 'refresh', child: Text('刷新章节')),
                  PopupMenuItem(value: 'download', child: Text('下载本书')),
                  PopupMenuItem(value: 'clear', child: Text('清理离线缓存')),
                  PopupMenuItem(value: 'remove', child: Text('移出书架')),
                ],
              ),
            ],
          ),
          body: chapters.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('$e')),
            data: (list) {
              unawaited(_autoRefreshIfEmpty(book, list));
              return Column(
                children: [
                  _Header(book: book, chapters: list),
                  const Divider(height: 1),
                  Expanded(
                    child: _reordering
                        ? _ReorderableChapters(book: book, chapters: list)
                        : _ChapterList(book: book, chapters: list),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _onMenu(String value, Book book) async {
    final services = ref.read(servicesProvider);
    final messenger = ScaffoldMessenger.of(context);

    switch (value) {
      case 'edit':
        await _editBook(book);
        break;
      case 'refresh':
        await services.library.refreshBook(book);
        ref.invalidate(chaptersProvider(book.id));
        ref.invalidate(shelfProvider);
        messenger.showSnackBar(const SnackBar(content: Text('章节已刷新')));
        break;
      case 'download':
        final list = await services.library.chapters(book.id);
        await services.downloads.enqueueBook(list);
        messenger.showSnackBar(
            SnackBar(content: Text('已加入下载队列（${list.length} 章）')));
        break;
      case 'clear':
        await services.downloads.clearBookCache(book.id);
        ref.invalidate(chaptersProvider(book.id));
        ref.invalidate(cacheUsageProvider);
        messenger.showSnackBar(const SnackBar(content: Text('离线缓存已清理，收听进度保留')));
        break;
      case 'remove':
        final ok = await _confirmRemove();
        if (!ok) return;
        await services.downloads.clearBookCache(book.id);
        await services.library.removeBook(book.id);
        services.sync.markDirty();
        ref.invalidate(shelfProvider);
        if (mounted) Navigator.of(context).pop();
        break;
    }
  }

  Future<bool> _confirmRemove() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('移出书架'),
        content: const Text('只会删除本地的书架条目与离线缓存，'
            '你网盘里的原始文件不会被动。'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('移出')),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _editBook(Book book) async {
    final titleCtrl = TextEditingController(text: book.title);
    final authorCtrl = TextEditingController(text: book.author ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('编辑书籍信息'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: '书名')),
            const SizedBox(height: 12),
            TextField(
                controller: authorCtrl,
                decoration: const InputDecoration(labelText: '作者')),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('保存')),
        ],
      ),
    );

    if (saved != true) return;
    await ref.read(servicesProvider).library.editBook(
          book,
          title: titleCtrl.text.trim().isEmpty ? null : titleCtrl.text.trim(),
          author: authorCtrl.text.trim().isEmpty ? null : authorCtrl.text.trim(),
        );
    ref.read(servicesProvider).sync.markDirty();
    ref.invalidate(shelfProvider);
    if (mounted) setState(() {});
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.book, required this.chapters});

  final Book book;
  final List<Chapter> chapters;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cached = chapters.where((c) => c.isCached).length;
    final total = chapters.fold<int>(0, (a, c) => a + c.size);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BookCover(
            title: book.title,
            coverFsId: book.coverFsId,
            width: 84,
            height: 112,
            radius: 12,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(book.title, style: theme.textTheme.titleLarge),
                if (book.author != null)
                  Text(book.author!,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: theme.hintColor)),
                const SizedBox(height: 8),
                Text('${chapters.length} 章 · ${formatBytes(total)}',
                    style: theme.textTheme.bodySmall),
                Text('已离线 $cached / ${chapters.length} 章',
                    style: theme.textTheme.bodySmall),
                if (book.sourceMissing)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text('源文件不可用：网盘中找不到该文件夹',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.colorScheme.error)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChapterList extends ConsumerStatefulWidget {
  const _ChapterList({required this.book, required this.chapters});

  final Book book;
  final List<Chapter> chapters;

  @override
  ConsumerState<_ChapterList> createState() => _ChapterListState();
}

class _ChapterListState extends ConsumerState<_ChapterList> {
  late List<Chapter> _chapters = [...widget.chapters];
  StreamSubscription<Chapter>? _sub;

  Book get book => widget.book;

  @override
  void initState() {
    super.initState();
    // 下载状态变化只影响单个章节，就地替换即可，
    // 不必让整个 provider 重新查库。
    _sub = ref.read(servicesProvider).downloads.events.listen((updated) {
      if (!mounted) return;
      final i = _chapters.indexWhere((c) => c.id == updated.id);
      if (i < 0) return;
      setState(() => _chapters[i] = updated);
    });
  }

  @override
  void didUpdateWidget(covariant _ChapterList old) {
    super.didUpdateWidget(old);
    if (!identical(old.chapters, widget.chapters)) {
      _chapters = [...widget.chapters];
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chapters = _chapters;

    return ListView.builder(
        itemCount: chapters.length,
        itemBuilder: (context, i) {
          final c = chapters[i];
          final isCurrent = i == book.currentChapterIndex;
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: isCurrent
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Text('${i + 1}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isCurrent
                        ? Theme.of(context).colorScheme.onPrimary
                        : null,
                  )),
            ),
            title: Text(c.title,
                maxLines: 2, overflow: TextOverflow.ellipsis),
            subtitle: Text(_subtitle(c)),
            trailing: _trailing(context, ref, c),
            onTap: () => _play(context, ref, i),
          );
        });
  }

  String _subtitle(Chapter c) {
    switch (c.cacheState) {
      case ChapterCacheState.cached:
        return '已离线 · ${formatBytes(c.downloadedBytes)}';
      case ChapterCacheState.downloading:
        final pct = c.size == 0 ? 0 : (c.downloadedBytes * 100 ~/ c.size);
        return '下载中 $pct%';
      case ChapterCacheState.queued:
        return '排队中';
      case ChapterCacheState.failed:
        return '下载失败，点右侧重试';
      case ChapterCacheState.none:
        return formatBytes(c.size);
    }
  }

  Widget _trailing(BuildContext context, WidgetRef ref, Chapter c) {
    final downloads = ref.read(servicesProvider).downloads;
    switch (c.cacheState) {
      case ChapterCacheState.cached:
        return const IconButton(
          icon: Icon(Icons.offline_pin, color: Colors.green),
          tooltip: '已离线',
          onPressed: null,
        );
      case ChapterCacheState.downloading:
      case ChapterCacheState.queued:
        return IconButton(
          icon: const Icon(Icons.close),
          tooltip: '取消下载',
          onPressed: () => downloads.cancel(c),
        );
      default:
        return IconButton(
          icon: const Icon(Icons.download_outlined),
          tooltip: '下载此章',
          onPressed: () => downloads.enqueueChapter(c),
        );
    }
  }

  Future<void> _play(BuildContext context, WidgetRef ref, int index) async {
    final services = ref.read(servicesProvider);
    await services.handler.openBook(book, _chapters, chapterIndex: index);
    await services.handler.play();
    if (!context.mounted) return;
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const PlayerScreen()));
  }
}

/// 手动拖动调整章节顺序（规格「手动调整顺序」）。
class _ReorderableChapters extends ConsumerStatefulWidget {
  const _ReorderableChapters({required this.book, required this.chapters});

  final Book book;
  final List<Chapter> chapters;

  @override
  ConsumerState<_ReorderableChapters> createState() =>
      _ReorderableChaptersState();
}

class _ReorderableChaptersState extends ConsumerState<_ReorderableChapters> {
  late final List<Chapter> _items = [...widget.chapters];

  @override
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
      itemCount: _items.length,
      // onReorderItem 已经替我们修正过移除后的下标，不用再手动减一
      onReorderItem: (oldIndex, newIndex) async {
        setState(() {
          final item = _items.removeAt(oldIndex);
          _items.insert(newIndex, item);
        });
        await ref
            .read(servicesProvider)
            .library
            .reorderChapters(widget.book, _items);
        ref.invalidate(chaptersProvider(widget.book.id));
      },
      itemBuilder: (context, i) => ListTile(
        key: ValueKey(_items[i].id),
        leading: const Icon(Icons.drag_handle),
        title: Text(_items[i].title,
            maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(_items[i].fileName,
            maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}
