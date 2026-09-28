import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/services.dart';
import '../domain/continue_listening.dart';
import '../domain/models.dart';
import 'book_detail_screen.dart';
import 'browse_screen.dart';
import 'player_screen.dart';
import 'widgets/book_cover.dart';
import 'widgets/empty_state.dart';
import 'widgets/format.dart';

/// 书架（library-catalog 规格「书架管理」）。
///
/// 列表下方是「继续收听」卡片（listening-progress 规格「首页续听入口」）：
/// 打开 App 最常见的诉求就是接着上次听，不该让用户先在一列同构卡片里
/// 认出那本书。放在下方而不是顶部，是因为那里离拇指更近。
class ShelfScreen extends ConsumerWidget {
  const ShelfScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shelf = ref.watch(shelfProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('书架'),
        actions: [
          IconButton(
            tooltip: '同步',
            icon: const Icon(Icons.sync),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final ok = await ref.read(servicesProvider).sync.syncNow();
              // 用 refresh(...future) 而不是 invalidate：前者会强制重算并等到
              // 新结果出来，后者只是标记失效。同步的重点恰恰是「拉回了新东西」，
              // 实测 invalidate 之后书架没刷新，得切一次标签页才显示出来。
              final books = await ref.refresh(shelfProvider.future);
              messenger.showSnackBar(SnackBar(
                content: Text(ok
                    ? '同步完成，书架 ${books.length} 本'
                    : '同步失败，稍后会自动重试'),
              ));
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => const BrowseScreen(path: '/'),
          ));
          ref.invalidate(shelfProvider);
        },
        icon: const Icon(Icons.add),
        label: const Text('添加书籍'),
      ),
      body: shelf.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorView(message: '$e', onRetry: () => ref.invalidate(shelfProvider)),
        data: (books) => books.isEmpty
            ? const _EmptyShelf()
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(shelfProvider),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
                  children: [
                    for (final book in books)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _BookTile(book: book),
                      ),
                    // 续听卡片放在书架下面：手够得着的地方
                    const ContinueListeningCard(),
                  ],
                ),
              ),
      ),
    );
  }
}

/// 首页「继续收听」卡片，位置在书架列表下方——手指够得着的那一头。
///
/// 只读本地库，冷启动时网盘不可达也照常显示；点一下从断点开始播放，
/// 但**不会**自动播放——启动就出声在耳机与车载上是惊吓。
class ContinueListeningCard extends ConsumerWidget {
  const ContinueListeningCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 底部的迷你播放条一出现，卡片就让位：同一本书在一屏上出现两次已经多余，
    // 何况卡片读的是 5 秒节流之前的断点，和播放条的实时位置还对不上。
    // 卡片要解决的是「刚打开 App，还没有播放会话」那一刻的事。
    //
    // 流的首帧到达前先用同步快照兜底，免得卡片闪一下再消失。
    final handler = ref.watch(servicesProvider).handler;
    final nowPlaying =
        ref.watch(nowPlayingProvider).valueOrNull ?? handler.mediaItem.valueOrNull;
    if (nowPlaying != null) return const SizedBox.shrink();

    final entry = ref.watch(continueListeningProvider);

    // 卡片是首屏的加分项，不是书架的前置条件：它自己在转圈或出错时
    // 让位给下面的列表，而不是把整页挡住。一本都没播过时同样什么都不画。
    final data = entry.valueOrNull;
    if (data == null) return const SizedBox.shrink();

    // 卡片里的书在上面的列表里还会出现一次。不把它从列表里剔掉：那会让
    // 「书架有几本」变得可疑，也会在卡片禁用时让这本书无处可点。两者形态
    // 差得够远，加上这里的留白，不会看成重复渲染。
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: _ContinueCard(entry: data),
    );
  }
}

class _ContinueCard extends ConsumerWidget {
  const _ContinueCard({required this.entry});

  final ContinueListening entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final book = entry.book;
    final chapter = entry.chapter;

    // 有章节时长就画章内进度（「这一章听到哪了」），没有就退回全书进度。
    // 时长要等播放器加载后才回填，新加的书一开始是空的。
    final durationMs = chapter?.durationMs;
    final progress = durationMs != null && durationMs > 0
        ? (book.currentPositionMs / durationMs).clamp(0.0, 1.0)
        : entry.bookProgress;

    return Card(
      elevation: 0,
      color: theme.colorScheme.primaryContainer,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        // 不能播的时候点卡片进详情页——那里能重新扫章节、也能看到源的状态，
        // 比给一个点了没反应的卡片好。播放动作本身在下面禁用掉。
        onTap: entry.canPlay
            ? () => startListening(context, ref, book)
            : () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => BookDetailScreen(bookId: book.id),
                )),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.headphones,
                      size: 16, color: theme.colorScheme.onPrimaryContainer),
                  const SizedBox(width: 6),
                  Text('继续收听',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      )),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BookCover(
                    title: book.title,
                    coverFsId: book.coverFsId,
                    width: 64,
                    height: 86,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(book.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.w600,
                            )),
                        const SizedBox(height: 4),
                        Text(
                          _subtitle(entry),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer
                                .withValues(alpha: 0.75),
                          ),
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 5,
                            backgroundColor: theme.colorScheme
                                .onPrimaryContainer
                                .withValues(alpha: 0.15),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.filled(
                    tooltip: entry.canPlay ? '继续收听' : entry.notReadyReason,
                    iconSize: 30,
                    icon: const Icon(Icons.play_arrow),
                    onPressed: entry.canPlay
                        ? () => startListening(context, ref, book)
                        : null,
                  ),
                ],
              ),
              // 不能播的原因摆在卡片上，让用户点之前就知道，而不是点了才发现
              if (!entry.canPlay)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 14, color: theme.colorScheme.error),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(entry.notReadyReason!,
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: theme.colorScheme.error)),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// 卡片副标题：章节名 + 断点位置。
  ///
  /// 已听完的书点下去会从第一章重新开始（openBook 的既有规则），
  /// 这件事得写在点击之前。
  static String _subtitle(ContinueListening entry) {
    if (entry.restartsFromBeginning) return '已听完 · 点击从第一章重新开始';

    final chapter = entry.chapter;
    if (chapter == null) return entry.notReadyReason ?? '';

    final position = formatDuration(entry.position);
    final total = chapter.durationMs;
    return total == null
        ? '${chapter.title} · 已听到 $position'
        : '${chapter.title} · $position / '
            '${formatDuration(Duration(milliseconds: total))}';
  }
}

