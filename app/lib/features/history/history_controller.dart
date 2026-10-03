import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yun_audiobook/app/providers.dart';

part 'history_controller.g.dart';

@riverpod
class HistoryController extends _$HistoryController {
  @override
  void build() {}

  Future<void> delete(int entryId) =>
      ref.read(databaseProvider).historyDao.deleteEntry(entryId);

  Future<void> clear() => ref.read(databaseProvider).historyDao.clear();
}
