## ADDED Requirements

### Requirement: 应用图标
应用 SHALL 使用云听书自己的标志（品牌绿背景上的白色云朵，云中四根音频条）作为启动图标。Android 8.0 及以上 SHALL 使用自适应图标（背景与前景分层，前景位于安全区内），并提供单色图层供系统主题图标使用；更低版本与 iOS 使用同一标志渲染的位图。应用 MUST NOT 使用 Flutter 默认图标。

#### Scenario: 桌面显示
- **WHEN** 用户安装应用后查看桌面
- **THEN** 图标为绿色背景上的白色云朵与音频条，名称为"云听书"

#### Scenario: 主题图标
- **WHEN** Android 13 及以上开启主题图标
- **THEN** 显示单色的云朵，音频条镂空

### Requirement: 通知栏图标
后台播放的通知 SHALL 使用云听书自己的单色小图标。

#### Scenario: 后台播放
- **WHEN** 用户开始播放后退到后台
- **THEN** 通知栏显示云朵小图标

### Requirement: 应用内标志
登录页 SHALL 显示与启动图标相同的标志。

#### Scenario: 打开登录页
- **WHEN** 未授权用户打开应用
- **THEN** 登录页顶部显示云听书标志
