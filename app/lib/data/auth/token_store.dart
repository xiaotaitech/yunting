import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 令牌必须存平台安全存储（Android Keystore / iOS Keychain），
/// 不得明文写入普通配置文件（netdisk-auth 规格「凭证安全存储」）。
class AuthToken {
  const AuthToken({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    required this.scope,
  });

  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;
  final String scope;

  /// 提前 5 分钟视为过期，避免请求正好卡在过期边界上。
  bool get isExpiring =>
      DateTime.now().isAfter(expiresAt.subtract(const Duration(minutes: 5)));

  Map<String, dynamic> toJson() => {
        'access_token': accessToken,
        'refresh_token': refreshToken,
        'expires_at': expiresAt.toIso8601String(),
        'scope': scope,
      };

  static AuthToken fromJson(Map<String, dynamic> json) => AuthToken(
        accessToken: json['access_token'] as String,
        refreshToken: json['refresh_token'] as String? ?? '',
        expiresAt: DateTime.parse(json['expires_at'] as String),
        scope: json['scope'] as String? ?? '',
      );

  /// 由代理返回的 token 响应构造，expires_in 是秒数。
  static AuthToken fromResponse(Map<String, dynamic> json) => AuthToken(
        accessToken: json['access_token'] as String,
        refreshToken: json['refresh_token'] as String? ?? '',
        expiresAt: DateTime.now()
            .add(Duration(seconds: (json['expires_in'] as num?)?.toInt() ?? 0)),
        scope: json['scope'] as String? ?? '',
      );
}

class TokenStore {
  TokenStore([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'baidu_auth_token';
  static const _deviceIdKey = 'device_id';

  final FlutterSecureStorage _storage;

  Future<AuthToken?> read() async {
    final raw = await _storage.read(key: _key);
    if (raw == null) return null;
    try {
      return AuthToken.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on Object catch (_) {
      // 存储损坏时当作未登录，而不是让应用起不来。
      await clear();
      return null;
    }
  }

  Future<void> write(AuthToken token) =>
      _storage.write(key: _key, value: jsonEncode(token.toJson()));

  Future<void> clear() => _storage.delete(key: _key);

  /// 设备标识用于同步时的 LWW 合并（listening-progress 规格）。
  Future<String> deviceId() async {
    final existing = await _storage.read(key: _deviceIdKey);
    if (existing != null) return existing;
    final generated =
        'dev-${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}';
    await _storage.write(key: _deviceIdKey, value: generated);
    return generated;
  }
}
