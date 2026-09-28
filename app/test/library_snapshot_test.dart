import 'package:flutter_test/flutter_test.dart';
import 'package:yun_audiobook/data/sync/library_snapshot.dart';

BookRecord rec(
  String id, {
  int chapter = 0,
  int position = 0,
  int updatedAt = 0,
  bool deleted = false,
  bool finished = false,
  String device = 'dev-a',
  String title = '书',
}) =>
    BookRecord(
      id: id,
      folderPath: '/books/$id',
      title: title,
      currentChapterIndex: chapter,
      currentPositionMs: position,
      finished: finished,
      deleted: deleted,
      addedAt: 0,
      updatedAt: updatedAt,
      lastPlayedAt: updatedAt,
      updatedByDevice: device,
    );

LibrarySnapshot snap(List<BookRecord> books) =>
    LibrarySnapshot(version: 1, books: books);

void main() {
  group('记录粒度合并', () {
    test('两台设备各自的新增都保留，不互相覆盖', () {
      // 设备 A 更新了《书甲》的进度，设备 B 新增了《书乙》
      final local = snap([rec('jia', chapter: 5, updatedAt: 200)]);
      final remote = snap([
        rec('jia', chapter: 1, updatedAt: 100),
        rec('yi', updatedAt: 150, device: 'dev-b'),
      ]);

      final merged = mergeSnapshots(local, remote);
      final ids = merged.books.map((b) => b.id).toSet();

      expect(ids, {'jia', 'yi'});
      expect(
        merged.books.firstWhere((b) => b.id == 'jia').currentChapterIndex,
        5,
        reason: '《书甲》必须保留设备 A 的进度',
      );
    });

    test('只在远端存在的书会被拉回来（新设备恢复）', () {
      final merged = mergeSnapshots(
        snap([]),
        snap([rec('x', chapter: 3, updatedAt: 100)]),
      );
      expect(merged.books.single.id, 'x');
      expect(merged.books.single.currentChapterIndex, 3);
    });
  });

  group('进度冲突', () {
    test('取更靠后的收听位置，而不是更晚的时间戳', () {
      // 远端时间戳更新，但本地明显听得更靠后——不能让进度回退
      final local = snap([rec('a', chapter: 8, position: 1000, updatedAt: 100)]);
      final remote =
          snap([rec('a', chapter: 3, position: 500, updatedAt: 999)]);

      final merged = mergeSnapshots(local, remote);
      expect(merged.books.single.currentChapterIndex, 8);
      expect(merged.books.single.currentPositionMs, 1000);
    });

    test('同一章内取更大的播放位置', () {
      final local = snap([rec('a', chapter: 2, position: 30000, updatedAt: 100)]);
      final remote =
          snap([rec('a', chapter: 2, position: 90000, updatedAt: 50)]);

      final merged = mergeSnapshots(local, remote);
      expect(merged.books.single.currentPositionMs, 90000);
    });
  });

  group('删除与更新冲突', () {
    test('删除更晚则以删除为准', () {
      final local = snap([rec('a', chapter: 4, updatedAt: 100)]);
      final remote = snap([rec('a', deleted: true, updatedAt: 500)]);

      final merged = mergeSnapshots(local, remote);
      expect(merged.books.single.deleted, isTrue);
    });

    test('更新更晚则保留这本书', () {
      final local = snap([rec('a', chapter: 4, updatedAt: 900)]);
      final remote = snap([rec('a', deleted: true, updatedAt: 100)]);

      final merged = mergeSnapshots(local, remote);
      expect(merged.books.single.deleted, isFalse);
      expect(merged.books.single.currentChapterIndex, 4);
    });
  });

  group('序列化', () {
    test('往返序列化保持字段不丢', () {
      final original = snap([
        rec('a', chapter: 3, position: 4200, updatedAt: 777, finished: true),
      ]);
      final restored = LibrarySnapshot.fromJson(original.toJson());

      expect(restored.books.single.id, 'a');
      expect(restored.books.single.currentChapterIndex, 3);
      expect(restored.books.single.currentPositionMs, 4200);
      expect(restored.books.single.finished, isTrue);
      expect(restored.books.single.updatedAt, 777);
    });
  });
}
