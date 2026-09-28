import 'package:flutter_test/flutter_test.dart';

import 'package:yun_audiobook/domain/continue_listening.dart';
import 'package:yun_audiobook/domain/models.dart';

/// 首页续听入口的选择逻辑（listening-progress 规格「首页续听入口」）。
///
/// 两处最容易搞错、也最难在真机上复现的地方钉在这里：
/// 1. 「最近收听」不等于「书架第一本」——BookDao.allBooks 按
///    `COALESCE(last_played_at, added_at) DESC` 排，一本刚加进来、
///    从没播过的书会排在真正在听的那本前面。
/// 2. 章节没解析出来、或刷新后章节变少导致序号越界时不能抛异常，
///    也不能按序号盲目索引——卡片得降级成「未就绪」。
void main() {
  final t0 = DateTime(2026, 9, 1, 20);

  Book book(
    String id, {
    DateTime? lastPlayedAt,
    int chapterCount = 10,
    int currentChapterIndex = 0,
    int currentPositionMs = 0,
    bool finished = false,
    bool sourceMissing = false,
  }) =>
      Book(
        id: id,
        folderPath: '/books/$id',
        title: id,
        chapterCount: chapterCount,
        currentChapterIndex: currentChapterIndex,
        currentPositionMs: currentPositionMs,
        finished: finished,
        sourceMissing: sourceMissing,
        addedAt: t0,
        updatedAt: t0,
        lastPlayedAt: lastPlayedAt,
      );

  List<Chapter> chapters(String bookId, int count) => [
        for (var i = 0; i < count; i++)
          Chapter(
            id: '$bookId-c$i',
            bookId: bookId,
            fsId: 'fs$i',
            path: '/books/$bookId/$i.mp3',
            title: '第 ${i + 1} 章',
            fileName: '$i.mp3',
            size: 1000,
            orderIndex: i,
          ),
      ];

  group('mostRecentlyPlayed', () {
    test('新加的书排在前面也不会被当成最近收听', () {
      // allBooks 的真实顺序：未播的新书用 added_at 参与排序，排在最前
      final books = [
        book('刚加进来的书'),
        book('在听的书', lastPlayedAt: t0),
      ];

      expect(ContinueListening.mostRecentlyPlayed(books)?.id, '在听的书');
    });

    test('多本播过时取时刻最新的一本', () {
      final books = [
        book('前天听的', lastPlayedAt: t0.subtract(const Duration(days: 2))),
        book('昨天听的', lastPlayedAt: t0.subtract(const Duration(days: 1))),
        book('上周听的', lastPlayedAt: t0.subtract(const Duration(days: 7))),
      ];

      expect(ContinueListening.mostRecentlyPlayed(books)?.id, '昨天听的');
    });

    test('一本都没播过时返回 null', () {
      expect(
        ContinueListening.mostRecentlyPlayed([book('甲'), book('乙')]),
        isNull,
      );
    });

    test('书架为空时返回 null', () {
      expect(ContinueListening.mostRecentlyPlayed(const []), isNull);
    });
  });

  group('from', () {
    test('正常情况定位到断点所在章节', () {
      final b = book('书', lastPlayedAt: t0, currentChapterIndex: 3, currentPositionMs: 65000);
      final entry = ContinueListening.from(b, chapters('书', 10));

      expect(entry.canPlay, isTrue);
      expect(entry.chapter?.title, '第 4 章');
      expect(entry.position, const Duration(milliseconds: 65000));
      expect(entry.notReadyReason, isNull);
    });

    test('章节还没解析出来时标记未就绪', () {
      final entry = ContinueListening.from(book('书', lastPlayedAt: t0), const []);

      expect(entry.canPlay, isFalse);
      expect(entry.chapter, isNull);
      expect(entry.notReadyReason, isNotNull);
    });

    test('记录的序号越界时不按序号索引', () {
      // 刷新后章节从 10 章变成 3 章，进度还停在第 8 章
      final b = book('书', lastPlayedAt: t0, currentChapterIndex: 7);
      final entry = ContinueListening.from(b, chapters('书', 3));

      expect(entry.canPlay, isFalse);
      expect(entry.chapter, isNull);
      expect(entry.notReadyReason, isNotNull);
    });

    test('源文件不可用时可见但不可播', () {
      final b = book('书', lastPlayedAt: t0, sourceMissing: true);
      final entry = ContinueListening.from(b, chapters('书', 10));

      expect(entry.canPlay, isFalse);
      expect(entry.book.title, '书');
      expect(entry.notReadyReason, isNotNull);
    });

    test('已听完的书指向第一章并标出会从头开始', () {
      // 听完之后网盘里少了几章：仍然能播（从第一章重来），
      // 不该因为旧的 currentChapterIndex 越界就被判成「章节找不到」
      final b = book('书',
          lastPlayedAt: t0, currentChapterIndex: 9, finished: true);
      final entry = ContinueListening.from(b, chapters('书', 3));

      expect(entry.canPlay, isTrue);
      expect(entry.restartsFromBeginning, isTrue);
      expect(entry.chapter?.title, '第 1 章');
    });
  });
}
