import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yun_audiobook/app/providers.dart';

part 'history_controller.g.dart';

/// keepAlive：这是无状态的命令入口，没有人 watch 它。自动释放的话，
/// 方法里第一个 await 之后 provider 就已被回收，再 ref.read 会直接抛错
/// （真机上「加入书架」就这样静默失败过）。
@Riverpod(keepAlive: true)
class HistoryController extends _$HistoryController {
  @override
  void build() {}

  Future<void> delete(int entryId) =>
      ref.read(databaseProvider).historyDao.deleteEntry(entryId);

  Future<void> clear() => ref.read(databaseProvider).historyDao.clear();
}
