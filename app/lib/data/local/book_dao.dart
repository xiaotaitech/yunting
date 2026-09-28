import 'package:sqflite/sqflite.dart';

import '../../domain/models.dart';
import 'database.dart';

/// 书架与章节的读写。所有时间戳以毫秒整数存储，便于 LWW 比较。
class BookDao {
  BookDao(this._app);

  final AppDatabase _app;
  Database get _db => _app.db;

  // ------------------------------------------------------------ 书

  Future<List<Book>> allBooks({bool includeDeleted = false}) async {
    final rows = await _db.query(
      'books',
      where: includeDeleted ? null : 'deleted = 0',
      orderBy: 'COALESCE(last_played_at, added_at) DESC',
    );
    return rows.map(_toBook).toList();
  }

  Future<Book?> bookById(String id) async {
    final rows =
        await _db.query('books', where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : _toBook(rows.first);
  }

  Future<Book?> bookByFolder(String folderPath) async {
    final rows = await _db.query('books',
        where: 'folder_path = ?', whereArgs: [folderPath], limit: 1);
    return rows.isEmpty ? null : _toBook(rows.first);
  }

  /// 更新或插入一本书。**绝不能用 `ConflictAlgorithm.replace`。**
  ///
  /// SQLite 的 REPLACE 是「先 DELETE 旧行再 INSERT」，而 chapters 对 books 有
  /// `ON DELETE CASCADE`——于是每次更新书籍元数据都会把该书的章节全部删光，
  /// 连 chapters 里存的离线缓存账（cache_state / local_path / downloaded_bytes）
  /// 一起没，磁盘上下载好的文件变成孤儿。
  ///
  /// 三个调用方都在踩：改名改作者（editBook）、标记网盘路径丢失
  /// （_markMissing）、保存手动排序（reorderChapters，刚排好就被删）。
  /// 实测：真机上把书改个名，34 章立刻变 0 章。
  ///
  /// 同步那边早就绕开了（见 library_sync 的 _applySnapshot），但 DAO 自己
  /// 没修。这里改成「先 UPDATE，没命中再 INSERT」，全程不删行。
  Future<void> upsertBook(Book book) async {
    final values = _fromBook(book);
    await _db.transaction((txn) async {
      final updated = await txn.update(
        'books',
        values,
        where: 'id = ?',
        whereArgs: [book.id],
      );
      if (updated == 0) await txn.insert('books', values);
    });
  }

  /// 软删除。同步合并需要知道「这本书被删过」，硬删会让删除操作丢失。
  Future<void> markBookDeleted(String id, String deviceId) => _db.update(
        'books',
        {
          'deleted': 1,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
          'updated_by_device': deviceId,
        },
        where: 'id = ?',
        whereArgs: [id],
      );

  Future<void> purgeBook(String id) =>
      _db.delete('books', where: 'id = ?', whereArgs: [id]);

  Future<void> updateProgress({
    required String bookId,
    required int chapterIndex,
    required int positionMs,
    required String deviceId,
    bool? finished,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db.update(
      'books',
      {
        'current_chapter_index': chapterIndex,
        'current_position_ms': positionMs,
        'updated_at': now,
        'last_played_at': now,
        'updated_by_device': deviceId,
        if (finished != null) 'finished': finished ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [bookId],
    );
  }

  // ------------------------------------------------------------ 章节

  Future<List<Chapter>> chaptersOf(String bookId) async {
    final rows = await _db.query('chapters',
        where: 'book_id = ?', whereArgs: [bookId], orderBy: 'order_index ASC');
    return rows.map(_toChapter).toList();
  }

  Future<void> replaceChapters(String bookId, List<Chapter> chapters) async {
    await _db.transaction((txn) async {
      // 保留已有的缓存状态，刷新章节列表不该让已下载的文件"消失"。
      final existing = await txn.query('chapters',
          columns: ['fs_id', 'cache_state', 'local_path', 'downloaded_bytes'],
          where: 'book_id = ?',
          whereArgs: [bookId]);
      final cacheByFsId = {
        for (final r in existing) r['fs_id'] as String: r,
      };

      await txn.delete('chapters', where: 'book_id = ?', whereArgs: [bookId]);
      for (final c in chapters) {
        final kept = cacheByFsId[c.fsId];
        await txn.insert('chapters', {
          ..._fromChapter(c),
          if (kept != null) ...{
            'cache_state': kept['cache_state'],
            'local_path': kept['local_path'],
            'downloaded_bytes': kept['downloaded_bytes'],
          },
        });
      }
      await txn.update('books', {'chapter_count': chapters.length},
          where: 'id = ?', whereArgs: [bookId]);
    });
  }

  /// 记下某章的真实时长。
  ///
  /// `duration_ms` 这一列建库时就有，但一直没人写：ID3 解析只取
  /// 标题/作者/专辑/track，时长要等播放器真正加载后才知道。
  /// 缺了它系统媒体通知画不出进度条（MediaItem.duration 为 null 时
  /// Android 不渲染 seekbar，两端都显示 00:00）。
  Future<void> setChapterDuration(String chapterId, int durationMs) =>
      _db.update(
        'chapters',
        {'duration_ms': durationMs},
        where: 'id = ?',
        whereArgs: [chapterId],
      );

  Future<void> updateChapter(Chapter chapter) => _db.update(
        'chapters',
        _fromChapter(chapter),
        where: 'id = ?',
        whereArgs: [chapter.id],
      );

  Future<void> updateChapterOrder(List<Chapter> ordered) async {
    await _db.transaction((txn) async {
      for (var i = 0; i < ordered.length; i++) {
        await txn.update('chapters', {'order_index': i},
            where: 'id = ?', whereArgs: [ordered[i].id]);
      }
    });
  }

  Future<void> setChapterCache(
    String chapterId, {
    required ChapterCacheState state,
    String? localPath,
    int? downloadedBytes,
  }) =>
      _db.update(
        'chapters',
        {
          'cache_state': state.index,
          'local_path': localPath,
          if (downloadedBytes != null) 'downloaded_bytes': downloadedBytes,
        },
        where: 'id = ?',
        whereArgs: [chapterId],
      );

  Future<List<Chapter>> cachedChapters() async {
    final rows = await _db.query('chapters',
        where: 'cache_state = ?', whereArgs: [ChapterCacheState.cached.index]);
    return rows.map(_toChapter).toList();
  }

  /// 各书的缓存占用，供「离线管理」页展示。
  Future<Map<String, int>> cacheUsageByBook() async {
    final rows = await _db.rawQuery(
      'SELECT book_id, SUM(downloaded_bytes) AS used FROM chapters '
      'WHERE cache_state = ? GROUP BY book_id',
      [ChapterCacheState.cached.index],
    );
    return {
      for (final r in rows)
        r['book_id'] as String: (r['used'] as num?)?.toInt() ?? 0,
    };
  }

  // ------------------------------------------------------------ 映射

  Book _toBook(Map<String, Object?> r) => Book(
        id: r['id'] as String,
        folderPath: r['folder_path'] as String,
        title: r['title'] as String,
        author: r['author'] as String?,
        coverFsId: r['cover_fs_id'] as String?,
        coverLocalPath: r['cover_local_path'] as String?,
        chapterCount: (r['chapter_count'] as num).toInt(),
        currentChapterIndex: (r['current_chapter_index'] as num).toInt(),
        currentPositionMs: (r['current_position_ms'] as num).toInt(),
        finished: (r['finished'] as num).toInt() == 1,
        sourceMissing: (r['source_missing'] as num).toInt() == 1,
        titleEditedByUser: (r['title_edited'] as num).toInt() == 1,
        authorEditedByUser: (r['author_edited'] as num).toInt() == 1,
        orderEditedByUser: (r['order_edited'] as num).toInt() == 1,
        addedAt: DateTime.fromMillisecondsSinceEpoch((r['added_at'] as num).toInt()),
        updatedAt:
            DateTime.fromMillisecondsSinceEpoch((r['updated_at'] as num).toInt()),
        lastPlayedAt: r['last_played_at'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(
                (r['last_played_at'] as num).toInt()),
        updatedByDevice: r['updated_by_device'] as String? ?? '',
      );

  Map<String, Object?> _fromBook(Book b) => {
        'id': b.id,
        'folder_path': b.folderPath,
        'title': b.title,
        'author': b.author,
        'cover_fs_id': b.coverFsId,
        'cover_local_path': b.coverLocalPath,
        'chapter_count': b.chapterCount,
        'current_chapter_index': b.currentChapterIndex,
        'current_position_ms': b.currentPositionMs,
        'finished': b.finished ? 1 : 0,
        'source_missing': b.sourceMissing ? 1 : 0,
        'title_edited': b.titleEditedByUser ? 1 : 0,
        'author_edited': b.authorEditedByUser ? 1 : 0,
        'order_edited': b.orderEditedByUser ? 1 : 0,
        'added_at': b.addedAt.millisecondsSinceEpoch,
        'updated_at': b.updatedAt.millisecondsSinceEpoch,
        'last_played_at': b.lastPlayedAt?.millisecondsSinceEpoch,
        'updated_by_device': b.updatedByDevice,
        'deleted': 0,
      };

  Chapter _toChapter(Map<String, Object?> r) => Chapter(
        id: r['id'] as String,
        bookId: r['book_id'] as String,
        fsId: r['fs_id'] as String,
        path: r['path'] as String,
        title: r['title'] as String,
        fileName: r['file_name'] as String,
        size: (r['size'] as num).toInt(),
        orderIndex: (r['order_index'] as num).toInt(),
        trackNumber: (r['track_number'] as num?)?.toInt(),
        durationMs: (r['duration_ms'] as num?)?.toInt(),
        cacheState: ChapterCacheState.values[(r['cache_state'] as num).toInt()],
        localPath: r['local_path'] as String?,
        downloadedBytes: (r['downloaded_bytes'] as num?)?.toInt() ?? 0,
      );

  Map<String, Object?> _fromChapter(Chapter c) => {
        'id': c.id,
        'book_id': c.bookId,
        'fs_id': c.fsId,
        'path': c.path,
        'title': c.title,
        'file_name': c.fileName,
        'size': c.size,
        'order_index': c.orderIndex,
        'track_number': c.trackNumber,
        'duration_ms': c.durationMs,
        'cache_state': c.cacheState.index,
        'local_path': c.localPath,
        'downloaded_bytes': c.downloadedBytes,
      };
}
