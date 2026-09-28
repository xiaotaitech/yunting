import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:yun_audiobook/update/app_updater.dart';

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

  http.Response json(Object o, [int status = 200]) =>
      http.Response.bytes(utf8.encode(jsonEncode(o)), status,
          headers: {'content-type': 'application/json; charset=utf-8'});

  final ghRelease = {
    'tag_name': 'v0.3.0',
    'body': '更新说明',
    'html_url': 'https://gh/page',
    'assets': [
      {
        'name': 'yunting-v0.3.0.apk',
        'browser_download_url': 'https://x/yunting-v0.3.0.apk'
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

  AppUpdater updater(http.Response Function(Uri) handler,
          {List<String> mirrors = const ['https://m/latest.json']}) =>
      AppUpdater(
        client: MockClient((req) async => handler(req.url)),
        repo: 'o/r',
        api: 'https://api',
        mirrors: mirrors,
      );

  test('取 GitHub 最新 Release 中固定名称的安装包', () async {
    final r = await updater((u) => u.path == '/repos/o/r/releases/latest'
        ? json(ghRelease)
        : json({}, 404)).latest();
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
        (u) => u.host == 'api' ? json(ghRelease) : json(mirrorJson)).latest();
    expect(r.pageUrl, 'https://gh/page');
    expect(r.apkUrls, ['https://cdn/yunting.apk', 'https://x/yunting.apk']);
  });

  test('还没有发布版本时明确提示', () async {
    expect(
      updater((_) => json({}, 404)).latest(),
      throwsA(isA<UpdateException>()
          .having((e) => e.message, 'message', '还没有发布版本')),
    );
  });
}
