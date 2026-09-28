## Why

云听书现在只能靠 `adb install` 或手动拷 APK 安装，发了新版本用户根本不知道；每换一次版本都得重新口头交代「去哪下、手机拦截了怎么点」。release 包一直用 debug 签名，不同机器打出来的包互相不能覆盖升级，谈不上分发。

设置页越堆越长：播放开关、离线、同步、隐私说明、诊断信息、退出登录平铺在一起，没有分组。应用还顶着 Flutter 的默认图标，桌面、通知栏、启动页都认不出是云听书。

## What Changes

- 新增 `app-distribution`：启动后静默检查新版本（同一版本只自动提示一次，失败不提示），「我的 → 检查更新」手动检查；系统下载管理器下载，完成后打开安装界面，缺"安装未知应用"权限时先授权、回来自动继续。
- 新增发布工作流：推送 `v*` 标签后构建签名 APK，发布到本仓库（开源仓库 `xiaotaitech/yunting`，代码与发布放在一起）的 Releases；`latest.json` 推到 `dist` 分支经 jsDelivr 分发，作为 GitHub API 不通时的版本信息备用线路。没有配置百度凭证与公网 OAuth 代理时发演示版。
- 新增 `app-help`：应用内「使用帮助」，内容来自 `assets/help.md`，支持按章节跳转；更新弹窗里直达安装说明。
- 新增 `app-layout`：底部导航「书架 / 历史 / 我的」，「我的」按「收听 / 播放 / 关于 / 账号」分组，页脚显示版本号。
- 新增 `app-branding`：云听书自己的标志（云 + 音频条，品牌绿 #3F6B4F），Android 自适应图标含单色主题层、通知栏小图标、iOS AppIcon，登录页使用同一标志。
- release 构建改为读 `keystore.properties` 或环境变量签名。

## Capabilities

### New Capabilities
- `app-distribution`: 检查更新、下载并安装更新、发布流程。
- `app-help`: 应用内使用帮助与章节跳转。
- `app-layout`: 一级导航与「我的」页分组。
- `app-branding`: 应用图标与标志。

### Modified Capabilities
（无）

## Impact

- Dart：`lib/update/`、`lib/ui/help_screen.dart`、`lib/ui/help/help_markdown.dart`、`lib/ui/update_dialog.dart`、`lib/ui/mine_screen.dart`（取代 `settings_screen.dart`）、`lib/ui/widgets/brand_mark.dart`；`tool/generate_icons_test.dart` 生成图标 PNG。
- Android：`MainActivity` 的 `yun/app` 通道；Manifest 增加 `REQUEST_INSTALL_PACKAGES`；`res/` 下自适应图标、单色层、通知图标。
- 构建：`android/app/build.gradle.kts` 签名；`.github/workflows/ci.yml`、`release.yml`。
- 仓库 Secrets：签名四项；`BAIDU_APP_KEY`、`OAUTH_PROXY_BASE` 配好后才发正式版（否则演示版）。
- 演示模式使用独立的本地库 `yun_audiobook_demo.db`，演示版升级到正式版时假数据不进真书架。

## 不做

- 安装包的国内镜像：APK 约 35MB，超过 jsDelivr 单文件上限；真有需要再找国内可达的对象存储。
- 分享安装包 / 下载二维码：后续单独提。
- 外观模式切换：跟随系统够用。
- iOS 应用内更新：iOS 不允许侧载，iOS 上隐藏「检查更新」。
