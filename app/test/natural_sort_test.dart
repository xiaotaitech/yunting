import 'package:flutter_test/flutter_test.dart';
import 'package:yun_audiobook/core/natural_sort.dart';

void main() {
  group('自然序排序', () {
    test('数字段按数值比较，而不是字典序', () {
      final files = ['第10章.mp3', '第2章.mp3', '第1章.mp3'];
      files.sort(compareNatural);
      expect(files, ['第1章.mp3', '第2章.mp3', '第10章.mp3']);
    });

    test('英文命名同样按数值排序', () {
      final files = ['ch10.mp3', 'ch2.mp3', 'ch1.mp3', 'ch21.mp3'];
      files.sort(compareNatural);
      expect(files, ['ch1.mp3', 'ch2.mp3', 'ch10.mp3', 'ch21.mp3']);
    });

    test('前导零不影响数值比较', () {
      final files = ['track007.mp3', 'track08.mp3', 'track9.mp3'];
      files.sort(compareNatural);
      expect(files, ['track007.mp3', 'track08.mp3', 'track9.mp3']);
    });

    test('多段数字按从左到右依次比较', () {
      final files = ['1-10.mp3', '1-2.mp3', '2-1.mp3'];
      files.sort(compareNatural);
      expect(files, ['1-2.mp3', '1-10.mp3', '2-1.mp3']);
    });

    test('大小写不影响顺序', () {
      expect(compareNatural('Chapter2.mp3', 'chapter10.mp3'), lessThan(0));
    });

    test('超长数字不会溢出', () {
      expect(
        compareNatural(
            'a99999999999999999999.mp3', 'a100000000000000000000.mp3'),
        lessThan(0),
      );
    });
  });

  group('章节排序入口', () {
    test('两边都有 track 号时按 track 排序，忽略文件名', () {
      final result = compareChapters(
        nameA: 'zzz.mp3',
        nameB: 'aaa.mp3',
        trackA: 1,
        trackB: 2,
      );
      expect(result, lessThan(0));
    });

    test('track 号缺失时回退到文件名自然序', () {
      final result = compareChapters(nameA: '第2章.mp3', nameB: '第10章.mp3');
      expect(result, lessThan(0));
    });

    test('只有一边有 track 号时不采信，走文件名', () {
      final result =
          compareChapters(nameA: '第10章.mp3', nameB: '第2章.mp3', trackA: 1);
      expect(result, greaterThan(0));
    });
  });

  group('track 号可用性判定', () {
    test('全员齐备才允许按 track 排序', () {
      expect(canSortByTrack([1, 2, 3]), isTrue);
    });

    test('只要有一个缺失就整体回退到文件名', () {
      expect(canSortByTrack([1, null, 3]), isFalse);
      expect(canSortByTrack([null, null]), isFalse);
    });

    test('空列表不算可用（没有可比的东西）', () {
      expect(canSortByTrack(const <int?>[]), isFalse);
    });
  });
}
