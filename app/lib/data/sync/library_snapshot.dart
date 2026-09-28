/// 同步载体的数据结构与合并规则（listening-progress 规格）。
///
/// 合并是**记录粒度**的 LWW，不是整文件覆盖——否则「手机上听到第 5 章、
/// 平板上加了一本新书」会互相抹掉。进度字段还有一条额外规则：取更靠后的
/// 收听位置，而不是单纯的较晚时间戳，因为进度回退是用户最反感的表现。
library;

class BookRecord {
  const BookRecord({
    required this.id,
    required this.folderPath,
    required this.title,
    this.author,
    this.coverFsId,
    required this.currentChapterIndex,
    required this.currentPositionMs,
    required this.finished,
    required this.deleted,
    required this.addedAt,
    required this.updatedAt,
    this.lastPlayedAt,
    required this.updatedByDevice,
    this.titleEditedByUser = false,
    this.authorEditedByUser = false,
    this.orderEditedByUser = false,
  });

  final String id;
  final String folderPath;
  final String title;
  final String? author;
  final String? coverFsId;
  final int currentChapterIndex;
  final int currentPositionMs;
  final bool finished;
  final bool deleted;
  final int addedAt;
  final int updatedAt;
  final int? lastPlayedAt;
  final String updatedByDevice;
  final bool titleEditedByUser;
  final bool authorEditedByUser;
  final bool orderEditedByUser;

  /// 收听位置的可比大小：先比章节，再比章内位置。
  /// 用它来判断"谁听得更靠后"，避免时钟偏移导致进度回退。
  bool isAheadOf(BookRecord other) {
    if (currentChapterIndex != other.currentChapterIndex) {
      return currentChapterIndex > other.currentChapterIndex;
    }
    return currentPositionMs > other.currentPositionMs;
  }

  BookRecord copyWith({
    int? currentChapterIndex,
    int? currentPositionMs,
    bool? finished,
    int? lastPlayedAt,
  }) =>
      BookRecord(
        id: id,
        folderPath: folderPath,
        title: title,
        author: author,
        coverFsId: coverFsId,
        currentChapterIndex: currentChapterIndex ?? this.currentChapterIndex,
        currentPositionMs: currentPositionMs ?? this.currentPositionMs,
        finished: finished ?? this.finished,
        deleted: deleted,
        addedAt: addedAt,
        updatedAt: updatedAt,
        lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
        updatedByDevice: updatedByDevice,
        titleEditedByUser: titleEditedByUser,
        authorEditedByUser: authorEditedByUser,
        orderEditedByUser: orderEditedByUser,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'folder_path': folderPath,
        'title': title,
        'author': author,
        'cover_fs_id': coverFsId,
        'current_chapter_index': currentChapterIndex,
        'current_position_ms': currentPositionMs,
        'finished': finished,
        'deleted': deleted,
        'added_at': addedAt,
        'updated_at': updatedAt,
        'last_played_at': lastPlayedAt,
        'updated_by_device': updatedByDevice,
        'title_edited': titleEditedByUser,
        'author_edited': authorEditedByUser,
        'order_edited': orderEditedByUser,
      };

  static BookRecord fromJson(Map<String, dynamic> j) => BookRecord(
        id: j['id'] as String,
        folderPath: j['folder_path'] as String,
        title: j['title'] as String,
        author: j['author'] as String?,
        coverFsId: j['cover_fs_id'] as String?,
        currentChapterIndex: (j['current_chapter_index'] as num?)?.toInt() ?? 0,
        currentPositionMs: (j['current_position_ms'] as num?)?.toInt() ?? 0,
        finished: j['finished'] as bool? ?? false,
        deleted: j['deleted'] as bool? ?? false,
        addedAt: (j['added_at'] as num?)?.toInt() ?? 0,
        updatedAt: (j['updated_at'] as num?)?.toInt() ?? 0,
        lastPlayedAt: (j['last_played_at'] as num?)?.toInt(),
        updatedByDevice: j['updated_by_device'] as String? ?? '',
        titleEditedByUser: j['title_edited'] as bool? ?? false,
        authorEditedByUser: j['author_edited'] as bool? ?? false,
        orderEditedByUser: j['order_edited'] as bool? ?? false,
      );
}

class LibrarySnapshot {
  const LibrarySnapshot({required this.version, required this.books});

  static const int currentVersion = 1;

  final int version;
  final List<BookRecord> books;

  Map<String, dynamic> toJson() => {
        'version': version,
        'books': books.map((b) => b.toJson()).toList(),
      };

  static LibrarySnapshot fromJson(Map<String, dynamic> j) => LibrarySnapshot(
        version: (j['version'] as num?)?.toInt() ?? currentVersion,
        books: ((j['books'] as List?) ?? const [])
            .map((e) => BookRecord.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
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
    version: LibrarySnapshot.currentVersion,
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
    finished: winner.finished || loser.finished ? ahead.finished : winner.finished,
    lastPlayedAt: [
      winner.lastPlayedAt ?? 0,
      loser.lastPlayedAt ?? 0,
    ].reduce((x, y) => x > y ? x : y),
  );
}
