## Context

界面与版本查询用 Dart 写；下载安装这类系统能力用 Kotlin 写在 `MainActivity`，经 `yun/app` MethodChannel 调用——为一个下载安装引入插件不划算，而系统 DownloadManager 本身就满足需求。

## Decisions

### D1 版本信息两路并查，下载只走 GitHub
同时请求 GitHub `releases/latest` 与 `latest.json`（jsDelivr cdn → fastly → raw.githubusercontent 依次尝试），哪个成功用哪个；两边版本一致时下载地址合并去重。
安装包不放镜像：只打 ARM 两个 ABI 的 APK 实测 34.7MB，超过 jsDelivr 单文件 20MB 上限。`latest.json` 只有几 KB，放镜像能解决国内 `api.github.com` 不通导致"检查不到更新"的问题。

### D2 下载交给系统 DownloadManager
通知栏进度、断点续传、退到后台不中断都是现成的。完成监听注册在 applicationContext 上，用户点"后台下载"关掉弹窗后照样在完成时打开安装界面。地址列表一个失败换下一个。

### D3 "安装未知应用"授权后自动继续
没有权限时记下下载 ID、打开授权页；`MainActivity.onResume` 发现已授权就继续安装。

### D4 "同一版本只提示一次"存在 sync_meta
键 `update_seen`。是否提示过是设备语义，不进网盘同步文件。

### D5 帮助内容单一来源
`app/assets/help.md` 是应用内帮助；仓库开源，网页上看的也是同一个文件。只支持够用的 Markdown 子集（标题、列表、段落、`**粗体**`、裸网址），不引入渲染依赖。章节锚点就是标题文本；「安装与更新」「隐私」两个锚点有单元测试守着。
安装说明按"用户看到的提示"组织而不是按手机品牌：用户手里只有屏幕上那句话，不一定知道自己的系统叫什么。

### D6 版本号由标签计算
`v0.3.1` → `--build-name=0.3.1 --build-number=301`（主×10000+次×100+修订），保证 versionCode 单调递增。

### D7 「我的」页分组
- 收听：离线管理、立即同步
- 播放：中断后自动恢复播放
- 关于：检查更新（仅 Android）、使用帮助、隐私说明（跳到帮助「隐私」）、诊断信息
- 账号：退出登录（演示模式隐藏）

### D8 标志的唯一来源是 Dart
`lib/ui/widgets/brand_mark.dart` 定义云的轮廓（底边直线 + 三段圆弧）与四根音频条，坐标系为自适应图标的 108×108，内容在直径 66 的安全区内。
- 应用内（登录页）直接用 CustomPainter 画；
- 旧版 Android 方形图标与 iOS AppIcon 由 `flutter test tool/generate_icons_test.dart` 渲染成 PNG（本机没有图像工具，这样也不引入依赖）；
- Android 8.0+ 自适应图标、单色主题层、通知图标是手写的矢量 XML，坐标与 Dart 一致。
通知图标只在 Dart 里按名字引用，用 `res/raw/keep.xml` 防止 release 资源压缩把它删掉。

## Risks

- 仓库还没有 Release：GitHub 返回 404，手动检查提示"还没有发布版本"，启动检查静默。
- 国内网络下 GitHub 下载慢或失败：下载失败会提示稍后重试；必要时再加国内镜像。
- 已装着 debug 签名测试包的用户无法直接覆盖成正式包：帮助里写明先同步、卸载、重装。
