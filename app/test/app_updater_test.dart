import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:yun_audiobook/features/update/app_updater.dart';

void main() {
  test('版本号按数字段比较', () {
    expect(AppUpdater.isNewer('0.3.0', '0.2.0'), isTrue);
    expect(AppUpdater.isNewer('v0.10.0', '0.9.3'), isTrue);
    expect(AppUpdater.isNewer('1.0', '0.9.9'), isTrue);
    expect(AppUpdater.isNewer('0.2.0', '0.2.0'), isFalse);
    expect(AppUpdater.isNewer('0.2.0', '0.2.1'), isFalse);
    expect(AppUpdater.isNewer('0.2', '0.2.0'), isFalse);
    // 构建号不参与比较
    expect(AppUpdater.isNewer('0.2.0', '0.2.0+5'), isFalse);
    expect(AppUpdater.isNewer('0.2.1', '0.2.0-ci'), isTrue);
  });

  test('更新说明去掉标题、粗体与安装包说明', () {
    const body = '## 云听书 0.3.1\n\n- 修复甲\n- **新增**乙\n\n'
        '下载 yunting.apk 安装；已安装的用户可在「我的 → 检查更新」中直接更新。';
    expect(AppUpdater.cleanNotes(body), '- 修复甲\n- 新增乙');
  });

  http.Response json(Object o, [int status = 200]) => http.Response.bytes(
        utf8.encode(jsonEncode(o)),
        status,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );

  final ghRelease = {
    'tag_name': 'v0.3.0',
    'body': '更新说明',
    'html_url': 'https://gh/page',
    'assets': [
      {
        'name': 'yunting-v0.3.0.apk',
        'browser_download_url': 'https://x/yunting-v0.3.0.apk',
      },
      {'name': 'yunting.apk', 'browser_download_url': 'https://x/yunting.apk'},
    ],
  };
  final mirrorJson = {
    'version': '0.3.0',
    'notes': '## 云听书 0.3.0\n\n- 镜像说明',
    'page': 'https://p',
    'apk': ['https://cdn/yunting.apk', 'https://x/yunting.apk'],
  };

  AppUpdater updater(
    http.Response Function(Uri) handler, {
    List<String> mirrors = const ['https://m/latest.json'],
  }) =>
      AppUpdater(
        client: MockClient((req) async => handler(req.url)),
        repo: 'o/r',
        api: 'https://api',
        mirrors: mirrors,
      );

  test('取 GitHub 最新 Release 中固定名称的安装包', () async {
    final r = await updater(
      (u) => u.path == '/repos/o/r/releases/latest'
          ? json(ghRelease)
          : json({}, 404),
    ).latest();
    expect(r.version, '0.3.0');
    expect(r.apkUrls, ['https://x/yunting.apk']);
    expect(r.notes, '更新说明');
    expect(r.pageUrl, 'https://gh/page');
  });

  test('GitHub 不通时用镜像，镜像按顺序尝试', () async {
    final r = await updater(
      (u) => switch (u.toString()) {
        'https://m/bad.json' => json({}, 404),
        'https://m/latest.json' => json(mirrorJson),
        _ => json({}, 503),
      },
      mirrors: const ['https://m/bad.json', 'https://m/latest.json'],
    ).latest();
    expect(r.version, '0.3.0');
    expect(r.notes, '- 镜像说明');
    expect(r.apkUrls, ['https://cdn/yunting.apk', 'https://x/yunting.apk']);
  });

  test('两边都可用且版本一致时合并下载地址，镜像在前', () async {
    final r = await updater(
      (u) => u.host == 'api' ? json(ghRelease) : json(mirrorJson),
    ).latest();
    expect(r.pageUrl, 'https://gh/page');
    expect(r.apkUrls, ['https://cdn/yunting.apk', 'https://x/yunting.apk']);
  });

  test('还没有发布版本时明确提示', () async {
    expect(
      updater((_) => json({}, 404)).latest(),
      throwsA(
        isA<UpdateException>().having((e) => e.message, 'message', '还没有发布版本'),
      ),
    );
  });

  group('下载前测速', () {
    /// 每条线路按给定的「每 64KB 耗时」吐数据；status 非 200/206 视为失败。
    AppUpdater updaterWith(
      Map<String, ({int status, Duration perChunk})> lines,
    ) =>
        AppUpdater(
          repo: 'o/r',
          client: MockClient.streaming((req, _) async {
            final line = lines[req.url.host]!;
            expect(
              req.headers['Range'],
              'bytes=0-${AppUpdater.probeBytes - 1}',
            );
            Stream<List<int>> body() async* {
              for (var i = 0; i < 4; i++) {
                await Future<void>.delayed(line.perChunk);
                yield List.filled(64 * 1024, 0);
              }
            }

            return http.StreamedResponse(
              line.status >= 400 ? const Stream.empty() : body(),
              line.status,
            );
          }),
        );

    test('按实测速度从快到慢排，失败的排最后', () async {
      final u = updaterWith({
        'slow.example': (
          status: 206,
          perChunk: const Duration(milliseconds: 60)
        ),
        'dead.example': (status: 403, perChunk: Duration.zero),
        'fast.example': (
          status: 206,
          perChunk: const Duration(milliseconds: 5)
        ),
      });
      final ranked = await u.fastestFirst([
        'https://slow.example/a.apk',
        'https://dead.example/a.apk',
        'https://fast.example/a.apk',
      ]);
      expect(ranked.map(AppUpdater.hostOf), [
        'fast.example',
        'slow.example',
        'dead.example',
      ]);
    });

    test('只有一条线路时不测速，原样返回', () async {
      final u = AppUpdater(
        repo: 'o/r',
        client: MockClient((_) async => fail('不该发请求')),
      );
      expect(await u.fastestFirst(['https://a/x.apk']), ['https://a/x.apk']);
    });

    test('卡住不给数据的线路在时限后放弃，不拖住整体', () async {
      final u = AppUpdater(
        repo: 'o/r',
        client: MockClient.streaming((req, _) async {
          if (req.url.host == 'hang.example') {
            // 永远不给数据也不关闭：只能靠测速时限脱身
            return http.StreamedResponse(
              StreamController<List<int>>().stream,
              206,
            );
          }
          return http.StreamedResponse(
            Stream.value(List.filled(AppUpdater.probeBytes, 0)),
            206,
          );
        }),
      );
      final watch = Stopwatch()..start();
      final ranked = await u.fastestFirst([
        'https://hang.example/a.apk',
        'https://ok.example/a.apk',
      ]);
      expect(AppUpdater.hostOf(ranked.first), 'ok.example');
      // 卡住的那条在 5 秒时限后放弃
      expect(watch.elapsed, greaterThanOrEqualTo(AppUpdater.probeTimeout));
      expect(watch.elapsed, lessThan(const Duration(seconds: 8)));
    });
  });

  test('镜像缓存不同步时取版本最高的那份，而不是先回来的', () async {
    final u = AppUpdater(
      repo: 'o/r',
      api: 'https://api.invalid',
      mirrors: ['https://stale/latest.json', 'https://fresh/latest.json'],
      client: MockClient((req) async {
        if (req.url.host == 'api.invalid') return http.Response('', 503);
        final v = req.url.host == 'stale' ? '0.4.2' : '0.5.0';
        // 旧的那份先回来
        if (req.url.host == 'fresh') {
          await Future<void>.delayed(const Duration(milliseconds: 50));
        }
        return http.Response(
          jsonEncode({
            'version': v,
            'apk': ['https://x/$v.apk']
          }),
          200,
        );
      }),
    );
    final r = await u.latest();
    expect(r.version, '0.5.0');
    expect(r.apkUrls, ['https://x/0.5.0.apk']);
  });
}
