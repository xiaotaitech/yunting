/// 同步载体的数据结构与合并规则（listening-progress 规格）。
///
/// 合并是**记录粒度**的 LWW，不是整文件覆盖——否则「手机上听到第 5 章、
/// 平板上加了一本新书」会互相抹掉。进度字段还有一条额外规则：取更靠后的
/// 收听位置，而不是单纯的较晚时间戳，因为进度回退是用户最反感的表现。
library;

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:yun_audiobook/domain/entities.dart';

part 'library_snapshot.freezed.dart';
part 'library_snapshot.g.dart';

/// 同步文件里的一条合集记录。JSON 键名沿用 v1，一个都不能改——
/// 旧版本 App 还在读写同一个文件。
@freezed
abstract class BookRecord with _$BookRecord {
  const factory BookRecord({
    required String id,
    @JsonKey(name: 'folder_path') required String folderPath,
    required String title,
    String? author,
    @JsonKey(name: 'cover_fs_id') String? coverFsId,
    @JsonKey(name: 'current_chapter_index') @Default(0) int currentChapterIndex,
    @JsonKey(name: 'current_position_ms') @Default(0) int currentPositionMs,
    @Default(false) bool finished,
    @Default(false) bool deleted,
    @JsonKey(name: 'added_at') @Default(0) int addedAt,
    @JsonKey(name: 'updated_at') @Default(0) int updatedAt,
    @JsonKey(name: 'last_played_at') int? lastPlayedAt,
    @JsonKey(name: 'updated_by_device') @Default('') String updatedByDevice,
    @JsonKey(name: 'title_edited') @Default(false) bool titleEditedByUser,
    @JsonKey(name: 'author_edited') @Default(false) bool authorEditedByUser,
    @JsonKey(name: 'order_edited') @Default(false) bool orderEditedByUser,

    /// v2 新增。旧版本 App 合并后重新上传时会把它丢掉，所以它只用于
    /// 「新拉回来的合集」；本地已有的合集以本地类型为准（见 LibrarySync）。
    @JsonKey(unknownEnumValue: SeriesKind.audiobook)
    @Default(SeriesKind.audiobook)
    SeriesKind kind,
  }) = _BookRecord;

  const BookRecord._();

  factory BookRecord.fromJson(Map<String, dynamic> json) =>
      _$BookRecordFromJson(json);

  /// 收听位置的可比大小：先比章节，再比章内位置。
  /// 用它来判断"谁听得更靠后"，避免时钟偏移导致进度回退。
  bool isAheadOf(BookRecord other) {
    if (currentChapterIndex != other.currentChapterIndex) {
      return currentChapterIndex > other.currentChapterIndex;
    }
    return currentPositionMs > other.currentPositionMs;
  }
}

@freezed
abstract class LibrarySnapshot with _$LibrarySnapshot {
  const factory LibrarySnapshot({
    @Default(LibrarySnapshot.currentVersion) int version,
    @Default(<BookRecord>[]) List<BookRecord> books,
  }) = _LibrarySnapshot;

  factory LibrarySnapshot.fromJson(Map<String, dynamic> json) =>
      _$LibrarySnapshotFromJson(json);

  /// v2：记录增加 kind。读 v1 照常（kind 缺省为有声书）。
  static const int currentVersion = 2;
}

/// 记录粒度合并本地与远端快照。纯函数，便于测试。
LibrarySnapshot mergeSnapshots(LibrarySnapshot local, LibrarySnapshot remote) {
  final merged = <String, BookRecord>{
    for (final b in local.books) b.id: b,
  };

  for (final r in remote.books) {
    final l = merged[r.id];
    if (l == null) {
      // 只在远端存在：直接采纳（另一台设备新增的书）
      merged[r.id] = r;
      continue;
    }
    merged[r.id] = _mergeRecord(l, r);
  }

  return LibrarySnapshot(
    books: merged.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt)),
  );
}

BookRecord _mergeRecord(BookRecord a, BookRecord b) {
  // 删除与更新冲突：以较晚的时间戳为准（规格「删除与更新冲突」）
  if (a.deleted != b.deleted) {
    return a.updatedAt >= b.updatedAt ? a : b;
  }

  // 基础字段按 LWW 取胜者
  final winner = a.updatedAt >= b.updatedAt ? a : b;
  final loser = identical(winner, a) ? b : a;

  // 进度是例外：取"听得更靠后"的那一份，防止时钟偏移造成进度回退
  // （规格「同一本书的进度冲突」）
  final ahead = loser.isAheadOf(winner) ? loser : winner;

  return winner.copyWith(
    currentChapterIndex: ahead.currentChapterIndex,
    currentPositionMs: ahead.currentPositionMs,
    finished:
        winner.finished || loser.finished ? ahead.finished : winner.finished,
    lastPlayedAt: [
      winner.lastPlayedAt ?? 0,
      loser.lastPlayedAt ?? 0,
    ].reduce((x, y) => x > y ? x : y),
  );
}
