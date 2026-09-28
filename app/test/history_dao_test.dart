import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:yun_audiobook/data/local/book_dao.dart';
import 'package:yun_audiobook/data/local/database.dart';
import 'package:yun_audiobook/data/local/history_dao.dart';
import 'package:yun_audiobook/domain/models.dart';

/// 播放历史的写入规则全在 HistoryDao 里，用真实 SQLite 钉住：
/// 同一章要合并成一条、时长只算像是真听了的那部分、条目有上限、
/// 移出书架不能让历史消失。
void main() {
  sqfliteFfiInit();

  late AppDatabase app;
  late BookDao books;
  late HistoryDao history;

  Book book(String id, String title, String folder) => Book(
        id: id,
        folderPath: folder,
        title: title,
        chapterCount: 3,
        addedAt: DateTime.fromMillisecondsSinceEpoch(1000),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(1000),
      );

  List<Chapter> chapters(String bookId, int n) => [
        for (var i = 0; i < n; i++)
          Chapter(
            id: '$bookId-ch$i',
            bookId: bookId,
            fsId: 'fs-$bookId-$i',
            path: '/x/$i.mp3',
            title: '第 ${i + 1} 章',
            fileName: '$i.mp3',
            size: 100,
            orderIndex: i,
          ),
      ];

  setUp(() async {
    app = await AppDatabase.openWith(databaseFactoryFfi, inMemoryDatabasePath);
    books = BookDao(app);
    history = HistoryDao(app);
    await books.upsertBook(book('b1', '三体', '/有声书/三体'));
    await books.replaceChapters('b1', chapters('b1', 3));
  });

  tearDown(() async => app.db.close());

  test('迁移后 play_history 表存在且为空', () async {
    expect(await history.recent(), isEmpty);
  });

  test('同一章连续上报合并成一条，不是每 5 秒插一行', () async {
    await history.record(bookId: 'b1', chapterIndex: 0, positionMs: 0);
    await history.record(bookId: 'b1', chapterIndex: 0, positionMs: 5000);
    await history.record(bookId: 'b1', chapterIndex: 0, positionMs: 10000);

    final all = await history.recent();
    expect(all.length, 1);
    expect(all.first.chapterTitle, '第 1 章');
    expect(all.first.bookTitle, '三体');
    // 0→5s→10s，两段各 5 秒
    expect(all.first.listenedMs, 10000);
    expect(all.first.lastPositionMs, 10000);
  });

  test('换章另起一条', () async {
    await history.record(bookId: 'b1', chapterIndex: 0, positionMs: 5000);
    await history.record(bookId: 'b1', chapterIndex: 1, positionMs: 1000);

    final all = await history.recent();
    expect(all.length, 2);
    // 最新的在前
    expect(all.first.chapterTitle, '第 2 章');
    expect(all.last.chapterTitle, '第 1 章');
  });

  test('往前拖进度条不算听过', () async {
    await history.record(bookId: 'b1', chapterIndex: 0, positionMs: 0);
    await history.record(bookId: 'b1', chapterIndex: 0, positionMs: 5000);
    // 直接拖到 30 分钟处：跨度远超一次上报可能听掉的音频
    await history.record(bookId: 'b1', chapterIndex: 0, positionMs: 1800000);

    final one = (await history.recent()).single;
    expect(one.listenedMs, 5000, reason: '拖过去的 30 分钟不是听的');
    expect(one.lastPositionMs, 1800000, reason: '但断点要跟着走，方便跳回来');
  });

  test('往后拖也不算，且不会算出负数', () async {
    await history.record(bookId: 'b1', chapterIndex: 0, positionMs: 60000);
    await history.record(bookId: 'b1', chapterIndex: 0, positionMs: 10000);

    final one = (await history.recent()).single;
    expect(one.listenedMs, 0);
  });

  test('倍速下一次上报跨度大，但在上界内仍计入', () async {
    // 3.0 倍速 + 5 秒上报间隔 = 一次约 15 秒音频，必须算听了
    await history.record(bookId: 'b1', chapterIndex: 0, positionMs: 0);
    await history.record(bookId: 'b1', chapterIndex: 0, positionMs: 15000);

    expect((await history.recent()).single.listenedMs, 15000);
  });

  test('本章听完打上标记', () async {
    await history.record(bookId: 'b1', chapterIndex: 0, positionMs: 0);
    await history.record(
        bookId: 'b1', chapterIndex: 0, positionMs: 5000, chapterFinished: true);

    expect((await history.recent()).single.finished, isTrue);
  });

  test('章节还没解析出来时不记空记录', () async {
    await books.upsertBook(book('b2', '还没扫的书', '/有声书/新书'));
    await history.record(bookId: 'b2', chapterIndex: 0, positionMs: 1000);

    expect(await history.recent(), isEmpty);
  });

  test('超过上限后丢最旧的', () async {
    await books.replaceChapters('b1', chapters('b1', 3));
    // 交替换章，制造出 maxEntries + 5 条记录
    for (var i = 0; i < HistoryDao.maxEntries + 5; i++) {
      await history.record(
          bookId: 'b1', chapterIndex: i % 3, positionMs: 1000 + i);
    }

    final all = await history.recent();
    expect(all.length, HistoryDao.maxEntries);
  });

  test('移出书架后历史仍在（没有级联外键）', () async {
    await history.record(bookId: 'b1', chapterIndex: 0, positionMs: 5000);
    await books.markBookDeleted('b1', 'dev-1');

    final all = await history.recent();
    expect(all.length, 1);
    expect(all.first.bookTitle, '三体');
  });

  test('把书彻底删掉，历史也还在', () async {
    await history.record(bookId: 'b1', chapterIndex: 0, positionMs: 5000);
    await books.purgeBook('b1');

    final all = await history.recent();
    expect(all.length, 1, reason: '历史是日志，删书不该让它消失');
    expect(all.first.chapterTitle, '第 1 章');
  });

  test('刷新章节改了标题，历史留的是当时那个', () async {
    await history.record(bookId: 'b1', chapterIndex: 0, positionMs: 5000);
    // 重新解析后第 1 章换了名字
    await books.replaceChapters('b1', [
      const Chapter(
        id: 'b1-ch0',
        bookId: 'b1',
        fsId: 'fs-b1-0',
        path: '/x/0.mp3',
        title: '序章（改名后）',
        fileName: '0.mp3',
        size: 100,
        orderIndex: 0,
      ),
    ]);

    expect((await history.recent()).single.chapterTitle, '第 1 章');
  });

  test('清空只清历史', () async {
    await history.record(bookId: 'b1', chapterIndex: 0, positionMs: 5000);
    await history.clear();

    expect(await history.recent(), isEmpty);
    expect((await books.bookById('b1'))!.title, '三体');
    expect((await books.chaptersOf('b1')).length, 3);
  });

  test('删单条', () async {
    await history.record(bookId: 'b1', chapterIndex: 0, positionMs: 5000);
    await history.record(bookId: 'b1', chapterIndex: 1, positionMs: 5000);
    final first = (await history.recent()).first;

    await history.deleteEntry(first.id);

    final all = await history.recent();
    expect(all.length, 1);
    expect(all.single.chapterTitle, '第 1 章');
  });
}
