import 'package:flutter_test/flutter_test.dart';
import 'package:yun_audiobook/data/drive/cloud_drive_source.dart';
import 'package:yun_audiobook/data/drive/routing_drive_source.dart';
import 'package:yun_audiobook/domain/entities.dart';

/// 只记录被调到了哪些方法的假网盘。
class RecordingDrive implements CloudDriveSource {
  RecordingDrive(this.id);

  @override
  final String id;
  final calls = <String>[];

  @override
  Future<List<DriveEntry>> listDirectory(String path) async {
    calls.add('list $path');
    return const [];
  }

  @override
  Future<List<DriveEntry>> listMediaFiles(MediaKind kind) async {
    calls.add('media');
    return const [];
  }

  @override
  Future<ResolvedMedia> resolveMedia(
    String fsId, {
    String? path,
    MediaKind kind = MediaKind.audio,
  }) async {
    calls.add('resolve $fsId');
    return ResolvedMedia(
      url: 'https://$id.test/$fsId',
      isLocal: false,
      expiresAt: DateTime(2100),
    );
  }

  @override
  Future<Map<String, DriveEntry>> fetchMetadata(List<String> fsIds) async {
    calls.add('meta ${fsIds.join(',')}');
    return {
      for (final f in fsIds)
        f: DriveEntry(fsId: f, path: f, name: f, isDirectory: false, size: 1),
    };
  }

  @override
  Future<List<int>> readRange(String fsId, int start, int endInclusive) async {
    calls.add('range $fsId');
    return const [];
  }

  @override
  Future<Stream<List<int>>> openStream(
    ResolvedMedia media, {
    int start = 0,
  }) async {
    calls.add('stream ${media.url}');
    return const Stream.empty();
  }
}

void main() {
  late RecordingDrive baidu;
  late RecordingDrive other;
  late RoutingDriveSource drive;

  setUp(() {
    baidu = RecordingDrive('baidu');
    other = RecordingDrive('aliyun');
    drive = RoutingDriveSource(primary: baidu, byPrefix: {'aliyun:': other});
  });

  test('按前缀分派，无前缀归主网盘', () async {
    await drive.listDirectory('/我的有声书');
    await drive.listDirectory('aliyun:/书');
    await drive.readRange('aliyun:f1', 0, 9);
    expect(baidu.calls, ['list /我的有声书']);
    expect(other.calls, ['list aliyun:/书', 'range aliyun:f1']);
  });

  test('下载取流交回解析出地址的那个网盘', () async {
    final media = await drive.resolveMedia('aliyun:f1');
    expect(media.sourceId, 'aliyun');
    await drive.openStream(media);
    expect(other.calls.last, 'stream https://aliyun.test/aliyun:f1');
    expect(baidu.calls, isEmpty);

    await drive.openStream(await drive.resolveMedia('123'));
    expect(baidu.calls.last, 'stream https://baidu.test/123');
  });

  test('批量元信息按来源拆开再合并', () async {
    final meta = await drive.fetchMetadata(['1', 'aliyun:a', '2']);
    expect(meta.keys, containsAll(['1', '2', 'aliyun:a']));
    expect(baidu.calls, ['meta 1,2']);
    expect(other.calls, ['meta aliyun:a']);
  });

  test('整盘扫描只走主网盘', () async {
    await drive.listMediaFiles(MediaKind.audio);
    expect(baidu.calls, ['media']);
    expect(other.calls, isEmpty);
  });
}
