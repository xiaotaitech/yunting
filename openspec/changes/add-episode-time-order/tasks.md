## 1. 数据：把文件时间带进章节

- [x] 1.1 `DriveEntry` 加 `serverCtime`：百度读 `server_ctime`，目录缓存 JSON 加 `ctime`（老缓存缺键读成 null），本机数据源两个时间都取修改时间，演示数据源造递增时间
- [ ] 1.2 schema v5：`chapters` 加 `created_at` / `synced_at`，`books` 加 `episode_order`（默认 `name`）；`Episode` 加 `createdAt` / `syncedAt`，`Series` 加 `episodeOrder` 枚举，DAO 读写映射

## 2. 排序

- [ ] 2.1 `_buildEpisodes` 按书的排序方式建顺序：按名称维持现状；按时间按上传时间 → 同步时间 → 自然序升序；两个分支（含手动排序下的追加分支）都写入时间
- [ ] 2.2 `LibraryRepository.setEpisodeOrder`：写排序方式、清 `orderEditedByUser`、整本刷新一次

## 3. 界面与文档

- [ ] 3.1 书详情页菜单加「章节排序：按名称 / 按时间」，章节行显示「M月D日同步」（不是今年带年份；时间未知不显示）
- [ ] 3.2 文档：`assets/help.md` 加按时间排序与同步日期的说明，README 功能列表同步

## 4. 验证

- [ ] 4.1 演示模式在模拟器上跑通：切到按时间、看到同步日期、切回按名称（截图）
