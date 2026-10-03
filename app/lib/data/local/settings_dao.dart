import 'package:drift/drift.dart';

import 'package:yun_audiobook/data/local/database.dart';

part 'settings_dao.g.dart';

/// 本地键值设置（sync_meta 表）。只存本机，不进同步文件。
@DriftAccessor(tables: [SyncMeta])
class SettingsDao extends DatabaseAccessor<AppDatabase>
    with _$SettingsDaoMixin {
  SettingsDao(super.attachedDatabase);

  /// 离线缓存上限（GB）。
  static const offlineQuotaKey = 'offline_quota_gb';
  static const offlineQuotaDefaultGb = 5;

  /// 视频清晰度：'720'（默认）或 '480'。只影响之后打开的视频。
  static const videoQualityKey = 'video_quality';
  static const videoQualityDefault = '720';

  /// 自动提示过的最新版本：同一版本只自动提示一次。
  static const updateSeenKey = 'update_seen';

  Future<String?> read(String key) async =>
      (await (select(syncMeta)..where((m) => m.key.equals(key)))
              .getSingleOrNull())
          ?.value;

  Stream<String?> watch(String key) =>
      (select(syncMeta)..where((m) => m.key.equals(key)))
          .watchSingleOrNull()
          .map((r) => r?.value);

  Future<void> write(String key, String value) => into(syncMeta)
      .insertOnConflictUpdate(SyncMetaCompanion.insert(key: key, value: value));
}
