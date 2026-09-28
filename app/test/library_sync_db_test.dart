import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:yun_audiobook/data/sync/library_snapshot.dart';

/// 同步写库这一段以前没有测试覆盖，结果漏掉一个会丢数据的 bug：
/// 用 `INSERT OR REPLACE` 更新 books 行时，SQLite 会先 DELETE 再 INSERT，
/// chapters 表的 `ON DELETE CASCADE` 于是把该书的章节全部删光——
/// 每同步一次章节就没一次。这组用例跑真实 SQLite，把这个行为钉死。
void main() {
  sqfliteFfiInit();
  final factory = databaseFactoryFfi;

  late Database db;

  /// 与 AppDatabase 相同的表结构（含那条关键的级联外键）。
  Future<void> createSchema(Database d) async {
    await d.execute('''
      CREATE TABLE books (
        id TEXT PRIMARY KEY,
        folder_path TEXT NOT NULL UNIQUE,
        title TEXT NOT NULL,
        chapter_count INTEGER NOT NULL DEFAULT 0,
        current_chapter_index INTEGER NOT NULL DEFAULT 0,
        current_position_ms INTEGER NOT NULL DEFAULT 0,
        updated_at INTEGER NOT NULL,
        deleted INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await d.execute('''
      CREATE TABLE chapters (
        id TEXT PRIMARY KEY,
        book_id TEXT NOT NULL REFERENCES books(id) ON DELETE CASCADE,
        title TEXT NOT NULL
      )
    ''');
  }

  Future<void> seedBookWithChapters() async {
    await db.insert('books', {
      'id': 'book-1',
      'folder_path': '/books/x',
      'title': '三体',
      'chapter_count': 5,
      'current_chapter_index': 0,
      'current_position_ms': 0,
      'updated_at': 100,
      'deleted': 0,
    });
    for (var i = 0; i < 5; i++) {
      await db.insert('chapters', {
        'id': 'ch-$i',
        'book_id': 'book-1',
        'title': '第 $i 章',
      });
    }
  }

  Future<int> countOf(String table) async {
    final rows = await db.rawQuery('SELECT COUNT(*) AS n FROM $table');
    return (rows.single['n'] as num).toInt();
  }

  Future<int> chapterCount() => countOf('chapters');

  setUp(() async {
    db = await factory.openDatabase(inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: 1,
          onConfigure: (d) => d.execute('PRAGMA foreign_keys = ON'),
          onCreate: (d, _) => createSchema(d),
        ));
    await seedBookWithChapters();
  });

  tearDown(() => db.close());

  test('前提：级联外键确实是打开的', () async {
    expect(await chapterCount(), 5);
    await db.delete('books', where: 'id = ?', whereArgs: ['book-1']);
    expect(await chapterCount(), 0, reason: '删书应当级联删章节');
  });

  test('INSERT OR REPLACE 会连带删掉章节——这正是当初的 bug', () async {
    await db.insert(
      'books',
      {
        'id': 'book-1',
        'folder_path': '/books/x',
        'title': '三体',
        'chapter_count': 0,
        'current_chapter_index': 2,
        'current_position_ms': 0,
        'updated_at': 200,
        'deleted': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    expect(await chapterCount(), 0,
        reason: 'REPLACE 先删后插，章节被级联删除——所以同步不能用它');
  });

  test('改用 UPDATE 后章节完好，进度也更新了', () async {
    // 这就是 _applySnapshot 现在的做法
    final updated = await db.update(
      'books',
      {'current_chapter_index': 2, 'updated_at': 200},
      where: 'id = ?',
      whereArgs: ['book-1'],
    );

    expect(updated, 1);
    expect(await chapterCount(), 5, reason: '章节必须原样保留');

    final row = (await db.query('books', where: 'id = ?', whereArgs: ['book-1']))
        .single;
    expect(row['current_chapter_index'], 2);
  });

  test('远端新增的书走 INSERT，不影响已有书的章节', () async {
    final updated = await db.update(
      'books',
      {'title': '小王子'},
      where: 'id = ?',
      whereArgs: ['book-2'],
    );
    expect(updated, 0, reason: '不存在时 UPDATE 返回 0，据此走 INSERT');

    await db.insert('books', {
      'id': 'book-2',
      'folder_path': '/books/y',
      'title': '小王子',
      'chapter_count': 0,
      'current_chapter_index': 0,
      'current_position_ms': 0,
      'updated_at': 300,
      'deleted': 0,
    });

    expect(await chapterCount(), 5, reason: '新增另一本书不该动到已有章节');
    expect(await countOf('books'), 2);
  });

  test('chapter_count 校准语句能算出真实章节数', () async {
    await db.update('books', {'chapter_count': 0});
    await db.rawUpdate(
      'UPDATE books SET chapter_count = '
      '(SELECT COUNT(*) FROM chapters WHERE chapters.book_id = books.id)',
    );

    final row = (await db.query('books', where: 'id = ?', whereArgs: ['book-1']))
        .single;
    expect(row['chapter_count'], 5);
  });

  test('合并结果写回后，进度取的是更靠后的那一份', () async {
    // 端到端串一遍：本地进度靠后，远端时间戳更新
    const local = LibrarySnapshot(version: 1, books: [
      BookRecord(
        id: 'book-1',
        folderPath: '/books/x',
        title: '三体',
        currentChapterIndex: 4,
        currentPositionMs: 9000,
        finished: false,
        deleted: false,
        addedAt: 0,
        updatedAt: 100,
        updatedByDevice: 'a',
      ),
    ]);
    const remote = LibrarySnapshot(version: 1, books: [
      BookRecord(
        id: 'book-1',
        folderPath: '/books/x',
        title: '三体',
        currentChapterIndex: 1,
        currentPositionMs: 100,
        finished: false,
        deleted: false,
        addedAt: 0,
        updatedAt: 999,
        updatedByDevice: 'b',
      ),
    ]);

    final merged = mergeSnapshots(local, remote).books.single;
    await db.update(
      'books',
      {
        'current_chapter_index': merged.currentChapterIndex,
        'current_position_ms': merged.currentPositionMs,
        'updated_at': merged.updatedAt,
      },
      where: 'id = ?',
      whereArgs: ['book-1'],
    );

    final row = (await db.query('books', where: 'id = ?', whereArgs: ['book-1']))
        .single;
    expect(row['current_chapter_index'], 4, reason: '不能让进度回退');
    expect(await chapterCount(), 5);
  });
}
