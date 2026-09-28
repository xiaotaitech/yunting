import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../core/config.dart';
import '../core/natural_sort.dart';
import '../data/auth/auth_repository.dart';
import '../data/drive/baidu/baidu_api_client.dart';
import '../data/drive/baidu/baidu_drive_source.dart';
import '../data/drive/cloud_drive_source.dart';
import '../data/drive/demo/demo_drive_source.dart';
import '../data/local/book_dao.dart';
import '../data/local/database.dart';
import '../data/local/history_dao.dart';
import '../data/sync/library_sync.dart';
import '../domain/continue_listening.dart';
import '../domain/library_repository.dart';
import '../domain/models.dart';
import '../download/download_manager.dart';
import '../playback/audiobook_handler.dart';
import '../playback/playback_url_resolver.dart';
import '../update/app_updater.dart';

/// 应用级依赖容器。在 main 里一次性装配，之后通过 riverpod 取用。
class AppServices {
  AppServices._({
    required this.auth,
    required this.database,
    required this.dao,
    required this.history,
    required this.drive,
    required this.api,
    required this.library,
    required this.resolver,
    required this.downloads,
    required this.sync,
    required this.handler,
  });

  final AuthRepository auth;
  final AppDatabase database;
  final BookDao dao;
  final HistoryDao history;
  final CloudDriveSource drive;
  final BaiduApiClient api;
  final LibraryRepository library;
  final PlaybackUrlResolver resolver;
  final DownloadManager downloads;
  final LibrarySync sync;
  final AudiobookHandler handler;

  static Future<AppServices> bootstrap() async {
    final auth = AuthRepository();
    await auth.restore();

    final database = await AppDatabase.open();
    final dao = BookDao(database);
    final history = HistoryDao(database);

    final api = BaiduApiClient(auth);
    // 演示模式换掉数据源，其余各层一行不用改——这正是 CloudDriveSource 抽象的用处
    final CloudDriveSource drive =
        AppConfig.demoMode ? DemoDriveSource() : BaiduDriveSource(api);

    final library = LibraryRepository(
      drive: drive,
      dao: dao,
      deviceId: auth.deviceId,
    );

    final resolver = PlaybackUrlResolver(drive);
    final sync = LibrarySync(drive: drive, db: database);
    final downloads = DownloadManager(api: api, resolver: resolver, dao: dao);

    late final AudiobookHandler handler;
    handler = await AudioService.init(
      builder: () => AudiobookHandler(
        resolver: resolver,
        onProgress: (bookId, chapterIndex, positionMs,
            {finished, chapterFinished}) async {
          await dao.updateProgress(
            bookId: bookId,
            chapterIndex: chapterIndex,
            positionMs: positionMs,
            deviceId: await auth.deviceId(),
            finished: finished,
          );
          // 播放历史蹭同一个上报节奏（每 5 秒），同一章会合并成一条记录，
          // 不会每次上报插一行。历史只存本机，不进同步。
          await history.record(
            bookId: bookId,
            chapterIndex: chapterIndex,
            positionMs: positionMs,
            chapterFinished: chapterFinished ?? false,
          );
          sync.markDirty();
        },
        onAuthFailure: () async {
          resolver.clear();
          await auth.signOut();
        },
        // 播放器报出真实时长后存下来：通知栏的进度条要靠它，
        // 而 ID3 解析拿不到时长
        onDuration: (chapterId, durationMs) =>
            dao.setChapterDuration(chapterId, durationMs),
      ),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.yunaudiobook.playback',
        androidNotificationChannelName: '听书播放',
        androidNotificationOngoing: true,
        // 自己的通知栏图标（res/drawable/ic_stat_yun.xml），不用默认的启动图标
        androidNotificationIcon: 'drawable/ic_stat_yun',
        androidStopForegroundOnPause: true,
      ),
    );
    await handler.configureSession();

    return AppServices._(
      auth: auth,
      database: database,
      dao: dao,
      history: history,
      drive: drive,
      api: api,
      library: library,
      resolver: resolver,
      downloads: downloads,
      sync: sync,
      handler: handler,
    );
  }
}

/// 在 main 中用 overrideWithValue 注入真实实例。
final servicesProvider = Provider<AppServices>(
  (ref) => throw UnimplementedError('AppServices 未注入'),
);

final authStateProvider = StreamProvider<AuthState>((ref) {
  final auth = ref.watch(servicesProvider).auth;
  return auth.stateChanges;
});

