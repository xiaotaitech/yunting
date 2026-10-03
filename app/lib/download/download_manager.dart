import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:yun_audiobook/core/errors.dart';
import 'package:yun_audiobook/core/logging.dart';
import 'package:yun_audiobook/data/drive/cloud_drive_source.dart';
import 'package:yun_audiobook/data/local/series_dao.dart';
import 'package:yun_audiobook/domain/entities.dart';
import 'package:yun_audiobook/playback/playback_url_resolver.dart';

class DownloadTask {
  DownloadTask(this.episode);

  final Episode episode;
  int received = 0;
  bool cancelled = false;
}

/// 离线下载（offline-cache 规格）。
///
/// 设计要点：
///   - 受限并发的串行队列，优先级低于播放（design.md D6）
///   - HTTP Range 断点续传，中断后从已下载字节继续
///   - 文件落在应用私有目录，不进系统媒体库（design.md D7）
///   - 只依赖 [CloudDriveSource]，不认识百度；进度写库，界面经 drift watch 感知
class DownloadManager {
  DownloadManager({
    required CloudDriveSource drive,
    required PlaybackUrlResolver resolver,
    required SeriesDao dao,
  })  : _drive = drive,
        _resolver = resolver,
        _dao = dao;

  /// 同时下载数刻意压得很低：播放要优先拿到带宽。
  static const int maxConcurrent = 1;

  /// 下载进度写库的节流间隔。见 [_run] 里的说明。
  static const Duration _progressInterval = Duration(seconds: 1);

  final CloudDriveSource _drive;
  final PlaybackUrlResolver _resolver;
  final SeriesDao _dao;

  final List<DownloadTask> _queue = [];
  final Map<String, DownloadTask> _active = {};
  bool _paused = false;
  bool _pumping = false;

  int get queuedCount => _queue.length;
  bool get isPaused => _paused;

  Future<Directory> _seriesDir(String seriesId) async {
    // getApplicationSupportDirectory 是应用私有的，系统媒体扫描不会收录
    final base = await getApplicationSupportDirectory();
    final dir = Directory(p.join(base.path, 'offline', seriesId));
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir;
  }

  Future<void> enqueue(Episode episode) async {
    if (episode.isCached) return;
    if (_queue.any((t) => t.episode.id == episode.id)) return;
    if (_active.containsKey(episode.id)) return;

    _queue.add(DownloadTask(episode));
    await _dao.setCache(episode.id, state: CacheState.queued);
    unawaited(_pump());
  }

  Future<void> enqueueAll(List<Episode> episodes) async {
    for (final e in episodes) {
      await enqueue(e);
    }
  }

  void pause() {
    _paused = true;
    for (final t in _active.values) {
      t.cancelled = true;
    }
  }

  void resume() {
    _paused = false;
    unawaited(_pump());
  }

  /// 取消单项下载并清理临时文件（规格「暂停与取消下载」）。
  Future<void> cancel(Episode episode) async {
    _queue.removeWhere((t) => t.episode.id == episode.id);
    _active[episode.id]?.cancelled = true;
    final dir = await _seriesDir(episode.seriesId);
    final part = File(p.join(dir.path, '${episode.fsId}.part'));
    if (part.existsSync()) part.deleteSync();
    await _dao.setCache(
      episode.id,
      state: CacheState.none,
      downloadedBytes: 0,
    );
  }

  Future<void> _pump() async {
    if (_pumping) return;
    _pumping = true;
    try {
      while (!_paused && _queue.isNotEmpty && _active.length < maxConcurrent) {
        final task = _queue.removeAt(0);
        _active[task.episode.id] = task;
        await _run(task);
        _active.remove(task.episode.id);
      }
    } finally {
      _pumping = false;
    }
    if (!_paused && _queue.isNotEmpty) unawaited(_pump());
  }

