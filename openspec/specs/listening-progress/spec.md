# listening-progress Specification

## Purpose
TBD - created by archiving change add-netdisk-audiobook-mvp. Update Purpose after archive.
## Requirements
### Requirement: 播放进度记录与断点续播
系统 SHALL 记录每本书的当前章节与章节内播放位置，并在重新打开该书时从断点继续。

#### Scenario: 断点续播
- **WHEN** 用户退出应用后重新打开并进入某本书
- **THEN** 播放器定位到上次收听的章节与秒级位置

#### Scenario: 进度持续保存
- **WHEN** 用户正在播放
- **THEN** 系统按节流频率持久化播放位置，应用被系统强制结束后进度丢失 MUST NOT 超过节流间隔

#### Scenario: 书架继续收听
- **WHEN** 用户在书架点击「继续收听」
- **THEN** 系统直接从该书断点开始播放，无需用户手动选章

#### Scenario: 已听完的书重新播放
- **WHEN** 用户打开一本已标记「已听完」的书并点击播放
- **THEN** 系统从第一章开头开始播放并清除「已听完」标记

