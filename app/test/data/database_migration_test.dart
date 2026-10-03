import 'dart:io';

import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';
import 'package:yun_audiobook/data/local/database.dart';
import 'package:yun_audiobook/domain/entities.dart';

/// sqflite（v1 / v2）→ drift（v3）迁移。
///
/// 这条路径必须有测试：真机上装着老库、里面是用户攒下来的书架和进度。
/// 迁移写错的话 App 一启动就崩在打不开数据库上——用户既进不去也拿不回数据。
/// 所以这里照抄当年的建表 SQL 造一个真的老库，再用当前代码打开它。
void main() {
  late Directory dir;
  late String dbPath;

  const booksV1 = '''
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
    )''';
  const chaptersV1 = '''
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
    )''';
  const historyV2 = '''
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
    )''';

  /// 按老版本的样子建库并装一份「用户已有的数据」。
  void createLegacy(int version) {
    final db = sqlite3.open(dbPath)
      ..execute(booksV1)
      ..execute(chaptersV1)
      ..execute(
        'CREATE INDEX idx_chapters_book ON chapters(book_id, order_index)',
      )
      ..execute('CREATE TABLE sync_meta (key TEXT PRIMARY KEY, '
          'value TEXT NOT NULL)');
    if (version >= 2) {
      db
        ..execute(historyV2)
        ..execute(
          'CREATE INDEX idx_history_last_at ON play_history(last_at DESC)',
        )
        ..execute(
          'INSERT INTO play_history (book_id, chapter_id, chapter_index, '
          'book_title, chapter_title, started_at, last_at, last_position_ms, '
          "listened_ms, finished) VALUES ('book-old', 'book-old-ch7', 7, "
          "'樊登讲书', '哲学的指引', 1500, 1900, 16000, 12000, 0)",
        );
    }
    db
      ..execute(
        'INSERT INTO books (id, folder_path, title, chapter_count, '
        'current_chapter_index, current_position_ms, order_edited, added_at, '
        "updated_at, last_played_at, updated_by_device) VALUES ('book-old', "
        "'/有声书/樊登讲书', '樊登讲书', 34, 7, 16000, 1, 1000, 2000, 1900, "
        "'dev-a')",
      )
      ..execute(
        'INSERT INTO chapters (id, book_id, fs_id, path, title, file_name, '
        'size, order_index, cache_state, local_path, downloaded_bytes) VALUES '
        "('book-old-ch7', 'book-old', 'fs-7', '/有声书/樊登讲书/哲学的指引.mp3', "
        "'哲学的指引', '哲学的指引.mp3', 46400000, 7, 3, '/data/cache/ch7.mp3', "
        '46400000)',
      )
      ..execute("INSERT INTO sync_meta VALUES ('last_sync_at', '2000')")
      ..userVersion = version
      ..close();
  }

  AppDatabase openCurrent() => AppDatabase(
        DatabaseConnection(
          NativeDatabase(File(dbPath)),
          closeStreamsSynchronously: true,
        ),
      );

  /// drift 是懒打开的：不发一条查询就不会连库，迁移也就不会跑。
  Future<void> openAndClose() async {
    final db = openCurrent();
    await db.customSelect('SELECT 1').get();
    await db.close();
  }

  Set<String> columnsOf(String table) {
    final db = sqlite3.open(dbPath);
    final cols = db
        .select('PRAGMA table_info($table)')
        .map((r) => r['name'] as String)
        .toSet();
    db.close();
    return cols;
  }

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('yun_migration_');
    dbPath = p.join(dir.path, 'yun_audiobook.db');
  });

  tearDown(() => dir.delete(recursive: true));

  for (final from in [1, 2]) {
    group('v$from → v3', () {
      setUp(() => createLegacy(from));

      test('书、断点、手动排序标记原样保留，类型落成有声书', () async {
        final db = openCurrent();
        final s = (await db.seriesDao.seriesById('book-old'))!;
        expect(s.title, '樊登讲书');
        expect(s.folderPath, '/有声书/樊登讲书');
        expect(s.episodeCount, 34);
        expect(s.currentEpisodeIndex, 7);
        expect(s.currentPositionMs, 16000);
        expect(s.orderEditedByUser, isTrue);
        expect(s.lastPlayedAt, DateTime.fromMillisecondsSinceEpoch(1900));
        expect(s.updatedByDevice, 'dev-a');
        expect(s.kind, SeriesKind.audiobook);
        await db.close();
      });

      test('离线缓存账原样保留，媒体类型落成音频', () async {
        final db = openCurrent();
        final eps = await db.seriesDao.episodesOf('book-old');
        expect(eps, hasLength(1));
        expect(eps.single.cacheState, CacheState.cached);
        expect(eps.single.localPath, '/data/cache/ch7.mp3');
        expect(eps.single.downloadedBytes, 46400000);
        expect(eps.single.mediaKind, MediaKind.audio);
        await db.close();
      });

      test('本地设置保留', () async {
        final db = openCurrent();
        expect(await db.settingsDao.read('last_sync_at'), '2000');
        await db.close();
      });

      test('历史可读可写', () async {
        final db = openCurrent();
        await db.historyDao.record(
          seriesId: 'book-old',
          episodeIndex: 7,
          positionMs: 20000,
        );
        final h = await db.historyDao.recent();
        expect(h, hasLength(1));
        expect(h.single.episodeTitle, '哲学的指引');
        // v2 已有的那条记录被续上（同一章），v1 是新插入的一条
        expect(h.single.lastPositionMs, 20000);
        await db.close();
      });

      test('级联删除仍然生效（foreign_keys 每次连接都打开）', () async {
        final db = openCurrent();
        await db.seriesDao.purge('book-old');
        expect(await db.seriesDao.episodesOf('book-old'), isEmpty);
        await db.close();
      });

      test('迁移后的列与全新建库完全一致', () async {
        await openAndClose();
        final migrated = {
          for (final t in ['books', 'chapters', 'sync_meta', 'play_history'])
            t: columnsOf(t),
        };
        await File(dbPath).delete();
        await openAndClose();
        for (final t in migrated.keys) {
          expect(migrated[t], columnsOf(t), reason: t);
        }
      });
    });
  }

  test('user_version 升到 3', () async {
    createLegacy(2);
    await openAndClose();
    final db = sqlite3.open(dbPath);
    expect(db.userVersion, 3);
    db.close();
  });
}
