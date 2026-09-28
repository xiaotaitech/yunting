import 'dart:async';
import 'dart:convert';


import '../../core/config.dart';
import '../../core/errors.dart';
import '../../core/logging.dart';
import '../drive/cloud_drive_source.dart';
import '../local/database.dart';
import 'library_snapshot.dart';

/// 状态同步（listening-progress 规格）。
///
/// 本地 SQLite 是权威读写来源；网盘 `/apps/<应用名>/library.json` 只是同步载体。
/// 同步全程后台异步，失败只重试、绝不阻塞收听。
/// 上传内容仅为书架与进度元数据，绝不包含任何音频。
class LibrarySync {
  LibrarySync({
    required CloudDriveSource drive,
    required AppDatabase db,
  })  : _drive = drive,
        _db = db;

  /// 节流窗口：变更频繁时不必每次都上传。
  static const Duration throttle = Duration(seconds: 30);

  final CloudDriveSource _drive;
  final AppDatabase _db;

  Timer? _pending;
  bool _running = false;

  /// 标记本地有变更，稍后合并上传。多次调用会被节流合并成一次。
  void markDirty() {
    _pending?.cancel();
    _pending = Timer(throttle, () => unawaited(syncNow()));
  }

  /// 新设备首次授权后调用：从网盘恢复书架与进度。
  Future<int> restoreFromCloud() async {
    final remote = await _readRemote();
    if (remote == null) return 0;
    await _applySnapshot(remote);
    Log.d('sync', '已从网盘恢复 ${remote.books.length} 本书');
    return remote.books.length;
  }

  /// 立即执行一次「拉取 → 合并 → 写回本地 → 上传」。
  Future<bool> syncNow() async {
    if (_running) return false;
    _running = true;
    try {
      final local = await _localSnapshot();
      final remote = await _readRemote();
      final merged =
          remote == null ? local : mergeSnapshots(local, remote);

      await _applySnapshot(merged);
      await _drive.writeAppStateFile(
        AppConfig.syncFilePath,
        const JsonEncoder.withIndent('  ').convert(merged.toJson()),
      );
      await _db.setMeta('last_sync_at',
          '${DateTime.now().millisecondsSinceEpoch}');
      Log.d('sync', '同步完成，共 ${merged.books.length} 条记录');
      return true;
    } on DriveException catch (e) {
      // 同步失败保留本地变更、下次再试，收听不受影响（规格「同步失败不影响使用」）
      Log.d('sync', '同步失败，稍后重试：${e.message}');
      markDirty();
      return false;
    } catch (e) {
      Log.d('sync', '同步失败，稍后重试：$e');
      markDirty();
      return false;
    } finally {
      _running = false;
    }
  }

  Future<DateTime?> lastSyncAt() async {
    final raw = await _db.meta('last_sync_at');
    final ms = int.tryParse(raw ?? '');
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<LibrarySnapshot?> _readRemote() async {
    final raw = await _drive.readAppStateFile(AppConfig.syncFilePath);
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      return LibrarySnapshot.fromJson(
          jsonDecode(raw) as Map<String, dynamic>);
    } catch (e) {
      // 远端文件损坏时不能让同步永久卡死，本地照常运行、下次覆盖它
      Log.e('sync', '远端状态文件无法解析，将以本地为准', e);
      return null;
    }
  }

  Future<LibrarySnapshot> _localSnapshot() async {
    final rows = await _db.db.query('books');
    return LibrarySnapshot(
      version: LibrarySnapshot.currentVersion,
      books: rows.map(_rowToRecord).toList(),
    );
  }

  Future<void> _applySnapshot(LibrarySnapshot snapshot) async {
    await _db.db.transaction((txn) async {
      for (final r in snapshot.books) {
        // 只写「同步得来」的字段。chapter_count 与 source_missing 是本地派生的，
        // 不属于同步内容，不能被远端记录覆盖。
        final values = {
          'folder_path': r.folderPath,
          'title': r.title,
          'author': r.author,
          'cover_fs_id': r.coverFsId,
          'current_chapter_index': r.currentChapterIndex,
          'current_position_ms': r.currentPositionMs,
          'finished': r.finished ? 1 : 0,
          'title_edited': r.titleEditedByUser ? 1 : 0,
          'author_edited': r.authorEditedByUser ? 1 : 0,
          'order_edited': r.orderEditedByUser ? 1 : 0,
          'added_at': r.addedAt,
          'updated_at': r.updatedAt,
          'last_played_at': r.lastPlayedAt,
          'updated_by_device': r.updatedByDevice,
          'deleted': r.deleted ? 1 : 0,
        };

        // 关键：绝不能用 INSERT OR REPLACE。
        // SQLite 的 REPLACE 是「先 DELETE 旧行再 INSERT」，而 chapters 表对
        // books 有 ON DELETE CASCADE——那样每同步一次就会把这本书的章节和
        // 离线缓存记录全部删光。实测过：同步后 chapters 表直接清零。
        final updated = await txn.update(
          'books',
          values,
          where: 'id = ?',
          whereArgs: [r.id],
        );
        if (updated == 0) {
          await txn.insert('books', {
            'id': r.id,
            ...values,
            // 新拉回来的书还没解析章节，等打开时再补
            'chapter_count': 0,
            'source_missing': 0,
          });
        }
      }
    });

    // chapter_count 是本地派生数据，按实际章节数校准一次。
    await _db.db.rawUpdate(
      'UPDATE books SET chapter_count = '
      '(SELECT COUNT(*) FROM chapters WHERE chapters.book_id = books.id)',
    );
  }

  BookRecord _rowToRecord(Map<String, Object?> r) => BookRecord(
        id: r['id'] as String,
        folderPath: r['folder_path'] as String,
        title: r['title'] as String,
        author: r['author'] as String?,
        coverFsId: r['cover_fs_id'] as String?,
        currentChapterIndex: (r['current_chapter_index'] as num).toInt(),
        currentPositionMs: (r['current_position_ms'] as num).toInt(),
        finished: (r['finished'] as num).toInt() == 1,
        deleted: (r['deleted'] as num).toInt() == 1,
        addedAt: (r['added_at'] as num).toInt(),
        updatedAt: (r['updated_at'] as num).toInt(),
        lastPlayedAt: (r['last_played_at'] as num?)?.toInt(),
        updatedByDevice: r['updated_by_device'] as String? ?? '',
        titleEditedByUser: (r['title_edited'] as num).toInt() == 1,
        authorEditedByUser: (r['author_edited'] as num).toInt() == 1,
        orderEditedByUser: (r['order_edited'] as num).toInt() == 1,
      );

  void dispose() => _pending?.cancel();
}
