import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:yun_audiobook/data/drive/cloud_drive_source.dart';
import 'package:yun_audiobook/data/local/database.dart';

part 'drive_cache_dao.g.dart';

/// 网盘目录列表的本地副本（local-first-drawer-ui）。
///
/// 「添加书籍」整盘扫描要 1–3 秒、按目录浏览每层都要等网络；
/// 先给上次的结果，后台再刷新。
@DriftAccessor(tables: [DriveCache])
class DriveCacheDao extends DatabaseAccessor<AppDatabase>
    with _$DriveCacheDaoMixin {
  DriveCacheDao(super.attachedDatabase);

  /// 没缓存过返回 null（与「缓存过、但是空目录」区分开）。
  Future<List<DriveEntry>?> read(String key) async {
    final row = await (select(driveCache)..where((c) => c.key.equals(key)))
        .getSingleOrNull();
    if (row == null) return null;
    return [
      for (final e in jsonDecode(row.json) as List<Object?>)
        DriveEntry.fromJson(e! as Map<String, Object?>),
    ];
  }

  Future<void> write(String key, List<DriveEntry> entries) =>
      into(driveCache).insertOnConflictUpdate(
        DriveCacheCompanion.insert(
          key: key,
          json: jsonEncode([for (final e in entries) e.toJson()]),
          fetchedAt: DateTime.now().millisecondsSinceEpoch,
        ),
      );

  /// 退出登录时整表清掉：换了账号，旧目录毫无意义。
  Future<void> clear() => delete(driveCache).go();
}
