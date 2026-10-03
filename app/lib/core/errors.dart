/// 错误分类。播放恢复流程要据此分流：鉴权失败走刷新令牌，
/// 网络失败走退避重试（audio-playback 规格「区分鉴权失败与网络失败」）。
enum DriveErrorKind {
  /// access_token 失效，应刷新后重放
  authExpired,

  /// 授权本身无效（如 errno=-6，scope 不对），应重新授权
  authInvalid,

  /// 限流 / 接口受限，应退避重试
  rateLimited,

  /// 文件或路径不存在
  notFound,

  /// 目录里没有可识别的媒体文件（认领时）
  noMedia,

  /// 网络层失败，应退避重试
  network,

  /// 链接失效（dlink 过期，403/410），应重新解析地址
  linkExpired,

  /// 设备存储不足
  storageFull,

  /// 其他接口错误
  api,
}

/// 网盘与播放链路上的错误。
///
/// [message] 是给日志与排障看的技术描述；面向用户的文案按 [kind] 在界面层
/// 从 l10n 里取（见 features/common/error_text.dart），不在这里拼。
class DriveException implements Exception {
  const DriveException(this.kind, this.message, {this.errno});

  final DriveErrorKind kind;
  final String message;
  final int? errno;

  /// 这一类错误值得自动重试（退避），其余的重试没有意义。
  bool get isRetryable =>
      kind == DriveErrorKind.network ||
      kind == DriveErrorKind.rateLimited ||
      kind == DriveErrorKind.linkExpired;

  /// 这一类错误意味着要动令牌，而不是重试。
  bool get isAuthProblem =>
      kind == DriveErrorKind.authExpired || kind == DriveErrorKind.authInvalid;

  @override
  String toString() => 'DriveException($kind, errno=$errno): $message';

  /// 把百度的 errno 映射成上面的分类。
  static DriveException fromErrno(int errno, {String? context}) {
    final where = context == null ? '' : '（$context）';
    switch (errno) {
      case -6:
        return DriveException(DriveErrorKind.authInvalid,
            'errno=-6：授权无效或 scope 不是 basic,netdisk$where',
            errno: errno,);
      case 111:
        return DriveException(
            DriveErrorKind.authExpired, 'errno=111：access_token 失效$where',
            errno: errno,);
      // -9 是「文件或目录不存在」，-7 是「文件名错误或无权访问」，
      // 都跟令牌无关。之前把 -9 归成 authExpired，结果路径一旦对不上，
      // 就会白刷一次 token、再失败、最后对用户说「授权失效请重新登录」，
      // 把人往完全错误的方向指。
      case -9:
        return DriveException(
            DriveErrorKind.notFound, 'errno=-9：文件或目录不存在$where',
            errno: errno,);
      case -7:
        return DriveException(DriveErrorKind.notFound,
            'errno=-7：文件或目录名错误，或无权访问$where',
            errno: errno,);
      case 31034:
      case 31045:
        return DriveException(
            DriveErrorKind.rateLimited, 'errno=$errno：请求受限$where',
            errno: errno,);
      case 31062:
      case 31066:
        return DriveException(
            DriveErrorKind.notFound, 'errno=$errno：文件不存在$where',
            errno: errno,);
      default:
        return DriveException(
            DriveErrorKind.api, '百度接口返回 errno=$errno$where',
            errno: errno,);
    }
  }

  /// HTTP 状态码到分类的映射，主要服务于 dlink 直连下载。
  static DriveException fromStatus(int status, {String? context}) {
    final where = context == null ? '' : '（$context）';
    if (status == 401) {
      return DriveException(
          DriveErrorKind.authExpired, 'HTTP 401$where',);
    }
    if (status == 403 || status == 410) {
      return DriveException(
          DriveErrorKind.linkExpired, 'HTTP $status：播放地址已失效$where',);
    }
    if (status == 404) {
      return DriveException(DriveErrorKind.notFound, 'HTTP 404$where');
    }
    if (status == 429) {
      return DriveException(DriveErrorKind.rateLimited, 'HTTP 429$where');
    }
    return DriveException(DriveErrorKind.api, 'HTTP $status$where');
  }
}
