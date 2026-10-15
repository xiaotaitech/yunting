## ADDED Requirements

### Requirement: App 内登录
登录 SHALL 默认在 App 内完成：百度授权页在内置 WebView 中打开，用户授权后 App MUST 拦截 `openapi.baidu.com/oauth/2.0/login_success` 回跳，取得 code 并经 OAuth 代理换取令牌；AppSecret MUST NOT 出现在客户端。WebView MUST NOT 跳转到非 http(s) 的地址。

#### Scenario: 内置页面登录
- **WHEN** 用户在登录页点「登录百度网盘」并在内置页面完成登录与授权
- **THEN** 登录页关闭，App 进入书架，全程没有离开 App

#### Scenario: 拒绝授权
- **WHEN** 用户在授权页拒绝
- **THEN** 回到登录页并提示已取消，可重新登录

### Requirement: 设备码备用
登录页 SHALL 保留设备码授权入口，供内置页面无法完成登录时在浏览器或其他设备上授权。

#### Scenario: 改用设备码
- **WHEN** 用户点「改用浏览器或其他设备授权」
- **THEN** 显示用户码与授权页地址，并轮询授权结果
