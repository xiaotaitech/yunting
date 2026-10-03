/// 领域实体（refactor-app-foundation D3）。
///
/// 「文件夹即合集」（design.md D4）：用户认领的一个网盘目录就是一个 [Series]
/// ——有声书或课程；目录里的媒体文件按自然序成为 [Episode]。
///
/// 改名不改存储：库表仍叫 books / chapters，同步 JSON 键也不变。
/// 换名字换不来用户价值，改表名却要冒迁移风险。
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'entities.freezed.dart';

/// 合集类型。决定界面用词（章 / 课）与默认播放形态。
enum SeriesKind {
  audiobook,
  course;

  static SeriesKind parse(String? raw) =>
      values.firstWhere((k) => k.name == raw, orElse: () => audiobook);
}

/// 单个条目的媒体类型。一门课里可能混着纯音频与视频。
enum MediaKind {
  audio,
  video;

  static MediaKind parse(String? raw) =>
      values.firstWhere((k) => k.name == raw, orElse: () => audio);
}

/// 存储里按 index 存整数，顺序不能动。
enum CacheState { none, queued, downloading, cached, failed }

@freezed
abstract class Episode with _$Episode {
  const factory Episode({
    required String id,
    required String seriesId,
    required String fsId,
    required String path,
    required String title,
    required String fileName,
    required int size,

    /// 最终展示顺序。用户手动拖动后这里会被改写并持久化。
    required int orderIndex,
    @Default(MediaKind.audio) MediaKind mediaKind,

    /// 音频标签里的 track 号，排序时优先于文件名（library-catalog 规格）。
    int? trackNumber,
    int? durationMs,
    @Default(CacheState.none) CacheState cacheState,
    String? localPath,
    @Default(0) int downloadedBytes,
  }) = _Episode;

  const Episode._();

  bool get isCached => cacheState == CacheState.cached && localPath != null;

  Duration? get duration =>
      durationMs == null ? null : Duration(milliseconds: durationMs!);
}

@freezed
abstract class Series with _$Series {
  const factory Series({
    required String id,

    /// 网盘中的目录路径。这是合集的身份，用于去重认领。
    required String folderPath,
    required String title,
    required DateTime addedAt,
    required DateTime updatedAt,
    @Default(SeriesKind.audiobook) SeriesKind kind,
    String? author,
    String? coverFsId,
    String? coverLocalPath,
    @Default(0) int episodeCount,
    @Default(0) int currentEpisodeIndex,
    @Default(0) int currentPositionMs,
    @Default(false) bool finished,

    /// 网盘路径消失时置位。条目与进度都保留（library-catalog 规格）。
    @Default(false) bool sourceMissing,

    /// 用户手动编辑过的字段不允许被自动识别结果覆盖。
    @Default(false) bool titleEditedByUser,
    @Default(false) bool authorEditedByUser,
    @Default(false) bool orderEditedByUser,
    DateTime? lastPlayedAt,

    /// 同步时的 LWW 合并依据（listening-progress 规格）。
    @Default('') String updatedByDevice,
  }) = _Series;

  const Series._();

  /// 从未播放过。书架上显示「未开始」而不是一个误导人的百分比。
  bool get notStarted => lastPlayedAt == null;

  Duration get position => Duration(milliseconds: currentPositionMs);

  /// 全合集维度的进度，书架卡片与续听卡片同一口径。
  double get progress => episodeCount == 0
      ? 0.0
      : ((currentEpisodeIndex + 1) / episodeCount).clamp(0.0, 1.0);
}

/// 音频标签解析结果。全部字段都是尽力而为，缺失是常态。
@freezed
abstract class AudioTags with _$AudioTags {
  const factory AudioTags({
    String? title,
    String? album,
    String? artist,
    int? track,
  }) = _AudioTags;

  const AudioTags._();

  static const empty = AudioTags();

  bool get isEmpty =>
      title == null && album == null && artist == null && track == null;
}

/// 播放历史里的一条（play-history）。
///
/// 合集名与条目名是**播放当时的快照**，不是现取的——刷新章节会把 chapters
/// 整批重建、书名也可能被改，历史该记的是「当时听的是什么」。
@freezed
abstract class PlayHistoryEntry with _$PlayHistoryEntry {
  const factory PlayHistoryEntry({
    required int id,
    required String seriesId,
    required String episodeId,

    /// 认领时的条目序号。用它跳回去续播；合集被刷新过就可能对不上，
    /// 所以跳转前要校验范围。
    required int episodeIndex,
    required String seriesTitle,
    required String episodeTitle,
    required DateTime startedAt,
    required DateTime lastAt,

    /// 最后一次上报的播放位置，用于跳回去接着听，也用于累计时长时算增量。
    required int lastPositionMs,

    /// 累计实际收听时长。只累加「像是在正常播放」的增量，
    /// 拖动进度条跳过去的部分不算（见 HistoryDao）。
    required int listenedMs,
    required bool finished,
    String? coverFsId,
  }) = _PlayHistoryEntry;
}
