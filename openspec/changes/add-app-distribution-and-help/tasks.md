## 1. OpenSpec

- [x] 1.1 `openspec init --tools claude`，补 `openspec/config.yaml` 项目背景
- [x] 1.2 本变更的提案、设计、规格、任务

## 2. 应用内更新

- [x] 2.1 `lib/update/app_updater.dart`：GitHub + 镜像并查、合并地址、版本比较、更新说明清洗
- [x] 2.2 单元测试 `test/app_updater_test.dart`
- [x] 2.3 Android `MainActivity`：`yun/app` 通道（版本号、DownloadManager 下载与失败换线、安装、授权后续装）
- [x] 2.4 Manifest 增加 `REQUEST_INSTALL_PACKAGES`
- [x] 2.5 `lib/update/app_installer.dart` 通道封装；`lib/ui/update_dialog.dart`
- [x] 2.6 启动静默检查（延迟 3 秒，`update_seen` 只提示一次）
- [x] 2.7 模拟器验证：启动提示、手动检查、下载、授权后自动续装、同一版本不重复提示
- [ ] 2.8 真机验证：云听书自己的 Release 覆盖安装、数据保留

## 3. 使用帮助

- [x] 3.1 `app/assets/help.md`，pubspec 登记 assets
- [x] 3.2 `lib/ui/help_screen.dart`：Markdown 子集解析、行内粗体与链接、章节锚点跳转
- [x] 3.3 解析单元测试 `test/help_markdown_test.dart`

## 4. 页面布局

- [x] 4.1 `lib/ui/mine_screen.dart` 分组布局，取代 `settings_screen.dart`
- [x] 4.2 底部导航改为 书架 / 历史 / 我的

## 5. 构建与发布

- [x] 5.1 `android/app/build.gradle.kts`：keystore.properties / 环境变量签名，都没有时回落 debug 签名
- [x] 5.2 `.github/workflows/ci.yml`、`release.yml`（版本号由标签计算、Release、dist 分支 latest.json、未配置凭证时发演示版）
- [x] 5.3 README「发布与分发」一节
- [x] 5.4 创建开源仓库 xiaotaitech/yunting、配置签名 Secrets、推送 v0.1.0 验证（演示版已发布，签名指纹核对一致）
- [ ] 5.5 部署公网 OAuth 代理，配置 BAIDU_APP_KEY / OAUTH_PROXY_BASE 后发第一个正式版

## 6. 图标与标志

- [x] 6.1 `lib/ui/widgets/brand_mark.dart`：标志几何与绘制
- [x] 6.2 Android 自适应图标（前景、背景色、单色层）与通知图标 `ic_stat_yun`，`raw/keep.xml` 保留
- [x] 6.3 `tool/generate_icons_test.dart` 生成旧版 Android 与 iOS 图标 PNG
- [x] 6.4 登录页使用标志；AudioServiceConfig 使用通知图标
- [x] 6.5 模拟器确认：桌面图标、启动页、通知栏图标
- [ ] 6.6 真机确认主题图标（Android 13+ 开启主题图标）
