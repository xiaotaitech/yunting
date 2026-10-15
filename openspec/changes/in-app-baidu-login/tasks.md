## 1. 授权

- [x] 1.1 AuthRepository：authorizeUrl / exchangeCode，与设备码共用落令牌逻辑
- [x] 1.2 OAuthCallback.parse：只认 openapi.baidu.com 的 login_success，区分 code 与拒绝
- [x] 1.3 单元测试：回跳识别、换令牌成功 / 失败

## 2. 界面

- [x] 2.1 BaiduLoginPage：WebView、进度条、只放行 http(s)、返回键网页内后退
- [x] 2.2 登录页：主按钮 App 内登录，设备码降为备用入口

## 3. 验证

- [x] 3.1 flutter analyze、flutter test
- [x] 3.2 模拟器：App 内打开授权页（页面与授权项显示正常；登录表单因模拟器网络对百度登录 CDN 的 TLS 被重置未出现，同地址用模拟器 Chrome 亦然，桌面浏览器正常）
- [ ] 3.3 真机：用真实账号走完登录 → 授权 → 回到书架（需要用户账号）
