/// 应用配置。AppKey 与 OAuth 代理地址通过 --dart-define 注入，
/// 不硬编码进源码（tasks.md 1.6）。AppSecret 永远不会出现在客户端。
class AppConfig {
  /// 百度网盘开放平台的 AppKey（client_id）。仅 AppKey，绝无 SecretKey。
  static const String baiduAppKey =
      String.fromEnvironment('BAIDU_APP_KEY');

  /// OAuth 代理基址，例如 http://192.168.1.10:8787
  static const String oauthProxyBase =
      String.fromEnvironment('OAUTH_PROXY_BASE');

  /// 演示模式：用本地假数据源替代百度网盘，跳过授权。
  ///
  /// 目的是让人在拿到 AppKey 之前就能把完整流程走一遍——书架、章节、
  /// 真实播放、进度记忆、倍速、睡眠定时都是真的在跑，只是音频来自本地生成。
  /// 它同时也是 `CloudDriveSource` 抽象（design.md D9）的第一个非百度实现，
  /// 顺带证明了那层抽象确实是可替换的。
  static const bool demoMode =
      bool.fromEnvironment('DEMO_MODE');

  /// 网盘中存放同步状态的应用专属目录（design.md D5）。
  static const String appFolderName = 'yun_audiobook';
  static String get syncDir => '/apps/$appFolderName';
  static String get syncFilePath => '$syncDir/library.json';

  /// 百度对 dlink 的强制要求：请求必须带这个 User-Agent，
  /// 且 302 跳转之后仍要保留（audio-playback 规格）。
  static const String panUserAgent = 'pan.baidu.com';

  static const String scope = 'basic,netdisk';

  /// 本项目的开源仓库，同时也是发布渠道：应用内检查更新读它的 Releases 与 dist 分支的 latest.json
  /// （app-distribution 规格）。fork 后自己发版时，发布工作流会把仓库名传进来。
  static const String releaseRepo = String.fromEnvironment('RELEASE_REPO',
      defaultValue: 'xiaotaitech/yunting',);

  static const List<String> audioExtensions = [
    'mp3', 'm4a', 'm4b', 'aac', 'flac', 'ogg', 'wav', 'wma', 'opus',
  ];

  static const List<String> coverFileNames = [
    'cover', 'folder', 'front', 'album', 'poster', 'default',
  ];

  static const List<String> imageExtensions = ['jpg', 'jpeg', 'png', 'webp'];

  static bool get isConfigured =>
      demoMode || (baiduAppKey.isNotEmpty && oauthProxyBase.isNotEmpty);

  /// 未配置时给出可执行的指引，而不是让应用静默失败。
  static const String setupHint = r'''
应用尚未配置百度网盘凭证。

1. 到 https://pan.baidu.com/union/console 登录百度账号 → 实名认证 → 创建应用（选软件类别）
   审核通过后在应用详情页取得 AppKey 与 SecretKey
2. 在 tools/.env 填入这两个值，运行 `npm run proxy` 启动 OAuth 代理
3. 用下面的方式重新构建 App（把 IP 换成运行代理的那台机器的局域网地址）：

   flutter run \
     --dart-define=BAIDU_APP_KEY=你的AppKey \
     --dart-define=OAUTH_PROXY_BASE=http://192.168.x.x:8787

还没申请到 AppKey？可以先用演示模式把完整流程走一遍：

   flutter run --dart-define=DEMO_MODE=true
''';
}
