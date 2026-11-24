# add-episode-time-order Implementation Plan

> **For agentic workers:** execute via `/opsx:apply` (subagent-driven-development or executing-plans). Tick tasks.md as tasks complete.

**Goal:** 章节存下网盘的上传 / 同步时间，书详情页显示同步日期，每本书可选「按名称 / 按时间（旧 → 新）」排序。

**Architecture:** 时间随列目录从 `DriveEntry` 进入 `_buildEpisodes`，落到 `chapters` 两个新列；书上的 `episode_order` 决定 `_buildEpisodes` 的比较器。切换排序 = 写排序方式 + 清手动标记 + 整本 `refresh`，重排后的进度与历史由 `replaceEpisodes` 按 fsId 跟随（已有）。

**Tech Stack:** Flutter / Dart 3.4+、drift（SQLite）、flutter_riverpod、freezed、flutter_test。

**Spec:** `proposal.md`, `specs/`, `design.md` in this change directory — the binding authority.

## Global Constraints

- 技术栈：Flutter（Dart 3.4+）、flutter_riverpod、just_audio + audio_service、sqflite；Android 原生部分用 Kotlin。
- 合规边界：只访问授权用户本人文件；不托管、不分发音频；不调用分享类接口。
- 文档、界面文案、规格一律用简体中文；规格里的 SHALL/MUST 保留英文关键字。
- 每个任务可独立验证；涉及原生代码的任务注明需要真机验证。
- 不做「新 → 旧」排序；方向固定为旧 → 新，续播往新的一期走。
- 不改书架（书与书之间）的排序。
- 不在 hold 里加任何东西；时间只从网盘文件元信息读。
- 不做「新一期」角标、未听标记等提醒。
- 时间缺失（老数据还没刷新）时不为补时间单独去请求网盘；等这本书下次正常刷新时补上。
- `flutter analyze` 与全量 `flutter test` — run once by the controller at verification, not per task.

公共前置：每条命令前 `cd ~/workspace/my-tools/yunting && source ./env.sh && cd app`。改了 drift 表或 freezed 实体后跑 `dart run build_runner build --delete-conflicting-outputs`。只格式化本任务改动的文件（`dart format <files>`），不要 `dart format lib test` 整目录。

---

### Task 1.1: DriveEntry 带上传时间

**Satisfies:** `specs/library-catalog/spec.md` → Scenario: 按时间从旧到新（数据前提）
**Model:** sonnet
**Kind:** code
**Files:** `lib/data/drive/cloud_drive_source.dart`、`lib/data/drive/baidu/baidu_drive_source.dart`、`lib/data/drive/local/local_media_source.dart`、`lib/data/drive/demo/demo_drive_source.dart`；测试 `test/data/drive_cache_test.dart`、`test/data/demo_drive_source_test.dart`、`test/data/local_media_source_test.dart`

- [ ] Write failing tests：`DriveEntry.fromJson(toJson(e))` 保留 `serverCtime`；不含 `ctime` 键的老 JSON 读出 `serverCtime == null`；演示数据源列出的文件 `serverCtime` 非空且同目录内随文件序递减（时间顺序与名称顺序相反，演示里切换排序看得出变化）；本机数据源 `serverCtime == serverMtime`
- [ ] Run `flutter test test/data/drive_cache_test.dart test/data/demo_drive_source_test.dart test/data/local_media_source_test.dart` — expect FAIL：`serverCtime` 未定义
- [ ] Implement：`DriveEntry` 加 `final int? serverCtime`（秒），`toJson` 写 `'ctime'`，`fromJson` 读 `j['ctime'] as int?`；百度 `_toEntry` 读 `raw['server_ctime']`；本机数据源两个时间都取 `r.mtime`；演示数据源按文件序给 `serverCtime` / `serverMtime` 造递减值
- [ ] Run 同上 — expect PASS
- [ ] Tick `- [x] 1.1` in tasks.md; commit：`DriveEntry 带上传时间（server_ctime）`

