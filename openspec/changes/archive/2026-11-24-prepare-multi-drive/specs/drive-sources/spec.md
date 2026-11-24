## ADDED Requirements

### Requirement: 按前缀分派数据源
合成数据源 SHALL 按路径 / fsId 前缀把请求交给登记的数据源，无前缀的 MUST 交给主网盘（百度），以兼容既有数据。下载取流 MUST 交回解析出该地址的数据源。

#### Scenario: 登记的第三方网盘
- **WHEN** 登记了前缀 `aliyun:` 的数据源，书架上一本书的路径以 `aliyun:` 开头
- **THEN** 浏览、播放与离线下载都由该数据源处理，百度数据源不收到任何请求

### Requirement: 通用网页授权登录
App 内登录页 SHALL 只依赖网页授权接口（授权页地址、回跳识别、code 换令牌），任何实现该接口的网盘都能复用同一个登录页。

#### Scenario: 复用登录页
- **WHEN** 新网盘实现了网页授权接口
- **THEN** 无需新写 WebView 页面即可在 App 内完成登录
