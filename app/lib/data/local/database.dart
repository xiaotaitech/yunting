import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/config.dart';

/// 本地 SQLite 是书架与进度的权威读写来源；网盘只是同步载体（design.md D5）。
class AppDatabase {
  AppDatabase._(this.db);

  final Database db;

  static Future<AppDatabase> open() async {
    final dir = await getApplicationDocumentsDirectory();
    // 演示模式单独一个库：演示版升级到正式版时，假网盘里的书不会混进真书架
    const name =
        AppConfig.demoMode ? 'yun_audiobook_demo.db' : 'yun_audiobook.db';
    return openWith(databaseFactory, p.join(dir.path, name));
  }

  /// 用指定 factory 与路径建库。生产走 [open]；
  /// 测试用 sqflite_common_ffi 的内存库跑这里，才能拿真实表结构
  /// （尤其是 chapters 那条 ON DELETE CASCADE）验真实 DAO 代码。
  static Future<AppDatabase> openWith(
      DatabaseFactory factory, String path) async {
    final db = await factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 2,
        onConfigure: (d) => d.execute('PRAGMA foreign_keys = ON'),
        onCreate: _create,
        onUpgrade: _upgrade,
      ),
    );
    return AppDatabase._(db);
  }

  static Future<void> _create(Database db, int version) async {
    await db.execute('''
      CREATE TABLE books (
        id TEXT PRIMARY KEY,
        folder_path TEXT NOT NULL UNIQUE,
        title TEXT NOT NULL,
        author TEXT,
        cover_fs_id TEXT,
        cover_local_path TEXT,
        chapter_count INTEGER NOT NULL DEFAULT 0,
        current_chapter_index INTEGER NOT NULL DEFAULT 0,
        current_position_ms INTEGER NOT NULL DEFAULT 0,
        finished INTEGER NOT NULL DEFAULT 0,
        source_missing INTEGER NOT NULL DEFAULT 0,
        title_edited INTEGER NOT NULL DEFAULT 0,
        author_edited INTEGER NOT NULL DEFAULT 0,
        order_edited INTEGER NOT NULL DEFAULT 0,
        added_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        last_played_at INTEGER,
        updated_by_device TEXT NOT NULL DEFAULT '',
        deleted INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE chapters (
        id TEXT PRIMARY KEY,
        book_id TEXT NOT NULL REFERENCES books(id) ON DELETE CASCADE,
        fs_id TEXT NOT NULL,
        path TEXT NOT NULL,
        title TEXT NOT NULL,
        file_name TEXT NOT NULL,
        size INTEGER NOT NULL,
        order_index INTEGER NOT NULL,
        track_number INTEGER,
        duration_ms INTEGER,
        cache_state INTEGER NOT NULL DEFAULT 0,
        local_path TEXT,
        downloaded_bytes INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute(
        'CREATE INDEX idx_chapters_book ON chapters(book_id, order_index)');

    // 同步元信息：记录上次成功同步的时间，供节流与合并使用。
    await db.execute('''
      CREATE TABLE sync_meta (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    await _createPlayHistory(db);
  }

  /// 播放历史（v2 新增）。
  ///
  /// 两个刻意的设计：
  ///
  /// 1. **不对 books 建外键。** 历史是「这台设备上听过什么」的日志，
  ///    移出书架、甚至把书彻底删掉，都不该让听过的记录消失。加了级联
  ///    反而会在删书时静默清空历史——那种坑这个库里已经踩过一次了。
  /// 2. **书名与章节名在播放当时快照下来。** 不靠 JOIN 现取：
  ///    `replaceChapters` 会把章节行整批删掉重建，章节 id 是按序号生成的
  ///    （`book-xxx-chN`），刷新后同一个 id 可能已经指向另一章；
  ///    书名也可能被用户改掉。历史要记的是「当时听的是什么」。
  static Future<void> _createPlayHistory(Database db) async {
    await db.execute('''
      CREATE TABLE play_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        book_id TEXT NOT NULL,
        chapter_id TEXT NOT NULL,
        chapter_index INTEGER NOT NULL,
        book_title TEXT NOT NULL,
        chapter_title TEXT NOT NULL,
        cover_fs_id TEXT,
        started_at INTEGER NOT NULL,
        last_at INTEGER NOT NULL,
        last_position_ms INTEGER NOT NULL DEFAULT 0,
        listened_ms INTEGER NOT NULL DEFAULT 0,
        finished INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute(
        'CREATE INDEX idx_history_last_at ON play_history(last_at DESC)');
  }

  static Future<void> _upgrade(Database db, int from, int to) async {
    // v1 -> v2：加播放历史表。老库里已有的书与进度一行不动。
    if (from < 2) await _createPlayHistory(db);
  }

  Future<String?> meta(String key) async {
    final rows = await db.query('sync_meta',
        where: 'key = ?', whereArgs: [key], limit: 1);
    return rows.isEmpty ? null : rows.first['value'] as String;
  }

  Future<void> setMeta(String key, String value) => db.insert(
        'sync_meta',
        {'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

  Future<void> close() => db.close();
}
