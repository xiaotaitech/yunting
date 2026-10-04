import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:yun_audiobook/domain/id3_parser.dart';

/// 拼一个 ID3v2.3/2.4 标签。frames 是（帧 id, 帧数据）。
Uint8List tag(List<(String, List<int>)> frames, {int major = 3}) {
  final body = <int>[];
  for (final (id, data) in frames) {
    final n = data.length;
    body
      ..addAll(id.codeUnits)
      ..addAll(
        major == 4
            ? [(n >> 21) & 0x7f, (n >> 14) & 0x7f, (n >> 7) & 0x7f, n & 0x7f]
            : [(n >> 24) & 0xff, (n >> 16) & 0xff, (n >> 8) & 0xff, n & 0xff],
      )
      ..addAll([0, 0])
      ..addAll(data);
  }
  final s = body.length;
  return Uint8List.fromList([
    ...'ID3'.codeUnits, major, 0, 0, //
    (s >> 21) & 0x7f, (s >> 14) & 0x7f, (s >> 7) & 0x7f, s & 0x7f,
    ...body,
  ]);
}

/// APIC：编码 + MIME\0 + 类型 + 描述 + 图片
List<int> apic(int type, List<int> image,
        {int encoding = 0, String desc = ''}) =>
    [
      encoding,
      ...'image/jpeg'.codeUnits,
      0,
      type,
      ...(encoding == 1
          ? [
              0xff,
              0xfe,
              ...desc.codeUnits.expand((c) => [c, 0]),
              0,
              0
            ]
          : [...desc.codeUnits, 0]),
      ...image,
    ];

void main() {
  const cover = [0xff, 0xd8, 1, 2, 3, 0xff, 0xd9];
  const back = [0xff, 0xd8, 9, 9, 0xff, 0xd9];

  test('取「封面」类型那张，而不是排在前面的其它图', () {
    final t = tag([('APIC', apic(4, back)), ('APIC', apic(3, cover))]);
    expect(Id3Parser.picture(t), cover);
  });

  test('没有封面类型时取第一张', () {
    expect(Id3Parser.picture(tag([('APIC', apic(0, back))])), back);
  });

  test('UTF-16 描述（两个 NUL 结尾）', () {
    final t = tag([('APIC', apic(3, cover, encoding: 1, desc: 'Front'))]);
    expect(Id3Parser.picture(t), cover);
  });

  test('v2.4 同步安全的帧长度', () {
    expect(Id3Parser.picture(tag([('APIC', apic(3, cover))], major: 4)), cover);
  });

  test('没有图、不是 ID3、截断：都返回 null 不抛错', () {
    expect(
        Id3Parser.picture(tag([
          ('TIT2', [0, ...'x'.codeUnits])
        ])),
        isNull);
    expect(Id3Parser.picture(Uint8List.fromList([1, 2, 3])), isNull);
    final t = tag([('APIC', apic(3, cover))]);
    expect(Id3Parser.picture(Uint8List.sublistView(t, 0, 20)), isNull);
  });

  test('标签总长：用来决定封面要读多少字节', () {
    final t = tag([('APIC', apic(3, cover))]);
    expect(Id3Parser.tagLength(Uint8List.sublistView(t, 0, 10)), t.length);
    expect(Id3Parser.tagLength(Uint8List.fromList(List.filled(10, 0))), isNull);
  });
}
