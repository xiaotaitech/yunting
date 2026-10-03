/// 「添加书籍」的候选：网盘里装着媒体文件的文件夹。
///
/// 纯函数，便于单测：分组规则与关键字匹配都有容易写错的边界
/// （根目录、路径末尾斜杠、多关键字、大小写）。
library;

import 'package:yun_audiobook/data/drive/cloud_drive_source.dart';

class MediaFolder {
  const MediaFolder({
    required this.path,
    required this.mediaCount,
    required this.totalBytes,
    this.latestMtime,
  });

  /// 文件夹的完整网盘路径，也是认领成合集时的身份。
  final String path;
  final int mediaCount;
  final int totalBytes;

  /// 夹内最新文件的修改时间（秒）。列表按它倒序：刚传上去的书排最前面。
  final int? latestMtime;

  String get name {
    final i = path.lastIndexOf('/');
    return i < 0 || i == path.length - 1 ? path : path.substring(i + 1);
  }

  /// 上一级路径，列表里用小字显示，区分同名文件夹（「卷一」到处都有）。
  String get parentPath {
    final i = path.lastIndexOf('/');
    return i <= 0 ? '/' : path.substring(0, i);
  }
}

/// 把媒体文件按所在文件夹分组，最新修改的在前。
List<MediaFolder> groupIntoFolders(Iterable<DriveEntry> files) {
  final byDir = <String, ({int count, int bytes, int? mtime})>{};
  for (final f in files) {
    if (f.isDirectory) continue;
    final cut = f.path.lastIndexOf('/');
    final dir = cut <= 0 ? '/' : f.path.substring(0, cut);
    final prev = byDir[dir];
    final mtime = f.serverMtime;
    byDir[dir] = (
      count: (prev?.count ?? 0) + 1,
      bytes: (prev?.bytes ?? 0) + f.size,
      mtime: [prev?.mtime, mtime].whereType<int>().fold<int?>(
            null,
            (a, b) => a == null || b > a ? b : a,
          ),
    );
  }
  final folders = [
    for (final MapEntry(key: path, value: v) in byDir.entries)
      MediaFolder(
        path: path,
        mediaCount: v.count,
        totalBytes: v.bytes,
        latestMtime: v.mtime,
      ),
  ]..sort((a, b) {
      final byTime = (b.latestMtime ?? 0).compareTo(a.latestMtime ?? 0);
      return byTime != 0 ? byTime : a.path.compareTo(b.path);
    });
  return folders;
}

/// 按关键字筛选。匹配整条路径而不只是文件夹名：搜「三体」要能找到
/// `…/三体/卷一`。空格分隔的多个词须全部命中（顺序不限），大小写不敏感。
List<MediaFolder> filterFolders(List<MediaFolder> folders, String query) {
  final terms = query
      .toLowerCase()
      .split(RegExp(r'\s+'))
      .where((t) => t.isNotEmpty)
      .toList();
  if (terms.isEmpty) return folders;
  return [
    for (final f in folders)
      if (terms.every(f.path.toLowerCase().contains)) f,
  ];
}
