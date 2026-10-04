## 1. 实现
- [x] 1.1 PlaybackSession.reset；LibraryRepository.restore
- [x] 1.2 LibraryController.removeMany / undoRemove，缓存延后清理
- [x] 1.3 书架管理模式界面（长按 / 管理入口、全选、确认、撤销、返回键退出）
- [x] 1.4 启动时补清孤儿缓存

## 2. 验证
- [x] 2.1 测试：批量移出、撤销恢复进度与时间戳、缓存延后且撤销的不清、移出在播/非在播
- [x] 2.2 模拟器：长按进入、多选、确认移出、撤销恢复
