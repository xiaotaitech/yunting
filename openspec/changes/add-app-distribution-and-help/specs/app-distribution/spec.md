## ADDED Requirements

### Requirement: 检查更新
系统 SHALL 从本项目开源仓库的最新 Release 与 jsDelivr 上的 `latest.json` 获取版本号、更新说明与安装包地址，任一可用即可。应用启动后 SHALL 静默检查一次，发现比当前版本新的版本时提示（同一版本只自动提示一次，检查失败不提示）；「我的 → 检查更新」SHALL 手动检查并显示结果。版本号按数字段比较（0.10.0 新于 0.9.3）。iOS 上 MUST NOT 显示检查更新入口。

#### Scenario: 发现新版本
- **WHEN** 当前版本为 0.1.0，最新 Release 为 v0.2.0
- **THEN** 显示"发现新版本 0.2.0"及更新说明，可选择"下载更新"

#### Scenario: 已是最新
- **WHEN** 用户手动检查且最新版本与当前版本相同
- **THEN** 提示"已是最新版本"

#### Scenario: 还没有发布版本
- **WHEN** 用户手动检查且仓库没有任何 Release、镜像也不可用
- **THEN** 提示"还没有发布版本"

#### Scenario: GitHub 不通
- **WHEN** GitHub 请求失败而 `latest.json` 可用
- **THEN** 按 `latest.json` 的版本与地址提示更新

### Requirement: 下载并安装更新
选择"下载更新"后，系统 SHALL 用系统下载管理器下载安装包（通知栏显示进度），按地址顺序尝试，一个失败换下一个；下载完成后打开系统安装界面。没有"安装未知应用"权限时 SHALL 先打开授权页，用户授权返回后自动继续安装。

#### Scenario: 下载完成
- **WHEN** 新版本安装包下载完成
- **THEN** 系统打开安装界面，用户确认后覆盖安装，书架、进度与离线缓存保留

#### Scenario: 关闭弹窗后台下载
- **WHEN** 用户点"后台下载"关闭弹窗
- **THEN** 下载继续，完成后仍打开安装界面

### Requirement: 发布流程
推送 `v*` 标签后，CI SHALL 运行测试并构建签名 APK，发布到本仓库的 Release（附固定名称 `yunting.apk` 与带版本号的安装包），更新说明优先取附注标签正文；同时把 `latest.json`（版本信息）推到 `dist` 分支供 jsDelivr 分发。未配置百度凭证或 OAuth 代理时 SHALL 构建演示版并在标题与说明中注明。所有渠道 MUST 使用同一签名密钥。

#### Scenario: 未配置百度凭证
- **WHEN** 仓库没有配置 BAIDU_APP_KEY 或 OAUTH_PROXY_BASE 时推送标签
- **THEN** 发布「云听书 x.y.z（演示版）」，安装后直接进入演示模式

#### Scenario: 发布 v0.2.0
- **WHEN** 维护者推送标签 v0.2.0
- **THEN** 仓库出现 Release「云听书 0.2.0」，versionName 为 0.2.0、versionCode 为 200
