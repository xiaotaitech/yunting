import 'dart:io';

import 'package:flutter/services.dart';

/// Android 原生的下载与安装（MainActivity 里的 `yun/app` 通道）。
///
/// 下载交给系统下载管理器：通知栏有进度，退到后台也不中断，
/// 完成后自动打开安装界面；缺少"安装未知应用"权限时先去授权，回来自动继续。
class AppInstaller {
  static const _channel = MethodChannel('yun/app');

  /// 只有 Android 能应用内更新；iOS 不允许侧载。
  static bool get supported => Platform.isAndroid;

  static String? _version;

  /// 当前安装的版本号（versionName）。
  static Future<String> version() async {
    if (_version != null) return _version!;
    if (!supported) return _version = '';
    try {
      _version = await _channel.invokeMethod<String>('versionName') ?? '';
    } on PlatformException {
      _version = '';
    } on MissingPluginException {
      _version = '';
    }
    return _version!;
  }

  /// 按顺序尝试 urls 下载安装包，一个失败换下一个。
  static Future<void> download(List<String> urls, String version) =>
      _channel.invokeMethod('download', {'urls': urls, 'version': version});
}
