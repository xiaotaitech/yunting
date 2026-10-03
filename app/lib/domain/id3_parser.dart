import 'dart:convert';
import 'dart:typed_data';

import 'package:yun_audiobook/domain/entities.dart';

/// 极简 ID3v2 标签解析。
///
/// 只解析我们真正会用到的四个文本帧（标题 / 专辑 / 作者 / 音轨号），
/// 靠 Range 请求读文件头部的若干 KB 即可完成，不必下载整个文件。
/// 解析失败一律返回 [AudioTags.empty] —— 元数据是尽力而为的增强，
/// 不是必需品，缺了自然回退到文件名（library-catalog 规格的优先级链）。
class Id3Parser {
  /// 读取头部这么多字节通常足以覆盖文本帧；封面图帧可能更大，但我们不解析它。
  static const int headerProbeBytes = 64 * 1024;

  static const int _nul = 0x00;

  static AudioTags parse(Uint8List bytes) {
    try {
      final v2 = _parseV2(bytes);
      if (v2 != null && !v2.isEmpty) return v2;
    } on Object catch (_) {
      // 标签损坏不该影响加书流程
    }
    return AudioTags.empty;
  }

  static AudioTags? _parseV2(Uint8List b) {
    if (b.length < 10) return null;
    if (b[0] != 0x49 || b[1] != 0x44 || b[2] != 0x33) return null; // "ID3"

    final major = b[3];
    if (major != 2 && major != 3 && major != 4) return null;

    final tagSize = _syncSafe(b, 6);
    final end = (10 + tagSize).clamp(0, b.length);

    String? title;
    String? album;
    String? artist;
    String? track;
    var offset = 10;
    final idLength = major == 2 ? 3 : 4;
    final sizeLength = major == 2 ? 3 : 4;
    final flagsLength = major == 2 ? 0 : 2;

    while (offset + idLength + sizeLength + flagsLength <= end) {
      final id = String.fromCharCodes(b.sublist(offset, offset + idLength));
      if (id.codeUnitAt(0) == _nul) break; // 进入 padding 区

      final int frameSize;
      if (major == 2) {
        frameSize =
            (b[offset + 3] << 16) | (b[offset + 4] << 8) | b[offset + 5];
      } else if (major == 4) {
        frameSize = _syncSafe(b, offset + 4);
      } else {
        frameSize = (b[offset + 4] << 24) |
            (b[offset + 5] << 16) |
            (b[offset + 6] << 8) |
            b[offset + 7];
      }

      final dataStart = offset + idLength + sizeLength + flagsLength;
      final dataEnd = dataStart + frameSize;
      if (frameSize <= 0 || dataEnd > b.length) break;

      final data = b.sublist(dataStart, dataEnd);
      switch (id) {
        case 'TIT2':
        case 'TT2':
          title = _decodeText(data);
        case 'TALB':
        case 'TAL':
          album = _decodeText(data);
        case 'TPE1':
        case 'TP1':
          artist = _decodeText(data);
        case 'TRCK':
        case 'TRK':
          track = _decodeText(data);
      }
      offset = dataEnd;
    }

    return AudioTags(
      title: clean(title),
      album: clean(album),
      artist: clean(artist),
      track: parseTrack(track),
    );
  }

  static int _syncSafe(Uint8List b, int offset) =>
      ((b[offset] & 0x7f) << 21) |
      ((b[offset + 1] & 0x7f) << 14) |
      ((b[offset + 2] & 0x7f) << 7) |
      (b[offset + 3] & 0x7f);

  /// 文本帧首字节是编码标记：0=Latin-1，1=UTF-16(BOM)，2=UTF-16BE，3=UTF-8。
  static String? _decodeText(Uint8List data) {
    if (data.isEmpty) return null;
    final encoding = data[0];
    final payload = data.sublist(1);
    if (payload.isEmpty) return null;
    switch (encoding) {
      case 0:
        return latin1.decode(payload, allowInvalid: true);
      case 1:
        return _decodeUtf16(payload, endianFromBom: true);
      case 2:
        return _decodeUtf16(payload, endianFromBom: false);
      default:
        return utf8.decode(payload, allowMalformed: true);
    }
  }

  static String _decodeUtf16(Uint8List bytes, {required bool endianFromBom}) {
    var data = bytes;
    var littleEndian = false;
    if (endianFromBom && data.length >= 2) {
      if (data[0] == 0xFF && data[1] == 0xFE) {
        littleEndian = true;
        data = data.sublist(2);
      } else if (data[0] == 0xFE && data[1] == 0xFF) {
        data = data.sublist(2);
      }
    }
    final units = <int>[];
    for (var i = 0; i + 1 < data.length; i += 2) {
      units.add(
        littleEndian
            ? data[i] | (data[i + 1] << 8)
            : (data[i] << 8) | data[i + 1],
      );
    }
    return String.fromCharCodes(units);
  }

  /// 文本帧常带结尾的 NUL 填充，去掉后再 trim。
  static String? clean(String? s) {
    if (s == null) return null;
    final trimmed = s.split(String.fromCharCode(_nul)).join().trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  /// TRCK 常见形式是 "3" 或 "3/12"，两种都要能取到 3。
  static int? parseTrack(String? raw) {
    final s = clean(raw);
    if (s == null) return null;
    final head = s.split('/').first.trim();
    return int.tryParse(head);
  }
}
