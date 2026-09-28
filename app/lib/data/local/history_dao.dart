import 'package:sqflite/sqflite.dart';

import '../../domain/models.dart';
import 'database.dart';

/// 播放历史的读写（play-history）。
///
/// 只存本机：历史条目多、增长快，塞进同步用的 library.json 会让那个文件
/// 一直变大；而且「这台设备上听过什么」本来就是本地语义。
class HistoryDao {
  HistoryDao(this._app);

  final AppDatabase _app;
  Database get _db => _app.db;

  /// 保留的条目上限。超出后按时间从旧到新丢，防止无限增长。
  static const int maxEntries = 500;

  /// 单次上报最多算作多少毫秒的「实际收听」。
  ///
  /// 进度上报每 5 秒一次（AudiobookHandler._progressSaveInterval），
  /// 3.0 倍速下一次上报对应 15 秒音频，所以 20 秒是够用的上界。
  /// 超过这个数的位置跳变只可能是拖动进度条或换了播放位置，
  /// 那不是「听了」，不能计入时长。
  static const int maxTickMs = 20 * 1000;

  /// 记一笔播放。
  ///
  /// 同一章连续上报会合并进同一条记录（更新时间与累计时长），
  /// 不会每 5 秒插一行——否则听一章就是几百条历史。
  Future<void> record({
    required String bookId,
    required int chapterIndex,
    required int positionMs,
    bool chapterFinished = false,
  }) async {
    await _db.transaction((txn) async {
      // 书名与章节名在这里快照下来，之后历史不再依赖 books/chapters
      final meta = await txn.rawQuery('''
        SELECT c.id AS chapter_id, c.title AS chapter_title,
               b.title AS book_title, b.cover_fs_id AS cover_fs_id
        FROM chapters c
        JOIN books b ON b.id = c.book_id
        WHERE c.book_id = ? AND c.order_index = ?
        LIMIT 1
      ''', [bookId, chapterIndex]);
      // 章节还没解析出来（比如刚从网盘同步回来）时什么也不记，
      // 记一条书名章节名都空的历史毫无意义。
      if (meta.isEmpty) return;

      final row = meta.first;
      final chapterId = row['chapter_id'] as String;
      final now = DateTime.now().millisecondsSinceEpoch;

      final latest = await txn.query(
        'play_history',
        orderBy: 'last_at DESC, id DESC',
        limit: 1,
      );

      final continuing = latest.isNotEmpty &&
          latest.first['book_id'] == bookId &&
          latest.first['chapter_id'] == chapterId;

      if (continuing) {
        final prev = latest.first;
        final lastPos = (prev['last_position_ms'] as num).toInt();
        final delta = positionMs - lastPos;
        // 只有「往前走了一小段」才算听过。往后拖、往前跳都不算。
        final add = (delta > 0 && delta <= maxTickMs) ? delta : 0;

        await txn.update(
          'play_history',
          {
            'last_at': now,
            'last_position_ms': positionMs,
            'listened_ms':
                (prev['listened_ms'] as num).toInt() + add,
            if (chapterFinished) 'finished': 1,
          },
          where: 'id = ?',
          whereArgs: [prev['id']],
        );
        return;
      }

      await txn.insert('play_history', {
        'book_id': bookId,
        'chapter_id': chapterId,
        'chapter_index': chapterIndex,
        'book_title': row['book_title'],
        'chapter_title': row['chapter_title'],
        'cover_fs_id': row['cover_fs_id'],
        'started_at': now,
        'last_at': now,
        'last_position_ms': positionMs,
        // 新记录不给起始位置计时长：这一笔只说明「开始听了」，
        // 听了多久由后续上报累加。
        'listened_ms': 0,
        'finished': chapterFinished ? 1 : 0,
      });

      // 只在插入时裁剪，更新时不必每 5 秒扫一遍表
      await txn.rawDelete('''
        DELETE FROM play_history WHERE id NOT IN (
          SELECT id FROM play_history ORDER BY last_at DESC, id DESC LIMIT ?
        )
      ''', [maxEntries]);
    });
  }

  Future<List<PlayHistoryEntry>> recent({int limit = maxEntries}) async {
    final rows = await _db.query(
      'play_history',
      orderBy: 'last_at DESC, id DESC',
      limit: limit,
    );
    return rows.map(_toEntry).toList();
  }

  Future<void> deleteEntry(int id) =>
      _db.delete('play_history', where: 'id = ?', whereArgs: [id]);

  Future<void> clear() => _db.delete('play_history');

  PlayHistoryEntry _toEntry(Map<String, Object?> r) => PlayHistoryEntry(
        id: (r['id'] as num).toInt(),
        bookId: r['book_id'] as String,
        chapterId: r['chapter_id'] as String,
        chapterIndex: (r['chapter_index'] as num).toInt(),
        bookTitle: r['book_title'] as String,
        chapterTitle: r['chapter_title'] as String,
        coverFsId: r['cover_fs_id'] as String?,
        startedAt:
            DateTime.fromMillisecondsSinceEpoch((r['started_at'] as num).toInt()),
        lastAt:
            DateTime.fromMillisecondsSinceEpoch((r['last_at'] as num).toInt()),
        lastPositionMs: (r['last_position_ms'] as num).toInt(),
        listenedMs: (r['listened_ms'] as num).toInt(),
        finished: (r['finished'] as num).toInt() == 1,
      );
}
