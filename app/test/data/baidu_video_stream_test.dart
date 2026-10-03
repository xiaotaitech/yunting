import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:yun_audiobook/core/errors.dart';
import 'package:yun_audiobook/data/auth/auth_repository.dart';
import 'package:yun_audiobook/data/auth/token_store.dart';
import 'package:yun_audiobook/data/drive/baidu/baidu_api_client.dart';
import 'package:yun_audiobook/data/drive/baidu/baidu_drive_source.dart';
import 'package:yun_audiobook/data/drive/cloud_drive_source.dart';
import 'package:yun_audiobook/domain/entities.dart';

import '../support/memory_storage.dart';

const playlist =
    '#EXTM3U\n#EXT-X-TARGETDURATION:10\n#EXTINF:10,\nhttps://seg/1.ts\n';

/// 百度转码取流（add-video-courses D1）。规则来自对真实网盘的实测：
/// 非会员第一次给 errno=133 + adTime + adToken，等够再带 adToken 请求才给 M3U8。
void main() {
  late Directory dir;
  late List<Uri> requests;
  late List<Duration> slept;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('yun_hls_');
    requests = [];
    slept = [];
  });
  tearDown(() => dir.delete(recursive: true));

  Future<BaiduDriveSource> sourceWith(
    List<String> responses, {
    String quality = '720',
  }) async {
    final store = TokenStore(MemoryStorage());
    await store.write(
      AuthToken(
        accessToken: 'tok',
        refreshToken: 'r',
        expiresAt: DateTime.now().add(const Duration(days: 1)),
        scope: 'basic,netdisk',
      ),
    );
    final auth = AuthRepository(store: store);
    await auth.restore();
    final queue = [...responses];
    final client = MockClient((req) async {
      requests.add(req.url);
      expect(req.headers['User-Agent'], BaiduDriveSource.videoUserAgent);
      return http.Response.bytes(utf8.encode(queue.removeAt(0)), 200);
    });
    return BaiduDriveSource(
      BaiduApiClient(auth, client: client),
      videoQuality: () async => quality,
      hlsDir: () async => dir,
      sleep: (d) async => slept.add(d),
    );
  }

  test('非会员：等 adTime 秒后带 adToken 重请求，M3U8 落成本地文件', () async {
    final drive = await sourceWith([
      jsonEncode({'errno': 133, 'adTime': 8, 'adToken': 'AD/+='}),
      playlist,
    ]);
    final media = await drive.resolveMedia(
      'fs1',
      path: '/课程/第1课.mp4',
      kind: MediaKind.video,
    );

    expect(slept.single, greaterThanOrEqualTo(const Duration(seconds: 8)));
    expect(requests, hasLength(2));
    expect(requests.first.queryParameters['type'], 'M3U8_AUTO_720');
    expect(requests.first.queryParameters['path'], '/课程/第1课.mp4');
    expect(requests.last.queryParameters['adToken'], 'AD/+=');

    expect(media.kind, StreamKind.hls);
    expect(media.mediaKind, MediaKind.video);
    // 分片是远程的、会过期：不能当本地文件（否则恢复流程不会重取）
    expect(media.isLocal, isFalse);
    expect(
        File(Uri.parse(media.url).toFilePath()).readAsStringSync(), playlist);
  });

  test('会员直接拿到 M3U8，不等待', () async {
    final drive = await sourceWith([playlist]);
    await drive.resolveMedia('fs1', path: '/a.mp4', kind: MediaKind.video);
    expect(slept, isEmpty);
    expect(requests, hasLength(1));
  });

  test('清晰度取自设置', () async {
    final drive = await sourceWith([playlist], quality: '480');
    await drive.resolveMedia('fs1', path: '/a.mp4', kind: MediaKind.video);
    expect(requests.single.queryParameters['type'], 'M3U8_AUTO_480');
  });

  test('文件不存在：报 notFound，不去等广告', () async {
    final drive = await sourceWith([
      jsonEncode({'errno': 31066})
    ]);
    await expectLater(
      drive.resolveMedia('fs1', path: '/a.mp4', kind: MediaKind.video),
      throwsA(
        isA<DriveException>()
            .having((e) => e.kind, 'kind', DriveErrorKind.notFound),
      ),
    );
    expect(slept, isEmpty);
  });

  test('还在转码：报可重试的错误', () async {
    final drive = await sourceWith([
      jsonEncode({'errno': 31341})
    ]);
    await expectLater(
      drive.resolveMedia('fs1', path: '/a.mp4', kind: MediaKind.video),
      throwsA(isA<DriveException>()
          .having((e) => e.isRetryable, 'retryable', isTrue)),
    );
  });

  test('等完广告仍没给 M3U8：报错而不是把 JSON 当播放列表', () async {
    final drive = await sourceWith([
      jsonEncode({'errno': 133, 'adTime': 1, 'adToken': 't'}),
      jsonEncode({'errno': 133, 'adTime': 1, 'adToken': 't2'}),
    ]);
    await expectLater(
      drive.resolveMedia('fs1', path: '/a.mp4', kind: MediaKind.video),
      throwsA(isA<DriveException>()),
    );
  });
}
