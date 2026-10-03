import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yun_audiobook/app/providers.dart';
import 'package:yun_audiobook/data/local/settings_dao.dart';

part 'offline_controller.g.dart';

@riverpod
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
