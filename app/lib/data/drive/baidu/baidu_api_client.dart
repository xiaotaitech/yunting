import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

import '../../../core/config.dart';
import '../../../core/errors.dart';
import '../../../core/logging.dart';
import '../../auth/auth_repository.dart';

/// 百度网盘 HTTP 客户端。
///
/// 三件事全部收口在这里，别处不再散落：
///   1. 强制注入 `User-Agent: pan.baidu.com`（百度对 Range 请求的硬性要求）
///   2. 令牌过期时自动刷新并重放一次请求
///   3. errno / HTTP 状态码到 [DriveException] 的映射
class BaiduApiClient {
  BaiduApiClient(this._auth, {http.Client? client})
      : _http = client ?? _createClient();

  /// dlink 会 302 跳到 CDN，而 **dart:io 跟随重定向时会丢掉请求 header 里的
  /// User-Agent**，换回它自己的默认值（`Dart/x.y (dart:io)`）。
  ///
  /// 百度对 Range 请求校验 UA：跳转后的请求带着 Dart 的默认 UA 过去，直接 403。
  /// 症状很有迷惑性——完整 GET 一切正常（无 Range 时百度不查 UA），
  /// 只有读 ID3、seek、断点续传这些用 Range 的地方全线失败。
  ///
  /// 所以 UA 必须同时设在 [HttpClient] 上，它才会跟着重定向一起走。
  /// 实测：只设 header → 403；同时设 HttpClient.userAgent → 206。
  static http.Client _createClient() {
    final inner = HttpClient()..userAgent = AppConfig.panUserAgent;
    return IOClient(inner);
  }

  static const _panBase = 'https://pan.baidu.com/rest/2.0';
  static const _pcsBase = 'https://d.pcs.baidu.com/rest/2.0';

  final AuthRepository _auth;
  final http.Client _http;

  Map<String, String> get _headers => const {
        'User-Agent': AppConfig.panUserAgent,
      };

