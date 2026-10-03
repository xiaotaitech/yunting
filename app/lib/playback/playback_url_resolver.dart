import 'dart:io';

import 'package:yun_audiobook/core/logging.dart';
import 'package:yun_audiobook/data/drive/cloud_drive_source.dart';
import 'package:yun_audiobook/domain/entities.dart';

/// 条目可播放地址的唯一来源（design.md D3 / D7）。
///
/// 把两件事收敛在同一个组件里，别处不再有第二处分支：
///   1. 本地缓存优先——已下载的章节不发任何网盘请求
///   2. dlink 只在内存里带 TTL 缓存，绝不持久化（它会过期，存了就是脏数据）
class PlaybackUrlResolver {
  PlaybackUrlResolver(this._drive);

  final CloudDriveSource _drive;
  final Map<String, ResolvedMedia> _cache = {};

  /// 解析章节的播放地址。
  ///
  /// [forceRefresh] 用于播放中断后的恢复：作废旧地址并强制重取。
  Future<ResolvedMedia> resolve(Episode episode,
      {bool forceRefresh = false,}) async {
    // 本地缓存优先（offline-cache 规格「本地缓存优先」）
    final local = episode.localPath;
    if (episode.isCached && local != null && File(local).existsSync()) {
      return ResolvedMedia(
        url: Uri.file(local).toString(),
        isLocal: true,
        expiresAt: DateTime.now().add(const Duration(days: 3650)),
      );
    }

    if (!forceRefresh) {
      final cached = _cache[episode.fsId];
      if (cached != null && !cached.isStale) return cached;
    }

    final resolved = await _drive.resolveMedia(episode.fsId);
    _cache[episode.fsId] = resolved;
    Log.d('resolver', '已解析播放地址：${episode.title}');
    return resolved;
  }

  /// 作废某个章节的地址缓存。链接失效时由播放恢复流程调用。
  void invalidate(String fsId) => _cache.remove(fsId);

  /// 退出登录时必须清空——旧令牌拼出来的地址已经没有意义
  /// （netdisk-auth 规格「用户主动退出登录」）。
  void clear() => _cache.clear();

  /// 预取下一章地址，减少章节切换的静默间隙
  /// （audio-playback 规格「预取下一章地址」）。
  Future<void> prefetch(Episode? episode) async {
    if (episode == null || episode.isCached) return;
    final cached = _cache[episode.fsId];
    if (cached != null && !cached.isStale) return;
    try {
      _cache[episode.fsId] = await _drive.resolveMedia(episode.fsId);
      Log.d('resolver', '已预取下一章地址：${episode.title}');
    } on Object catch (e) {
      // 预取失败无所谓，真正播放时会再解析一次
      Log.d('resolver', '预取失败（忽略）：$e');
    }
  }
}
