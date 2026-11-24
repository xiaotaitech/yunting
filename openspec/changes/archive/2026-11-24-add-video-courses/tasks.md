## 1. 数据
- [x] 1.1 视频扩展名识别；认领时 kind=course
- [x] 1.2 resolveMedia(fsId, path, kind)；百度转码取流 + adToken + 落本地 M3U8；清晰度设置
- [x] 1.3 演示数据源：示例课程（本地 HLS 资源）
- [x] 1.4 添加页「有声书 / 课程」两栏（listMediaFiles(video)）

## 2. 播放
- [x] 2.1 VideoEngine（video_player）
- [x] 2.2 CompositeEngine 按媒体类型切换内核
- [x] 2.3 测试：组合内核切换与事件转发；百度取流（adToken 流程、错误）

## 3. 界面
- [x] 3.1 视频播放页（画面、全屏横屏、准备中提示）
- [x] 3.2 课程详情与下载入口隐藏；下载全部跳过视频
- [x] 3.3 「我的」清晰度设置

## 4. 收尾
- [x] 4.1 analyze / test 全绿；APK ≤ 20MB；演示模式模拟器冒烟（视频播放、全屏、自动下一课、后台声音）
