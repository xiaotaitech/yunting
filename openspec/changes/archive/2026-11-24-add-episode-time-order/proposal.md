## Why

「樊登讲书」「非凡精读」这类追更的书，是 hold 每晚把新的一期转存进网盘目录。文件名只有书名、没有期号，章节按名字排，新的一期插在列表中间：看不出哪期是新来的，听完一期自动续播也不是按更新先后走。网盘的每个文件本来就带时间，App 列目录时已经拿到了，只是没存下来，也没用上。

## What Changes

- 每一章记下两个网盘时间：上传时间（`server_ctime`，转存时保留，基本就是这一期的发布时间）与同步时间（`server_mtime`，转存进你网盘的时间）。
- 书详情页的章节行显示同步日期，例如「11月21日同步」。
- 每本书可以单独选章节排序：「按名称」（现在的自然序，默认）或「按时间」（旧 → 新，最早的一期在上）。选了「按时间」之后，刷新时新的一期总是排在末尾。
- 选排序方式会清掉之前手动拖出来的顺序；之后再手动拖动，仍按现在的规则保留手动顺序。
- 本地库升级到 v5：章节表加两个时间列，书表加排序方式列。老数据的时间为空，下次刷新这本书时补上。

## Capabilities

### New Capabilities

（无）

### Modified Capabilities

- `library-catalog`：「章节自然序排列」扩展为可按书选择排序方式（按名称 / 按时间），并在章节上展示同步时间。

## Impact

- `app/lib/data/drive/`：`DriveEntry` 加 `serverCtime`；百度数据源读 `server_ctime`，目录缓存的 JSON 带上它；本机数据源只有修改时间，两个时间都取它。
- `app/lib/data/local/database.dart`：schema v5 迁移（`chapters` 加 `created_at`、`synced_at`；`books` 加 `episode_order`）。
- `app/lib/domain/entities.dart`：`Episode` 加两个时间，`Series` 加排序方式。
- `app/lib/data/repositories/library_repository.dart`：认领与刷新时按书的排序方式建章节顺序。
- `app/lib/features/library/`：书详情页加排序切换，章节行显示同步日期。
- 文案进 `app_zh.arb`。

## Non-Goals

- 不做「新 → 旧」排序；方向固定为旧 → 新，续播往新的一期走。
- 不改书架（书与书之间）的排序。
- 不在 hold 里加任何东西；时间只从网盘文件元信息读。
- 不做「新一期」角标、未听标记等提醒。
- 时间缺失（老数据还没刷新）时不为补时间单独去请求网盘；等这本书下次正常刷新时补上。
