import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yun_audiobook/data/drive/demo/demo_drive_source.dart';
import 'package:yun_audiobook/data/drive/local/local_media_source.dart';
import 'package:yun_audiobook/data/drive/routing_drive_source.dart';
import 'package:yun_audiobook/data/local/database.dart';
import 'package:yun_audiobook/data/repositories/library_repository.dart';
import 'package:yun_audiobook/data/sync/library_sync.dart';
import 'package:yun_audiobook/domain/entities.dart';
import 'package:yun_audiobook/domain/local_media.dart';

/// 手机里的文件（MediaStore 的样子：/相对目录/文件名）。
final Map<MediaKind,
    List<({String id, int mtime, String name, String path, int size})>> rows = {
  MediaKind.audio: [
    (id: '11', name: '第1章.mp3', path: '/Music/三体/第1章.mp3', size: 100, mtime: 5),
    (
      id: '12',
      name: '第10章.mp3',
      path: '/Music/三体/第10章.mp3',
      size: 100,
      mtime: 6
    ),
    (id: '13', name: '第2章.mp3', path: '/Music/三体/第2章.mp3', size: 100, mtime: 7),
    (id: '21', name: '1.m4a', path: '/Recordings/会议/1.m4a', size: 50, mtime: 9),
  ],
  MediaKind.video: [
    (
      id: '31',
      name: '第1课.mp4',
      path: '/Movies/英语/第1课.mp4',
      size: 900,
      mtime: 4
    ),
  ],
};

/// 演示网盘，但同步文件存在内存里（单测里没有 path_provider）。
class MemoryStateDemo extends DemoDriveSource {
  final files = <String, String>{};

  @override
  Future<String?> readAppStateFile(String path) async => files[path];

  @override
  Future<void> writeAppStateFile(String path, String content) async =>
      files[path] = content;
}

LocalMediaSource fakeLocal({bool granted = true}) => LocalMediaSource(
      query: (k) async => rows[k]!,
      hasPermission: (_) async => granted,
      requestPermission: (_) async => granted,
    );

void main() {
  group('本机数据源', () {
    test('路径与 fsId 带 local: 前缀，播放地址是 MediaStore 的 content://', () async {
      final local = fakeLocal();
      final files = await local.listMediaFiles(MediaKind.video);
      expect(files.single.path, 'local:/Movies/英语/第1课.mp4');
      expect(files.single.fsId, 'local:v:31');
      final media = await local.resolveMedia(files.single.fsId);
      expect(media.url, 'content://media/external/video/media/31');
      expect(media.mediaKind, MediaKind.video);
      expect(media.isLocal, isTrue);
    });

    test('目录内容由全部媒体推出：直接的文件 + 含媒体的子目录', () async {
      final local = fakeLocal();
      final root = await local.listDirectory('local:/Music');
      expect(root.single.isDirectory, isTrue);
      expect(root.single.path, 'local:/Music/三体');
      final book = await local.listDirectory('local:/Music/三体');
      expect(book.where((e) => !e.isDirectory), hasLength(3));
    });

    test('没授权时什么都不列，不抛错', () async {
      expect(await fakeLocal(granted: false).listMediaFiles(MediaKind.audio),
          isEmpty);
    });
  });

  group('网盘 + 本机', () {
    late AppDatabase db;
    late RoutingDriveSource drive;
    late LibraryRepository library;

    setUp(() {
      db = AppDatabase(
        DatabaseConnection(NativeDatabase.memory(),
            closeStreamsSynchronously: true),
      );
      drive = RoutingDriveSource(remote: MemoryStateDemo(), local: fakeLocal());
      library = LibraryRepository(
        drive: drive,
        dao: db.seriesDao,
        deviceId: () async => 'dev',
      );
    });
    tearDown(() => db.close());

    test('按前缀分派：本机路径走本机，其余走网盘', () async {
      expect(
        (await drive.resolveMedia('local:a:11')).url,
        'content://media/external/audio/media/11',
      );
      final remote = await drive.listDirectory('/我的有声书');
      expect(remote.any((e) => e.name == '三体'), isTrue);
    });

    test('认领本机文件夹：自然序排章，标签读不到时退回文件名', () async {
      final s = await library.claimFolder('local:/Music/三体');
      expect(s.title, '三体');
      expect(s.isLocal, isTrue);
      final eps = await db.seriesDao.episodesOf(s.id);
      expect(eps.map((e) => e.title), ['第1章', '第2章', '第10章']);
      expect(eps.every((e) => e.isLocal), isTrue);
    });

    test('本机视频文件夹认领为课程', () async {
      final s = await library.claimFolder('local:/Movies/英语');
      expect(s.kind, SeriesKind.course);
    });

    test('本机书不进同步文件', () async {
      await library.claimFolder('local:/Music/三体');
      await library.claimFolder('/我的有声书/小王子');
      final sync = LibrarySync(drive: drive, db: db);
      await sync.syncNow();
      final uploaded =
          await drive.readAppStateFile('/apps/yun_audiobook/library.json');
      expect(uploaded, contains('小王子'));
      expect(uploaded, isNot(contains('local:')));
      sync.dispose();
    });
  });
}
