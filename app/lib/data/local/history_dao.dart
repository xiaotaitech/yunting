import 'package:drift/drift.dart';

import '../../domain/entities.dart';
import 'database.dart';

part 'history_dao.g.dart';

/// 播放历史的读写（play-history）。
///
/// 只存本机：历史条目多、增长快，塞进同步用的 library.json 会让那个文件
/// 一直变大；而且「这台设备上听过什么」本来就是本地语义。
@DriftAccessor(tables: [Books, Chapters, PlayHistory])
class HistoryDao extends DatabaseAccessor<AppDatabase> with _$HistoryDaoMixin {
  HistoryDao(super.attachedDatabase);

  /// 保留的条目上限。超出后按时间从旧到新丢，防止无限增长。
  static const int maxEntries = 500;

  /// 单次上报最多算作多少毫秒的「实际收听」。
  ///
  /// 进度上报每 5 秒一次（PlaybackSession.progressSaveInterval），
  /// 3.0 倍速下一次上报对应 15 秒音频，所以 20 秒是够用的上界。
  /// 超过这个数的位置跳变只可能是拖动进度条或换了播放位置，
  /// 那不是「听了」，不能计入时长。
  static const int maxTickMs = 20 * 1000;

  /// 记一笔播放。
  ///
  /// 同一条目连续上报会合并进同一条记录（更新时间与累计时长），
  /// 不会每 5 秒插一行——否则听一章就是几百条历史。
  Future<void> record({
    required String seriesId,
    required int episodeIndex,
    required int positionMs,
    bool episodeFinished = false,
  }) =>
      transaction(() async {
        // 书名与章节名在这里快照下来，之后历史不再依赖 books/chapters
        final meta = await (select(chapters).join([
          innerJoin(books, books.id.equalsExp(chapters.bookId)),
        ])
              ..where(
                chapters.bookId.equals(seriesId) &
                    chapters.orderIndex.equals(episodeIndex),
              )
              ..limit(1))
            .getSingleOrNull();
        // 章节还没解析出来（比如刚从网盘同步回来）时什么也不记，
        // 记一条书名章节名都空的历史毫无意义。
        if (meta == null) return;

        final chapter = meta.readTable(chapters);
        final book = meta.readTable(books);
        final now = DateTime.now().millisecondsSinceEpoch;

        final latest = await (select(playHistory)
              ..orderBy([
                (h) => OrderingTerm.desc(h.lastAt),
                (h) => OrderingTerm.desc(h.id),
              ])
              ..limit(1))
            .getSingleOrNull();

        final continuing = latest != null &&
            latest.bookId == seriesId &&
            latest.chapterId == chapter.id;

        if (continuing) {
          final delta = positionMs - latest.lastPositionMs;
          // 只有「往前走了一小段」才算听过。往后拖、往前跳都不算。
          final add = (delta > 0 && delta <= maxTickMs) ? delta : 0;
          await (update(playHistory)..where((h) => h.id.equals(latest.id)))
              .write(
            PlayHistoryCompanion(
              lastAt: Value(now),
              lastPositionMs: Value(positionMs),
              listenedMs: Value(latest.listenedMs + add),
              finished:
                  episodeFinished ? const Value(true) : const Value.absent(),
            ),
          );
          return;
        }

        await into(playHistory).insert(
          PlayHistoryCompanion.insert(
            bookId: seriesId,
            chapterId: chapter.id,
            chapterIndex: episodeIndex,
            bookTitle: book.title,
            chapterTitle: chapter.title,
            coverFsId: Value(book.coverFsId),
            startedAt: now,
            lastAt: now,
            lastPositionMs: Value(positionMs),
            // 新记录不给起始位置计时长：这一笔只说明「开始听了」，
            // 听了多久由后续上报累加。
            listenedMs: const Value(0),
            finished: Value(episodeFinished),
          ),
        );

        // 只在插入时裁剪，更新时不必每 5 秒扫一遍表
        await customStatement(
          'DELETE FROM play_history WHERE id NOT IN ('
          'SELECT id FROM play_history ORDER BY last_at DESC, id DESC LIMIT ?)',
          [maxEntries],
        );
      });

  SimpleSelectStatement<$PlayHistoryTable, HistoryRow> _recentQuery(
    int limit,
  ) =>
      select(playHistory)
        ..orderBy([
          (h) => OrderingTerm.desc(h.lastAt),
          (h) => OrderingTerm.desc(h.id),
        ])
        ..limit(limit);

  Future<List<PlayHistoryEntry>> recent({int limit = maxEntries}) async =>
      (await _recentQuery(limit).get()).map(_toEntry).toList();

  /// 历史列表。播放中每 5 秒会写一次库，watch 会跟着推——
  /// 界面按天分组展示，变化很小，可以接受。
  Stream<List<PlayHistoryEntry>> watchRecent({int limit = maxEntries}) =>
      _recentQuery(limit).watch().map((r) => r.map(_toEntry).toList());

  Future<void> deleteEntry(int id) =>
      (delete(playHistory)..where((h) => h.id.equals(id))).go();

  Future<void> clear() => delete(playHistory).go();

  static PlayHistoryEntry _toEntry(HistoryRow r) => PlayHistoryEntry(
        id: r.id,
        seriesId: r.bookId,
        episodeId: r.chapterId,
        episodeIndex: r.chapterIndex,
        seriesTitle: r.bookTitle,
        episodeTitle: r.chapterTitle,
        coverFsId: r.coverFsId,
        startedAt: DateTime.fromMillisecondsSinceEpoch(r.startedAt),
        lastAt: DateTime.fromMillisecondsSinceEpoch(r.lastAt),
        lastPositionMs: r.lastPositionMs,
        listenedMs: r.listenedMs,
        finished: r.finished,
      );
}
