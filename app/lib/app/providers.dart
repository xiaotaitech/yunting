/// Provider 装配（refactor-app-foundation D7）。
///
/// 读：drift 的 watch 流直接变成 StreamProvider，库一变界面自动刷新，
/// 不再有手动 invalidate。写：走 features 里的 controller。
library;

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:video_player/video_player.dart';
import 'package:yun_audiobook/app/app_services.dart';
import 'package:yun_audiobook/core/config.dart';
import 'package:yun_audiobook/core/logging.dart';
import 'package:yun_audiobook/core/natural_sort.dart';
import 'package:yun_audiobook/data/auth/auth_repository.dart';
import 'package:yun_audiobook/data/covers/cover_service.dart';
import 'package:yun_audiobook/data/drive/cloud_drive_source.dart';
import 'package:yun_audiobook/data/local/database.dart';
import 'package:yun_audiobook/data/local/settings_dao.dart';
import 'package:yun_audiobook/data/repositories/library_repository.dart';
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
DownloadManager downloadManager(Ref ref) =>
    ref.watch(servicesProvider).downloads;

@Riverpod(keepAlive: true)
PlaybackSession playbackSession(Ref ref) => ref.watch(servicesProvider).session;

@Riverpod(keepAlive: true)
AudioServiceBridge audioBridge(Ref ref) => ref.watch(servicesProvider).bridge;

@Riverpod(keepAlive: true)
CoverService coverService(Ref ref) => ref.watch(servicesProvider).covers;

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
/// 数据取自 books 表而不是 play_history：历史有条目上限，老书的断点可能已被裁掉，
/// 而合集表里的进度一直都在。全程只读本地库，不碰网络：冷启动时 token 可能正在刷新，卡片仍要立刻可见。
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
///
/// 先出本地缓存、后台向网盘刷新（local-first-drawer-ui）。
@riverpod
class Browse extends _$Browse {
  @override
  Future<List<DriveEntry>> build(String path) => _cachedThenFresh(
        ref,
        'dir:$path',
        () => ref.read(libraryRepositoryProvider).browse(path),
        (fresh) => state = AsyncData(_sortEntries(fresh)),
      ).then(_sortEntries);

  /// 下拉刷新：等网盘结果回来。失败时保留已显示的列表，返回 false。
  Future<bool> refresh() async {
    final fresh = await _fetchAndStore(
      ref,
      'dir:$path',
      () => ref.read(libraryRepositoryProvider).browse(path),
    );
    if (fresh == null) return false;
    state = AsyncData(_sortEntries(fresh));
    return true;
  }
}

List<DriveEntry> _sortEntries(List<DriveEntry> entries) =>
    [...entries]..sort((a, b) {
        if (a.isDirectory != b.isDirectory) return a.isDirectory ? -1 : 1;
        return compareNatural(a.name, b.name);
      });

/// 有缓存：立即返回缓存，后台刷新成功后经 [onFresh] 推新值，失败不打扰。
/// 没缓存：等网盘，失败照常抛给界面。
Future<List<DriveEntry>> _cachedThenFresh(
  Ref ref,
  String key,
  Future<List<DriveEntry>> Function() fetch,
  void Function(List<DriveEntry>) onFresh,
) async {
  final cache = ref.read(databaseProvider).driveCacheDao;
  final cached = await cache.read(key);
  if (cached == null) {
    final fresh = await fetch();
    await cache.write(key, fresh);
    return fresh;
  }
  unawaited(
    _fetchAndStore(ref, key, fetch).then((fresh) {
      if (fresh != null && ref.mounted) onFresh(fresh);
    }),
  );
  return cached;
}

/// 取网盘并写缓存；失败返回 null（只记日志）。
Future<List<DriveEntry>?> _fetchAndStore(
  Ref ref,
  String key,
  Future<List<DriveEntry>> Function() fetch,
) async {
  final cache = ref.read(databaseProvider).driveCacheDao;
  try {
    final fresh = await fetch();
    await cache.write(key, fresh);
    return fresh;
  } on Object catch (e) {
    Log.d('cache', '刷新 $key 失败，沿用缓存：$e');
    return null;
  }
}

/// 网盘目录对应的书架条目（未删除的），用于浏览时显示「已在书架中」。
@riverpod
Future<Series?> seriesAtFolder(Ref ref, String folderPath) {
  ref.watch(shelfProvider);
  return ref.watch(databaseProvider).seriesDao.seriesByFolder(folderPath);
}

/// 网盘里所有装着某类媒体的文件夹（「添加书籍」页的有声书 / 课程两栏）。
///
/// 整盘扫描要 1–3 秒：先出本地缓存，后台再扫（local-first-drawer-ui）。
/// keepAlive：本次会话内反复进出添加页不必重扫。
@Riverpod(keepAlive: true)
class MediaFolders extends _$MediaFolders {
  @override
  Future<List<MediaFolder>> build(MediaKind kind) => _cachedThenFresh(
        ref,
        'media:${kind.name}',
        _fetch,
        (fresh) => state = AsyncData(groupIntoFolders(fresh)),
      ).then(groupIntoFolders);

  Future<List<DriveEntry>> _fetch() =>
      ref.read(servicesProvider).drive.listMediaFiles(kind);

  /// 下拉刷新：等网盘结果回来。失败时保留已显示的列表，返回 false。
  Future<bool> refresh() async {
    final fresh = await _fetchAndStore(ref, 'media:${kind.name}', _fetch);
    if (fresh == null) return false;
    state = AsyncData(groupIntoFolders(fresh));
    return true;
  }
}

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

/// 「添加书籍」的搜索历史，最近在前。
@riverpod
Stream<List<String>> searchHistory(Ref ref) => ref
    .watch(databaseProvider)
    .settingsDao
    .watch(SettingsDao.searchHistoryKey)
    .map((raw) =>
        raw == null ? const [] : List<String>.from(jsonDecode(raw) as List));

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

/// 播放会话状态。先给当前值，再跟流——新打开的页面不会先闪一下空状态。
@riverpod
Stream<PlaybackSnapshot> playback(Ref ref) async* {
  final session = ref.watch(playbackSessionProvider);
  yield session.current;
  yield* session.states;
}
