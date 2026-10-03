import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

import 'package:yun_audiobook/core/config.dart';
import 'package:yun_audiobook/data/local/history_dao.dart';
import 'package:yun_audiobook/data/local/series_dao.dart';
import 'package:yun_audiobook/data/local/settings_dao.dart';

part 'database.g.dart';

/// 本地 SQLite 是书架与进度的权威读写来源；网盘只是同步载体（design.md D5）。
///
/// 表名与列名沿用 v2（sqflite 时代）的写法，一个字都不改：drift 直接打开
/// 老用户手机上那个库文件，按 `PRAGMA user_version` 走增量迁移。
/// 所以下面表类的 getter 名就是老列名的驼峰形式（chapterCount → chapter_count），
/// 领域层的改名（Book → Series）只发生在 DAO 的映射里。
///
/// 时间列一律是毫秒整数：drift 的 DateTimeColumn 默认存秒，与老数据不兼容。
@DataClassName('BookRow')
class Books extends Table {
  TextColumn get id => text()();
  TextColumn get folderPath => text().unique()();
  TextColumn get title => text()();
  TextColumn get author => text().nullable()();
  TextColumn get coverFsId => text().nullable()();
  TextColumn get coverLocalPath => text().nullable()();
  IntColumn get chapterCount => integer().withDefault(const Constant(0))();
  IntColumn get currentChapterIndex =>
      integer().withDefault(const Constant(0))();
  IntColumn get currentPositionMs =>
      integer().withDefault(const Constant(0))();
  BoolColumn get finished => boolean().withDefault(const Constant(false))();
  BoolColumn get sourceMissing =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get titleEdited => boolean().withDefault(const Constant(false))();
  BoolColumn get authorEdited =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get orderEdited => boolean().withDefault(const Constant(false))();
  IntColumn get addedAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get lastPlayedAt => integer().nullable()();
  TextColumn get updatedByDevice => text().withDefault(const Constant(''))();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();

  /// v3：合集类型（SeriesKind.name）。老数据全部是有声书。
  TextColumn get kind => text().withDefault(const Constant('audiobook'))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('ChapterRow')
@TableIndex(name: 'idx_chapters_book', columns: {#bookId, #orderIndex})
class Chapters extends Table {
  TextColumn get id => text()();
  TextColumn get bookId =>
      text().references(Books, #id, onDelete: KeyAction.cascade)();
  TextColumn get fsId => text()();
  TextColumn get path => text()();
  TextColumn get title => text()();
  TextColumn get fileName => text()();
  IntColumn get size => integer()();
  IntColumn get orderIndex => integer()();
  IntColumn get trackNumber => integer().nullable()();
  IntColumn get durationMs => integer().nullable()();

  /// CacheState.index
  IntColumn get cacheState => integer().withDefault(const Constant(0))();
  TextColumn get localPath => text().nullable()();
  IntColumn get downloadedBytes => integer().withDefault(const Constant(0))();

  /// v3：媒体类型（MediaKind.name）。老数据全部是音频。
  TextColumn get mediaKind => text().withDefault(const Constant('audio'))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// 本地键值存储。表名带 sync 是历史原因——最早只存同步时间，
/// 后来离线配额、更新提示也放这里；为几个标量单开表不划算。
class SyncMeta extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

/// 播放历史（v2 新增）。
///
/// 两个刻意的设计：
///
/// 1. **不对 books 建外键。** 历史是「这台设备上听过什么」的日志，
///    移出书架、甚至把书彻底删掉，都不该让听过的记录消失。加了级联
///    反而会在删书时静默清空历史——那种坑这个库里已经踩过一次了。
/// 2. **书名与章节名在播放当时快照下来。** 不靠 JOIN 现取：
///    `replaceEpisodes` 会把章节行整批删掉重建，章节 id 是按序号生成的
///    （`book-xxx-chN`），刷新后同一个 id 可能已经指向另一章；
///    书名也可能被用户改掉。历史要记的是「当时听的是什么」。
@DataClassName('HistoryRow')
@TableIndex.sql(
    'CREATE INDEX idx_history_last_at ON play_history(last_at DESC)',)
class PlayHistory extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get bookId => text()();
  TextColumn get chapterId => text()();
  IntColumn get chapterIndex => integer()();
  TextColumn get bookTitle => text()();
  TextColumn get chapterTitle => text()();
  TextColumn get coverFsId => text().nullable()();
  IntColumn get startedAt => integer()();
  IntColumn get lastAt => integer()();
  IntColumn get lastPositionMs => integer().withDefault(const Constant(0))();
  IntColumn get listenedMs => integer().withDefault(const Constant(0))();
  BoolColumn get finished => boolean().withDefault(const Constant(false))();
}

@DriftDatabase(
  tables: [Books, Chapters, SyncMeta, PlayHistory],
  daos: [SeriesDao, HistoryDao, SettingsDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  /// 生产入口。演示模式单独一个库：演示版升级到正式版时，
  /// 假网盘里的书不会混进真书架。
  factory AppDatabase.open() => AppDatabase(_openFile());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          // v1 -> v2：加播放历史表。老库里已有的书与进度一行不动。
          if (from < 2) {
            await m.createTable(playHistory);
            await m.createIndex(idxHistoryLastAt);
          }
          // v2 -> v3：媒体类型。默认值让老数据整体落成「有声书 / 音频」。
          if (from < 3) {
            await m.addColumn(books, books.kind);
            await m.addColumn(chapters, chapters.mediaKind);
          }
        },
        // 级联删除（删书连带删章节）依赖它；SQLite 默认是关的，每次连接都要开。
        beforeOpen: (_) => customStatement('PRAGMA foreign_keys = ON'),
      );

  static QueryExecutor _openFile() => LazyDatabase(() async {
        final dir = await getApplicationDocumentsDirectory();
        const name =
            AppConfig.demoMode ? 'yun_audiobook_demo.db' : 'yun_audiobook.db';
        // Android 上 sqlite 默认的临时目录 /tmp 不可写
        sqlite3.tempDirectory = (await getTemporaryDirectory()).path;
        return NativeDatabase.createInBackground(File(p.join(dir.path, name)));
      });
}
