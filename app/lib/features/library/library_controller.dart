import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yun_audiobook/app/providers.dart';
import 'package:yun_audiobook/domain/entities.dart';

part 'library_controller.g.dart';

/// 书架变更的唯一入口。每个改动之后都标记待同步——
/// 原来 `markDirty` 散落在界面里手动调，漏一处就少同步一次。
/// keepAlive：这是无状态的命令入口，没有人 watch 它。自动释放的话，
/// 方法里第一个 await 之后 provider 就已被回收，再 ref.read 会直接抛错
/// （真机上「加入书架」就这样静默失败过）。
@Riverpod(keepAlive: true)
class LibraryController extends _$LibraryController {
  @override
  void build() {}

  // 一次性查询。不要用 `ref.read(xxxProvider.future)` 代替：那些是自动释放的
  // 流 provider，没有监听者时会在发出第一个值之前就被回收，直接抛
  // 「disposed during loading state」（真机上点播放就这样失败过）。

  Future<List<Episode>> episodesOf(String seriesId) =>
      ref.read(databaseProvider).seriesDao.episodesOf(seriesId);

  /// 书架上（未删除）的全部合集。
  Future<List<Series>> shelfOnce() =>
      ref.read(databaseProvider).seriesDao.shelf();

  /// 书架上的这个合集；已移出书架的返回 null。
  Future<Series?> onShelf(String seriesId) async =>
      (await shelfOnce()).where((s) => s.id == seriesId).firstOrNull;

  /// 认领网盘文件夹为合集。
  Future<Series> claim(String folderPath, {String? title}) async {
    final series = await ref
        .read(libraryRepositoryProvider)
        .claimFolder(folderPath, titleOverride: title);
    ref.read(librarySyncProvider).markDirty();
    return series;
  }

  /// 重新扫描网盘里的条目。只影响本地派生数据，不需要同步。
  Future<void> refresh(Series series) =>
      ref.read(libraryRepositoryProvider).refresh(series);

  Future<void> edit(Series series, {String? title, String? author}) async {
    await ref
        .read(libraryRepositoryProvider)
        .edit(series, title: title, author: author);
    ref.read(librarySyncProvider).markDirty();
  }

  Future<void> reorder(Series series, List<Episode> ordered) async {
    await ref.read(libraryRepositoryProvider).reorder(series, ordered);
    ref.read(librarySyncProvider).markDirty();
  }

  /// 移出书架：连同离线缓存一起清掉，网盘原文件一个字节不动。
  Future<void> remove(Series series) async {
    await ref.read(downloadManagerProvider).clearSeriesCache(series.id);
    await ref.read(libraryRepositoryProvider).remove(series.id);
    ref.read(librarySyncProvider).markDirty();
  }

  /// 课程视频走转码流，没有可离线的文件（add-video-courses「课程不提供离线」），只下音频。
  Future<void> downloadAll(Series series) async {
    final episodes = await episodesOf(series.id);
    await ref.read(downloadManagerProvider).enqueueAll(
          episodes.where((e) => e.mediaKind == MediaKind.audio).toList(),
        );
  }

  Future<void> download(Episode episode) async {
    if (episode.mediaKind == MediaKind.video) return;
    await ref.read(downloadManagerProvider).enqueue(episode);
  }

  Future<void> cancelDownload(Episode episode) =>
      ref.read(downloadManagerProvider).cancel(episode);

  Future<void> clearCache(Series series) =>
      ref.read(downloadManagerProvider).clearSeriesCache(series.id);
}
