import 'package:flutter_test/flutter_test.dart';
import 'package:yun_audiobook/core/config.dart';
import 'package:yun_audiobook/data/drive/cloud_drive_source.dart';
import 'package:yun_audiobook/domain/entities.dart';
import 'package:yun_audiobook/playback/playback_url_resolver.dart';

/// 可控的假数据源：能数出被解析了几次，也能造出"已过期"的地址。
class FakeDrive implements CloudDriveSource {
  FakeDrive({this.ttl = const Duration(minutes: 25)});

  final Duration ttl;
  int resolveCalls = 0;

  @override
  String get id => 'fake';

  @override
  Future<ResolvedMedia> resolveMedia(
    String fsId, {
    String? path,
    MediaKind kind = MediaKind.audio,
  }) async {
    resolveCalls++;
    return ResolvedMedia(
      url: 'https://cdn.example.com/$fsId?token=v$resolveCalls',
      isLocal: false,
      expiresAt: DateTime.now().add(ttl),
      headers: const {'User-Agent': AppConfig.panUserAgent},
    );
  }

  @override
  Future<List<DriveEntry>> listDirectory(String path) async => [];

  @override
  Future<Map<String, DriveEntry>> fetchMetadata(List<String> fsIds) async => {};

  @override
  Future<List<int>> readRange(String fsId, int start, int end) async => [];

  @override
  Future<Stream<List<int>>> openStream(
    ResolvedMedia media, {
    int start = 0,
  }) async =>
      const Stream.empty();

  @override
  Future<List<DriveEntry>> listMediaFiles(MediaKind kind) async => const [];

  @override
  Future<String?> readAppStateFile(String path) async => null;

  @override
  Future<void> writeAppStateFile(String path, String content) async {}
}

Episode episode({String fsId = '1001'}) => Episode(
      id: 'ch1',
      seriesId: 'b1',
      fsId: fsId,
      path: '/books/b1/01.mp3',
      title: '第一章',
      fileName: '01.mp3',
      size: 30 * 1024 * 1024,
      orderIndex: 0,
    );

void main() {
  group('播放地址解析', () {
    test('未过期时复用缓存，不重复打网盘接口', () async {
      final drive = FakeDrive();
      final resolver = PlaybackUrlResolver(drive);

      await resolver.resolve(episode());
      await resolver.resolve(episode());
      await resolver.resolve(episode());

      expect(drive.resolveCalls, 1);
    });

    test('解析出的地址必须带 pan.baidu.com 的 UA', () async {
      final media = await PlaybackUrlResolver(FakeDrive()).resolve(episode());
      expect(media.headers['User-Agent'], 'pan.baidu.com');
    });

    test('forceRefresh 会拿到一个全新的地址（链接失效后的恢复路径）', () async {
      final drive = FakeDrive();
      final resolver = PlaybackUrlResolver(drive);

      final first = await resolver.resolve(episode());
      final second = await resolver.resolve(episode(), forceRefresh: true);

      expect(drive.resolveCalls, 2);
      expect(second.url, isNot(first.url));
    });

    test('invalidate 之后下一次解析必然重新取地址', () async {
      final drive = FakeDrive();
      final resolver = PlaybackUrlResolver(drive);

      await resolver.resolve(episode());
      resolver.invalidate('1001');
      await resolver.resolve(episode());

      expect(drive.resolveCalls, 2);
    });

    test('TTL 到期的地址被视为陈旧，会自动重取', () async {
      // ttl 为负数即"生下来就过期"，模拟 dlink 已失效
      final drive = FakeDrive(ttl: const Duration(seconds: -1));
      final resolver = PlaybackUrlResolver(drive);

      await resolver.resolve(episode());
      await resolver.resolve(episode());

      expect(drive.resolveCalls, 2);
    });

    test('clear 之后所有缓存都失效（退出登录场景）', () async {
      final drive = FakeDrive();
      final resolver = PlaybackUrlResolver(drive);

      await resolver.resolve(episode());
      resolver.clear();
      await resolver.resolve(episode());

      expect(drive.resolveCalls, 2);
    });

    test('预取会把地址提前放进缓存，正式播放时不再解析', () async {
      final drive = FakeDrive();
      final resolver = PlaybackUrlResolver(drive);

      await resolver.prefetch(episode());
      expect(drive.resolveCalls, 1);

      await resolver.resolve(episode());
      expect(drive.resolveCalls, 1, reason: '预取过的地址应当被直接复用');
    });

    test('预取 null（已是最后一章）不发请求', () async {
      final drive = FakeDrive();
      await PlaybackUrlResolver(drive).prefetch(null);
      expect(drive.resolveCalls, 0);
    });
  });
}
