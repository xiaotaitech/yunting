import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:yun_audiobook/data/local/database.dart';
import 'package:yun_audiobook/data/local/history_dao.dart';

/// v1 → v2 迁移（加 play_history 表）。
///
/// 这条路径必须有测试：真机上已经装着 v1 的库、里面是用户攒下来的书架和
/// 进度。迁移写错的话 App 一启动就崩，而且崩在打不开数据库上——用户既进不去
/// 也拿不回数据。所以这里建一个真的 v1 库，再用当前代码打开它。
void main() {
  sqfliteFfiInit();

  late Directory dir;
  late String dbPath;

  /// v1 的表结构，照抄当时的 _create（那时候没有 play_history）。
  Future<void> createV1(String path) async {
    final db = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onConfigure: (d) => d.execute('PRAGMA foreign_keys = ON'),
        onCreate: (db, _) async {
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
          await db.execute('''
            CREATE TABLE sync_meta (
              key TEXT PRIMARY KEY,
              value TEXT NOT NULL
            )
          ''');
        },
      ),
    );

    // 装一份「用户已有的数据」
    await db.insert('books', {
      'id': 'book-old',
      'folder_path': '/有声书/樊登讲书',
      'title': '樊登讲书',
      'chapter_count': 34,
      'current_chapter_index': 7,
      'current_position_ms': 16000,
      'added_at': 1000,
      'updated_at': 2000,
    });
    await db.insert('chapters', {
      'id': 'book-old-ch7',
      'book_id': 'book-old',
      'fs_id': 'fs-7',
      'path': '/有声书/樊登讲书/哲学的指引.mp3',
      'title': '哲学的指引',
      'file_name': '哲学的指引.mp3',
      'size': 46400000,
      'order_index': 7,
      'cache_state': 2,
      'local_path': '/data/cache/ch7.mp3',
      'downloaded_bytes': 46400000,
    });
    await db.insert('sync_meta', {'key': 'last_sync_at', 'value': '2000'});
    await db.close();
  }

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('yun_migration_');
    dbPath = p.join(dir.path, 'yun_audiobook.db');
    await createV1(dbPath);
  });

  tearDown(() async => dir.delete(recursive: true));

  test('打开 v1 库不报错，并升到 v2', () async {
    final app = await AppDatabase.openWith(databaseFactoryFfi, dbPath);
    addTearDown(() => app.db.close());

    expect(await app.db.getVersion(), 2);
  });

  test('迁移后 play_history 可用', () async {
    final app = await AppDatabase.openWith(databaseFactoryFfi, dbPath);
    addTearDown(() => app.db.close());
    final history = HistoryDao(app);

    expect(await history.recent(), isEmpty);

    await history.record(bookId: 'book-old', chapterIndex: 7, positionMs: 1000);
    final all = await history.recent();
    expect(all.length, 1);
    expect(all.single.chapterTitle, '哲学的指引');
    expect(all.single.bookTitle, '樊登讲书');
  });

  test('迁移不动用户原有的书架、进度与离线缓存', () async {
    final app = await AppDatabase.openWith(databaseFactoryFfi, dbPath);
    addTearDown(() => app.db.close());

    final book = (await app.db.query('books')).single;
    expect(book['title'], '樊登讲书');
    expect(book['chapter_count'], 34);
    expect(book['current_chapter_index'], 7);
    expect(book['current_position_ms'], 16000);

    final chapter = (await app.db.query('chapters')).single;
    expect(chapter['title'], '哲学的指引');
    expect(chapter['local_path'], '/data/cache/ch7.mp3',
        reason: '离线缓存的账不能在迁移中丢');

    final meta = (await app.db.query('sync_meta')).single;
    expect(meta['value'], '2000');
  });

  test('重复打开不会重建表或丢数据', () async {
    final first = await AppDatabase.openWith(databaseFactoryFfi, dbPath);
    final history = HistoryDao(first);
    await history.record(bookId: 'book-old', chapterIndex: 7, positionMs: 1000);
    await first.db.close();

    final second = await AppDatabase.openWith(databaseFactoryFfi, dbPath);
    addTearDown(() => second.db.close());

    expect((await HistoryDao(second).recent()).length, 1);
    expect((await second.db.query('books')).length, 1);
  });

  test('全新库（走 onCreate）也有 play_history', () async {
    final fresh = p.join(dir.path, 'fresh.db');
    final app = await AppDatabase.openWith(databaseFactoryFfi, fresh);
    addTearDown(() => app.db.close());

    expect(await app.db.getVersion(), 2);
    expect(await HistoryDao(app).recent(), isEmpty);
  });
}
