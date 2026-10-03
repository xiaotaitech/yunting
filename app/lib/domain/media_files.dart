/// 文件类型识别：哪些网盘文件能成为合集里的条目。
///
/// 认领、刷新、浏览三处必须同一个口径，否则会出现「浏览时显示是音频、
/// 加进书架却说没有可识别的文件」。所以只在这里判断一次。
library;

import 'package:yun_audiobook/core/config.dart';
import 'package:yun_audiobook/data/drive/cloud_drive_source.dart';
import 'package:yun_audiobook/domain/entities.dart';

/// 本变更只识别音频；视频识别在 add-video-courses 里加。
MediaKind? mediaKindOf(DriveEntry e) {
  if (e.isDirectory) return null;
  if (AppConfig.audioExtensions.contains(e.extension)) return MediaKind.audio;
  return null;
}

bool isMediaEntry(DriveEntry e) => mediaKindOf(e) != null;
