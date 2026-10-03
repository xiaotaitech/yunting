import 'package:flutter_test/flutter_test.dart';
import 'package:yun_audiobook/data/repositories/library_repository.dart';

void main() {
  group('合集 ID 由路径派生', () {
    test('同一路径在任何设备上都得到同一个 id', () {
      expect(seriesIdForFolder('/有声书/三体'), seriesIdForFolder('/有声书/三体'));
    });

    test('不同路径得到不同 id', () {
      expect(
        seriesIdForFolder('/有声书/三体'),
        isNot(seriesIdForFolder('/有声书/球状闪电')),
      );
    });

    test('id 形式稳定，便于排查', () {
      final id = seriesIdForFolder('/books/x');
      // 前缀仍是 book-：它进了同步文件，旧版本 App 也认这个格式
      expect(id, startsWith('book-'));
      expect(id.length, 'book-'.length + 16);
    });
  });
}
