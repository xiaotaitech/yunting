import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// 一个发布版本：版本号、说明、安装包下载地址（按优先顺序，前一个失败换下一个）与发布页地址。
class AppRelease {
  const AppRelease({
    required this.version,
    required this.notes,
    required this.apkUrls,
    required this.pageUrl,
  });

  final String version;
  final String notes;
  final List<String> apkUrls;
  final String pageUrl;

  AppRelease copyWith({List<String>? apkUrls}) => AppRelease(
        version: version,
        notes: notes,
        apkUrls: apkUrls ?? this.apkUrls,
        pageUrl: pageUrl,
      );
}

class UpdateException implements Exception {
  const UpdateException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// 检查新版本。这是应用自身的分发渠道，与网盘内容无关。
///
/// 同时查 GitHub Releases 和 jsDelivr 上的 latest.json（国内 api.github.com 常不通）：
/// 哪个能用用哪个，两个都能用且版本一致时下载地址合并去重。
/// latest.json 由发布工作流写到仓库的 dist 分支（.github/workflows/release.yml）。
class AppUpdater {
  AppUpdater({
    required http.Client client,
    required this.repo,
    this.apkName = defaultApkName,
    this.api = 'https://api.github.com',
    List<String>? mirrors,
  })  : _client = client,
        mirrors = mirrors ?? mirrorsFor(repo);

  static const defaultApkName = 'yunting.apk';
  static const _timeout = Duration(seconds: 15);

  final http.Client _client;
  final String repo;
  final String apkName;
  final String api;
  final List<String> mirrors;

  /// 发布页（最新版本）。
  String get latestPage => 'https://github.com/$repo/releases/latest';

  Future<AppRelease> latest() async {
    final gh = _capture(_github());
    final mirror = _capture(_mirror());
    final g = await gh;
    final m = (await mirror).value;
    final r = g.value;
    if (r == null && m != null) return m;
    if (r == null) throw g.error!;
    if (m != null && m.version == r.version) {
      return r.copyWith(apkUrls: {...m.apkUrls, ...r.apkUrls}.toList());
    }
    return r;
  }

  Future<AppRelease> _github() async {
    final res = await _client.get(
      Uri.parse('$api/repos/$repo/releases/latest'),
      headers: {
        'Accept': 'application/vnd.github+json',
        'User-Agent': 'Yunting',
      },
    ).timeout(_timeout);
    // 仓库还没有任何 Release（或仓库不存在）时 GitHub 返回 404
    if (res.statusCode == 404) throw const UpdateException('还没有发布版本');
    if (res.statusCode != 200) {
      throw UpdateException('HTTP ${res.statusCode}');
    }
    final j = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final assets =
        (j['assets'] as List? ?? const []).cast<Map<String, dynamic>>();
    final apk = assets.where((a) => a['name'] == apkName).firstOrNull;
    return AppRelease(
      version: _stripV(j['tag_name'] as String),
      notes: cleanNotes(j['body'] as String? ?? ''),
      apkUrls: [if (apk != null) apk['browser_download_url'] as String],
      pageUrl: j['html_url'] as String? ?? latestPage,
    );
  }

  /// 依次尝试各镜像的 latest.json，第一个成功的为准。
  Future<AppRelease> _mirror() async {
    Object last = const UpdateException('没有可用的镜像');
    for (final url in mirrors) {
      try {
        final res = await _client.get(Uri.parse(url),
            headers: {'User-Agent': 'Yunting'}).timeout(_timeout);
        if (res.statusCode != 200) {
          last = UpdateException('HTTP ${res.statusCode}');
          continue;
        }
        final j =
            jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
        return AppRelease(
          version: _stripV(j['version'] as String),
          notes: cleanNotes(j['notes'] as String? ?? ''),
          apkUrls: (j['apk'] as List? ?? const []).cast<String>(),
          pageUrl: j['page'] as String? ?? latestPage,
        );
      } catch (e) {
        last = e;
      }
    }
    throw last;
  }

  /// jsDelivr 的两个入口加 raw.githubusercontent（与 api.github.com 不同域名，有时一个通一个不通）。
  static List<String> mirrorsFor(String repo) => [
        'https://cdn.jsdelivr.net/gh/$repo@dist/latest.json',
        'https://fastly.jsdelivr.net/gh/$repo@dist/latest.json',
        'https://raw.githubusercontent.com/$repo/dist/latest.json',
      ];

  /// 更新说明给应用内显示：去掉 Markdown 标题行、粗体标记，
  /// 以及发布页上"下载 yunting.apk"之类只对网页有用的说明。
  static String cleanNotes(String body) => body
      .split('\n')
      .where((l) => !l.trimLeft().startsWith('#') && !l.contains('.apk'))
      .map((l) => l.replaceAll('**', ''))
      .join('\n')
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .trim();

  /// latest 是否比 current 新：按数字段比较（0.10.0 > 0.9.3），非数字后缀忽略。
  static bool isNewer(String latest, String current) {
    // "+构建号" 不参与比较
    List<int> parts(String v) => _stripV(v)
        .split('+')
        .first
        .split(RegExp(r'[.\-]'))
        .map((s) => int.tryParse(RegExp(r'^\d*').stringMatch(s) ?? '') ?? 0)
        .toList();
    final a = parts(latest);
    final b = parts(current);
    for (var i = 0; i < (a.length > b.length ? a.length : b.length); i++) {
      final x = i < a.length ? a[i] : 0;
      final y = i < b.length ? b[i] : 0;
      if (x != y) return x > y;
    }
    return false;
  }

  static String _stripV(String v) => v.startsWith('v') ? v.substring(1) : v;
}

class _Result<T> {
  _Result(this.value, this.error);
  final T? value;
  final Object? error;
}

Future<_Result<T>> _capture<T>(Future<T> f) =>
    f.then((v) => _Result<T>(v, null),
        onError: (Object e) => _Result<T>(null, e));
