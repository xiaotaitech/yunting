/// 网页授权登录的接入点（in-app-baidu-login；多网盘预留）。
///
/// 「在网页里登录、授权后回跳带 code、再经代理换令牌」是主流网盘开放平台
/// 共同的形态。一个网盘实现这个接口，App 内登录页（WebLoginPage）就能
/// 直接用它，不用再写一遍 WebView、回跳拦截与返回键处理。
/// 百度网盘的实现是 AuthRepository；接入步骤见 README「接入其他网盘」。
library;

abstract interface class WebOAuthLogin {
  /// 授权页地址（手机版页面）。AppSecret 不进客户端：地址与换令牌都走代理。
  Future<Uri> authorizeUrl();

  /// 识别授权完成后的回跳地址；不是回跳返回 null（WebView 照常导航）。
  OAuthCallback? parseCallback(Uri url);

  /// 授权码直接显示在页面上、没有回跳时，从页面读出 code 的 JS 表达式：
  /// 返回 code 字符串，读不到返回空串。只在 [isCodePage] 为真的页面上执行。
  String? get codeScript;

  /// 是否可能是显示授权码的页面（决定要不要执行 [codeScript]）。
  bool isCodePage(Uri url);

  /// 页面加载完后注入的 CSS，用来藏掉授权页里与 App 顶栏重复的内容；不需要返回 null。
  String? get pageCss;

  /// 用回跳带回的 code 换令牌并保存，完成后视为已登录。
  Future<void> exchangeCode(String code);
}

/// 回跳结果：拿到 code，或用户拒绝。
sealed class OAuthCallback {
  const OAuthCallback();
}

final class OAuthCode extends OAuthCallback {
  const OAuthCode(this.code);
  final String code;
}

final class OAuthDenied extends OAuthCallback {
  const OAuthDenied(this.reason);
  final String reason;
}
