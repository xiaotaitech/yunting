import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yun_audiobook/app/providers.dart';
import 'package:yun_audiobook/data/drive/demo/demo_drive_source.dart';
import 'package:yun_audiobook/data/local/database.dart';
import 'package:yun_audiobook/data/repositories/library_repository.dart';
import 'package:yun_audiobook/data/sync/library_sync.dart';
import 'package:yun_audiobook/domain/entities.dart';
import 'package:yun_audiobook/features/library/library_controller.dart';
import 'package:yun_audiobook/features/player/playback_controller.dart';
import 'package:yun_audiobook/playback/playback_session.dart';
import 'package:yun_audiobook/playback/playback_url_resolver.dart';

import '../support/playback_fakes.dart';

/// 命令式 controller 必须撑过自己的 await。
///
/// 回归：它们原来是自动释放的，没人 watch。「加入书架」时
/// `claim` 在第一个 await 之后 provider 已被回收，紧接着的
/// `ref.read(librarySyncProvider)` 抛「Cannot use the Ref after it has been
/// disposed」——书其实已经加进库了，界面却既不回书架也不提示。
void main() {
  late AppDatabase db;
  late LibrarySync sync;
  late ProviderContainer container;
  late PlaybackSession session;

  setUp(() {
    db = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    final drive = DemoDriveSource();
    sync = LibrarySync(drive: drive, db: db);
    session = PlaybackSession(
      engine: FakeEngine(),
      resolver: PlaybackUrlResolver(FakeDrive()),
      sink: RecordingSink(),
    );
    container = ProviderContainer(
      overrides: [
        playbackSessionProvider.overrideWithValue(session),
        databaseProvider.overrideWithValue(db),
        librarySyncProvider.overrideWithValue(sync),
        libraryRepositoryProvider.overrideWithValue(
          LibraryRepository(
            drive: drive,
            dao: db.seriesDao,
            deviceId: () async => 'test-device',
          ),
        ),
      ],
    );
  });

  tearDown(() async {
    await session.dispose();
    sync.dispose();
    container.dispose();
    await db.close();
  });

  test('没人 watch 时 claim 也能跑完整个流程', () async {
    final series = await container
        .read(libraryControllerProvider.notifier)
        .claim('/我的有声书/三体');
    expect(series.episodeCount, 5);
    expect((await db.seriesDao.shelf()).single.id, series.id);
  });

  // 回归：resume 原来用 `ref.read(episodesProvider(id).future)` 取条目，
  // 那是没人监听的自动释放流 provider，发出第一个值之前就被回收，
  // 抛「disposed during loading state」——真机上点播放键没有任何反应。
  test('没人 watch 时 resume 能取到条目并开始准备', () async {
    final series = await container
        .read(libraryControllerProvider.notifier)
        .claim('/我的有声书/三体');
    final result = await container
        .read(playbackControllerProvider.notifier)
        .resume(series);
    expect(result, isA<OpenStarted>());
    expect(session.current.series?.id, series.id);
    expect(session.current.episodes, hasLength(5));
  });

  test('认领装着视频的文件夹：成为课程，条目是视频', () async {
    final series = await container
        .read(libraryControllerProvider.notifier)
        .claim('/我的课程/英语入门');
    expect(series.kind, SeriesKind.course);
    final episodes = await db.seriesDao.episodesOf(series.id);
    expect(episodes, hasLength(3));
    expect(episodes.every((e) => e.mediaKind == MediaKind.video), isTrue);
  });
}
