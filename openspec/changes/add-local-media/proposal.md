## Why

手机里本来就有的有声书、录音、课程视频，也想用同一个书架来听、来看，享受同样的续播、倍速、定时与历史。

## What Changes

- 「添加书籍」新增「网盘 / 本机」切换；本机栏读系统 MediaStore，按文件夹列出全部音频 / 视频，
  可搜索、一键加入，体验与网盘栏一致。首次使用申请「音乐和音频」/「照片和视频」权限（14 起视频支持部分授权）。
- 本机书直接播放 content:// 地址，不复制、不上传；不提供离线下载。
- 本机书不进同步文件（文件只在这台手机上）。
- 来源由路径 / fsId 的 `local:` 前缀区分，不改库表、不需要迁移。

## Impact

- 新增原生 MethodChannel `yun/media`（Kotlin，无第三方依赖）；Manifest 增加三项媒体读取权限。
- RoutingDriveSource 合成网盘与本机两个数据源；CompositeEngine 新增「不设 UA」的本机音频内核
  （just_audio 设了 UA 时会经回环代理，而代理不认 content://）。
- 仅 Android。
