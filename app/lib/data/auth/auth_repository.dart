import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:yun_audiobook/core/config.dart';
import 'package:yun_audiobook/core/errors.dart';
import 'package:yun_audiobook/core/logging.dart';
import 'package:yun_audiobook/data/auth/token_store.dart';

/// 设备码授权的进行中状态。设备码流程不需要回调域名，
/// 是移动端与本地联调最省事的路径。
class DeviceAuthSession {
  const DeviceAuthSession({
    required this.deviceCode,
    required this.userCode,
    required this.verificationUrl,
    required this.qrcodeUrl,
    required this.expiresIn,
    required this.interval,
  });

  final String deviceCode;
  final String userCode;
  final String verificationUrl;
  final String? qrcodeUrl;
  final int expiresIn;
  final int interval;
}

enum AuthState { unknown, signedOut, signedIn }

/// 授权仓库。所有涉及 AppSecret 的动作都交给 OAuth 代理完成，
/// 客户端只持有 AppKey（design.md D2）。
class AuthRepository {
  AuthRepository({TokenStore? store, http.Client? client, String? proxyBase})
      : _store = store ?? TokenStore(),
        _http = client ?? http.Client(),
        _proxyBase = proxyBase ?? AppConfig.oauthProxyBase;

  final TokenStore _store;
  final http.Client _http;

  /// OAuth 代理基址。可注入，测试里换成假代理才能真正验证刷新逻辑。
  final String _proxyBase;

  AuthToken? _cached;

  /// 并发刷新去重：多个请求同时撞上过期时，只发起一次刷新，
  /// 其余等待同一个 Future（netdisk-auth 规格「并发请求下的刷新」）。
  Future<AuthToken>? _refreshInFlight;

  final _stateController = StreamController<AuthState>.broadcast();
  Stream<AuthState> get stateChanges => _stateController.stream;

  AuthState _state = AuthState.unknown;

  /// 当前授权状态的同步快照。bootstrap 阶段已经 restore 过，
  /// UI 直接读它即可，不必在 build 里反复触发异步恢复。
  AuthState get currentState => _state;

  void _emit(AuthState state) {
    _state = state;
    if (!_stateController.isClosed) _stateController.add(state);
  }

  Uri _proxy(String path) => Uri.parse('$_proxyBase$path');

  Future<AuthState> restore() async {
    _cached = await _store.read();
    final state = _cached == null ? AuthState.signedOut : AuthState.signedIn;
    _emit(state);
    return state;
  }

  Future<String> deviceId() => _store.deviceId();

  /// 返回当前可用的 access_token，必要时先刷新。
  Future<String> accessToken() async {
    final token = _cached ??= await _store.read();
    if (token == null) {
      throw const DriveException(DriveErrorKind.authInvalid, '尚未授权百度网盘');
    }
    if (!token.isExpiring) return token.accessToken;
    final refreshed = await refresh();
    return refreshed.accessToken;
  }

  /// 刷新令牌。同一时刻只会有一次真正的网络请求在飞。
  Future<AuthToken> refresh() {
    return _refreshInFlight ??= _doRefresh().whenComplete(() {
      _refreshInFlight = null;
    });
  }

  Future<AuthToken> _doRefresh() async {
    final current = _cached ?? await _store.read();
    if (current == null || current.refreshToken.isEmpty) {
      await signOut();
      throw const DriveException(DriveErrorKind.authInvalid, '缺少 refresh_token，需要重新授权');
    }
    final res = await _post('/oauth/refresh', {'refresh_token': current.refreshToken});
    if (res == null) {
      // refresh_token 本身失效：清凭证、跳登录，但本地书架与进度必须保留
      // （netdisk-auth 规格「refresh_token 失效」）。
      await signOut();
      throw const DriveException(DriveErrorKind.authInvalid, 'refresh_token 已失效，请重新授权');
    }
    final token = AuthToken.fromResponse(res);
    // 百度刷新响应里可能不带新的 refresh_token，此时沿用旧的。
    final merged = token.refreshToken.isEmpty
        ? AuthToken(
            accessToken: token.accessToken,
            refreshToken: current.refreshToken,
            expiresAt: token.expiresAt,
            scope: token.scope,
          )
        : token;
    _cached = merged;
    await _store.write(merged);
    Log.d('auth', '令牌已刷新 access_token=${Log.redact(merged.accessToken)}');
    return merged;
  }

