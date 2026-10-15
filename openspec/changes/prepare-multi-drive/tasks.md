## 1. 数据源

- [x] 1.1 RoutingDriveSource：主网盘 + byPrefix 登记表；本机改为登记 `local:`
- [x] 1.2 ResolvedMedia.sourceId；openStream 按来源分派
- [x] 1.3 单元测试：前缀分派、下载取流回到原来源、批量元信息拆分、整盘扫描只走主网盘

## 2. 登录

- [x] 2.1 WebOAuthLogin 接口与 OAuthCallback；AuthRepository 实现
- [x] 2.2 WebLoginPage 通用化（含主页面加载失败的自有出错页）

## 3. 文档

- [x] 3.1 README「接入其他网盘」