  /// GET 一个返回 JSON 的网盘接口。鉴权失败会自动刷新令牌并重放一次。
  Future<Map<String, dynamic>> getJson(
    String path,
    Map<String, String> query, {
    bool isPcs = false,
  }) async {
    return _withTokenRetry((token) async {
      final uri = Uri.parse('${isPcs ? _pcsBase : _panBase}$path').replace(
        queryParameters: {...query, 'access_token': token},
      );
      final res = await _http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 25));
      Log.d('baidu', 'GET $path -> ${res.statusCode}');
      if (res.statusCode >= 400) {
        throw DriveException.fromStatus(res.statusCode, context: path);
      }
      final decoded = jsonDecode(utf8.decode(res.bodyBytes));
      if (decoded is! Map<String, dynamic>) {
        throw DriveException(DriveErrorKind.api, '接口 $path 返回了非预期结构');
      }
      _throwOnErrno(decoded, path);
      return decoded;
    });
  }

  Future<Map<String, dynamic>> postForm(
    String path,
    Map<String, String> query,
    Map<String, String> form, {
    bool isPcs = false,
  }) async {
    return _withTokenRetry((token) async {
      final uri = Uri.parse('${isPcs ? _pcsBase : _panBase}$path').replace(
        queryParameters: {...query, 'access_token': token},
      );
      final res = await _http
          .post(uri, headers: _headers, body: form)
          .timeout(const Duration(seconds: 30));
      Log.d('baidu', 'POST $path -> ${res.statusCode}');
      if (res.statusCode >= 400) {
        throw DriveException.fromStatus(res.statusCode, context: path);
      }
      final decoded =
          jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      _throwOnErrno(decoded, path);
      return decoded;
    });
  }

  /// 上传一个分片。状态同步文件很小，单片足够。
  Future<Map<String, dynamic>> uploadSlice({
    required String path,
    required String uploadId,
    required int partSeq,
    required Uint8List bytes,
  }) async {
    return _withTokenRetry((token) async {
      final uri = Uri.parse('$_pcsBase/pcs/superfile2').replace(
        queryParameters: {
          'method': 'upload',
          'access_token': token,
          'type': 'tmpfile',
          'path': path,
          'uploadid': uploadId,
          'partseq': '$partSeq',
        },
      );
      final request = http.MultipartRequest('POST', uri)
        ..headers.addAll(_headers)
        ..files.add(http.MultipartFile.fromBytes('file', bytes,
            filename: 'chunk'));
      final streamed = await request.send().timeout(const Duration(seconds: 60));
      final res = await http.Response.fromStream(streamed);
      Log.d('baidu', 'UPLOAD slice $partSeq -> ${res.statusCode}');
      if (res.statusCode >= 400) {
        throw DriveException.fromStatus(res.statusCode, context: 'superfile2');
      }
      return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    });
  }

  /// 直接对 dlink 发起请求。必须带 UA，且 http 包默认会跟随 302
  /// 并在跳转后保留我们设置的 header（audio-playback 规格）。
  Future<http.StreamedResponse> openStream(
    String dlink, {
    String? range,
  }) async {
    return _withTokenRetry((token) async {
      final uri = Uri.parse(_appendToken(dlink, token));
      final req = http.Request('GET', uri)
        ..followRedirects = true
        ..maxRedirects = 5
        ..headers.addAll(_headers);
      if (range != null) req.headers['Range'] = range;
      final res = await _http.send(req).timeout(const Duration(seconds: 30));
      Log.d('baidu', 'STREAM ${Log.redactUrl(dlink)} -> ${res.statusCode}');
      if (res.statusCode >= 400) {
        throw DriveException.fromStatus(res.statusCode, context: 'dlink');
      }
      return res;
    });
  }

  /// 读取文件的一段字节（ID3 解析、断点续传都靠它）。
  Future<Uint8List> readRange(String dlink, int start, int endInclusive) async {
    final res = await openStream(dlink, range: 'bytes=$start-$endInclusive');
    final builder = BytesBuilder(copy: false);
    await for (final chunk in res.stream) {
      builder.add(chunk);
    }
    return builder.takeBytes();
  }

  static final _tokenParam = RegExp(r'access_token=[^&]*');

  /// 拼上当前令牌；地址里已有旧令牌时**替换**而不是追加。
  ///
  /// 两个原因：`resolveMedia` 返回的地址本就带了 access_token，下载与 Range
  /// 读取还会再走一遍这里——单纯追加会拼出两个同名参数；而更要紧的是，
  /// 令牌过期后的刷新重放必须让新令牌真正生效，光跳过就等于用旧令牌重试。
  String _appendToken(String dlink, String token) {
    final encoded = Uri.encodeComponent(token);
    if (_tokenParam.hasMatch(dlink)) {
      return dlink.replaceAll(_tokenParam, 'access_token=$encoded');
    }
    return '$dlink${dlink.contains('?') ? '&' : '?'}access_token=$encoded';
  }

  /// 给 URL 拼上当前令牌，供播放器直接使用。
  Future<String> authorizedUrl(String dlink) async =>
      _appendToken(dlink, await _auth.accessToken());

  void _throwOnErrno(Map<String, dynamic> json, String path) {
    final errno = (json['errno'] as num?)?.toInt() ?? 0;
    if (errno != 0) throw DriveException.fromErrno(errno, context: path);
    final errorCode = json['error_code'];
    if (errorCode != null && errorCode != 0) {
      throw DriveException(DriveErrorKind.api,
          '接口 $path 返回 error_code=$errorCode ${json['error_msg'] ?? ''}');
    }
  }

  /// 鉴权失败时刷新令牌并重放一次；其余错误原样抛给调用方分流处理。
  Future<T> _withTokenRetry<T>(Future<T> Function(String token) action) async {
    var token = await _auth.accessToken();
    try {
      return await action(token);
    } on DriveException catch (e) {
      if (e.kind != DriveErrorKind.authExpired) rethrow;
      Log.d('baidu', '令牌过期，刷新后重放请求');
      token = (await _auth.refresh()).accessToken;
      return action(token);
    }
  }

  void dispose() => _http.close();
}
