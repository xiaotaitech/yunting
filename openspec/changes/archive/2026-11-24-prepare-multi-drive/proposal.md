## Why

用户要求「预留接入第三方网盘的口子」。现状：`CloudDriveSource` 接口已抽象，但合成源 `RoutingDriveSource` 写死了「百度 / 本机」二选一，下载取流一律交给百度；登录（`AuthRepository`、App 内登录页）是百度专用的。接第二家网盘要动这些地方。

## What Changes

- `RoutingDriveSource` 改为「主网盘 + 按前缀登记的其它源」：路径 / fsId 带 `<id>:` 前缀的交给对应源，无前缀归主网盘（百度，兼容老数据）；批量元信息按来源拆分再合并。
- `ResolvedMedia` 增加 `sourceId`，由合成源填上；下载时 `openStream` 交回解析出地址的那个源。
- 抽出 `WebOAuthLogin` 接口（授权页地址、回跳识别、code 换令牌），`AuthRepository` 实现它；App 内登录页改为通用的 `WebLoginPage`。
- README 增加「接入其他网盘」步骤。

## 不做

- 实现任何第二家网盘（阿里云盘、115、夸克等）。
- 多账号同时登录的界面、令牌存储的多实例化——等真接第二家时按其授权方式再定。
