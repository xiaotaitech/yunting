import 'package:flutter_test/flutter_test.dart';
import 'package:yun_audiobook/core/natural_sort.dart';

/// 复刻 LibraryRepository._buildChapters 的排序规则：
/// 先按所在目录自然序，同目录内再按文件名自然序。
List<String> sortChapters(List<String> paths) {
  final sorted = [...paths]..sort((a, b) {
      final dirA = parentDirOf(a);
      final dirB = parentDirOf(b);
      if (dirA != dirB) return compareNatural(dirA, dirB);
      return compareNatural(a.split('/').last, b.split('/').last);
    });
  return sorted;
}

void main() {
  group('parentDirOf', () {
    test('取父目录', () {
      expect(parentDirOf('/a/b/c.mp3'), '/a/b');
      expect(parentDirOf('/a/c.mp3'), '/a');
    });

    test('顶层文件回退到根', () {
      expect(parentDirOf('/c.mp3'), '/');
      expect(parentDirOf('c.mp3'), '/');
    });
  });

  group('跨子目录的章节顺序', () {
    // 真实数据的形状：序号在目录名上，文件名本身没有序号。
    // 只按文件名排会排出 0411 → 0404 → 0516 这种无意义的顺序。
    test('序号在目录名上时，按目录排', () {
      final result = sortChapters([
        '/书/0411  90%的不舒服/90%的不舒服.mp3',
        '/书/0103 我们终将穿越风暴/我们终将穿越风暴.mp3',
        '/书/0516 为什么10倍增长/为什么10倍增长.mp3',
        '/书/0404  一个人的疗愈/一个人的疗愈.mp3',
      ]);

      expect(result.map(parentDirOf).map((d) => d.split('/').last).toList(), [
        '0103 我们终将穿越风暴',
        '0404  一个人的疗愈',
        '0411  90%的不舒服',
        '0516 为什么10倍增长',
      ]);
    });

    test('目录本身也按自然序，第10卷不能排到第2卷前', () {
      final result = sortChapters([
        '/书/第10卷/a.mp3',
        '/书/第2卷/a.mp3',
        '/书/第1卷/a.mp3',
      ]);
      expect(result.map(parentDirOf).map((d) => d.split('/').last).toList(),
          ['第1卷', '第2卷', '第10卷']);
    });

    test('同一子目录内仍按文件名自然序', () {
      final result = sortChapters([
        '/书/第1卷/第10章.mp3',
        '/书/第1卷/第2章.mp3',
        '/书/第2卷/第1章.mp3',
        '/书/第1卷/第1章.mp3',
      ]);
      expect(result, [
        '/书/第1卷/第1章.mp3',
        '/书/第1卷/第2章.mp3',
        '/书/第1卷/第10章.mp3',
        '/书/第2卷/第1章.mp3',
      ]);
    });

    test('单目录的书行为不变——等价于纯按文件名排', () {
      final paths = [
        '/书/第10章.mp3',
        '/书/第2章.mp3',
        '/书/第1章.mp3',
      ];
      final byDir = sortChapters(paths);
      final byName = [...paths]
        ..sort((a, b) => compareNatural(a.split('/').last, b.split('/').last));

      expect(byDir, byName);
      expect(byDir.last, '/书/第10章.mp3');
    });
  });
}