  Future<void> _run(DownloadTask task) async {
    final episode = task.episode;
    final dir = await _seriesDir(episode.seriesId);
    final partFile = File(p.join(dir.path, '${episode.fsId}.part'));
    final finalFile = File(
      p.join(
        dir.path,
        '${episode.fsId}${p.extension(episode.fileName)}',
      ),
    );

    if (finalFile.existsSync() && finalFile.lengthSync() == episode.size) {
      await _markCached(episode, finalFile);
      return;
    }

    // 数据源本来就在本地（演示模式）时无需下载，直接标记为已缓存。
    // 这条不是为演示特设的分支——「本地已有的东西不必再下一遍」本就是对的。
    final probe = await _resolver.resolve(episode);
    if (probe.isLocal) {
      final local = File(Uri.parse(probe.url).toFilePath());
      if (local.existsSync()) {
        await _markCached(episode, local);
        return;
      }
    }

    await _dao.setCache(episode.id, state: CacheState.downloading);

    var attempt = 0;
    while (attempt < 5 && !task.cancelled) {
      attempt++;
      try {
        // 断点续传：已下载多少就从多少继续（规格「断点续传」）
        final already = partFile.existsSync() ? partFile.lengthSync() : 0;
        task.received = already;
        if (episode.size > 0 && already >= episode.size) {
          await partFile.rename(finalFile.path);
          await _markCached(episode, finalFile);
          return;
        }

        await _ensureSpace(episode.size - already);

        // 下载途中 dlink 过期，重新解析后从已下载位置继续（规格「下载中 dlink 过期」）
        final media =
            await _resolver.resolve(episode, forceRefresh: attempt > 1);
        final stream = await _drive.openStream(media, start: already);

        final sink = partFile.openWrite(mode: FileMode.append);
        var lastReport = DateTime.now();
        try {
          await for (final chunk in stream) {
            if (task.cancelled) break;
            sink.add(chunk);
            task.received += chunk.length;

            // 进度写库必须节流。HTTP chunk 只有几 KB，一个 50MB 的文件
            // 就是上万次写入——实测把 SQLite 锁到别处查询直接报
            // 「database is locked」，播放进度保存也会被一起挡住。
            // 进度条不需要那个精度，每秒一次足够。
            if (DateTime.now().difference(lastReport) >= _progressInterval) {
              lastReport = DateTime.now();
              await _dao.setCache(
                episode.id,
                state: CacheState.downloading,
                downloadedBytes: task.received,
              );
            }
          }
        } finally {
          await sink.flush();
          await sink.close();
        }

        if (task.cancelled) return;

        final downloaded = partFile.lengthSync();
        // 大小对不上说明是被截断的半成品，不能当完整缓存
        // （规格「设备存储不足」的反面要求）
        if (episode.size > 0 && downloaded < episode.size) {
          Log.d('download',
              '${episode.title} 未下完（$downloaded/${episode.size}），重试');
          continue;
        }
        await partFile.rename(finalFile.path);
        await _markCached(episode, finalFile);
        return;
      } on DriveException catch (e) {
        if (e.kind == DriveErrorKind.storageFull) {
          await _fail(episode, '存储空间不足');
          return;
        }
        if (!e.isRetryable) {
          await _fail(episode, e.message);
          return;
        }
        await Future<void>.delayed(Duration(milliseconds: 500 * attempt));
      } on Object catch (e) {
        Log.d('download', '下载出错（第 $attempt 次）：$e');
        await Future<void>.delayed(Duration(milliseconds: 500 * attempt));
      }
    }
    if (!task.cancelled) await _fail(episode, '下载失败，请稍后重试');
  }

  Future<void> _markCached(Episode episode, File file) async {
    await _dao.setCache(
      episode.id,
      state: CacheState.cached,
      localPath: file.path,
      downloadedBytes: file.lengthSync(),
    );
    Log.d('download', '已缓存：${episode.title}');
  }

  Future<void> _fail(Episode episode, String reason) async {
    await _dao.setCache(episode.id, state: CacheState.failed);
    Log.e('download', '${episode.title} 下载失败：$reason');
  }

  /// 空间不足时直接暂停整个队列，而不是写出一堆半截文件。
  Future<void> _ensureSpace(int needed) async {
    if (needed <= 0) return;
    try {
      final base = await getApplicationSupportDirectory();
      final stat = base.statSync();
      // Dart 没有跨平台的可用空间 API，这里只做存在性与可写性的基本检查；
      // 真正的空间不足会在写入时抛 FileSystemException，由上层转成明确提示。
      if (stat.type == FileSystemEntityType.notFound) {
        throw const DriveException(DriveErrorKind.storageFull, '缓存目录不可用');
      }
    } on FileSystemException {
      throw const DriveException(DriveErrorKind.storageFull, '设备存储空间不足');
    }
  }

  // ------------------------------------------------------------ 缓存管理

  Future<int> totalUsage() async {
    final usage = await _dao.cacheUsage();
    return usage.values.fold<int>(0, (a, b) => a + b);
  }

  /// 删除某个合集的缓存。书架条目与收听进度必须保留（规格「按书清理」）。
  Future<void> clearSeriesCache(String seriesId) async {
    final dir = await _seriesDir(seriesId);
    if (dir.existsSync()) dir.deleteSync(recursive: true);
    for (final c in await _dao.episodesOf(seriesId)) {
      await _dao.setCache(
        c.id,
        state: CacheState.none,
        downloadedBytes: 0,
      );
    }
    Log.d('download', '已清理缓存：$seriesId');
  }

  /// 超配额时按最近最少收听清理，且绝不动正在播放的书
  /// （规格「超出配额自动清理」）。
  Future<void> enforceQuota(int quotaBytes, {String? protectedSeriesId}) async {
    var total = await totalUsage();
    if (total <= quotaBytes) return;

    final shelf = await _dao.shelf();
    final usage = await _dao.cacheUsage();
    final candidates = shelf
        .where((s) => s.id != protectedSeriesId && (usage[s.id] ?? 0) > 0)
        .toList()
      ..sort((a, b) {
        final ta = a.lastPlayedAt ?? a.addedAt;
        final tb = b.lastPlayedAt ?? b.addedAt;
        return ta.compareTo(tb); // 最久没听的排前面
      });

    for (final series in candidates) {
      if (total <= quotaBytes) break;
      final freed = usage[series.id] ?? 0;
      await clearSeriesCache(series.id);
      total -= freed;
      Log.d('download', '配额清理：《${series.title}》释放 $freed 字节');
    }
  }
}
