import 'dart:convert';

import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yun_audiobook/core/config.dart';
import 'package:yun_audiobook/data/drive/cloud_drive_source.dart';
import 'package:yun_audiobook/data/local/database.dart';
import 'package:yun_audiobook/data/sync/library_snapshot.dart';
import 'package:yun_audiobook/data/sync/library_sync.dart';
import 'package:yun_audiobook/domain/entities.dart';

/// 网盘上只有一份同步文件的假数据源。
class FakeDrive implements CloudDriveSource {
  String? stateFile;

  @override
  String get id => 'fake';

  @override
  Future<String?> readAppStateFile(String path) async => stateFile;

  @override
  Future<void> writeAppStateFile(String path, String content) async =>
      stateFile = content;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// 同步写库这一段以前没有测试覆盖，结果漏掉一个会丢数据的 bug：
/// 用 `INSERT OR REPLACE` 更新 books 行时，SQLite 会先 DELETE 再 INSERT，
/// chapters 表的 `ON DELETE CASCADE` 于是把该书的章节全部删光——
/// 每同步一次章节就没一次。这组用例跑真实 SQLite + 真实 LibrarySync，
/// 把这个行为钉死。
void main() {
  late AppDatabase db;
  late FakeDrive drive;
  late LibrarySync sync;

  Series series({
    String id = 'book-1',
    String folder = '/books/x',
    String title = '三体',
    int updatedAt = 100,
    int episodeIndex = 0,
    int positionMs = 0,
    SeriesKind kind = SeriesKind.audiobook,
  }) =>
      Series(
        id: id,
        folderPath: folder,
        title: title,
        kind: kind,
        currentEpisodeIndex: episodeIndex,
        currentPositionMs: positionMs,
        addedAt: DateTime.fromMillisecondsSinceEpoch(0),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(updatedAt),
        lastPlayedAt: DateTime.fromMillisecondsSinceEpoch(updatedAt),
        updatedByDevice: 'a',
      );

  Future<void> seedSeriesWithEpisodes({
    SeriesKind kind = SeriesKind.audiobook,
    int episodeIndex = 0,
    int positionMs = 0,
  }) async {
    await db.seriesDao.upsertSeries(
      series(kind: kind, episodeIndex: episodeIndex, positionMs: positionMs),
    );
    await db.seriesDao.replaceEpisodes('book-1', [
      for (var i = 0; i < 5; i++)
        Episode(
          id: 'ch-$i',
          seriesId: 'book-1',
          fsId: 'fs-$i',
          path: '/books/x/$i.mp3',
          title: '第 $i 章',
          fileName: '$i.mp3',
          size: 100,
          orderIndex: i,
        ),
    ]);
  }

  /// 把一份快照放到「网盘」上，等同于另一台设备已经同步过。
  void putRemote(List<BookRecord> records) =>
      drive.stateFile = jsonEncode(LibrarySnapshot(books: records).toJson());

  BookRecord remoteRecord({
    String id = 'book-1',
    String folder = '/books/x',
    String title = '三体',
    int updatedAt = 999,
    int chapter = 0,
    int position = 0,
    SeriesKind kind = SeriesKind.audiobook,
  }) =>
      BookRecord(
        id: id,
        folderPath: folder,
        title: title,
        currentChapterIndex: chapter,
        currentPositionMs: position,
        updatedAt: updatedAt,
        updatedByDevice: 'b',
        kind: kind,
      );

  Future<int> episodeCountInTable() async {
    final rows =
        await db.customSelect('SELECT COUNT(*) AS n FROM chapters').get();
    return rows.single.read<int>('n');
  }

  setUp(() {
    db = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    drive = FakeDrive();
    sync = LibrarySync(drive: drive, db: db);
  });

  tearDown(() async {
    sync.dispose();
    await db.close();
  });

  test('前提：级联外键确实是打开的', () async {
    await seedSeriesWithEpisodes();
    expect(await episodeCountInTable(), 5);
    await db.seriesDao.purge('book-1');
    expect(await episodeCountInTable(), 0, reason: '删书应当级联删章节');
  });

  test('INSERT OR REPLACE 会连带删掉章节——这正是当初的 bug', () async {
    await seedSeriesWithEpisodes();
    await db.customStatement(
      'INSERT OR REPLACE INTO books (id, folder_path, title, chapter_count, '
      'current_chapter_index, current_position_ms, added_at, updated_at) '
      "VALUES ('book-1', '/books/x', '三体', 0, 2, 0, 0, 200)",
    );

    expect(
      await episodeCountInTable(),
      0,
      reason: 'REPLACE 先删后插，章节被级联删除——所以同步不能用它',
    );
  });

  test('同步写回用 UPDATE：章节完好，进度也更新了', () async {
    await seedSeriesWithEpisodes();
    putRemote([remoteRecord(chapter: 2)]);

    expect(await sync.syncNow(), isTrue);

    expect(await episodeCountInTable(), 5, reason: '章节必须原样保留');
    final s = (await db.seriesDao.seriesById('book-1'))!;
    expect(s.currentEpisodeIndex, 2);
  });

  test('远端新增的书走 INSERT，不影响已有书的章节', () async {
    await seedSeriesWithEpisodes();
    putRemote([
      remoteRecord(updatedAt: 100),
      remoteRecord(id: 'book-2', folder: '/books/y', title: '小王子'),
    ]);

    await sync.syncNow();

    expect(await episodeCountInTable(), 5, reason: '新增另一本书不该动到已有章节');
    expect(await db.seriesDao.shelf(), hasLength(2));
    expect((await db.seriesDao.seriesById('book-2'))!.title, '小王子');
  });

  test('episode_count 校准：同步后等于真实章节数', () async {
    await seedSeriesWithEpisodes();
    await db.customStatement('UPDATE books SET chapter_count = 0');
    putRemote([remoteRecord()]);

    await sync.syncNow();

    expect((await db.seriesDao.seriesById('book-1'))!.episodeCount, 5);
  });

  test('合并结果写回后，进度取的是更靠后的那一份', () async {
    // 端到端串一遍：本地进度靠后，远端时间戳更新
    await seedSeriesWithEpisodes(episodeIndex: 4, positionMs: 9000);
    putRemote([remoteRecord(chapter: 1, position: 100)]);

    await sync.syncNow();

    final s = (await db.seriesDao.seriesById('book-1'))!;
    expect(s.currentEpisodeIndex, 4, reason: '不能让进度回退');
    expect(s.currentPositionMs, 9000);
    expect(await episodeCountInTable(), 5);
  });

  test('同步成功后记下最近同步时间', () async {
    expect(await sync.watchLastSyncAt().first, isNull);

    await sync.syncNow();

    expect(await sync.watchLastSyncAt().first, isNotNull);
    expect(AppConfig.syncFilePath, isNotEmpty);
    expect(drive.stateFile, isNotNull, reason: '合并结果要上传回网盘');
  });

  group('合集类型 kind', () {
    test('本地是 course，远端记录没有 kind（旧版 App 上传）→ 同步后仍是 course', () async {
      await seedSeriesWithEpisodes(kind: SeriesKind.course);
      // 旧版本 App 合并后重新上传，会把 kind 丢掉；而且它的时间戳更新
      drive.stateFile = jsonEncode({
        'books': [
          {
            'id': 'book-1',
            'folder_path': '/books/x',
            'title': '三体',
            'updated_at': 999,
            'updated_by_device': 'b',
          },
        ],
      });

      await sync.syncNow();

      final s = (await db.seriesDao.seriesById('book-1'))!;
      expect(s.kind, SeriesKind.course, reason: '已有合集的类型以本地为准');
      expect(
        s.updatedAt,
        DateTime.fromMillisecondsSinceEpoch(999),
        reason: '其它同步字段照常采纳远端',
      );
    });

    test('远端新增的合集采纳远端记录里的 kind', () async {
      putRemote([
        remoteRecord(
          id: 'course-1',
          folder: '/课程/x',
          kind: SeriesKind.course,
        ),
      ]);

      await sync.restoreFromCloud();

      expect(
        (await db.seriesDao.seriesById('course-1'))!.kind,
        SeriesKind.course,
      );
    });
  });
}
