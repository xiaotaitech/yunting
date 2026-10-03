import 'package:drift/drift.dart';
import 'package:yun_audiobook/data/local/database.dart';
import 'package:yun_audiobook/domain/entities.dart';

part 'series_dao.g.dart';

/// 书架（合集）与条目的读写。所有时间戳以毫秒整数存储，便于 LWW 比较。
@DriftAccessor(tables: [Books, Chapters])
class SeriesDao extends DatabaseAccessor<AppDatabase> with _$SeriesDaoMixin {
  SeriesDao(super.attachedDatabase);

  // ------------------------------------------------------------ 合集

  SimpleSelectStatement<$BooksTable, BookRow> _shelfQuery() =>
      select(books)
        ..where((b) => b.deleted.equals(false))
        ..orderBy([
          (b) => OrderingTerm.desc(
                coalesce([b.lastPlayedAt, b.addedAt]),
              ),
        ]);

  Future<List<Series>> shelf() async =>
      (await _shelfQuery().get()).map(_toSeries).toList();

  /// 书架列表，库变了就推新值——界面不再需要手动 invalidate。
  Stream<List<Series>> watchShelf() =>
      _shelfQuery().watch().map((rows) => rows.map(_toSeries).toList());

  Future<Series?> seriesById(String id) async {
    final row = await (select(books)..where((b) => b.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _toSeries(row);
  }

  Stream<Series?> watchSeries(String id) =>
      (select(books)..where((b) => b.id.equals(id)))
          .watchSingleOrNull()
          .map((r) => r == null ? null : _toSeries(r));

  /// 书架上（未删除）的那本。原来不过滤软删除：移出书架的书再去认领，
  /// 会被当成"已在书架中"直接返回，书架上却看不到，那个文件夹就再也加不回来。
  Future<Series?> seriesByFolder(String folderPath) async {
    final row = await (select(books)
          ..where(
            (b) => b.folderPath.equals(folderPath) & b.deleted.equals(false),
          ))
        .getSingleOrNull();
    return row == null ? null : _toSeries(row);
  }

  /// 这个文件夹曾经用过的 id（含已删除的）。重新认领时沿用它：
  /// folder_path 有唯一约束，老版本按时间戳生成的 id 与路径派生的对不上，
  /// 另起一个 id 插入会撞约束。
  Future<String?> idByFolderIncludingDeleted(String folderPath) async {
    final row = await (select(books)
          ..where((b) => b.folderPath.equals(folderPath)))
        .getSingleOrNull();
    return row?.id;
  }

  /// 更新或插入一个合集。**绝不能用 INSERT OR REPLACE。**
  ///
  /// SQLite 的 REPLACE 是「先 DELETE 旧行再 INSERT」，而 chapters 对 books 有
  /// `ON DELETE CASCADE`——于是每次更新书籍元数据都会把该书的章节全部删光，
  /// 连 chapters 里存的离线缓存账（cache_state / local_path / downloaded_bytes）
  /// 一起没，磁盘上下载好的文件变成孤儿。
  ///
  /// 三个调用方都在踩：改名改作者、标记网盘路径丢失、保存手动排序（刚排好就被删）。
  /// 实测：真机上把书改个名，34 章立刻变 0 章。
  ///
  /// 所以是「先 UPDATE，没命中再 INSERT」，全程不删行。
  /// drift 的 `insertOnConflictUpdate` 生成的是 `ON CONFLICT DO UPDATE`，
  /// 不删行，本可以用；但这里显式写出来，让这条约束一眼可见。
  Future<void> upsertSeries(Series series) => transaction(() async {
        final values = _fromSeries(series);
        final updated = await (update(books)
              ..where((b) => b.id.equals(series.id)))
            .write(values);
        if (updated == 0) await into(books).insert(values);
      });

  /// 软删除。同步合并需要知道「这本书被删过」，硬删会让删除操作丢失。
  Future<void> markDeleted(String id, String deviceId) =>
      (update(books)..where((b) => b.id.equals(id))).write(
        BooksCompanion(
          deleted: const Value(true),
          updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
          updatedByDevice: Value(deviceId),
        ),
      );

  Future<void> purge(String id) =>
      (delete(books)..where((b) => b.id.equals(id))).go();

  Future<void> updateProgress({
    required String seriesId,
    required int episodeIndex,
    required int positionMs,
    required String deviceId,
    bool? finished,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return (update(books)..where((b) => b.id.equals(seriesId))).write(
      BooksCompanion(
        currentChapterIndex: Value(episodeIndex),
        currentPositionMs: Value(positionMs),
        updatedAt: Value(now),
        lastPlayedAt: Value(now),
        updatedByDevice: Value(deviceId),
        finished: finished == null ? const Value.absent() : Value(finished),
      ),
    );
  }

  // ------------------------------------------------------------ 条目

  SimpleSelectStatement<$ChaptersTable, ChapterRow> _episodesQuery(
    String seriesId,
  ) =>
      select(chapters)
        ..where((c) => c.bookId.equals(seriesId))
        ..orderBy([(c) => OrderingTerm.asc(c.orderIndex)]);

  Future<List<Episode>> episodesOf(String seriesId) async =>
      (await _episodesQuery(seriesId).get()).map(_toEpisode).toList();

  Stream<List<Episode>> watchEpisodes(String seriesId) => _episodesQuery(
        seriesId,
      ).watch().map((rows) => rows.map(_toEpisode).toList());

  Future<void> replaceEpisodes(String seriesId, List<Episode> episodes) =>
      transaction(() async {
        // 保留已有的缓存状态，刷新章节列表不该让已下载的文件"消失"。
        final existing = await (select(chapters)
              ..where((c) => c.bookId.equals(seriesId)))
            .get();
        final cacheByFsId = {for (final r in existing) r.fsId: r};

        await (delete(chapters)..where((c) => c.bookId.equals(seriesId))).go();
        for (final e in episodes) {
          final kept = cacheByFsId[e.fsId];
          await into(chapters).insert(
            _fromEpisode(e).copyWith(
              cacheState: kept == null ? null : Value(kept.cacheState),
              localPath: kept == null ? null : Value(kept.localPath),
              downloadedBytes:
                  kept == null ? null : Value(kept.downloadedBytes),
            ),
          );
        }
        await (update(books)..where((b) => b.id.equals(seriesId))).write(
          BooksCompanion(chapterCount: Value(episodes.length)),
        );
      });

  /// 记下某条目的真实时长。
  ///
  /// `duration_ms` 这一列建库时就有，但 ID3 解析只取标题/作者/专辑/track，
  /// 时长要等播放器真正加载后才知道。缺了它系统媒体通知画不出进度条
  /// （MediaItem.duration 为 null 时 Android 不渲染 seekbar，两端都显示 00:00）。
  Future<void> setDuration(String episodeId, int durationMs) =>
      (update(chapters)..where((c) => c.id.equals(episodeId)))
          .write(ChaptersCompanion(durationMs: Value(durationMs)));

  Future<void> updateEpisode(Episode episode) =>
      (update(chapters)..where((c) => c.id.equals(episode.id)))
          .write(_fromEpisode(episode));

  Future<void> updateOrder(List<Episode> ordered) => transaction(() async {
        for (var i = 0; i < ordered.length; i++) {
          await (update(chapters)..where((c) => c.id.equals(ordered[i].id)))
              .write(ChaptersCompanion(orderIndex: Value(i)));
        }
      });

  Future<void> setCache(
    String episodeId, {
    required CacheState state,
    String? localPath,
    int? downloadedBytes,
  }) =>
      (update(chapters)..where((c) => c.id.equals(episodeId))).write(
        ChaptersCompanion(
          cacheState: Value(state.index),
          localPath: Value(localPath),
          downloadedBytes: downloadedBytes == null
              ? const Value.absent()
              : Value(downloadedBytes),
        ),
      );

  Future<List<Episode>> cachedEpisodes() async => (await (select(chapters)
            ..where((c) => c.cacheState.equals(CacheState.cached.index)))
          .get())
      .map(_toEpisode)
      .toList();

  /// 各合集的缓存占用，供「离线管理」页展示。
  Stream<Map<String, int>> watchCacheUsage() {
    final used = chapters.downloadedBytes.sum();
    final query = selectOnly(chapters)
      ..addColumns([chapters.bookId, used])
      ..where(chapters.cacheState.equals(CacheState.cached.index))
      ..groupBy([chapters.bookId]);
    return query.watch().map(
          (rows) => {
            for (final r in rows) r.read(chapters.bookId)!: r.read(used) ?? 0,
          },
        );
  }

  Future<Map<String, int>> cacheUsage() => watchCacheUsage().first;

  // ------------------------------------------------------------ 映射

  static Series _toSeries(BookRow r) => Series(
        id: r.id,
        folderPath: r.folderPath,
        title: r.title,
        kind: SeriesKind.parse(r.kind),
        author: r.author,
        coverFsId: r.coverFsId,
        coverLocalPath: r.coverLocalPath,
        episodeCount: r.chapterCount,
        currentEpisodeIndex: r.currentChapterIndex,
        currentPositionMs: r.currentPositionMs,
        finished: r.finished,
        sourceMissing: r.sourceMissing,
        titleEditedByUser: r.titleEdited,
        authorEditedByUser: r.authorEdited,
        orderEditedByUser: r.orderEdited,
        addedAt: DateTime.fromMillisecondsSinceEpoch(r.addedAt),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(r.updatedAt),
        lastPlayedAt: r.lastPlayedAt == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(r.lastPlayedAt!),
        updatedByDevice: r.updatedByDevice,
      );

  static BooksCompanion _fromSeries(Series s) => BooksCompanion.insert(
        id: s.id,
        folderPath: s.folderPath,
        title: s.title,
        kind: Value(s.kind.name),
        author: Value(s.author),
        coverFsId: Value(s.coverFsId),
        coverLocalPath: Value(s.coverLocalPath),
        chapterCount: Value(s.episodeCount),
        currentChapterIndex: Value(s.currentEpisodeIndex),
        currentPositionMs: Value(s.currentPositionMs),
        finished: Value(s.finished),
        sourceMissing: Value(s.sourceMissing),
        titleEdited: Value(s.titleEditedByUser),
        authorEdited: Value(s.authorEditedByUser),
        orderEdited: Value(s.orderEditedByUser),
        addedAt: s.addedAt.millisecondsSinceEpoch,
        updatedAt: s.updatedAt.millisecondsSinceEpoch,
        lastPlayedAt: Value(s.lastPlayedAt?.millisecondsSinceEpoch),
        updatedByDevice: Value(s.updatedByDevice),
        deleted: const Value(false),
      );

  static Episode _toEpisode(ChapterRow r) => Episode(
        id: r.id,
        seriesId: r.bookId,
        fsId: r.fsId,
        path: r.path,
        title: r.title,
        fileName: r.fileName,
        size: r.size,
        orderIndex: r.orderIndex,
        mediaKind: MediaKind.parse(r.mediaKind),
        trackNumber: r.trackNumber,
        durationMs: r.durationMs,
        cacheState: CacheState.values[r.cacheState],
        localPath: r.localPath,
        downloadedBytes: r.downloadedBytes,
      );

  static ChaptersCompanion _fromEpisode(Episode e) => ChaptersCompanion.insert(
        id: e.id,
        bookId: e.seriesId,
        fsId: e.fsId,
        path: e.path,
        title: e.title,
        fileName: e.fileName,
        size: e.size,
        orderIndex: e.orderIndex,
        mediaKind: Value(e.mediaKind.name),
        trackNumber: Value(e.trackNumber),
        durationMs: Value(e.durationMs),
        cacheState: Value(e.cacheState.index),
        localPath: Value(e.localPath),
        downloadedBytes: Value(e.downloadedBytes),
      );
}
