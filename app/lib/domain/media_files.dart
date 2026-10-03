/// 文件类型识别：哪些网盘文件能成为合集里的条目。
///
/// 认领、刷新、浏览三处必须同一个口径，否则会出现「浏览时显示是音频、
/// 加进书架却说没有可识别的文件」。所以只在这里判断一次。
library;

import 'package:yun_audiobook/core/config.dart';
import 'package:yun_audiobook/data/drive/cloud_drive_source.dart';
import 'package:yun_audiobook/domain/entities.dart';

MediaKind? mediaKindOf(DriveEntry e) {
  if (e.isDirectory) return null;
  if (AppConfig.audioExtensions.contains(e.extension)) return MediaKind.audio;
  if (AppConfig.videoExtensions.contains(e.extension)) return MediaKind.video;
  return null;
}

/// 含视频的合集是课程，否则是有声书（add-video-courses D4）。
SeriesKind seriesKindOf(Iterable<MediaKind> kinds) =>
    kinds.contains(MediaKind.video) ? SeriesKind.course : SeriesKind.audiobook;

bool isMediaEntry(DriveEntry e) => mediaKindOf(e) != null;