### Task 1.2: schema v5 与实体字段

**Satisfies:** `specs/library-catalog/spec.md` → Scenario: 老数据没有时间
**Model:** sonnet
**Kind:** code
**Files:** `lib/data/local/database.dart`、`lib/data/local/series_dao.dart`、`lib/domain/entities.dart`（及生成文件）；测试 `test/data/database_migration_test.dart`、`test/data/series_dao_upsert_test.dart`

- [ ] Write failing tests：迁移测试里 v4 库升级后 `user_version` 为 5、老章节 `createdAt` / `syncedAt` 为 null、老书 `episodeOrder == EpisodeOrder.name`、迁移后列与全新建库一致（沿用现有对比用例，把期望版本改为 5）；DAO 往返：`replaceEpisodes` 写入的时间与 `upsertSeries` 写入的 `episodeOrder.time` 能原样读回
- [ ] Run `flutter test test/data/database_migration_test.dart test/data/series_dao_upsert_test.dart` — expect FAIL
- [ ] Implement：`enum EpisodeOrder { name, time }`；`Episode` 加 `DateTime? createdAt, DateTime? syncedAt`；`Series` 加 `@Default(EpisodeOrder.name) EpisodeOrder episodeOrder`；`Chapters` 加 `IntColumn createdAt/syncedAt nullable`（秒），`Books` 加 `TextColumn episodeOrder withDefault('name')`；`schemaVersion` 5，`if (from < 5)` 三个 `addColumn`；`series_dao.dart` 的 `_toEpisode/_fromEpisode/_toSeries/_fromSeries` 映射；跑 build_runner
- [ ] Run 同上 — expect PASS
- [ ] Tick `- [x] 1.2` in tasks.md; commit：`本地库 v5：章节记上传与同步时间，书记章节排序方式`

### Task 2.1: 按书的排序方式建章节顺序

**Satisfies:** `specs/library-catalog/spec.md` → Scenario: 数字段按数值比较；优先采用 track 标签；按时间从旧到新；按时间时新的一期排在末尾；手动调整顺序
**Model:** sonnet
**Kind:** code
**Files:** `lib/data/repositories/library_repository.dart`；测试 `test/data/library_refresh_test.dart`

- [ ] Write failing tests（用现有本机数据源 + 内存库的写法，`Row.mtime` 即时间）：
  - 文件名顺序与时间顺序相反，书为 `time` → `episodesOf` 按时间升序，章节 `syncedAt` 非空
  - 书为 `time`，加入一个时间最新、名字排在中间的文件后 `refresh` → 新文件在末尾，已有顺序不变
  - 时间相同的两个文件 → 按自然序
  - 书为 `name` → 与现状一致（现有用例不改）
  - `orderEditedByUser` 为真时追加分支写入的章节也带时间
- [ ] Run `flutter test test/data/library_refresh_test.dart` — expect FAIL
- [ ] Implement：`_buildEpisodes` 增加参数 `EpisodeOrder order`；`time` 时比较器为 `serverCtime`（null 视为最大）→ `serverMtime` → 现有自然序比较；构造 `Episode` 时填 `createdAt/syncedAt`（`DateTime.fromMillisecondsSinceEpoch(s * 1000)`）；认领传 `EpisodeOrder.name`，`refresh` 传 `series.episodeOrder`；追加分支同样填时间
- [ ] Run 同上 — expect PASS
- [ ] Tick `- [x] 2.1` in tasks.md; commit：`章节可按上传时间从旧到新排序`

### Task 2.2: 切换排序方式

**Satisfies:** `specs/library-catalog/spec.md` → Scenario: 切换排序方式覆盖手动顺序
**Model:** haiku
**Kind:** code
**Files:** `lib/data/repositories/library_repository.dart`、`lib/features/library/library_controller.dart`；测试 `test/data/library_refresh_test.dart`

