import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yun_audiobook/app/providers.dart';
import 'package:yun_audiobook/core/logging.dart';

part 'series_cover.g.dart';

/// 封面文件的字节上限。封面本该是小图，真碰上几十 MB 的就放弃——
/// 不值得为一张装饰图在限速账号上耗带宽。
const int _maxCoverBytes = 4 * 1024 * 1024;

/// 封面字节，按 fsId 缓存，一次会话只从网盘取一次。
///
/// 走 `readRange` 一次读完，而不是把 dlink 丢给 `Image.network`：
/// dlink 有时效，过期后图片会变成一个静默失败的空白框，而封面小文件
/// 读完就与网络无关了，之后随便重建多少次都不再请求。
@Riverpod(keepAlive: true)
Future<Uint8List?> coverBytes(Ref ref, String fsId) async {
  final drive = ref.watch(servicesProvider).drive;
  try {
    final entry = (await drive.fetchMetadata([fsId]))[fsId];
    if (entry == null || entry.size <= 0) return null;
    if (entry.size > _maxCoverBytes) {
      Log.d('cover', '封面过大，改用占位：${entry.name}（${entry.size} 字节）');
      return null;
    }
    return Uint8List.fromList(await drive.readRange(fsId, 0, entry.size - 1));
  } on Object catch (e) {
    // 封面是纯装饰。取不到就用占位，绝不能让它影响加书或播放。
    Log.d('cover', '封面读取失败，改用占位：$e');
    return null;
  }
}

/// 合集封面。
///
/// 网盘目录里有 cover / folder / front 之类的图片时显示真图（`coverFsId`
/// 在认领时就扫出来存库了，之前一直没人渲染）；取不到时用「书名首字 +
/// 由书名决定的色相」占位。
///
/// 为什么占位不能是统一图标：书架靠封面区分书，一屏十几本全是同一个耳机
/// 图标，等于没有封面。首字加配色至少保证每本书长得不一样，且同一本书在
/// 任何设备、任何时候都是同一个颜色（哈希只取决于书名）。
class SeriesCover extends ConsumerWidget {
  const SeriesCover({
    required this.title,
    required this.coverFsId,
    required this.width,
    required this.height,
    this.localPath,
    super.key,
    this.radius = 10,
  });

  final String title;
  final String? coverFsId;

  /// 本机封面文件（自动从媒体里取的、或用户手动选的），优先于网盘封面图。
  final String? localPath;
  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fsId = coverFsId;

    Widget child = _Placeholder(title: title, width: width, height: height);
    final local = localPath;
    if (local != null && File(local).existsSync()) {
      child = Image.file(
        File(local),
        width: width,
        height: height,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) =>
            _Placeholder(title: title, width: width, height: height),
      );
    } else if (fsId != null && fsId.isNotEmpty) {
      // 加载中与失败都落回占位，不放 spinner：封面区域一闪一闪比慢一点更难受
      final bytes = ref.watch(coverBytesProvider(fsId)).value;
      if (bytes != null) {
        child = Image.memory(
          bytes,
          width: width,
          height: height,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (_, __, ___) =>
              _Placeholder(title: title, width: width, height: height),
        );
      }
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(width: width, height: height, child: child),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({
    required this.title,
    required this.width,
    required this.height,
  });

  final String title;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final hue = (_stableHash(title) % 360).toDouble();

    // 饱和度压低、明度拉开，保证首字和底色在两种主题下都够对比。
    final bg = HSLColor.fromAHSL(1, hue, dark ? 0.30 : 0.38, dark ? 0.26 : 0.84)
        .toColor();
    final fg = HSLColor.fromAHSL(1, hue, dark ? 0.50 : 0.55, dark ? 0.84 : 0.30)
        .toColor();

    return Container(
      color: bg,
      alignment: Alignment.center,
      child: Text(
        _initialOf(title),
        style: TextStyle(
          fontSize: math.min(width, height) * 0.44,
          fontWeight: FontWeight.w600,
          color: fg,
          height: 1,
        ),
      ),
    );
  }
}

/// 取书名里第一个「能当字用」的字符。
///
/// 直接取 `title[0]` 不行：真实数据里有 `%90的不舒服，呼吸就能解决`
/// 这种以符号开头的标题，占位上印一个「%」毫无意义。
String _initialOf(String title) {
  final match = RegExp('[A-Za-z0-9一-鿿]').firstMatch(title);
  if (match != null) return match.group(0)!.toUpperCase();
  final trimmed = title.trim();
  // runes 而不是 substring(0,1)：别把代理对（emoji 之类）切成半个字符
  return trimmed.isEmpty ? '书' : String.fromCharCode(trimmed.runes.first);
}

/// 自己实现哈希而不是用 `String.hashCode`：后者在不同进程里可以不一样，
/// 那会让同一本书今天蓝、明天绿。这个只取决于字符本身。
int _stableHash(String s) {
  var h = 2166136261;
  for (final unit in s.codeUnits) {
    h = (h ^ unit) * 16777619 & 0x7fffffff;
  }
  return h;
}
