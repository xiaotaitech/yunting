# 云听书 — 以百度网盘为数据源的听书 App

把你自己百度网盘里的有声书文件夹，变成一个帆书级别的听书 App：书架、章节续播、
倍速、睡眠定时、后台/锁屏播放、离线下载。书架、进度与历史只存本机。

**不托管、不转存、不分发任何音频**——所有音频始终留在你自己的网盘账号里。

---

## 仓库结构

```
openspec/changes/add-netdisk-audiobook-mvp/   规格（提案 / 设计 / 五份能力规格 / 任务清单）
tools/                                        OAuth 代理 + Phase 0 链路验证工具（Node）
app/                                          Flutter 客户端（Android + iOS）
env.sh                                        本机工具链环境变量
```

## 架构一句话

客户端直连百度网盘取文件与音频流；服务端只有一个 serverless 函数负责 OAuth
换取/刷新令牌（AppSecret 不能进客户端）。**只代理凭证，不代理数据。**
书架与进度写回你网盘的 `/apps/yun_audiobook/library.json`，零数据库、零内容托管。

设计取舍与百度平台的硬约束，见
[`openspec/changes/add-netdisk-audiobook-mvp/design.md`](openspec/changes/add-netdisk-audiobook-mvp/design.md)。

---

## 想先看看长什么样？演示模式不需要任何凭证

```bash
source ./env.sh
cd app && flutter run --dart-define=DEMO_MODE=true
# 或者连模拟器一起：./run-emulator.sh demo
```

演示模式用一个本地假网盘替代百度（`DemoDriveSource`），音频是现场生成的。
**除了音频内容，其余全是真的在跑**：目录浏览、认领成书、章节自然序（数据里刻意放了
「第2章 / 第10章」，一眼能看出排对没有）、播放、断点续播、倍速、睡眠定时。

这也是 `CloudDriveSource` 抽象的实证——换掉数据源，UI 与播放层一行没改。

---

## 你需要先做的一件事（外部前置条件）

百度网盘开放平台的 AppKey / SecretKey 必须由你自己申请，需要**实名认证**，
这一步没法代劳：

**控制台**（申请入口）：<https://pan.baidu.com/union/console>
**官方文档**：<https://pan.baidu.com/union/doc/>

步骤：

1. **登录百度账号** —— 用你日常那个网盘账号就行，不用另注册
2. **实名认证** —— 填真实姓名 + 身份证号。这是硬性前置，没认证不能建应用
3. **创建应用** —— 在控制台点「创建应用」，要填：
   - 应用类别：选**软件类别**
   - 应用名称、应用描述：如实写「个人使用的网盘音频播放器」之类即可
4. **等审核通过**
5. **在应用详情页记下凭证** —— 会给你 4 个：`AppId` / `AppKey` / `SecretKey` / `SignKey`。
   本项目只用 **AppKey** 和 **SecretKey**，另外两个用不上

几点提醒：

- 个人实名认证**只能创建 1 个应用**（企业认证是 10 个），所以别浪费名额。
- 网上流传过「暂停个人创建应用」的说法。官方文档现在仍写着个人认证可创建 1 个，
  但**以你打开控制台时的实际情况为准**。如果确实建不了，先用上面的演示模式，
  代码这边不需要改动，等能建了填上凭证即可。
- **SecretKey 只填进 `tools/.env`**（已在 `.gitignore` 里），它只在 OAuth 代理进程内使用，
  绝不会下发到 App。App 侧只拿 AppKey。

拿到之后：

```bash
cd tools
cp .env.example .env
# 编辑 .env，填入 BAIDU_APP_KEY 与 BAIDU_SECRET_KEY
```

---

## 第一步：验证链路（强烈建议先跑这个）

这一步验证整个项目的技术前提。跑不通，客户端做得再好也没意义。

```bash
cd tools
npm run verify

# 想指定某个目录（Windows Git Bash 必须加 MSYS_NO_PATHCONV=1，
# 否则 /开头的参数会被改写成 C:/Program Files/Git/... 然后报 errno=-7）：
MSYS_NO_PATHCONV=1 npm run verify -- "/有声书/三体"

# 顺带：想知道网盘里哪个音频最大（UA 对照测试需要 >20MB 的文件）
node src/find-large-audio.mjs
```

