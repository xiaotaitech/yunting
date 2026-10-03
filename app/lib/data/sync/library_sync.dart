import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:yun_audiobook/core/config.dart';
import 'package:yun_audiobook/core/errors.dart';
import 'package:yun_audiobook/core/logging.dart';
import 'package:yun_audiobook/data/drive/cloud_drive_source.dart';
import 'package:yun_audiobook/data/local/database.dart';
import 'package:yun_audiobook/data/sync/library_snapshot.dart';
import 'package:yun_audiobook/domain/entities.dart';

/// 状态同步（listening-progress 规格）。
///
/// 本地 SQLite 是权威读写来源；网盘 `/apps/<应用名>/library.json` 只是同步载体。
/// 同步全程后台异步，失败只重试、绝不阻塞收听。
/// 上传内容仅为书架与进度元数据，绝不包含任何音频。
///
/// 两个出口让界面不必自己记得调 [markDirty]：书架类变更由 controller 调用，
/// 播放进度由 PlaybackSink 调用。
class LibrarySync {
  LibrarySync({
    required CloudDriveSource drive,
    required AppDatabase db,
  })  : _drive = drive,
        _db = db;

  static const _lastSyncKey = 'last_sync_at';

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
      await _db.settingsDao.write(
        _lastSyncKey,
        '${DateTime.now().millisecondsSinceEpoch}',
      );
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

  Stream<DateTime?> watchLastSyncAt() =>
      _db.settingsDao.watch(_lastSyncKey).map((raw) {
        final ms = int.tryParse(raw ?? '');
        return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
      });

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
    // 含软删除的行：删除也是要同步出去的变更
    final rows = await _db.select(_db.books).get();
    return LibrarySnapshot(books: rows.map(_rowToRecord).toList());
  }

  Future<void> _applySnapshot(LibrarySnapshot snapshot) async {
    final books = _db.books;
    await _db.transaction(() async {
      for (final r in snapshot.books) {
        // 只写「同步得来」的字段。chapter_count 与 source_missing 是本地派生的，
        // 不属于同步内容，不能被远端记录覆盖；kind 对已有的行也以本地为准
        // （旧版本 App 上传时会丢掉它）。
        final values = BooksCompanion(
          folderPath: Value(r.folderPath),
          title: Value(r.title),
          author: Value(r.author),
          coverFsId: Value(r.coverFsId),
          currentChapterIndex: Value(r.currentChapterIndex),
          currentPositionMs: Value(r.currentPositionMs),
          finished: Value(r.finished),
          titleEdited: Value(r.titleEditedByUser),
          authorEdited: Value(r.authorEditedByUser),
          orderEdited: Value(r.orderEditedByUser),
          addedAt: Value(r.addedAt),
          updatedAt: Value(r.updatedAt),
          lastPlayedAt: Value(r.lastPlayedAt),
          updatedByDevice: Value(r.updatedByDevice),
          deleted: Value(r.deleted),
        );

        // 关键：绝不能用 INSERT OR REPLACE。
        // SQLite 的 REPLACE 是「先 DELETE 旧行再 INSERT」，而 chapters 表对
        // books 有 ON DELETE CASCADE——那样每同步一次就会把这本书的章节和
        // 离线缓存记录全部删光。实测过：同步后 chapters 表直接清零。
        final updated =
            await (_db.update(books)..where((b) => b.id.equals(r.id)))
                .write(values);
        if (updated == 0) {
          await _db.into(books).insert(
                values.copyWith(
                  id: Value(r.id),
                  kind: Value(r.kind.name),
                  // 新拉回来的合集还没解析条目，等打开时再补
                  chapterCount: const Value(0),
                  sourceMissing: const Value(false),
                ),
              );
        }
      }
    });

    // chapter_count 是本地派生数据，按实际条目数校准一次。
    await _db.customStatement(
      'UPDATE books SET chapter_count = '
      '(SELECT COUNT(*) FROM chapters WHERE chapters.book_id = books.id)',
    );
  }

  BookRecord _rowToRecord(BookRow r) => BookRecord(
        id: r.id,
        folderPath: r.folderPath,
        title: r.title,
        author: r.author,
        coverFsId: r.coverFsId,
        currentChapterIndex: r.currentChapterIndex,
        currentPositionMs: r.currentPositionMs,
        finished: r.finished,
        deleted: r.deleted,
        addedAt: r.addedAt,
        updatedAt: r.updatedAt,
        lastPlayedAt: r.lastPlayedAt,
        updatedByDevice: r.updatedByDevice,
        titleEditedByUser: r.titleEdited,
        authorEditedByUser: r.authorEdited,
        orderEditedByUser: r.orderEdited,
        kind: SeriesKind.parse(r.kind),
      );

  void dispose() => _pending?.cancel();
}
