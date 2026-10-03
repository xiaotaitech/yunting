import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yun_audiobook/app/providers.dart';
import 'package:yun_audiobook/domain/entities.dart';

part 'library_controller.g.dart';

/// 书架变更的唯一入口。每个改动之后都标记待同步——
/// 原来 `markDirty` 散落在界面里手动调，漏一处就少同步一次。
@riverpod
class LibraryController extends _$LibraryController {
  @override
  void build() {}

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

  Future<void> downloadAll(Series series) async {
    final episodes = await ref.read(episodesProvider(series.id).future);
    await ref.read(downloadManagerProvider).enqueueAll(episodes);
  }

  Future<void> download(Episode episode) =>
      ref.read(downloadManagerProvider).enqueue(episode);

  Future<void> cancelDownload(Episode episode) =>
      ref.read(downloadManagerProvider).cancel(episode);

  Future<void> clearCache(Series series) =>
      ref.read(downloadManagerProvider).clearSeriesCache(series.id);
}