  // ---------------------------------------------------------- 设备码授权

  Future<DeviceAuthSession> startDeviceAuth() async {
    final res = await _post('/oauth/device/start', const {});
    if (res == null) {
      throw const DriveException(DriveErrorKind.api, 'OAuth 代理未能发起设备码授权');
    }
    return DeviceAuthSession(
      deviceCode: res['device_code'] as String,
      userCode: res['user_code'] as String,
      verificationUrl: res['verification_url'] as String,
      qrcodeUrl: res['qrcode_url'] as String?,
      expiresIn: (res['expires_in'] as num?)?.toInt() ?? 300,
      interval: (res['interval'] as num?)?.toInt() ?? 5,
    );
  }

  /// 轮询直到用户完成授权。用户拒绝或超时会抛出可展示的错误。
  Future<AuthToken> awaitDeviceAuth(
    DeviceAuthSession session, {
    void Function()? onTick,
  }) async {
    final deadline = DateTime.now().add(Duration(seconds: session.expiresIn));
    var interval = Duration(seconds: session.interval);

    while (DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(interval);
      onTick?.call();
      final res = await _post('/oauth/device/poll', {'device_code': session.deviceCode});
      if (res == null) continue;
      switch (res['status'] as String?) {
        case 'ok':
          final token = AuthToken.fromResponse(res);
          _cached = token;
          await _store.write(token);
          _emit(AuthState.signedIn);
          Log.d('auth', '授权成功 scope=${token.scope}');
          return token;
        case 'slow_down':
          interval += const Duration(seconds: 2);
        case 'denied':
          throw const DriveException(DriveErrorKind.authInvalid, '你在授权页拒绝了本次授权');
        case 'expired':
          throw const DriveException(DriveErrorKind.authInvalid, '授权码已过期，请重新发起授权');
        default:
          break; // authorization_pending：继续等
      }
    }
    throw const DriveException(DriveErrorKind.network, '等待授权超时，请重新发起');
  }

  /// 退出登录。默认保留本地书架与进度——用户退出登录不等于要丢数据。
  Future<void> signOut({bool keepLocalData = true}) async {
    _cached = null;
    await _store.clear();
    _emit(AuthState.signedOut);
    Log.d('auth', '已退出登录（本地数据${keepLocalData ? '保留' : '清除'}）');
  }

  Future<Map<String, dynamic>?> _post(String path, Map<String, dynamic> body) async {
    if (_proxyBase.isEmpty) {
      throw const DriveException(DriveErrorKind.api, 'OAuth 代理地址未配置');
    }
    try {
      final res = await _http
          .post(_proxy(path),
              headers: const {'Content-Type': 'application/json'},
              body: jsonEncode(body),)
          .timeout(const Duration(seconds: 20));
      // 只记录路径与状态码，绝不记录响应体（含令牌）。
      Log.d('auth', 'POST $path -> ${res.statusCode}');
      if (res.statusCode == 401) return null;
      if (res.statusCode >= 400) {
        // 代理会把百度的失败原因放在 message 里（例如 AppKey 配错时的
        // "invalid_client: unknown client id"）。只报状态码等于把唯一有用的
        // 线索丢掉，用户看到「HTTP 502」根本无从排查。
        throw DriveException(DriveErrorKind.api, _proxyErrorMessage(res));
      }
      return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    } on DriveException {
      rethrow;
    } on Object catch (e) {
      throw DriveException(
          DriveErrorKind.network, '无法连接 OAuth 代理（$_proxyBase）：$e',);
    }
  }

  /// 从代理的错误响应里取出可读原因，取不到才退回状态码。
  /// 响应体只含错误信息，不含令牌，可以安全展示。
  static String _proxyErrorMessage(http.Response res) {
    try {
      final body = jsonDecode(utf8.decode(res.bodyBytes));
      if (body is Map) {
        final message = body['message'] ?? body['error'];
        if (message is String && message.isNotEmpty) {
          return 'OAuth 代理：$message';
        }
      }
    } on Object catch (_) {
      // 响应不是 JSON，退回状态码
    }
    return 'OAuth 代理返回 HTTP ${res.statusCode}';
  }

  void dispose() {
    unawaited(_stateController.close());
    _http.close();
  }
}