它会依次验证并打印结论：

| 检查项 | 验证什么 |
|---|---|
| 0.3a 设备码授权 | OAuth 走得通，scope=`basic,netdisk` |
| 0.3b 用户信息 | 令牌有效；顺带告诉你是不是非会员（影响限速） |
| 0.3c/d 列目录 | 能读到你网盘的目录与音频文件 |
| 0.3e 取 dlink | `filemetas?dlink=1` 能拿到下载地址 |
| **0.3f 带 UA 下载** | 带 `User-Agent: pan.baidu.com` 能下大文件，且正确跟随 302 |
| 0.3g 不带 UA 对照 | 用浏览器 UA 请求同一个 dlink，看是否真被拒（实测未被拒） |
| 0.4 Range | 支持断点续传与 seek |
| 0.5 实测速率 | 决定「流播优先」还是「先下载后听」 |

授权走的是百度官方的[设备码模式](https://pan.baidu.com/union/doc/fl1x114ti)：
工具会打印一个网址和用户码，你在浏览器里完成授权，它自动继续。
**不需要备案域名，也不需要配置回调地址。**

---

## 第二步：启动 OAuth 代理

```bash
cd tools
npm run proxy
# OAuth 代理已启动：http://0.0.0.0:8787
```

真机测试时，手机要能访问到这台机器，所以要用**局域网 IP**（不是 127.0.0.1）：

```bash
# Windows 查本机 IP
ipconfig | findstr IPv4
```

这个代理只做两件事：`code → token` 和 `refresh_token → token`。
它不接触任何文件元数据、不缓存音频、日志不记录用户文件路径。

### 公网部署：阿里云 bj1

正式版用的就是这个 Node 代理（`tools/src/oauth-proxy.mjs`），跑在阿里云 ECS bj1 上（systemd `yunting-oauth`，监听 127.0.0.1:8787），
nginx 反代到 `https://yunting-auth.xiaotai.tech`。部署与凭据由 mooring 仓库管理：改了 `tools/src/` 后在 mooring 跑 `host/bj1/sync.sh`
推送并重启；百度 AppKey / SecretKey 在机器的 `/etc/yunting-oauth.env`，不进仓库。

---

## 第三步：跑 App

工具链已经装在 `D:\sdk` 下，先加载环境：

```bash
source ./env.sh          # bash
```

然后带上你的 AppKey 与代理地址运行：

```bash
cd app
flutter run \
  --dart-define=BAIDU_APP_KEY=你的AppKey \
  --dart-define=OAUTH_PROXY_BASE=http://192.168.x.x:8787
```

打 APK（也可以直接用脚本：`./build-apk.sh <AppKey> <代理地址>`）：

```bash
cd app
flutter build apk --release \
  --dart-define=BAIDU_APP_KEY=你的AppKey \
  --dart-define=OAUTH_PROXY_BASE=http://192.168.x.x:8787
# 产物：app/build/app/outputs/flutter-apk/app-release.apk
```

> 不带 `--dart-define` 构建出来的包能装能开，但会停在「需要先完成配置」引导页——
> 这是故意的，比让你面对一个点了没反应的登录页要好。

---

## App 里怎么用

1. **登录**：点「登录百度网盘」→ App 内的百度页面里登录并授权 → 自动进书架
   （备用：「改用浏览器或其他设备授权」走设备码）
2. **加书**：书架右上角「＋」→ 列出网盘里所有装着音频的文件夹（可搜索，也可按目录找）
   → 点「＋」加入书架。网盘目录与搜索词记在本机，二次打开不用等
3. **听**：点书 → 点任意章节开播；或在书架直接点「继续收听」从断点接上
4. **播放页**：倍速（0.5x–3.0x）、睡眠定时（固定时长 / 播完本章）、±15 秒、
   进度拖动、章节列表（打开就落在当前章）；退到后台或锁屏继续放，通知栏可控
5. **离线**：书籍详情页菜单「下载本书」，或单章右侧下载按钮；
   左上角菜单「离线管理」看占用、设配额、按书清理
6. **最近收听**：书架左上角菜单（或左边缘右滑）打开侧边栏，按天记下听过的章节与
   实际收听时长，点一条跳回断点续播。只存本机

---

## 已知的外部约束（不是 bug）

这些是百度侧给定的条件，架构是绕着它们设计的：

- **UA**：网上普遍说 dlink 必须带 `User-Agent: pan.baidu.com`，否则 >20MB 会被拒。
  2026-08-30 用 50.2MB 的文件实测，带浏览器 UA 照样 HTTP 200——**这条当前不成立**。
  代码仍然带 UA（代价为零，百度策略可能变回去），但它不是「不带就用不了」。
  真正排除 Web/PWA 的是 CORS：`d.pcs.baidu.com` 不给浏览器发跨域头。
- **dlink 有时效**，播放中可能失效。App 会自动重取并 seek 回原位置续播，
  你只会看到一次短暂缓冲。
- **非会员账号下载限速**。有声书常见码率（64–128kbps）通常够流播，
  高码率/无损资源建议先下载。
- **分享类接口不对个人开发者开放**，所以没有也不会有「导入分享链接」功能。

## 合规边界

写进架构，不只是写进文案：

- 只调用「读取当前授权用户本人文件」的接口。代码里**不存在**调用分享类接口、
  解析分享链接、访问他人网盘的路径。
- 服务端不落任何文件元数据、不落音频，日志不记录文件名/路径。
- 不往用户网盘写任何东西：书架、进度、历史只存本机（0.x 早期版本写过的
  `/apps/yun_audiobook/library.json` 不再读写，也不删）。
- 令牌存于系统安全存储；令牌与 dlink 在日志中一律脱敏。

---

## 发布与分发

规格见
[`openspec/changes/add-app-distribution-and-help/`](openspec/changes/add-app-distribution-and-help/)。

- **CI**（`.github/workflows/ci.yml`）：推送到 main 或提交 PR 时跑 `flutter analyze`、`flutter test` 并打包，安装包作为构件保留 14 天。
- **发布**（`.github/workflows/release.yml`）：推送 `v*` 标签（`git tag -a v0.2.0 -m "云听书 0.2.0" -m "- 更新说明…" && git push origin v0.2.0`）后测试、打签名包，
  发布到本仓库的 Releases，附固定名称的 `yunting.apk`。代码与发布在同一个仓库，用自带的 `GITHUB_TOKEN`，不需要额外令牌。
  版本号由标签计算：`v0.3.1` → versionName 0.3.1、versionCode 301。附注标签的正文就是更新说明。
  同时把 `latest.json` 和安装包推到 `dist` 分支经 jsDelivr 分发（国内 `api.github.com`、GitHub 下载常不通）。
  安装包地址按提交 sha 引用（cdn / fastly 两个入口 + GitHub 直链），发版后自动 purge 与预热。
  安装包能放上 jsDelivr（单文件上限 20MB）靠两点：原生库压缩打包（`useLegacyPackaging`）与 Dart 混淆，
  整包约 18MB；调试符号作为构件保留 90 天，用于还原崩溃堆栈。超过 20MB 时工作流自动只走 GitHub。
  **没有配置 `BAIDU_APP_KEY` / `OAUTH_PROXY_BASE` 时发的是演示版**（标题带「演示版」），配好后下一个标签自动变成正式版。
- **应用内**：启动时静默检查新版本（同一版本只提示一次），「我的 → 检查更新」可手动检查；下载前对各线路测速（各取 256KB、最多 5 秒），
  最快的优先，失败自动换下一条；下载完成后直接打开安装界面，
  需要"安装未知应用"授权时授权回来自动继续。「我的 → 使用帮助」里有各品牌手机的安装说明。

图标：标志定义在 `app/lib/features/common/widgets/brand_mark.dart`（耳机 + 播放键，橙色渐变），改完运行 `cd app && flutter test tool/generate_icons_test.dart` 重新生成 PNG；
Android 自适应图标是 `res/drawable/ic_launcher_*.xml`，坐标与 Dart 一致，要一起改。

需要的仓库 Secrets：

| 名称 | 用途 |
|---|---|
| `KEYSTORE_BASE64` / `KEYSTORE_PASSWORD` / `KEY_ALIAS` / `KEY_PASSWORD` | 签名。所有渠道必须同一个密钥，否则无法覆盖升级 |
| `BAIDU_APP_KEY` / `OAUTH_PROXY_BASE` | 打进安装包的 AppKey 与 OAuth 代理地址（代理必须公网可达）。不配置则发演示版 |

包名是 `tech.xiaotai.yunting`（0.3 之后）。更早的 `com.yunaudiobook.yun_audiobook` 是另一把密钥签的旧包，
已废弃；两者包名不同，可以同时装在手机上。

本机签名：根目录放 `keystore.properties`（已忽略），`KEYSTORE_FILE` 相对仓库根目录：

```properties
KEYSTORE_FILE=keystore/yunting-release.jks
KEYSTORE_PASSWORD=...
KEY_ALIAS=yunting
KEY_PASSWORD=...
```

没有签名配置时 release 包回落 debug 签名，只适合自己装着测。

---

## 开源协议

[MIT](LICENSE)。

---

## 开发

```bash
source ./env.sh
cd app
flutter pub get
dart run build_runner build -d   # freezed / drift / riverpod / json 生成代码（不入库）
flutter analyze                  # 静态检查（very_good_analysis）
flutter test                     # 单元测试
```

开发时可以用 `dart run build_runner watch -d` 让生成代码随改随生成；文案在 `lib/l10n/app_zh.arb`，
`flutter pub get` 时自动生成。

代码结构（refactor-app-foundation）：

```
app/lib/
  core/       配置、错误、日志、自然排序
  domain/     实体（Series / Episode，freezed）与纯函数
  data/       drift 本地库与 DAO（含网盘目录缓存）、百度/演示数据源、令牌
  playback/   PlaybackSession（会话逻辑）+ MediaEngine（播放器内核）+ AudioServiceBridge（系统通知）
  download/   离线下载队列
  features/   各页面：controller + 页面 + 小部件
  app/        装配、providers、路由、主题、启动页
```

界面只经 `features/*/…_controller.dart` 改状态；读数据用 `app/providers.dart` 里的 watch 流，库一变界面自动刷新。

### 接入其他网盘

目前只实现了百度网盘，但留好了三个接入点（prepare-multi-drive），接一家新网盘（以阿里云盘为例）按下面做：

1. **数据源**：在 `data/drive/<网盘>/` 实现 `CloudDriveSource`，`id` 取 `aliyun`，
   产出的路径与 fsId 一律带 `aliyun:` 前缀（无前缀的路径永远归百度——老用户库里的数据都没有前缀）。
2. **分派**：`app/app_services.dart` 里 `RoutingDriveSource(byPrefix: {...})` 加一项 `'aliyun:': AliyunDriveSource(...)`。
   书架、认领、播放、离线下载自动按前缀走到它；解析出的播放地址带 `sourceId`，下载取流会交回同一个源。
3. **登录**：实现 `WebOAuthLogin`（`data/auth/web_oauth_login.dart`）：授权页地址、回跳识别、code 换令牌。
   AppSecret 照例放 OAuth 代理（`tools/src/oauth-proxy.mjs` 加对应端点），令牌存储用独立的键，别和百度的混在一起。
   App 内登录页 `WebLoginPage` 直接复用，不用再写 WebView。
4. **入口**：登录页加一个「登录阿里云盘」按钮；「添加书籍」加一个来源分段（现在的整盘扫描 `listMediaFiles` 只走百度）。

新网盘的书与百度、本机的书存在同一张表里，靠前缀区分，不需要改库表。

规格与任务清单：

```bash
openspec show add-netdisk-audiobook-mvp
openspec status --change add-netdisk-audiobook-mvp
```
