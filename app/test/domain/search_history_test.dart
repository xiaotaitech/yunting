import 'package:flutter_test/flutter_test.dart';
import 'package:yun_audiobook/domain/search_history.dart';

void main() {
  test('最近在前，空白不记', () {
    var h = SearchHistory.push(const [], '三体');
    h = SearchHistory.push(h, '  ');
    h = SearchHistory.push(h, ' 小王子 ');
    expect(h, ['小王子', '三体']);
  });

  test('重复的词挪到最前，不重复记', () {
    final h = SearchHistory.push(const ['小王子', '三体'], '三体');
    expect(h, ['三体', '小王子']);
  });

  test('超出上限丢最旧的', () {
    var h = <String>[];
    for (var i = 0; i < 12; i++) {
      h = SearchHistory.push(h, '$i');
    }
    expect(h, hasLength(SearchHistory.maxEntries));
    expect(h.first, '11');
    expect(h.last, '2');
  });
}
