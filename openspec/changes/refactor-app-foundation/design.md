## Context

三个子项目的第一个：① 工程地基 → ② 视频课程 → ③ 界面与品牌升级。
本变更只换地基，界面观感与用户可见行为保持不变；它的验收标准是「用户感觉不到任何变化，
但视频与新界面可以直接往上搭」。

现有代码里有大量真机踩坑留下的修复与注释（30 秒加载超时、`play()` 不能 await、
REPLACE 会触发级联删除、准备期间不写进度……）。重构的第一纪律：**行为不丢，注释随代码迁移**。

## Goals / Non-Goals

- Goals：媒体抽象就位；播放核心可测；状态单向流动；库表与同步格式可演进；严格 lint 零告警。
- Non-Goals：视频播放、界面改版、新功能。

## Decisions

### D1 技术栈

| 方面 | 选择 | 理由 |
|---|---|---|
| 状态 | `flutter_riverpod` 3 + `riverpod_annotation` / `riverpod_generator` | 已在用 Riverpod，换代码生成的 Notifier 成本最低 |
| 模型 | `freezed` + `json_serializable` | 不可变、`copyWith`、联合类型、同步快照序列化 |
| 数据库 | `drift` + `sqlite3_flutter_libs` | 类型安全、`watch()` 响应式查询替代手动 invalidate、迁移可测 |
| 路由 | `go_router`，底部三栏用 `StatefulShellRoute.indexedStack` | 保留现在 IndexedStack 的「切栏不丢滚动位置」 |
| 文案 | `flutter_localizations` + `intl` + ARB（`generate: true`） | 先只有 `zh`，但文案全部离开代码 |
| Lint | `very_good_analysis`，关掉 `public_member_api_docs`、`lines_longer_than_80_chars` | App 不是库；中文注释与字符串行宽不适合 80 列 |

生成文件（`*.g.dart`、`*.freezed.dart`）不入库，CI 先跑 `build_runner`。

### D2 目录与依赖方向

```
lib/
  core/        config、errors、logging、natural_sort、result 等无依赖工具
  domain/      freezed 实体 + 仓库接口 + 纯函数（排序、续听、ID3）
  data/        drift 库与 DAO、百度/演示数据源、令牌、同步
  playback/    session、engine 接口与 just_audio 实现、audio_service 桥、resolver、sleep timer
  download/    下载队列（只依赖 CloudDriveSource，不再依赖百度客户端）
  features/<name>/{controllers,view,widgets}
  app/         router、bootstrap、providers 装配、theme、l10n 入口
```

`features` 只依赖 `domain`、`playback`、`download` 暴露的接口与 provider；不得 import `data/` 的具体实现。

### D3 领域模型

- `Series`（原 Book）：`kind: SeriesKind {audiobook, course}`，其余字段不变。
- `Episode`（原 Chapter）：`mediaKind: MediaKind {audio, video}`，其余字段不变。
- 库表名、列名、同步 JSON 键**一律不改**（`books`/`chapters`/`chapter_*`），只在 drift 的
  `@DataClassName` 与映射层改名。改表名换不来任何用户价值，却要冒迁移风险。
- 界面文案按 `kind` 取词：有声书「章」、课程「课」，词表在 ARB 里。本变更里只会出现有声书。

### D4 数据库：sqflite → drift，v2 → v3

- 同一个文件 `yun_audiobook.db`（演示 `yun_audiobook_demo.db`），drift 读 `PRAGMA user_version`，
  老库是 2，走 `onUpgrade(2 → 3)`：
  `ALTER TABLE books ADD COLUMN kind TEXT NOT NULL DEFAULT 'audiobook'`、
  `ALTER TABLE chapters ADD COLUMN media_kind TEXT NOT NULL DEFAULT 'audio'`。
  v1 → 2 的「建 play_history」保留。