/// 书架列表。加书、删书、进度变化后调用 `ref.invalidate` 刷新。
final shelfProvider = FutureProvider<List<Book>>((ref) async {
  return ref.watch(servicesProvider).library.shelf();
});

/// 首页续听入口（listening-progress 规格「首页续听入口」）。
///
/// 数据取自 books 表而不是 play_history：历史只存本机，换台设备就是空的，
/// 而书目进度会随 library.json 同步回来——首页续听在新设备上也得接得上。
///
/// 两次读取都走本地 SQLite（`shelf()` → allBooks，`chapters()` → chaptersOf），
/// 不碰网络：冷启动时 token 可能正在刷新、网盘可能不可达，卡片仍要立刻可见。
///
/// 依赖 shelfProvider 而不是自己查 DAO，这样同步或续播之后
/// `invalidate(shelfProvider)` 一处就能让卡片跟着刷新。
final continueListeningProvider =
    FutureProvider<ContinueListening?>((ref) async {
  final books = await ref.watch(shelfProvider.future);
  final book = ContinueListening.mostRecentlyPlayed(books);
  // 一本都没播过（含书架为空）时不给卡片——没有断点可续。
  if (book == null) return null;

  final chapters = await ref.watch(servicesProvider).library.chapters(book.id);
  return ContinueListening.from(book, chapters);
});

/// 单本书。书籍详情页用它而不是在 build 里直接查库：后者每次重建都重查一遍，
/// 从播放页回来时当前章的高亮也不会跟着变。
final bookProvider = FutureProvider.family<Book?, String>((ref, bookId) async {
  return ref.watch(servicesProvider).dao.bookById(bookId);
});

final chaptersProvider =
    FutureProvider.family<List<Chapter>, String>((ref, bookId) async {
  return ref.watch(servicesProvider).library.chapters(bookId);
});

/// 目录浏览。key 是网盘路径。
final browseProvider =
    FutureProvider.family<List<DriveEntry>, String>((ref, path) async {
  final entries = await ref.watch(servicesProvider).library.browse(path);
  // 目录在前、文件在后，各自按**自然序**排列。
  // 用字典序会把「第10章」排在「第1章」前面——认领成书之后章节是自然序的，
  // 浏览时却不是，同一批文件在两个界面顺序不一致，很难不让人以为排错了。
  entries.sort((a, b) {
    if (a.isDirectory != b.isDirectory) return a.isDirectory ? -1 : 1;
    return compareNatural(a.name, b.name);
  });
  return entries;
});

/// 当前播放会话里装着的条目。为 null 表示这次启动还没开始播放。
///
/// 与迷你播放条同一个数据源（audio_service 的 mediaItem），它俩必须同进同退：
/// 播放条一出现，首页的续听卡片就得让位，否则同一本书在一屏上出现两次。
final nowPlayingProvider = StreamProvider<MediaItem?>((ref) {
  return ref.watch(servicesProvider).handler.mediaItem;
});

/// 播放历史。播放中每 5 秒会有一次写入，但这里不自动刷新——
/// 让列表在用户眼前跳动没有意义，进入页面或下拉时重取即可。
final historyProvider = FutureProvider<List<PlayHistoryEntry>>((ref) async {
  return ref.watch(servicesProvider).history.recent();
});

/// 离线缓存上限（GB）。
///
/// 存在 sync_meta 这张通用 KV 表里。表名带 sync 是历史原因，它就是本地的
/// 键值存储；为一个整数单开一张表更不划算。
///
/// 原来这个值只是离线页的一个局部变量，页面一销毁就回到默认 5 GB——
/// 选完只在当下执行一次清理，之后再没人按它约束缓存。
const offlineQuotaMetaKey = 'offline_quota_gb';
const offlineQuotaDefaultGb = 5;

final offlineQuotaGbProvider = FutureProvider<int>((ref) async {
  final raw =
      await ref.watch(servicesProvider).database.meta(offlineQuotaMetaKey);
  return int.tryParse(raw ?? '') ?? offlineQuotaDefaultGb;
});

final cacheUsageProvider = FutureProvider<Map<String, int>>((ref) async {
  return ref.watch(servicesProvider).downloads.usageByBook();
});

final configuredProvider = Provider<bool>((ref) => AppConfig.isConfigured);

/// 应用内检查更新（app-distribution 规格）。
final appUpdaterProvider = Provider<AppUpdater>(
    (ref) => AppUpdater(client: http.Client(), repo: AppConfig.releaseRepo));

/// 自动提示过的最新版本：同一版本只自动提示一次。存本机，不进同步文件。
const updateSeenMetaKey = 'update_seen';
