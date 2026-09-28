import 'package:flutter_test/flutter_test.dart';
import 'package:yun_audiobook/domain/library_repository.dart';

void main() {
  group('书籍 ID 由路径派生', () {
    test('同一路径在任何设备上都得到同一个 id', () {
      expect(bookIdForFolder('/有声书/三体'), bookIdForFolder('/有声书/三体'));
    });

    test('不同路径得到不同 id', () {
      expect(bookIdForFolder('/有声书/三体'),
          isNot(bookIdForFolder('/有声书/球状闪电')));
    });

    test('id 形式稳定，便于排查', () {
      final id = bookIdForFolder('/books/x');
      expect(id, startsWith('book-'));
      expect(id.length, 'book-'.length + 16);
    });
  });
}