/// 续播入口。首页续听卡片与书架条目上的播放键共用这一条路径——
/// 分成两份的话，两个入口迟早会对同一种异常给出两种反应，
/// 而异常正是用户最容易撞见的地方。
Future<void> startListening(
    BuildContext context, WidgetRef ref, Book book) async {
  final services = ref.read(servicesProvider);
  final messenger = ScaffoldMessenger.of(context);
  final navigator = Navigator.of(context);

  // App 只是切后台又回来时，播放器里还装着这本书。此时再 openBook 会重新
  // setAudioSource，把正在播的位置冲回书上记录的断点——那是 5 秒节流之前的
  // 位置，听感就是「点一下倒退几秒」。直接回播放页即可。
  final current = services.handler.mediaItem.valueOrNull;
  if (current != null && current.extras?['bookId'] == book.id) {
    navigator.push(MaterialPageRoute(builder: (_) => const PlayerScreen()));
    return;
  }

  if (book.sourceMissing) {
    messenger.showSnackBar(
      const SnackBar(content: Text('这本书的源文件在网盘里找不到了')),
    );
    return;
  }

  final chapters = await services.library.chapters(book.id);
  if (chapters.isEmpty) {
    messenger.showSnackBar(
      const SnackBar(content: Text('这本书的章节还没解析出来，打开书籍详情可以重新扫描')),
    );
    return;
  }
  // 已听完的书会从第一章重来（openBook 的既有规则），越界判定要跟着走，
  // 否则一本听完之后又在网盘里少了几章的书会被误判成「章节找不到」。
  final index = book.finished ? 0 : book.currentChapterIndex;
  if (index < 0 || index >= chapters.length) {
    messenger.showSnackBar(
      const SnackBar(content: Text('这一章在网盘里已经找不到了')),
    );
    return;
  }

  await services.handler.openBook(book, chapters);
  await services.handler.play();
  if (!context.mounted) return;
  await navigator.push(MaterialPageRoute(builder: (_) => const PlayerScreen()));

  // 从播放页退回来时才刷。不能在 push 之前刷：last_played_at 由每 5 秒一次的
  // 进度上报写入，刚 play() 完那一刻库里还是上一本书的时刻，卡片会纹丝不动。
  if (context.mounted) ref.invalidate(shelfProvider);
}

class _BookTile extends ConsumerWidget {
  const _BookTile({required this.book});

  final Book book;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final progress = book.chapterCount == 0
        ? 0.0
        : (book.currentChapterIndex + 1) / book.chapterCount;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => BookDetailScreen(bookId: book.id),
        )),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              BookCover(
                title: book.title,
                coverFsId: book.coverFsId,
                width: 60,
                height: 80,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(book.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium),
                    if (book.author != null)
                      Text(book.author!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: theme.hintColor)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            // 从网盘同步回来的书章节还没解析（library_sync 先
                            // 把 chapter_count 置 0，打开详情页时会自动补扫），
                            // 这时「已听至第 1 章 / 共 0 章」是自相矛盾的。
                            book.chapterCount == 0
                                ? '章节待解析'
                                : book.finished
                                    ? '已听完 · 共 ${book.chapterCount} 章'
                                    : '第 ${book.currentChapterIndex + 1} / ${book.chapterCount} 章',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: theme.hintColor),
                          ),
                        ),
                        // 光有进度条读不出「听到哪了」，补一个百分比。
                        // 等宽数字，免得百分比变化时这一行左右抖。
                        if (book.chapterCount > 0)
                          Text('${(progress * 100).round()}%',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.hintColor,
                                fontFeatures: const [
                                  FontFeature.tabularFigures()
                                ],
                              )),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // 细一点、带圆角，别像个未打磨的控件
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: progress.clamp(0.0, 1.0),
                        minHeight: 5,
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                      ),
                    ),
                    // 网盘路径消失时保留条目与进度，只做提示（规格要求）
                    if (book.sourceMissing)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Row(
                          children: [
                            Icon(Icons.warning_amber_rounded,
                                size: 14, color: theme.colorScheme.error),
                            const SizedBox(width: 4),
                            Text('源文件不可用',
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(color: theme.colorScheme.error)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                tooltip: '继续收听',
                icon: const Icon(Icons.play_circle_fill, size: 36),
                onPressed: book.sourceMissing
                    ? null
                    : () => startListening(context, ref, book),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyShelf extends StatelessWidget {
  const _EmptyShelf();

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      icon: Icons.library_books_outlined,
      title: '书架还是空的',
      description: '点右下角「添加书籍」，从你的百度网盘里挑一个装着有声书的文件夹加进来。',
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('重试')),
          ],
        ),
      ),
    );
  }
}
