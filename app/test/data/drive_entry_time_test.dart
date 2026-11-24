import 'package:flutter_test/flutter_test.dart';
import 'package:yun_audiobook/data/drive/cloud_drive_source.dart';
import 'package:yun_audiobook/data/drive/demo/demo_drive_source.dart';
import 'package:yun_audiobook/data/drive/local/local_media_source.dart';
import 'package:yun_audiobook/data/repositories/library_repository.dart';
import 'package:yun_audiobook/domain/entities.dart';

/// 章节按时间排序要用的两个网盘时间（add-episode-time-order）：
/// 上传时间 serverCtime、同步时间 serverMtime，都是秒。
void main() {
  test('目录缓存 JSON 带上上传时间', () {
    const e = DriveEntry(
      fsId: '1',
      path: '/书/a.mp3',
      name: 'a.mp3',
      isDirectory: false,
      size: 10,
      serverCtime: 100,
      serverMtime: 200,
    );
    final back = DriveEntry.fromJson(e.toJson());
    expect(back.serverCtime, 100);
    expect(back.serverMtime, 200);
  });

  test('升级前的目录缓存没有 ctime 键：读成 null，不报错', () {
    final old = DriveEntry.fromJson({
      'fsId': '1',
      'path': '/书/a.mp3',
      'name': 'a.mp3',
      'dir': false,
      'size': 10,
      'mtime': 200,
    });
    expect(old.serverCtime, isNull);
    expect(old.serverMtime, 200);
  });

  test('演示网盘：文件都有时间，且时间顺序与文件序相反', () async {
    final files = (await DemoDriveSource().listDirectory('/我的有声书/三体'))
        .where(LibraryRepository.isMedia)
        .toList();
    expect(files.every((f) => f.serverCtime != null && f.serverMtime != null),
        isTrue);
    for (var i = 1; i < files.length; i++) {
      expect(files[i].serverCtime! < files[i - 1].serverCtime!, isTrue,
          reason: '${files[i].name} 应比 ${files[i - 1].name} 更早');
    }
  });

  test('本机文件只有修改时间：两个时间都取它', () async {
    final local = LocalMediaSource(
      query: (k) async => k == MediaKind.audio
          ? [
              (
                id: '1',
                name: 'a.mp3',
                path: '/Music/书/a.mp3',
                size: 1,
                mtime: 42,
              ),
            ]
          : [],
      hasPermission: (_) async => true,
      requestPermission: (_) async => true,
    );
    final f = (await local.listMediaFiles(MediaKind.audio)).single;
    expect(f.serverCtime, 42);
    expect(f.serverMtime, 42);
  });
}