- [ ] Write failing test：先 `reorder` 打乱顺序（`orderEditedByUser` 为真），再 `setEpisodeOrder(series, EpisodeOrder.time)` → 书的 `orderEditedByUser` 为假、`episodeOrder` 为 `time`、章节按时间排列；当前章节仍指向同一个文件
- [ ] Run `flutter test test/data/library_refresh_test.dart` — expect FAIL
- [ ] Implement：
  ```dart
  Future<void> setEpisodeOrder(Series series, EpisodeOrder order) async {
    final updated = series.copyWith(
      episodeOrder: order,
      orderEditedByUser: false,
      updatedAt: DateTime.now(),
      updatedByDevice: await _deviceId(),
    );
    await _dao.upsertSeries(updated);
    await refresh(updated);
  }
  ```
  controller 加同名转发方法
- [ ] Run 同上 — expect PASS
- [ ] Tick `- [x] 2.2` in tasks.md; commit：`书可切换章节排序方式`

### Task 3.1: 详情页排序菜单与同步日期

**Satisfies:** `specs/library-catalog/spec.md` → Scenario: 显示同步日期；老数据没有时间
**Model:** sonnet
**Kind:** code
**Files:** `lib/features/library/series_detail_page.dart`、`lib/features/library/widgets/episode_list.dart`、`lib/l10n/app_zh.arb`（及 gen）；新建 `lib/features/library/synced_label.dart`；测试 `test/features/synced_label_test.dart`

- [ ] Write failing test：`syncedLabel(l, DateTime(2026,11,21), now: DateTime(2026,11,24))` → `11月21日同步`；跨年 → `2025年11月21日同步`；`null` → `null`
- [ ] Run `flutter test test/features/synced_label_test.dart` — expect FAIL
- [ ] Implement：arb 加 `detailSyncedOn`（`{month}月{day}日同步`）、`detailSyncedOnYear`、`detailMenuOrderByName`（按名称排序）、`detailMenuOrderByTime`（按时间排序）；`syncedLabel` 纯函数；章节副标题在现有文本后接「 · 11月21日同步」（有值时）；详情页菜单加两项 `CheckedPopupMenuItem`，选中当前方式，点另一项调 `setEpisodeOrder` 后提示刷新结果；跑 `flutter gen-l10n`
- [ ] Run 同上 — expect PASS
- [ ] Tick `- [x] 3.1` in tasks.md; commit：`书详情页：章节排序菜单与同步日期`

### Task 3.2: 文档

**Satisfies:** 用户可见行为的文档覆盖
**Model:** haiku
**Kind:** docs
**Files:** `assets/help.md`、`../README.md`

- [ ] `assets/help.md` 第 38 行附近「加入书架」一节后加：书详情页右上菜单可选「按名称 / 按时间」，按时间是最早一期在上、新一期排在最后，适合追更的目录；章节下显示同步到网盘的日期；选排序方式会覆盖手动拖出来的顺序
- [ ] README 功能列表补一句「章节可按名称或按时间排序，显示同步日期」
- [ ] Run `flutter test test/help_markdown_test.dart` — expect PASS
- [ ] Tick `- [x] 3.2` in tasks.md; commit：`帮助与 README：章节按时间排序`

### Task 4.1: 演示模式端到端

**Satisfies:** `specs/library-catalog/spec.md` → Scenario: 按时间从旧到新；显示同步日期（真机界面）
**Model:** haiku
**Kind:** verification
**Files:** 无

- [ ] 申请 skiff 租约，`./run-emulator.sh demo` 装到模拟器 phone
- [ ] 认领一本演示书 → 打开详情页，截图：章节下有同步日期
- [ ] 菜单选「按时间排序」，截图：顺序按时间旧 → 新；再选回「按名称排序」，截图
- [ ] 释放租约；截图路径写进最终报告
- [ ] Tick `- [x] 4.1` in tasks.md; commit tasks.md：`验证：演示模式下章节按时间排序`
