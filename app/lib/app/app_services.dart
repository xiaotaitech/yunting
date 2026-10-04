import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:yun_audiobook/core/config.dart';
import 'package:yun_audiobook/data/auth/auth_repository.dart';
import 'package:yun_audiobook/data/covers/cover_service.dart';
import 'package:yun_audiobook/data/drive/baidu/baidu_api_client.dart';
import 'package:yun_audiobook/data/drive/baidu/baidu_drive_source.dart';
import 'package:yun_audiobook/data/drive/cloud_drive_source.dart';
import 'package:yun_audiobook/data/drive/demo/demo_drive_source.dart';
import 'package:yun_audiobook/data/drive/local/local_media_source.dart';
import 'package:yun_audiobook/data/drive/routing_drive_source.dart';
import 'package:yun_audiobook/data/local/database.dart';
import 'package:yun_audiobook/data/local/settings_dao.dart';
import 'package:yun_audiobook/data/repositories/library_repository.dart';
import 'package:yun_audiobook/data/sync/library_sync.dart';
import 'package:yun_audiobook/download/download_manager.dart';
import 'package:yun_audiobook/playback/audio_service_bridge.dart';
import 'package:yun_audiobook/playback/composite_engine.dart';
import 'package:yun_audiobook/playback/just_audio_engine.dart';
import 'package:yun_audiobook/playback/playback_session.dart';
import 'package:yun_audiobook/playback/playback_url_resolver.dart';
import 'package:yun_audiobook/playback/video_engine.dart';

/// 应用级依赖容器（refactor-app-foundation D8）。
///
/// 由 bootstrapProvider 在启动页后台一次性装配，之后经 Riverpod 取用。
/// 界面层不直接拿它：只经 app/providers.dart 里的细粒度 provider。
class AppServices {
  AppServices._({
    required this.auth,
    required this.database,
    required this.drive,
    required this.library,
    required this.resolver,
    required this.downloads,
    required this.sync,
    required this.session,
    required this.bridge,
    required this.videoEngine,
    required this.localMedia,
    required this.covers,
  });

  final AuthRepository auth;
  final AppDatabase database;
  final CloudDriveSource drive;
  final LibraryRepository library;
  final PlaybackUrlResolver resolver;
  final DownloadManager downloads;
  final LibrarySync sync;
  final PlaybackSession session;
  final AudioServiceBridge bridge;

  /// 视频画面由界面直接画，需要拿到当前的播放器实例。
  final VideoEngine videoEngine;

  /// 本机媒体：「添加书籍」本机栏的列表与授权。
  final LocalMediaSource localMedia;

  /// 自动封面与手动更换封面。
  final CoverService covers;

  /// [AudioService.init] 一个进程只能调一次。启动失败后「重试」会再走一遍
  /// [create]，那时复用第一次建好的桥，而不是再 init 一次。
  static AudioServiceBridge? _bridge;
  static VideoEngine? _videoEngine;

  static Future<AppServices> create() async {
    final auth = AuthRepository();
    await auth.restore();

    final database = AppDatabase.open();

    // 演示模式换掉数据源，其余各层一行不用改——这正是 CloudDriveSource 抽象的用处
    final local = LocalMediaSource();
    final remote = AppConfig.demoMode
        ? DemoDriveSource()
        : BaiduDriveSource(
            BaiduApiClient(auth),
            videoQuality: () async =>
                await database.settingsDao.read(SettingsDao.videoQualityKey) ??
                SettingsDao.videoQualityDefault,
          );
    // 网盘与本机合成一个数据源：书架、播放各层不用区分来源（add-local-media）
    final drive = RoutingDriveSource(remote: remote, local: local);

    final library = LibraryRepository(
      drive: drive,
      dao: database.seriesDao,
      deviceId: auth.deviceId,
    );
    final resolver = PlaybackUrlResolver(drive);
    final sync = LibrarySync(drive: drive, db: database);
    final covers = CoverService(
      dao: database.seriesDao,
      drive: drive,
      extractLocal: local.extractCover,
    );
    // 已在书架上、还没封面的书：启动稳定后在后台补一遍（新加的书在认领时补）
    unawaited(
      Future<void>.delayed(const Duration(seconds: 5), () async {
        await covers.backfill(await database.seriesDao.shelf());
      }),
    );
    final downloads = DownloadManager(
      drive: drive,
      resolver: resolver,
      dao: database.seriesDao,
    );

    final videoEngine = _videoEngine ??= VideoEngine();
    final session = _bridge?.session ??
        PlaybackSession(
          engine: CompositeEngine(
            audio: JustAudioEngine(),
            video: videoEngine,
            localAudio: JustAudioEngine.local(),
          ),
          resolver: resolver,
          sink: _DatabasePlaybackSink(
            database: database,
            auth: auth,
            resolver: resolver,
            sync: sync,
          ),
        );

    final bridge = _bridge ??= await AudioService.init(
      builder: () => AudioServiceBridge(session),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'tech.xiaotai.yunting.playback',
        androidNotificationChannelName: '听书播放',
        androidNotificationOngoing: true,
        // 自己的通知栏图标（res/drawable/ic_stat_yun.xml），不用默认的启动图标
        androidNotificationIcon: 'drawable/ic_stat_yun',
      ),
    );
    await bridge.configureAudioSession();

    return AppServices._(
      auth: auth,
      database: database,
      drive: drive,
      library: library,
      resolver: resolver,
      downloads: downloads,
      sync: sync,
      session: bridge.session,
      bridge: bridge,
      videoEngine: videoEngine,
      localMedia: local,
      covers: covers,
    );
  }
}

/// 播放会话的真实出口：进度写库、记历史、标记待同步、回填时长、鉴权失效登出。
class _DatabasePlaybackSink implements PlaybackSink {
  _DatabasePlaybackSink({
    required this.database,
    required this.auth,
    required this.resolver,
    required this.sync,
  });

  final AppDatabase database;
  final AuthRepository auth;
  final PlaybackUrlResolver resolver;
  final LibrarySync sync;

  @override
  Future<void> progress({
    required String seriesId,
    required int episodeIndex,
    required int positionMs,
    bool? finished,
    bool episodeFinished = false,
  }) async {
    await database.seriesDao.updateProgress(
      seriesId: seriesId,
      episodeIndex: episodeIndex,
      positionMs: positionMs,
      deviceId: await auth.deviceId(),
      finished: finished,
    );
    // 播放历史蹭同一个上报节奏（每 5 秒），同一集会合并成一条记录，
    // 不会每次上报插一行。历史只存本机，不进同步。
    await database.historyDao.record(
      seriesId: seriesId,
      episodeIndex: episodeIndex,
      positionMs: positionMs,
      episodeFinished: episodeFinished,
    );
    sync.markDirty();
  }

  @override
  Future<void> duration(String episodeId, int durationMs) =>
      database.seriesDao.setDuration(episodeId, durationMs);

  @override
  Future<void> authFailed() async {
    resolver.clear();
    await auth.signOut();
  }
}
