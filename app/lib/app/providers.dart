/// Provider 装配（refactor-app-foundation D7）。
///
/// 读：drift 的 watch 流直接变成 StreamProvider，库一变界面自动刷新，
/// 不再有手动 invalidate。写：走 features 里的 controller。
library;

import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:video_player/video_player.dart';
import 'package:yun_audiobook/app/app_services.dart';
import 'package:yun_audiobook/core/config.dart';
import 'package:yun_audiobook/core/natural_sort.dart';
import 'package:yun_audiobook/data/auth/auth_repository.dart';
import 'package:yun_audiobook/data/drive/cloud_drive_source.dart';
import 'package:yun_audiobook/data/local/database.dart';
import 'package:yun_audiobook/data/local/settings_dao.dart';
import 'package:yun_audiobook/data/repositories/library_repository.dart';
import 'package:yun_audiobook/data/sync/library_sync.dart';
import 'package:yun_audiobook/domain/continue_listening.dart';
import 'package:yun_audiobook/domain/entities.dart';
import 'package:yun_audiobook/domain/media_folders.dart';
import 'package:yun_audiobook/download/download_manager.dart';
import 'package:yun_audiobook/features/update/app_updater.dart';
import 'package:yun_audiobook/playback/audio_service_bridge.dart';
import 'package:yun_audiobook/playback/playback_session.dart';

part 'providers.g.dart';

// ------------------------------------------------------------ 装配

/// 启动装配。界面在它完成前显示启动页，失败显示原因与重试。
@Riverpod(keepAlive: true)
Future<AppServices> bootstrap(Ref ref) => AppServices.create();

/// 只在 bootstrap 完成之后才会被读到（路由在那之前不存在）。
@Riverpod(keepAlive: true)
AppServices services(Ref ref) => ref.watch(bootstrapProvider).requireValue;

@Riverpod(keepAlive: true)
AppDatabase database(Ref ref) => ref.watch(servicesProvider).database;

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) => ref.watch(servicesProvider).auth;

@Riverpod(keepAlive: true)
LibraryRepository libraryRepository(Ref ref) =>
    ref.watch(servicesProvider).library;

@Riverpod(keepAlive: true)
LibrarySync librarySync(Ref ref) => ref.watch(servicesProvider).sync;

@Riverpod(keepAlive: true)
DownloadManager downloadManager(Ref ref) =>
    ref.watch(servicesProvider).downloads;

@Riverpod(keepAlive: true)
PlaybackSession playbackSession(Ref ref) => ref.watch(servicesProvider).session;

@Riverpod(keepAlive: true)
AudioServiceBridge audioBridge(Ref ref) => ref.watch(servicesProvider).bridge;

/// 当前的视频播放器实例（无视频时为 null）。播放页用它画画面。
@Riverpod(keepAlive: true)
Stream<VideoPlayerController?> videoController(Ref ref) async* {
  final engine = ref.watch(servicesProvider).videoEngine;
  final changes = StreamController<VideoPlayerController?>();
  void push() => changes.add(engine.controller.value);
  engine.controller.addListener(push);
  ref.onDispose(() {
    engine.controller.removeListener(push);
    unawaited(changes.close());
  });
  yield engine.controller.value;
  yield* changes.stream;
}

/// 视频清晰度（'720' / '480'）。
@riverpod
Stream<String> videoQuality(Ref ref) => ref
    .watch(databaseProvider)
    .settingsDao
    .watch(SettingsDao.videoQualityKey)
    .map((v) => v ?? SettingsDao.videoQualityDefault);

@Riverpod(keepAlive: true)
AppUpdater appUpdater(Ref ref) =>
    AppUpdater(client: http.Client(), repo: AppConfig.releaseRepo);

// ------------------------------------------------------------ 读模型

@riverpod
Stream<AuthState> authState(Ref ref) async* {
  final auth = ref.watch(authRepositoryProvider);
  yield auth.currentState;
  yield* auth.stateChanges;
}

/// 书架列表（未删除，最近收听在前）。
@riverpod
Stream<List<Series>> shelf(Ref ref) =>
    ref.watch(databaseProvider).seriesDao.watchShelf();

@riverpod
Stream<Series?> series(Ref ref, String seriesId) =>
    ref.watch(databaseProvider).seriesDao.watchSeries(seriesId);

