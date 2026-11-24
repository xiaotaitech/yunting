## Why

登录要跳出 App：点「授权百度网盘」后打开系统浏览器，在百度设备授权页手动输入 App 里显示的用户码，再切回 App 等轮询。用户要求尽量在 App 内完成。

百度授权码模式支持 `redirect_uri=oob`（实测线上 AppKey 打开手机版授权页正常，显示「登录并授权」与短信登录），授权完成跳到固定地址 `openapi.baidu.com/oauth/2.0/login_success?code=…`。OAuth 代理早已有 `/oauth/authorize-url` 与 `/oauth/exchange`，只是 App 没用。

## What Changes

- 登录主路径改为 App 内登录：WebView 打开百度手机版授权页，用户在里面登录并授权；拦截 `login_success` 回跳拿到 code，经代理换令牌。
- WebView 只放行 http(s)，拦掉唤起百度 App 的自定义 scheme；返回键先在网页内后退。
- 设备码授权保留为备用入口「改用浏览器或其他设备授权」。
- 新增依赖 `webview_flutter`（用系统 WebView，体积增量小）。

## 不做

- 代理改动（接口已存在）。
- 自动填充账号密码（purser 等）。
