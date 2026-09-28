/// 领域模型。
///
/// 「文件夹即书」（design.md D4）：一本书就是用户认领的一个网盘目录，
/// 目录里的音频文件按自然序成为章节。
library;

enum ChapterCacheState { none, queued, downloading, cached, failed }

class Chapter {
  const Chapter({
    required this.id,
    required this.bookId,
    required this.fsId,
    required this.path,
    required this.title,
    required this.fileName,
    required this.size,
    required this.orderIndex,
    this.trackNumber,
    this.durationMs,
    this.cacheState = ChapterCacheState.none,
    this.localPath,
    this.downloadedBytes = 0,
  });

  final String id;
  final String bookId;
  final String fsId;
  final String path;
  final String title;
  final String fileName;
  final int size;

  /// 最终展示顺序。用户手动拖动后这里会被改写并持久化。
  final int orderIndex;

  /// 音频标签里的 track 号，排序时优先于文件名（library-catalog 规格）。
  final int? trackNumber;
  final int? durationMs;

  final ChapterCacheState cacheState;
  final String? localPath;
  final int downloadedBytes;

  bool get isCached => cacheState == ChapterCacheState.cached && localPath != null;

  Chapter copyWith({
    String? title,
    int? orderIndex,
    int? trackNumber,
    int? durationMs,
    ChapterCacheState? cacheState,
    String? localPath,
    int? downloadedBytes,
    bool clearLocalPath = false,
  }) =>
      Chapter(
        id: id,
        bookId: bookId,
        fsId: fsId,
        path: path,
        title: title ?? this.title,
        fileName: fileName,
        size: size,
        orderIndex: orderIndex ?? this.orderIndex,
        trackNumber: trackNumber ?? this.trackNumber,
        durationMs: durationMs ?? this.durationMs,
        cacheState: cacheState ?? this.cacheState,
        localPath: clearLocalPath ? null : (localPath ?? this.localPath),
        downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      );
}

class Book {
  const Book({
    required this.id,
    required this.folderPath,
    required this.title,
    this.author,
    this.coverFsId,
    this.coverLocalPath,
    this.chapterCount = 0,
    this.currentChapterIndex = 0,
    this.currentPositionMs = 0,
    this.finished = false,
    this.sourceMissing = false,
    this.titleEditedByUser = false,
    this.authorEditedByUser = false,
    this.orderEditedByUser = false,
    required this.addedAt,
    required this.updatedAt,
    this.lastPlayedAt,
    this.updatedByDevice = '',
  });

  final String id;

  /// 网盘中的目录路径。这是书的身份，用于去重认领。
  final String folderPath;

  final String title;
  final String? author;
  final String? coverFsId;
  final String? coverLocalPath;
  final int chapterCount;

  final int currentChapterIndex;
  final int currentPositionMs;
  final bool finished;

  /// 网盘路径消失时置位。条目与进度都保留（library-catalog 规格）。
  final bool sourceMissing;

  /// 用户手动编辑过的字段不允许被自动识别结果覆盖。
  final bool titleEditedByUser;
  final bool authorEditedByUser;
  final bool orderEditedByUser;

  final DateTime addedAt;
  final DateTime updatedAt;
  final DateTime? lastPlayedAt;

  /// 同步时的 LWW 合并依据（listening-progress 规格）。
  final String updatedByDevice;

  Book copyWith({
    String? title,
    String? author,
    String? coverFsId,
    String? coverLocalPath,
    int? chapterCount,
    int? currentChapterIndex,
    int? currentPositionMs,
    bool? finished,
    bool? sourceMissing,
    bool? titleEditedByUser,
    bool? authorEditedByUser,
    bool? orderEditedByUser,
    DateTime? updatedAt,
    DateTime? lastPlayedAt,
    String? updatedByDevice,
  }) =>
      Book(
        id: id,
        folderPath: folderPath,
        title: title ?? this.title,
        author: author ?? this.author,
        coverFsId: coverFsId ?? this.coverFsId,
        coverLocalPath: coverLocalPath ?? this.coverLocalPath,
        chapterCount: chapterCount ?? this.chapterCount,
        currentChapterIndex: currentChapterIndex ?? this.currentChapterIndex,
        currentPositionMs: currentPositionMs ?? this.currentPositionMs,
        finished: finished ?? this.finished,
        sourceMissing: sourceMissing ?? this.sourceMissing,
        titleEditedByUser: titleEditedByUser ?? this.titleEditedByUser,
        authorEditedByUser: authorEditedByUser ?? this.authorEditedByUser,
        orderEditedByUser: orderEditedByUser ?? this.orderEditedByUser,
        addedAt: addedAt,
        updatedAt: updatedAt ?? this.updatedAt,
        lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
        updatedByDevice: updatedByDevice ?? this.updatedByDevice,
      );
}

/// 音频标签解析结果。全部字段都是尽力而为，缺失是常态。
class AudioTags {
  const AudioTags({this.title, this.album, this.artist, this.track});

  final String? title;
  final String? album;
  final String? artist;
  final int? track;

  bool get isEmpty =>
      title == null && album == null && artist == null && track == null;

  static const empty = AudioTags();
}

/// 播放历史里的一条（play-history）。
///
/// 书名与章节名是**播放当时的快照**，不是现取的——刷新章节会把 chapters
/// 整批重建、书名也可能被改，历史该记的是「当时听的是什么」。
class PlayHistoryEntry {
  const PlayHistoryEntry({
    required this.id,
    required this.bookId,
    required this.chapterId,
    required this.chapterIndex,
    required this.bookTitle,
    required this.chapterTitle,
    this.coverFsId,
    required this.startedAt,
    required this.lastAt,
    required this.lastPositionMs,
    required this.listenedMs,
    required this.finished,
  });

  final int id;
  final String bookId;
  final String chapterId;

  /// 认领时的章节序号。用它跳回去续播；书被刷新过就可能对不上，
  /// 所以跳转前要校验范围。
  final int chapterIndex;

  final String bookTitle;
  final String chapterTitle;
  final String? coverFsId;

  final DateTime startedAt;
  final DateTime lastAt;

  /// 最后一次上报的播放位置，用于跳回去接着听，也用于累计时长时算增量。
  final int lastPositionMs;

  /// 累计实际收听时长。只累加「像是在正常播放」的增量，
  /// 拖动进度条跳过去的部分不算（见 HistoryDao）。
  final int listenedMs;

  final bool finished;
}
