## Why

产品要从「网盘听书」走向「网盘听书 + 课程学习」（后续加视频课程），并整体提升观感与功能深度。
现在的代码分层清楚、真机坑都已填平，但有几处地基撑不住下一步：

- 播放核心 `AudiobookHandler` 一个类承担选集、加载、卡死看门狗、链接失效恢复、进度、睡眠定时、
  audio_service 适配等 11 项职责，且没有任何测试；它直接绑死 just_audio，视频无处插入。
- 「音频」是写死在每一层的前提：模型、库表、扫描、下载、播放都没有媒体类型的概念。
- Riverpod 只被当作服务定位器；变更散落在界面里（同一个「正在播就回播放页」判断写了 3 处，
  `markDirty` 在界面里手动调 3 处），界面直接订阅各服务私有的 stream。
- 手写 SQL 与 `copyWith`、`Navigator.push`、硬编码文案、默认 lint——都是继续扩展时的摩擦。
- `DownloadManager` 绕过 `CloudDriveSource` 直接依赖百度客户端。

## What Changes

- **技术栈现代化**：riverpod_generator（Notifier）、freezed + json_serializable、drift（替换 sqflite）、
  go_router、gen-l10n（ARB，先只有中文）、very_good_analysis 级 lint。
- **目录按功能组织**：`core / data / domain / playback / features/* / app`，依赖方向
  `features → domain ← data`，界面只经 controller 改变状态。
- **领域模型泛化**：书 → `Series`（合集，带 `kind`：audiobook / course），章节 → `Episode`
  （带 `mediaKind`：audio / video）。本变更只产生 audio 类型，视频识别与播放在后续变更。
- **播放核心拆分**：`PlaybackSession`（选集、进度、恢复、看门狗、睡眠定时；纯 Dart 可测）
  + `MediaEngine` 接口（本变更提供 just_audio 实现）+ `AudioServiceBridge`（系统媒体通知）。
- **数据迁移**：库表 v2 → v3 原地升级（加媒体类型列，老数据一行不动）；同步快照 v1 → v2
  （加类型字段，读 v1 兼容，老版本 App 读 v2 也不出错）。
- **启动流程**：有加载页，不再在 `runApp` 之前阻塞。
- **CI**：增加代码生成步骤与覆盖率输出。

## 不做

- 任何界面视觉改版（第 ③ 个子项目）。本变更界面观感与交互保持不变。
- 视频识别、播放与课程界面（第 ② 个子项目）。
- 改动 OAuth 代理、百度接口调用方式、同步合并规则。

## Impact

- `app/` 几乎全部 Dart 文件会被移动或改写；`test/` 随之迁移并补充播放核心、下载、认领流程测试。
- 库文件名 `yun_audiobook.db` 与同步路径 `/apps/yun_audiobook/library.json` 不变，已安装用户升级无感。
- `.github/workflows/ci.yml`、`release.yml` 增加 `build_runner` 步骤。
