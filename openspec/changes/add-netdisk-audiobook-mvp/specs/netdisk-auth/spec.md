## ADDED Requirements

### Requirement: 百度网盘 OAuth 授权登录
系统 SHALL 通过百度网盘开放平台的 OAuth 2.0 授权码模式获取用户授权，`scope` 参数 MUST 固定为 `basic,netdisk`。`code → token` 的交换 MUST 由服务端 OAuth 代理完成，AppSecret MUST NOT 出现在客户端。

#### Scenario: 首次授权成功
- **WHEN** 用户在登录页点击「授权百度网盘」并在百度授权页完成同意
- **THEN** 客户端拿到回调中的 `code`，交给 OAuth 代理换取 `access_token` 与 `refresh_token`，安全存储于设备后进入书架页

#### Scenario: 用户在授权页取消
- **WHEN** 用户在百度授权页点击拒绝或直接返回
- **THEN** 系统停留在登录页并提示「未完成授权」，不产生任何本地凭证

#### Scenario: scope 传参错误
- **WHEN** 授权请求的 scope 不是 `basic,netdisk`，导致后续接口返回 `errno=-6`
- **THEN** 系统 SHALL 将其识别为授权配置错误并引导用户重新授权，而非当作普通网络错误重试

### Requirement: 令牌生命周期管理
系统 SHALL 在 `access_token` 临近过期或收到鉴权失败响应时，使用 `refresh_token` 自动换取新令牌，全过程对用户无感。

#### Scenario: 令牌过期自动刷新
- **WHEN** 任一网盘接口因令牌过期而失败
- **THEN** 系统自动调用 OAuth 代理刷新令牌，并用新令牌重放该请求；用户不感知中断

#### Scenario: refresh_token 失效
- **WHEN** 刷新令牌本身已失效或被用户在百度侧解除授权
- **THEN** 系统清除本地凭证、跳转登录页并提示需要重新授权；本地书架与进度数据 MUST 保留不被删除

#### Scenario: 并发请求下的刷新
- **WHEN** 多个网盘请求同时遭遇令牌过期
- **THEN** 系统 SHALL 只发起一次刷新，其余请求等待该次刷新结果后重放

### Requirement: 凭证安全存储与退出登录
令牌 MUST 存储在平台安全存储中（Android Keystore / iOS Keychain），MUST NOT 以明文写入普通配置文件或日志。

#### Scenario: 用户主动退出登录
- **WHEN** 用户在设置页点击「退出登录」并确认
- **THEN** 系统清除本地令牌与内存中的 dlink 缓存，返回登录页

#### Scenario: 日志脱敏
- **WHEN** 系统记录任何网络请求日志
- **THEN** `access_token`、`refresh_token` 与 dlink MUST 被脱敏，不得完整出现在日志中
