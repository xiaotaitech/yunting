import 'package:flutter/foundation.dart';

/// 日志脱敏（netdisk-auth 规格「日志脱敏」）。
/// 令牌与 dlink 绝不允许完整出现在日志里。
class Log {
  static String redact(String? value) {
    if (value == null || value.isEmpty) return '';
    if (value.length <= 8) return '***';
    return '${value.substring(0, 4)}***${value.substring(value.length - 4)}';
  }

  static final _tokenParam = RegExp('(access_token=)[^&]+', caseSensitive: false);
  static final _signParam = RegExp('(sign=)[^&]+', caseSensitive: false);

  static String redactUrl(String url) => url
      .replaceAllMapped(_tokenParam, (m) => '${m[1]}***')
      .replaceAllMapped(_signParam, (m) => '${m[1]}***');

  static void d(String tag, String message) {
    if (kDebugMode) debugPrint('[$tag] $message');
  }

  static void e(String tag, String message, [Object? error]) {
    debugPrint('[$tag] ERROR $message${error == null ? '' : ' :: $error'}');
  }
}
