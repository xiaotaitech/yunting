import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yun_audiobook/data/drive/demo/demo_drive_source.dart';
import 'package:yun_audiobook/data/drive/local/local_media_source.dart';
import 'package:yun_audiobook/data/drive/routing_drive_source.dart';
import 'package:yun_audiobook/data/local/database.dart';
import 'package:yun_audiobook/data/repositories/library_repository.dart';
import 'package:yun_audiobook/domain/entities.dart';
import 'package:yun_audiobook/domain/local_media.dart';

typedef Row = ({String id, int mtime, String name, String path, int size});

Row ch(int n) => (
      id: '$n',
      name: '第$n章.mp3',
      path: '/Music/书/第$n章.mp3',
      size: 100,
      mtime: n
    );

void main() {
  late AppDatabase db;
  late LibraryRepository library;
  late List<Row> files;

  setUp(() {
    files = [ch(1), ch(2)];
    db = AppDatabase(
      DatabaseConnection(NativeDatabase.memory(),
          closeStreamsSynchronously: true),
    );
    library = LibraryRepository(
      drive: RoutingDriveSource(
        primary: DemoDriveSource(),
        byPrefix: {
          localPrefix: LocalMediaSource(
            query: (k) async => k == MediaKind.audio ? files : const [],
            hasPermission: (_) async => true,
            requestPermission: (_) async => true,
          ),
        },
      ),
      dao: db.seriesDao,
      deviceId: () async => 'dev',
    );
  });
  tearDown(() => db.close());

  test('文件夹没变化：返回 0，条目不动', () async {
    final s = await library.claimFolder('local:/Music/书');
    expect(await library.refresh(s, onlyIfChanged: true), 0);
    expect(await db.seriesDao.episodesOf(s.id), hasLength(2));
  });

  test('文件夹新增了文件：返回新增数，书架上的集数跟着变', () async {
    final s = await library.claimFolder('local:/Music/书');
    files = [...files, ch(3), ch(4)];
    expect(await library.refresh(s, onlyIfChanged: true), 2);
    final eps = await db.seriesDao.episodesOf(s.id);
    expect(eps.map((e) => e.title), ['第1章', '第2章', '第3章', '第4章']);
    expect((await db.seriesDao.seriesById(s.id))!.episodeCount, 4);
  });

  test('重扫后已记下的时长还在', () async {
    final s = await library.claimFolder('local:/Music/书');
    final first = (await db.seriesDao.episodesOf(s.id)).first;
    await db.seriesDao.setDuration(first.id, 60000);
    files = [...files, ch(3)];
    await library.refresh(s, onlyIfChanged: true);
    expect((await db.seriesDao.episodesOf(s.id)).first.durationMs, 60000);
  });

  group('按时间排序（add-episode-time-order）', () {
    Row at(String name, int t) => (
          id: name,
          name: '$name.mp3',
          path: '/Music/书/$name.mp3',
          size: 100,
          mtime: t
        );

    Future<Series> claimByTime() async {
      final s = await library.claimFolder('local:/Music/书');
      final byTime = s.copyWith(episodeOrder: EpisodeOrder.time);
      await db.seriesDao.upsertSeries(byTime);
      await library.refresh(byTime);
      return byTime;
    }

    Future<List<String>> titles(String id) async =>
        (await db.seriesDao.episodesOf(id)).map((e) => e.title).toList();

    test('按上传时间从旧到新，章节带上时间', () async {
      files = [at('甲', 30), at('乙', 10), at('丙', 20)];
      final s = await claimByTime();
      expect(await titles(s.id), ['乙', '丙', '甲']);
      final first = (await db.seriesDao.episodesOf(s.id)).first;
      expect(first.createdAt, DateTime.fromMillisecondsSinceEpoch(10 * 1000));
      expect(first.syncedAt, DateTime.fromMillisecondsSinceEpoch(10 * 1000));
    });

    test('新的一期排在末尾，已有顺序不变', () async {
      files = [at('乙', 10), at('丁', 20)];
      final s = await claimByTime();
      files = [...files, at('丙', 30)];
      expect(await library.refresh(s, onlyIfChanged: true), 1);
      expect(await titles(s.id), ['乙', '丁', '丙']);
    });

    test('时间相同按自然序', () async {
      files = [at('第10章', 5), at('第2章', 5), at('第1章', 9)];
      final s = await claimByTime();
      expect(await titles(s.id), ['第2章', '第10章', '第1章']);
    });

    test('按名称时不受时间影响', () async {
      files = [at('第2章', 1), at('第1章', 9)];
      final s = await library.claimFolder('local:/Music/书');
      expect(await titles(s.id), ['第1章', '第2章']);
    });

    test('手动排过序时追加的新章节也带时间', () async {
      files = [at('乙', 10), at('甲', 20)];
      final s = await library.claimFolder('local:/Music/书');
      await library.reorder(
          s, (await db.seriesDao.episodesOf(s.id)).reversed.toList());
      final edited = (await db.seriesDao.seriesById(s.id))!;
      files = [...files, at('丙', 30)];
      await library.refresh(edited, onlyIfChanged: true);
      final last = (await db.seriesDao.episodesOf(s.id)).last;
      expect(last.title, '丙');
      expect(last.syncedAt, DateTime.fromMillisecondsSinceEpoch(30 * 1000));
    });

    test('手动排过序的老数据：刷新时给已有章节补上时间', () async {
      files = [at('乙', 10), at('甲', 20)];
      final s = await library.claimFolder('local:/Music/书');
      await library.reorder(s, await db.seriesDao.episodesOf(s.id));
      // 模拟升级前认领的书：章节没有时间
      await db.seriesDao.replaceEpisodes(s.id, [
        for (final e in await db.seriesDao.episodesOf(s.id))
          e.copyWith(createdAt: null, syncedAt: null),
      ]);
      final edited = (await db.seriesDao.seriesById(s.id))!;
      await library.refresh(edited);
      final eps = await db.seriesDao.episodesOf(s.id);
      expect(eps.every((e) => e.syncedAt != null), isTrue);
    });

    test('切换排序方式：覆盖手动顺序，进度仍在同一个文件上', () async {
      files = [at('甲', 30), at('乙', 10), at('丙', 20)];
      final s = await library.claimFolder('local:/Music/书');
      // 认领后按码位是 丙 乙 甲；手动拖成 甲 丙 乙，听到甲（第 0 个）
      final eps = await db.seriesDao.episodesOf(s.id);
      await library.reorder(s, [eps[2], eps[0], eps[1]]);
      expect(await titles(s.id), ['甲', '丙', '乙']);
      await db.seriesDao.updateProgress(
        seriesId: s.id,
        episodeIndex: 0,
        positionMs: 5000,
        deviceId: 'dev',
      );

      await library.setEpisodeOrder(
        (await db.seriesDao.seriesById(s.id))!,
        EpisodeOrder.time,
      );

      final book = (await db.seriesDao.seriesById(s.id))!;
      expect(book.episodeOrder, EpisodeOrder.time);
      expect(book.orderEditedByUser, isFalse);
      expect(await titles(s.id), ['乙', '丙', '甲']);
      expect(book.currentEpisodeIndex, 2);
      expect(book.currentPositionMs, 5000);
    });
  });
}
