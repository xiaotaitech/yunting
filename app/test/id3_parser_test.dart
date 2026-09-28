import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:yun_audiobook/domain/id3_parser.dart';

/// 构造一个最小的 ID3v2.3 标签，用于验证解析逻辑。
Uint8List buildId3v3(Map<String, String> frames) {
  final body = BytesBuilder();
  frames.forEach((id, value) {
    final payload = [0x03, ...utf8.encode(value)]; // 0x03 = UTF-8
    body.add(ascii.encode(id));
    final size = payload.length;
    body.add([
      (size >> 24) & 0xff,
      (size >> 16) & 0xff,
      (size >> 8) & 0xff,
      size & 0xff,
    ]);
    body.add([0x00, 0x00]); // flags
    body.add(payload);
  });

  final frameBytes = body.takeBytes();
  final tagSize = frameBytes.length;
  final header = <int>[
    0x49, 0x44, 0x33, // "ID3"
    0x03, 0x00, // v2.3
    0x00, // flags
    // syncsafe size
    (tagSize >> 21) & 0x7f,
    (tagSize >> 14) & 0x7f,
    (tagSize >> 7) & 0x7f,
    tagSize & 0x7f,
  ];
  return Uint8List.fromList([...header, ...frameBytes]);
}

void main() {
  group('ID3v2 解析', () {
    test('解析标题、专辑、作者与音轨号', () {
      final bytes = buildId3v3({
        'TIT2': '第三章 破晓',
        'TALB': '三体',
        'TPE1': '刘慈欣',
        'TRCK': '3/12',
      });

      final tags = Id3Parser.parse(bytes);
      expect(tags.title, '第三章 破晓');
      expect(tags.album, '三体');
      expect(tags.artist, '刘慈欣');
      expect(tags.track, 3);
    });

    test('TRCK 为纯数字时同样能取到', () {
      final tags = Id3Parser.parse(buildId3v3({'TRCK': '7'}));
      expect(tags.track, 7);
    });

    test('非 ID3 文件返回空标签而不是抛异常', () {
      final tags = Id3Parser.parse(Uint8List.fromList(List.filled(64, 0x41)));
      expect(tags.isEmpty, isTrue);
    });

    test('截断的数据不会让解析崩溃', () {
      final full = buildId3v3({'TIT2': '标题很长很长很长'});
      final truncated = Uint8List.fromList(full.take(14).toList());
      expect(() => Id3Parser.parse(truncated), returnsNormally);
    });

    test('清理结尾的 NUL 填充', () {
      final withNul = 'abc${String.fromCharCode(0)}';
      expect(Id3Parser.clean(withNul), 'abc');
    });

    test('空白与全 NUL 视为无值', () {
      expect(Id3Parser.clean('   '), isNull);
      expect(Id3Parser.clean(String.fromCharCode(0)), isNull);
    });
  });
}
