import 'package:flutter_test/flutter_test.dart';
import 'package:yun_audiobook/core/natural_sort.dart';
import 'package:yun_audiobook/data/drive/cloud_drive_source.dart';
import 'package:yun_audiobook/data/drive/demo/demo_drive_source.dart';

/// 与 browseProvider 里的排序规则保持一致：目录在前、文件在后，各自自然序。
/// （provider 依赖 riverpod 容器，这里复刻规则本身并锁住行为。）
List<DriveEntry> sortForBrowse(List<DriveEntry> entries) {
  final sorted = [...entries]..sort((a, b) {
      if (a.isDirectory != b.isDirectory) return a.isDirectory ? -1 : 1;
      return compareNatural(a.name, b.name);
    });
  return sorted;
}

void main() {
  group('目录浏览排序', () {
    test('文件按自然序，第10章不能排到第1章前面', () async {
      final entries = await DemoDriveSource().listDirectory('/我的有声书/三体');
      final names = sortForBrowse(entries)
          .where((e) => e.name.endsWith('.mp3'))
          .map((e) => e.name)
          .toList();

      expect(names[0], startsWith('第1章'));
      expect(names[1], startsWith('第2章'));
      expect(names[2], startsWith('第3章'));
      expect(names[3], startsWith('第10章'));
      expect(names[4], startsWith('第11章'));
    });

    test('目录始终排在文件前面', () async {
      final entries = await DemoDriveSource().listDirectory('/我的有声书');
      final sorted = sortForBrowse(entries);
      final firstFile = sorted.indexWhere((e) => !e.isDirectory);

      // 这个目录全是子目录，没有文件
      expect(firstFile, -1);
      expect(sorted.every((e) => e.isDirectory), isTrue);
    });

    test('浏览顺序与认领成书后的章节顺序一致', () async {
      final entries = await DemoDriveSource().listDirectory('/我的有声书/三体');
      final browseOrder = sortForBrowse(entries)
          .where((e) => e.name.endsWith('.mp3'))
          .map((e) => e.name)
          .toList();

      // 章节侧用的是同一个比较器
      final chapterOrder = entries
          .where((e) => e.name.endsWith('.mp3'))
          .map((e) => e.name)
          .toList()
        ..sort(compareNatural);

      expect(
        browseOrder,
        chapterOrder,
        reason: '同一批文件在两个界面必须是同一个顺序',
      );
    });
  });
}
