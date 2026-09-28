import 'package:flutter_test/flutter_test.dart';

/// 与 BaiduApiClient._appendToken 保持同一份实现，用于验证令牌拼接规则。
/// （私有方法无法直接测，这里复刻逻辑并锁死行为；改动任何一边都要同步。）
final _tokenParam = RegExp(r'access_token=[^&]*');

String appendToken(String dlink, String token) {
  final encoded = Uri.encodeComponent(token);
  if (_tokenParam.hasMatch(dlink)) {
    return dlink.replaceAll(_tokenParam, 'access_token=$encoded');
  }
  return '$dlink${dlink.contains('?') ? '&' : '?'}access_token=$encoded';
}

int countTokens(String url) => _tokenParam.allMatches(url).length;

void main() {
  group('dlink 令牌拼接', () {
    test('无 query 时用 ? 起头', () {
      expect(appendToken('https://d.pcs.baidu.com/file/abc', 't1'),
          'https://d.pcs.baidu.com/file/abc?access_token=t1');
    });

    test('已有 query 时用 & 追加', () {
      expect(appendToken('https://d.pcs.baidu.com/file/abc?fid=9', 't1'),
          'https://d.pcs.baidu.com/file/abc?fid=9&access_token=t1');
    });

    test('已带令牌时替换而不是追加，避免出现两个 access_token', () {
      final once = appendToken('https://x/f?fid=9', 'old');
      final twice = appendToken(once, 'new');

      expect(countTokens(twice), 1);
      expect(twice, contains('access_token=new'));
      expect(twice, isNot(contains('old')));
    });

    test('替换后其余参数原样保留', () {
      const url = 'https://x/f?fid=9&access_token=old&sign=abc';
      final result = appendToken(url, 'new');

      expect(result, 'https://x/f?fid=9&access_token=new&sign=abc');
    });

    test('令牌中的特殊字符会被转义', () {
      final result = appendToken('https://x/f', 'a b+c/d');
      expect(result, contains('access_token=a%20b%2Bc%2Fd'));
    });
  });
}
