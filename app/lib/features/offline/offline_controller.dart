import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yun_audiobook/app/providers.dart';
import 'package:yun_audiobook/data/local/settings_dao.dart';

part 'offline_controller.g.dart';

/// keepAlive：这是无状态的命令入口，没有人 watch 它。自动释放的话，
/// 方法里第一个 await 之后 provider 就已被回收，再 ref.read 会直接抛错
/// （真机上「加入书架」就这样静默失败过）。
@Riverpod(keepAlive: true)
class OfflineController extends _$OfflineController {
  @override
  void build() {}

  /// 改离线配额：先落盘再执行清理——不存的话下次进来又回到默认值。
  /// 正在播放的那一个永远不会被清理。
  Future<void> setQuotaGb(int gb) async {
    await ref
        .read(databaseProvider)
        .settingsDao
        .write(SettingsDao.offlineQuotaKey, '$gb');
    await ref.read(downloadManagerProvider).enforceQuota(
          gb * 1024 * 1024 * 1024,
          protectedSeriesId:
              ref.read(playbackSessionProvider).current.series?.id,
        );
  }

  Future<void> clearSeries(String seriesId) =>
      ref.read(downloadManagerProvider).clearSeriesCache(seriesId);
}
