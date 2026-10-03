## Context

前置调研（2026-10-03/04，真实网盘实测）：
- 原文件 dlink 非会员约 94 KB/s，课程原片码率约 2.2 Mbps，不可流播。
- 转码流 `xpan/file?method=streaming&type=M3U8_AUTO_720|480`：非会员首次返回 `errno=133, adTime=8, adToken`，
  等 adTime 秒后带 `adToken` 重请求得到 M3U8；720p 分片 10 秒、约 240 kbps，实测下载约为播放所需 7 倍。
- 分片地址不校验 UA，约 8 小时失效。
- 验证：video_player 以 `networkUrl(file://….m3u8, formatHint: hls)` 播放本地 M3U8 + 百度远程分片，
  可正常起播、跳转、持续缓冲。

## Decisions

### D1 取流在 Dart 里完成，M3U8 落本地文件
BaiduDriveSource.resolveMedia 对视频走转码接口（含 adToken 等待），把 M3U8 写到临时目录，
返回 `ResolvedMedia(url: file://…, kind: hls, isLocal: false, expiresAt: +7h)`。
`isLocal=false`：分片仍是远程的，会过期，恢复流程照常作废重取。
不用本地 HTTP 代理（Android 9+ 禁明文，项目里踩过）。

### D2 组合内核
`VideoEngine`（video_player）与 `JustAudioEngine` 都实现 MediaEngine；`CompositeEngine` 按
`ResolvedMedia.mediaKind` 切到对应内核、转发其事件，另一个停下。PlaybackSession 不感知视频。
视频内核开 `allowBackgroundPlayback`，退后台声音继续；通知栏仍由 AudioServiceBridge 负责。
视频画面通过 `videoControllerProvider`（VideoEngine 暴露的 ValueListenable）给界面。

### D3 播放页按条目类型切换
音频沿用现有播放页；视频条目显示画面区（16:9，可全屏横屏）+ 同一套进度/传输控件。
「准备中」时视频条目显示「正在准备视频（约 8 秒）」。

### D4 课程识别
`mediaKindOf` 加视频扩展名；认领时含视频即 `SeriesKind.course`。ID3 探测只对音频。

### D5 清晰度
本地设置 `video_quality`（720/480），BaiduDriveSource 取流时读取。

## Risks

- adToken 规则是百度的非公开行为，可能变化 → 取流失败按 DriveException(api) 报出，可重试。
- 演示模式：用 ffmpeg 生成的本地 HLS（随包资源，约 200KB）演示视频播放，不联网。
