import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:yun_audiobook/data/local/book_dao.dart';
import 'package:yun_audiobook/data/local/database.dart';
import 'package:yun_audiobook/domain/models.dart';

/// `BookDao.upsertBook` 以前用 `ConflictAlgorithm.replace`，而 SQLite 的
/// REPLACE 是「先 DELETE 旧行再 INSERT」——chapters 对 books 有
/// `ON DELETE CASCADE`，于是每次更新书籍元数据都把该书章节删光。
///
/// 真机上的表现：把书改个名，34 章立刻变 0 章；离线缓存的账也一起没。
/// 同步路径早就绕开了这个坑（library_sync_db_test 钉的是那一半），
/// 但 DAO 自己没修，editBook / _markMissing / reorderChapters 全在踩。
///
/// 这组用例跑真实 SQLite + 真实表结构 + 真实 DAO，把行为钉死。
void main() {
  sqfliteFfiInit();

  late AppDatabase app;
  late BookDao dao;

  Book makeBook({
    String title = '三体',
    String? author,
    bool sourceMissing = false,
    bool orderEdited = false,
  }) =>
      Book(
        id: 'book-1',
        folderPath: '/有声书/三体',
        title: title,
        author: author,
        chapterCount: 3,
        sourceMissing: sourceMissing,
        orderEditedByUser: orderEdited,
        addedAt: DateTime.fromMillisecondsSinceEpoch(1000),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(1000),
      );

  List<Chapter> makeChapters() => [
        for (var i = 0; i < 3; i++)
          Chapter(
            id: 'book-1-ch$i',
            bookId: 'book-1',
            fsId: 'fs-$i',
            path: '/有声书/三体/第${i + 1}章.mp3',
            title: '第 ${i + 1} 章',
            fileName: '第${i + 1}章.mp3',
            size: 1000 + i,
            orderIndex: i,
          ),
      ];

  setUp(() async {
    // 内存库，每次 open 都是全新的一份，用例之间互不影响
    app = await AppDatabase.openWith(databaseFactoryFfi, inMemoryDatabasePath);
    dao = BookDao(app);
    await dao.upsertBook(makeBook());
    await dao.replaceChapters('book-1', makeChapters());
  });

  tearDown(() async => app.db.close());

  test('前置条件：种子数据就位，且级联外键是开着的', () async {
    expect((await dao.chaptersOf('book-1')).length, 3);
    final fk = await app.db.rawQuery('PRAGMA foreign_keys');
    expect(fk.first.values.first, 1, reason: '级联没开的话这组用例证明不了任何事');
  });

  test('改书名不会删掉章节', () async {
    await dao.upsertBook(makeBook(title: '三体（重制）'));

    expect((await dao.chaptersOf('book-1')).length, 3);
    expect((await dao.bookById('book-1'))!.title, '三体（重制）');
  });

  test('改作者不会删掉章节', () async {
    await dao.upsertBook(makeBook(author: '刘慈欣'));

    expect((await dao.chaptersOf('book-1')).length, 3);
    expect((await dao.bookById('book-1'))!.author, '刘慈欣');
  });

  test('标记网盘路径丢失不会删掉章节（条目与进度都要保留）', () async {
    await dao.upsertBook(makeBook(sourceMissing: true));

    expect((await dao.chaptersOf('book-1')).length, 3);
    expect((await dao.bookById('book-1'))!.sourceMissing, isTrue);
  });

  test('保存手动排序不会把刚排好的章节删掉', () async {
    // reorderChapters 的顺序：先写章节顺序，紧接着 upsertBook 标记 order_edited。
    // 旧实现下第二步会把第一步的成果连根删掉。
    final reordered = [
      for (final c in makeChapters().reversed.toList().asMap().entries)
        Chapter(
          id: c.value.id,
          bookId: c.value.bookId,
          fsId: c.value.fsId,
          path: c.value.path,
          title: c.value.title,
          fileName: c.value.fileName,
          size: c.value.size,
          orderIndex: c.key,
        ),
    ];
    await dao.updateChapterOrder(reordered);
    await dao.upsertBook(makeBook(orderEdited: true));

    final after = await dao.chaptersOf('book-1');
    expect(after.length, 3);
    expect(after.map((c) => c.title).toList(),
        ['第 3 章', '第 2 章', '第 1 章'], reason: '手动顺序必须留住');
  });

  test('章节里的离线缓存账不会被元数据更新冲掉', () async {
    await dao.setChapterCache(
      'book-1-ch0',
      state: ChapterCacheState.cached,
      localPath: '/data/cache/ch0.mp3',
      downloadedBytes: 1000,
    );

    await dao.upsertBook(makeBook(title: '改个名'));

    final ch0 = (await dao.chaptersOf('book-1')).firstWhere(
        (c) => c.id == 'book-1-ch0');
    expect(ch0.isCached, isTrue, reason: '缓存记录没了，磁盘上的文件就成孤儿');
    expect(ch0.localPath, '/data/cache/ch0.mp3');
    expect(ch0.downloadedBytes, 1000);
  });

  test('回填章节时长只动那一列，缓存记录不受影响', () async {
    await dao.setChapterCache(
      'book-1-ch0',
      state: ChapterCacheState.cached,
      localPath: '/data/cache/ch0.mp3',
      downloadedBytes: 1000,
    );

    // 系统媒体通知的进度条依赖这个值；ID3 拿不到时长，只能播放器报了才写
    await dao.setChapterDuration('book-1-ch0', 3042000);

    final ch0 =
        (await dao.chaptersOf('book-1')).firstWhere((c) => c.id == 'book-1-ch0');
    expect(ch0.durationMs, 3042000);
    expect(ch0.isCached, isTrue);
    expect(ch0.localPath, '/data/cache/ch0.mp3');
    expect(ch0.title, '第 1 章');
  });

  test('upsert 一本不存在的书走插入', () async {
    await dao.upsertBook(Book(
      id: 'book-2',
      folderPath: '/有声书/球状闪电',
      title: '球状闪电',
      addedAt: DateTime.fromMillisecondsSinceEpoch(2000),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(2000),
    ));

    expect((await dao.bookById('book-2'))!.title, '球状闪电');
    // 原来那本不受影响
    expect((await dao.chaptersOf('book-1')).length, 3);
  });
}
