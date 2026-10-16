import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:yun_audiobook/core/logging.dart';
import 'package:yun_audiobook/data/auth/web_oauth_login.dart';
import 'package:yun_audiobook/features/common/widgets/empty_state.dart';
import 'package:yun_audiobook/l10n/l10n.dart';

/// App 内的网盘登录授权页（in-app-baidu-login）。
///
/// 在 WebView 里打开网盘的手机版授权页，用户在这里输账号密码或短信登录，
/// 点「授权」后网盘跳到回跳地址——在那一刻拦下来，带着 code 或拒绝原因
/// 返回上一页。全程不离开 App，也不用记用户码。
///
/// 与具体网盘无关：认哪个地址是回跳由 [WebOAuthLogin.parseCallback] 决定。
/// 只放行 http(s)：页面里唤起网盘 App 的 scheme（baiduboxapp:// 之类）
/// 一律拦掉，免得被带出去。
class WebLoginPage extends StatefulWidget {
  const WebLoginPage({
    required this.login,
    required this.authorizeUrl,
    required this.title,
    super.key,
  });

  final WebOAuthLogin login;
  final Uri authorizeUrl;
  final String title;

  /// 打开登录页，返回回跳结果；用户中途关掉返回 null。
  static Future<OAuthCallback?> open(
    BuildContext context, {
    required WebOAuthLogin login,
    required Uri authorizeUrl,
    required String title,
  }) =>
      Navigator.of(context).push<OAuthCallback>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => WebLoginPage(
            login: login,
            authorizeUrl: authorizeUrl,
            title: title,
          ),
        ),
      );

  @override
  State<WebLoginPage> createState() => _WebLoginPageState();
}

class _WebLoginPageState extends State<WebLoginPage> {
  late final WebViewController _web;
  int _progress = 0;
  bool _done = false;

  /// 主页面加载失败的原因。不用 WebView 自带的英文报错页。
  String? _error;

  @override
  void initState() {
    super.initState();
    // 平台调用按发出顺序执行，不必逐个 await
    _web = WebViewController();
    unawaited(_web.setJavaScriptMode(JavaScriptMode.unrestricted));
    unawaited(
      _web.setNavigationDelegate(
        NavigationDelegate(
          onProgress: (p) {
            if (mounted) setState(() => _progress = p);
          },
          onPageFinished: (url) {
            final uri = Uri.tryParse(url);
            if (uri != null) unawaited(_readCodeFromPage(uri));
            final css = widget.login.pageCss;
            if (css == null) return;
            final style = jsonEncode(css);
            unawaited(_web.runJavaScript(
              "var s = document.createElement('style'); "
              's.textContent = $style; document.head.appendChild(s);',
            ));
          },
          onNavigationRequest: (request) {
            final uri = Uri.tryParse(request.url);
            if (uri == null) return NavigationDecision.prevent;
            final callback = widget.login.parseCallback(uri);
            if (callback != null) {
              _finish(callback);
              return NavigationDecision.prevent;
            }
            return uri.scheme == 'http' || uri.scheme == 'https'
                ? NavigationDecision.navigate
                : NavigationDecision.prevent;
          },
          // 服务端 302 到回跳地址时不一定经过 onNavigationRequest，这里兜底
          onUrlChange: (change) {
            final uri = Uri.tryParse(change.url ?? '');
            final callback =
                uri == null ? null : widget.login.parseCallback(uri);
            if (callback != null) _finish(callback);
          },
          onWebResourceError: (error) {
            // 图片、统计脚本之类的子资源失败不影响登录，只管主页面
            if (error.isForMainFrame != true || !mounted) return;
            setState(() => _error = error.description);
          },
        ),
      ),
    );
    unawaited(_web.loadRequest(widget.authorizeUrl));
  }

  /// 授权码显示在页面上而没有回跳时，从页面读出来，当作回跳处理。
  Future<void> _readCodeFromPage(Uri url) async {
    final script = widget.login.codeScript;
    if (script == null || !widget.login.isCodePage(url)) return;
    // 授权码可能由页面脚本在加载完后才填进去，读不到就隔一会儿再试
    for (var i = 0; i < 6 && !_done && mounted; i++) {
      try {
        final result = await _web.runJavaScriptReturningResult(script);
        // Android 返回的字符串结果带 JSON 引号
        final code = result is String ? result.replaceAll('"', '') : '';
        if (code.isNotEmpty) return _finish(OAuthCode(code));
      } on Object catch (e) {
        Log.e('auth', '读取页面上的授权码失败', e);
      }
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
  }

  void _finish(OAuthCallback callback) {
    if (_done || !mounted) return;
    _done = true;
    Navigator.of(context).pop(callback);
  }

  Future<void> _retry() async {
    setState(() => _error = null);
    await _web.reload();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return PopScope(
      // 返回键先在网页里后退（比如从短信登录退回账号密码），退到头才关页面
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        if (_error == null && await _web.canGoBack()) {
          await _web.goBack();
        } else {
          navigator.pop();
        }
      },
      child: Scaffold(
        // 弹键盘时不缩 WebView：百度登录页的脚本在输入框聚焦 0.5 秒后只要页面高度
        // 一变就判定键盘已收起并让输入框失焦，而 Flutter 逐帧缩放 WebView 会撞上，
        // 结果键盘弹出即收回。输入框都在页面上半部分，不会被键盘挡住。
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          leading: IconButton(
            tooltip: l.actionCancel,
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(widget.title),
          bottom: _progress < 100 && _error == null
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(2),
                  child: LinearProgressIndicator(
                    value: _progress == 0 ? null : _progress / 100,
                    minHeight: 2,
                  ),
                )
              : null,
        ),
        body: _error != null
            ? EmptyState(
                icon: Icons.cloud_off_outlined,
                title: l.loginWebFailed,
                description: l.loginWebFailedHint(_error!),
                action: FilledButton(
                  onPressed: _retry,
                  child: Text(l.actionRetry),
                ),
              )
            : WebViewWidget(controller: _web),
      ),
    );
  }
}
