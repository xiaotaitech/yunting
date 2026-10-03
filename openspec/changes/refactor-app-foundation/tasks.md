## 1. 工具链

- [ ] 1.1 依赖：riverpod 3 + generator、freezed、json_serializable、drift、go_router、intl、very_good_analysis、fake_async
- [ ] 1.2 analysis_options 切到 very_good_analysis（D1 列出的例外）
- [ ] 1.3 l10n 脚手架：l10n.yaml、app_zh.arb

## 2. 领域与数据

- [ ] 2.1 freezed 实体：Series / Episode / PlayHistoryEntry / AudioTags，MediaKind / SeriesKind
- [ ] 2.2 drift 库：表定义对齐 v2 列名，毫秒时间转换器，v1→2→3 迁移，foreign_keys
- [ ] 2.3 DAO 迁移到 drift：SeriesDao（原 BookDao）、HistoryDao、SettingsDao（sync_meta）
- [ ] 2.4 迁移测试：v2 原始 SQL 造库 → drift 打开逐列比对；原 DAO 测试迁移
- [ ] 2.5 CloudDriveSource.openRange；ResolvedMedia.kind；百度与演示实现
- [ ] 2.6 同步快照 v2（freezed + json），读 v1 兼容
- [ ] 2.7 LibraryRepository 去重（子目录展开只留一处）

## 3. 播放

- [ ] 3.1 MediaEngine 接口 + JustAudioEngine
- [ ] 3.2 PlaybackSession + PlaybackSink；行为逐条对齐原 AudiobookHandler
- [ ] 3.3 AudioServiceBridge
- [ ] 3.4 Session 测试（FakeEngine + fake_async）：超时、卡死、恢复退避、鉴权、弱网、进度节流、章末/全书、定时、竞态

## 4. 下载

- [ ] 4.1 DownloadManager 只依赖 CloudDriveSource；测试断点续传、取消、配额

## 5. 应用层

- [ ] 5.1 providers 装配 + bootstrapProvider + 启动页
- [ ] 5.2 go_router（StatefulShellRoute 三栏 + 详情/浏览/播放/离线/帮助/登录）
- [ ] 5.3 controllers：playback、shelf、series、browse、history、offline、account、update

## 6. 界面迁移（观感不变）

- [ ] 6.1 书架、续听卡片
- [ ] 6.2 详情、浏览
- [ ] 6.3 播放页（拆小 widget）、迷你播放条
- [ ] 6.4 历史、我的、离线、帮助、登录、配置引导、更新对话框
- [ ] 6.5 全部文案进 ARB

## 7. 收尾

- [ ] 7.1 CI / release 增加 build_runner；覆盖率
- [ ] 7.2 README 开发章节更新
- [ ] 7.3 flutter analyze 零告警、flutter test 全绿、release APK 可构建；演示模式模拟器冒烟
