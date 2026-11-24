## Context

章节顺序由 `LibraryRepository._buildEpisodes` 决定：按目录、再按文件名自然序（全部文件都有 track 标签时按 track）。认领和刷新都走它，刷新通过 `SeriesDao.replaceEpisodes` 整批重建章节行；用户手动拖过顺序（`orderEditedByUser`）时，刷新只把新文件追加到末尾。

百度 `xpan/file` 列目录返回的每个文件带 `server_ctime` 和 `server_mtime`。对 hold 订阅目录实测（2026-11-24）：

| 字段 | 含义 | 实测 |
|---|---|---|
| `server_ctime` | 文件最初上传进网盘的时间，转存时保留 | 樊登 48 个文件 48 个不同日期，每周一期 |
| `server_mtime` | 转存进本人网盘的时间 | 基本是 hold 每晚 23:33 那一轮；早期一批同为 10-16 09:24 |

`DriveEntry` 目前只取了 `server_mtime`，用于媒体文件夹的「最近更新」；章节表里没有任何时间。

上一个修复（提交 6da5033）已经让 `replaceEpisodes` 在重排时按 fsId 把书的当前章节和播放历史跟到新位置，所以切换排序方式整批重排不会让进度错位。

## Goals / Non-Goals

**Goals:**
- 章节存下上传时间与同步时间；书详情页显示同步日期。
- 每本书可选「按名称 / 按时间」，按时间是旧 → 新。

**Non-Goals:** 见 proposal。

## Decisions

### D1 排序用上传时间，显示用同步时间

- 排序键：`createdAt`（`server_ctime`）升序 → `syncedAt`（`server_mtime`）升序 → 现有自然序。
- 显示：`syncedAt`，文案「11月21日同步」，不是今年时带年份（「2025年11月21日同步」）。

为什么排序不用同步时间：早期一批是同一时刻转存的，同步时间全部相同，排不出先后；文件被改名、移动也可能刷新 `server_mtime`，让旧的一期突然跳到末尾。上传时间在转存时保留，基本就是发布时间，又是每期唯一，作为排序键更稳。两者在追更目录里先后一致，显示同步时间不会和顺序打架。

备选：只存一个时间。省一列，但要么排序不稳，要么显示的不是用户要的「同步时间」，不取。

### D2 排序方式存在书上，选了就重排

- `books` 加 `episode_order`（`name` | `time`，默认 `name`），`Series.episodeOrder` 用枚举。
- 书详情页右上菜单加「章节排序：按名称 / 按时间」单选。选中后：写入排序方式、清掉 `orderEditedByUser`，再对这本书执行一次 `refresh`（不带 `onlyIfChanged`），由 `_buildEpisodes` 按新方式重建。
- 这次刷新顺带拿到文件时间，所以老数据切到「按时间」时不会因为时间为空而排错。
- 手动拖动的规则不变：拖过之后 `orderEditedByUser` 为真，刷新只追加。

备选：只在界面层排序、不改 `orderIndex`。播放器、续播、历史都按 `orderIndex` 走，界面和续播顺序会不一致，不取。

### D3 时间从列目录带过来，不额外请求

- `DriveEntry` 加 `serverCtime`；百度数据源读 `server_ctime`；目录缓存 JSON 加 `ctime` 键（老缓存没有这个键时读成 null，无需清缓存）。
- 本机数据源只有修改时间：`serverCtime` 与 `serverMtime` 都取它。
- 演示数据源给每个文件造一个递增的时间，演示模式下也能看到效果。
- `Episode` 加 `createdAt`、`syncedAt`（可空，`DateTime`）；`_buildEpisodes` 和手动排序下的追加分支都填上。
- 迁移 v4 → v5：`chapters` 加 `created_at`、`synced_at`（可空整数，毫秒，沿用库里时间列的约定），`books` 加 `episode_order`（默认 `'name'`）。老行时间为空，下一次刷新这本书时由 `replaceEpisodes` 整批写入。

## Risks / Trade-offs

- [上传时间缺失或全部相同（比如整个目录一次性上传）] → 按时间退化为按同步时间、再退化为自然序，不会比现在更乱。
- [用户切到按时间后，又想回到自己拖的顺序] → 回不去，规格里写明「切换排序方式覆盖手动顺序」；切换前不做二次确认，影响仅限顺序，可以再拖。
- [切换排序要列一次目录、探一次 ID3] → 和手动「刷新」开销相同，只在用户主动切换时发生。

## Migration Plan

- schema 4 → 5 只加列，带默认值或可空，老库原地升级，无数据改写。
- 回滚：旧版本 App 打开 v5 库会因版本号更高而失败，与以往升级一致，不支持降级安装。
