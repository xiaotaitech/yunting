// 验证假设：dart:io 跟随 302 重定向时，是否保留了我们设的 User-Agent。
//
// 背景：App 读 ID3 时对 dlink 发 Range 请求，全部 403；
// 而同样的请求用 Node 发（带 pan.baidu.com 的 UA）是 206。
// Node 那边已经证明「Range + 浏览器 UA」必 403，所以怀疑
// dart:io 在重定向后换回了自己的默认 UA（Dart/x.y (dart:io)）。
//
// 跑法：把 dlink 写进一个文件，然后
//   dart run tool/probe_redirect_ua.dart <该文件路径>
// （不直接传 URL：dlink 里有大量 & ，在 Windows cmd 下会被当成命令分隔符）
import 'dart:io';

const panUa = 'pan.baidu.com';

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln('用法：dart run tool/probe_redirect_ua.dart <存放 dlink 的文件>');
    exit(1);
  }
  final raw = File(args.first).readAsStringSync().trim();
  final url = Uri.parse(raw);

  await attempt('followRedirects=true（App 现在的做法）',
      url: url, followRedirects: true, setClientUserAgent: false);

  await attempt('followRedirects=true + HttpClient.userAgent 也设成 pan.baidu.com',
      url: url, followRedirects: true, setClientUserAgent: true);

  await attempt('followRedirects=false（手动看第一跳）',
      url: url, followRedirects: false, setClientUserAgent: false);

  await manualFollow(url);
}

Future<void> attempt(
  String label, {
  required Uri url,
  required bool followRedirects,
  required bool setClientUserAgent,
}) async {
  final client = HttpClient();
  if (setClientUserAgent) client.userAgent = panUa;
  try {
    final req = await client.getUrl(url);
    req.followRedirects = followRedirects;
    req.maxRedirects = 5;
    req.headers.set(HttpHeaders.userAgentHeader, panUa);
    req.headers.set(HttpHeaders.rangeHeader, 'bytes=0-65535');
    final res = await req.close();
    final body = await consume(res);
    print(
        '  ${res.statusCode == 206 || res.statusCode == 302 ? "OK  " : "FAIL"} $label');
    print('       HTTP ${res.statusCode} · 收到 $body 字节'
        '${res.headers.value('content-range') != null ? " · ${res.headers.value('content-range')}" : ""}');
  } catch (e) {
    print('  FAIL $label\n       异常：$e');
  } finally {
    client.close(force: true);
  }
}

/// 手动跟随重定向，每一跳都自己把 header 重新带上。
Future<void> manualFollow(Uri url) async {
  final client = HttpClient();
  try {
    var target = url;
    for (var hop = 0; hop < 5; hop++) {
      final req = await client.getUrl(target);
      req.followRedirects = false;
      req.headers.set(HttpHeaders.userAgentHeader, panUa);
      req.headers.set(HttpHeaders.rangeHeader, 'bytes=0-65535');
      final res = await req.close();

      if (res.isRedirect) {
        final loc = res.headers.value(HttpHeaders.locationHeader);
        await res.drain<void>();
        if (loc == null) break;
        target = target.resolve(loc);
        continue;
      }
      final body = await consume(res);
      print('  ${res.statusCode == 206 ? "OK  " : "FAIL"} 手动跟随重定向，每跳都重设 UA');
      print('       HTTP ${res.statusCode} · 收到 $body 字节 · 跳转 $hop 次');
      return;
    }
    print('  FAIL 手动跟随重定向 —— 跳转次数超限');
  } catch (e) {
    print('  FAIL 手动跟随重定向\n       异常：$e');
  } finally {
    client.close(force: true);
  }
}

Future<int> consume(HttpClientResponse res) async {
  var n = 0;
  await for (final chunk in res) {
    n += chunk.length;
  }
  return n;
}
