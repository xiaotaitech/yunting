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

Row ch(int n) =>
    (id: '$n', name: '第$n章.mp3', path: '/Music/书/第$n章.mp3', size: 100, mtime: n);

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
}