- 时间列沿用毫秒整数：drift 的 `DateTimeColumn` 默认存秒，所以用 `IntColumn` + 毫秒 `TypeConverter`。
- `beforeOpen` 打开 `PRAGMA foreign_keys = ON`（级联删除依赖它）。
- 迁移测试：用原 v2 建表 SQL 造库、写入样本，再用 drift 打开，逐列比对。

### D5 数据源

- `CloudDriveSource` 增加 `openRange(fsId, start)`（返回字节流 + 总长），`DownloadManager` 改为只依赖它。
- `ResolvedMedia` 增加 `kind: StreamKind {progressive, hls}`，本变更只产生 progressive；为 ② 留位。

### D6 播放核心拆分

```
PlaybackSession (纯 Dart, 可测)
  ├─ 队列：series + episodes + index、start / playAt / next / prev
  ├─ 加载：resolve → engine.load(timeout 30s)，startGen 防竞态，preparing / playAfterLoad
  ├─ 恢复：invalidate → forceRefresh → reload @position，4 次指数退避；鉴权失败不重试
  ├─ 看门狗：5s 一跳，缓冲 25s 不涨判卡死
  ├─ 弱网：1 分钟 4 次缓冲提示一次
  ├─ 进度：5s 节流，准备期间不写；章末 chapterFinished、全书 finished
  ├─ 睡眠定时：SleepTimer（不变）
  └─ 输出：state stream（freezed PlaybackSnapshot）、failures、hints
MediaEngine (接口)          ← JustAudioEngine（UA 走 userAgent 参数，不传 headers）
AudioServiceBridge extends BaseAudioHandler  ← 把系统媒体按钮转给 session，把 snapshot 映射成 PlaybackState/MediaItem
```

- 进度、历史、同步 dirty、时长回填、鉴权失效：由 session 通过一个 `PlaybackSink` 接口上报，
  在 app 层用真实 DAO 实现——不再是 bootstrap 里的内联闭包。
- `MediaEngine` 的事件以「快照 + 完成事件 + 错误事件」三条流给出，FakeEngine 在测试里可以精确驱动。
- 测试：`fake_async` 驱动 FakeEngine，覆盖规格「播放行为不变」列出的每一条。

### D7 状态与 controller

- 读：drift `watch()` → `StreamProvider`（书架、单本、章节、历史、缓存占用），
  数据变了界面自动刷新，删除所有手动 `ref.invalidate`。
- 写：每个 feature 一个或几个 `@riverpod class XxxController extends _$XxxController`，
  例如 `PlaybackController.open(series, episodeIndex?)` 统一「正在播就回播放页」判断，
  `SeriesController.remove / edit / refresh` 内部负责 `sync.markDirty()`。
- 一次性的界面反馈（SnackBar）用 controller 返回的 `Result`/抛出的领域错误，由 view 决定怎么呈现。

### D8 启动

`main` 只 `runApp`；`bootstrapProvider`（`FutureProvider`）完成令牌恢复、开库、`AudioService.init`；
未完成显示启动页，失败显示原因与重试；未配置 AppKey 仍走配置引导页。

### D9 同步快照 v2

freezed + json_serializable 改写 `LibrarySnapshot`/`BookRecord`，键名不变，新增 `kind`（缺省 audiobook），
`version` 写 2。合并规则（记录级 LWW、进度取更靠前）一字不改，原有测试原样迁移。

## Risks / Trade-offs

- **大面积改写引入回归** → 先迁移现有 127 个测试并保持全绿，再补 session/下载/认领测试；
  每个阶段独立提交，可单独回退。
- **drift 打开 sqflite 建的库** → 迁移测试用原始建表 SQL 造库，验证每一列。
- **代码生成拖慢 CI** → `build_runner` 约 30–60 秒，可接受。

## Migration Plan

升级即迁移，无需用户操作；库 v3 无法降级回旧版本 App（旧版 sqflite 遇到更高 user_version 会走 onDowngrade 报错）——
与以往版本一致，只支持向上升级。