@riverpod
Stream<List<Episode>> episodes(Ref ref, String seriesId) =>
    ref.watch(databaseProvider).seriesDao.watchEpisodes(seriesId);

/// 首页续听入口（listening-progress 规格「首页续听入口」）。
///
/// 数据取自 books 表而不是 play_history：历史只存本机，换台设备就是空的，
/// 而合集进度会随 library.json 同步回来——首页续听在新设备上也得接得上。
/// 全程只读本地库，不碰网络：冷启动时 token 可能正在刷新，卡片仍要立刻可见。
@riverpod
Future<ContinueListening?> continueListening(Ref ref) async {
  final shelf = await ref.watch(shelfProvider.future);
  final series = ContinueListening.mostRecentlyPlayed(shelf);
  // 一个都没播过（含书架为空）时不给卡片——没有断点可续。
  if (series == null) return null;
  final episodes = await ref.watch(episodesProvider(series.id).future);
  return ContinueListening.from(series, episodes);
}

/// 目录浏览。目录在前、文件在后，各自按**自然序**排列。
///
/// 用字典序会把「第10章」排在「第1章」前面——认领之后条目是自然序的，
/// 浏览时却不是，同一批文件在两个界面顺序不一致，很难不让人以为排错了。
@riverpod
Future<List<DriveEntry>> browse(Ref ref, String path) async {
  final entries = await ref.watch(libraryRepositoryProvider).browse(path);
  return entries
    ..sort((a, b) {
      if (a.isDirectory != b.isDirectory) return a.isDirectory ? -1 : 1;
      return compareNatural(a.name, b.name);
    });
}

/// 网盘目录对应的书架条目（未删除的），用于浏览时显示「已在书架中」。
@riverpod
Future<Series?> seriesAtFolder(Ref ref, String folderPath) {
  ref.watch(shelfProvider);
  return ref.watch(databaseProvider).seriesDao.seriesByFolder(folderPath);
}

/// 网盘里所有装着某类媒体的文件夹（「添加书籍」页的有声书 / 课程两栏）。
///
/// keepAlive：一次扫描整盘要 1–3 秒，本次会话内反复进出添加页不必重扫；
/// 想看新传上去的文件就在页面上下拉刷新（`ref.refresh`）。
@Riverpod(keepAlive: true)
Future<List<MediaFolder>> mediaFolders(Ref ref, MediaKind kind) async =>
    groupIntoFolders(
      await ref.watch(servicesProvider).drive.listMediaFiles(kind),
    );

/// 本机里装着某类媒体的文件夹（「添加书籍」本机栏）。读 MediaStore 很快，刷新即重查。
@Riverpod(keepAlive: true)
Future<List<MediaFolder>> localMediaFolders(Ref ref, MediaKind kind) async =>
    groupIntoFolders(
      await ref.watch(servicesProvider).localMedia.listMediaFiles(kind),
    );

/// 是否已授权读取本机该类媒体。授权后 invalidate 它与 [localMediaFoldersProvider]。
@riverpod
Future<bool> localMediaPermission(Ref ref, MediaKind kind) =>
    ref.watch(servicesProvider).localMedia.hasPermission(kind);

@riverpod
Stream<List<PlayHistoryEntry>> history(Ref ref) =>
    ref.watch(databaseProvider).historyDao.watchRecent();

@riverpod
Stream<Map<String, int>> cacheUsage(Ref ref) =>
    ref.watch(databaseProvider).seriesDao.watchCacheUsage();

/// 离线缓存上限（GB）。存在本地键值表，不进同步。
@riverpod
Stream<int> offlineQuotaGb(Ref ref) => ref
    .watch(databaseProvider)
    .settingsDao
    .watch(SettingsDao.offlineQuotaKey)
    .map((raw) => int.tryParse(raw ?? '') ?? SettingsDao.offlineQuotaDefaultGb);

@riverpod
Stream<DateTime?> lastSyncAt(Ref ref) =>
    ref.watch(librarySyncProvider).watchLastSyncAt();

/// 播放会话状态。先给当前值，再跟流——新打开的页面不会先闪一下空状态。
@riverpod
Stream<PlaybackSnapshot> playback(Ref ref) async* {
  final session = ref.watch(playbackSessionProvider);
  yield session.current;
  yield* session.states;
}
