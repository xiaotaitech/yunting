import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:yun_audiobook/data/covers/cover_service.dart';
import 'package:yun_audiobook/data/drive/cloud_drive_source.dart';
import 'package:yun_audiobook/data/local/database.dart';
import 'package:yun_audiobook/domain/entities.dart';

import '../domain/id3_picture_test.dart' show apic, tag;

const image = [0xff, 0xd8, 7, 7, 7, 0xff, 0xd9];

class FakeDrive implements CloudDriveSource {
  final files = <String, Uint8List>{};
  final thumbs = <String, String>{};
  int reads = 0;

  @override
  Future<List<int>> readRange(String fsId, int start, int endInclusive) async {
    reads++;
    final f = files[fsId]!;
    return f.sublist(start, (endInclusive + 1).clamp(0, f.length));
  }

  @override
  Future<Map<String, DriveEntry>> fetchMetadata(List<String> fsIds) async => {
        for (final id in fsIds)
          id: DriveEntry(
            fsId: id,
            path: '/x',
            name: 'x',
            isDirectory: false,
            size: 1,
            thumbnailUrl: thumbs[id],
          ),
      };

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late AppDatabase db;
  late Directory dir;
  late FakeDrive drive;
  late CoverService covers;
  late List<String> localExtracts;

  setUp(() async {
    db = AppDatabase(
      DatabaseConnection(NativeDatabase.memory(),
          closeStreamsSynchronously: true),
    );
    dir = await Directory.systemTemp.createTemp('yun_covers_');
    drive = FakeDrive();
    localExtracts = [];
    covers = CoverService(
      dao: db.seriesDao,
      drive: drive,
      extractLocal: (uri, kind) async {
        localExtracts.add(uri);
        return Uint8List.fromList(image);
      },
      client: MockClient(
        (req) async => req.url.host == 'thumb'
            ? http.Response.bytes(image, 200)
            : http.Response('', 404),
      ),
      dir: () async => dir,
    );
  });
  tearDown(() async {
    await db.close();
    await dir.delete(recursive: true);
  });

  Future<Series> seriesWith(List<Episode> eps, {String? coverFsId}) async {
    final s = Series(
      id: 's1',
      folderPath: '/书',
      title: '三体',
      coverFsId: coverFsId,
      addedAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
    await db.seriesDao.upsertSeries(s);
    await db.seriesDao.replaceEpisodes(s.id, eps);
    return s;
  }

  Episode ep(String fsId, String name, {MediaKind kind = MediaKind.audio}) =>
      Episode(
        id: 's1-$fsId',
        seriesId: 's1',
        fsId: fsId,
        path: '/书/$name',
        title: name,
        fileName: name,
        size: 1,
        orderIndex: int.tryParse(fsId.replaceAll(RegExp(r'\D'), '')) ?? 0,
        mediaKind: kind,
      );

  Future<List<int>?> savedCover() async {
    final path = (await db.seriesDao.seriesById('s1'))!.coverLocalPath;
    return path == null ? null : File(path).readAsBytesSync();
  }

  test('网盘 mp3：只读 ID3 标签那一段，取内嵌封面', () async {
    final mp3 = tag([('APIC', apic(3, image))]);
    drive.files['1'] = Uint8List.fromList([...mp3, ...List.filled(5000, 0)]);
    await covers.ensure(await seriesWith([ep('1', '1.mp3')]));
    expect(await savedCover(), image);
    expect(drive.reads, 2, reason: '先读 10 字节头，再读整个标签');
  });

  test('第一集没图就看第二集', () async {
    drive.files['1'] = tag([
      ('TIT2', [0, 65])
    ]);
    drive.files['2'] = tag([('APIC', apic(3, image))]);
    await covers.ensure(await seriesWith([ep('1', '1.mp3'), ep('2', '2.mp3')]));
    expect(await savedCover(), image);
  });

  test('网盘视频：用百度的缩略图', () async {
    drive.thumbs['v1'] = 'https://thumb/v1.jpg';
    await covers.ensure(
      await seriesWith([ep('v1', '1.mp4', kind: MediaKind.video)]),
    );
    expect(await savedCover(), image);
  });

  test('本机文件：交给系统取', () async {
    await covers.ensure(await seriesWith([ep('local:a:11', '1.mp3')]));
    expect(localExtracts, ['content://media/external/audio/media/11']);
    expect(await savedCover(), image);
  });

  test('已经有网盘封面图：不再去取', () async {
    await covers.ensure(
      await seriesWith([ep('local:a:11', '1.mp3')], coverFsId: 'img'),
    );
    expect(localExtracts, isEmpty);
  });

  test('取不到就算了：不抛错，也不写路径', () async {
    drive.files['1'] = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
    await covers.ensure(await seriesWith([ep('1', '1.mp3')]));
    expect(await savedCover(), isNull);
  });

  test('手动选的图覆盖自动封面，旧文件被清掉', () async {
    final s = await seriesWith([ep('local:a:11', '1.mp3')]);
    await covers.ensure(s);
    final picked = File('${dir.path}/picked')..writeAsBytesSync([1, 2, 3]);
    await covers.setManual(s.id, picked.path);
    expect(await savedCover(), [1, 2, 3]);
    final left = dir.listSync().where((f) => f.path.contains('s1-'));
    expect(left, hasLength(1));
  });
}
