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

  /// 标签总长（含 10 字节头）。不是 ID3v2 时返回 null。
  /// 用来决定封面要读多少字节：图片帧就在标签里，标签之外不必读。
  static int? tagLength(Uint8List header) {
    if (header.length < 10) return null;
    if (header[0] != 0x49 || header[1] != 0x44 || header[2] != 0x33) {
      return null;
    }
    return 10 + _syncSafe(header, 6);
  }

  /// 内嵌封面（APIC / v2.2 的 PIC 帧）的图片字节。优先「封面」类型（3），
  /// 没有就取第一张。没有或损坏返回 null——封面是装饰，不能影响任何流程。
  static Uint8List? picture(Uint8List b) {
    try {
      return _picture(b);
    } on Object catch (_) {
      return null;
    }
  }

  static Uint8List? _picture(Uint8List b) {
    if (b.length < 10) return null;
    if (b[0] != 0x49 || b[1] != 0x44 || b[2] != 0x33) return null;
    final major = b[3];
    if (major != 2 && major != 3 && major != 4) return null;
    final end = (10 + _syncSafe(b, 6)).clamp(0, b.length);
    final idLength = major == 2 ? 3 : 4;
    final headerLength = major == 2 ? 6 : 10;

    Uint8List? first;
    var offset = 10;
    while (offset + headerLength <= end) {
      if (b[offset] == _nul) break;
      final id = String.fromCharCodes(b.sublist(offset, offset + idLength));
      final size = major == 2
          ? (b[offset + 3] << 16) | (b[offset + 4] << 8) | b[offset + 5]
          : major == 4
              ? _syncSafe(b, offset + 4)
              : (b[offset + 4] << 24) |
                  (b[offset + 5] << 16) |
                  (b[offset + 6] << 8) |
                  b[offset + 7];
      final dataStart = offset + headerLength;
      final dataEnd = dataStart + size;
      if (size <= 0 || dataEnd > b.length) break;

      if (id == 'APIC' || id == 'PIC') {
        final d = b.sublist(dataStart, dataEnd);
        final encoding = d[0];
        var i = 1;
        if (id == 'PIC') {
          i += 3; // 固定三字节格式，如 "JPG"
        } else {
          while (i < d.length && d[i] != _nul) {
            i++; // MIME，Latin-1，NUL 结尾
          }
          i++;
        }
        final type = d[i];
        i++;
        // 描述：UTF-16 系编码以两个 NUL 结尾，其余一个
        final wide = encoding == 1 || encoding == 2;
        while (i < d.length) {
          if (wide) {
            if (i + 1 < d.length && d[i] == _nul && d[i + 1] == _nul) {
              i += 2;
              break;
            }
            i += 2;
          } else {
            if (d[i] == _nul) {
              i++;
              break;
            }
            i++;
          }
        }
        if (i < d.length) {
          final image = Uint8List.fromList(d.sublist(i));
          if (type == 3) return image;
          first ??= image;
        }
      }
      offset = dataEnd;
    }
    return first;
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
