// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 启动装配。界面在它完成前显示启动页，失败显示原因与重试。

@ProviderFor(bootstrap)
final bootstrapProvider = BootstrapProvider._();

/// 启动装配。界面在它完成前显示启动页，失败显示原因与重试。

final class BootstrapProvider extends $FunctionalProvider<
        AsyncValue<AppServices>, AppServices, FutureOr<AppServices>>
    with $FutureModifier<AppServices>, $FutureProvider<AppServices> {
  /// 启动装配。界面在它完成前显示启动页，失败显示原因与重试。
  BootstrapProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'bootstrapProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$bootstrapHash();

  @$internal
  @override
  $FutureProviderElement<AppServices> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<AppServices> create(Ref ref) {
    return bootstrap(ref);
  }
}

String _$bootstrapHash() => r'899f137e35e7f025bb9485fe73ecafe665a5a7dd';

/// 只在 bootstrap 完成之后才会被读到（路由在那之前不存在）。

@ProviderFor(services)
final servicesProvider = ServicesProvider._();

/// 只在 bootstrap 完成之后才会被读到（路由在那之前不存在）。

final class ServicesProvider
    extends $FunctionalProvider<AppServices, AppServices, AppServices>
    with $Provider<AppServices> {
  /// 只在 bootstrap 完成之后才会被读到（路由在那之前不存在）。
  ServicesProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'servicesProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$servicesHash();

  @$internal
  @override
  $ProviderElement<AppServices> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppServices create(Ref ref) {
    return services(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppServices value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppServices>(value),
    );
  }
}

String _$servicesHash() => r'3e4c3a7dc13bda35cccb01f561332727e07d25fb';

@ProviderFor(database)
final databaseProvider = DatabaseProvider._();

final class DatabaseProvider
    extends $FunctionalProvider<AppDatabase, AppDatabase, AppDatabase>
    with $Provider<AppDatabase> {
  DatabaseProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'databaseProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$databaseHash();

  @$internal
  @override
  $ProviderElement<AppDatabase> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppDatabase create(Ref ref) {
    return database(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppDatabase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppDatabase>(value),
    );
  }
}

String _$databaseHash() => r'6f6fe2e51bb1053b77dd95c13784d7d5b7bed776';

@ProviderFor(authRepository)
final authRepositoryProvider = AuthRepositoryProvider._();

final class AuthRepositoryProvider
    extends $FunctionalProvider<AuthRepository, AuthRepository, AuthRepository>
    with $Provider<AuthRepository> {
  AuthRepositoryProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'authRepositoryProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$authRepositoryHash();

  @$internal
  @override
  $ProviderElement<AuthRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AuthRepository create(Ref ref) {
    return authRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthRepository>(value),
    );
  }
}

String _$authRepositoryHash() => r'fc093d6634c3cd7cd7d6132d225d7adb36c91d21';

@ProviderFor(libraryRepository)
final libraryRepositoryProvider = LibraryRepositoryProvider._();

final class LibraryRepositoryProvider extends $FunctionalProvider<
    LibraryRepository,
    LibraryRepository,
    LibraryRepository> with $Provider<LibraryRepository> {
  LibraryRepositoryProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'libraryRepositoryProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$libraryRepositoryHash();

  @$internal
  @override
  $ProviderElement<LibraryRepository> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  LibraryRepository create(Ref ref) {
    return libraryRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LibraryRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LibraryRepository>(value),
    );
  }
}

String _$libraryRepositoryHash() => r'7d610910b57dd2d839c37e0dd284c4a156fc7c3e';

@ProviderFor(librarySync)
final librarySyncProvider = LibrarySyncProvider._();

final class LibrarySyncProvider
    extends $FunctionalProvider<LibrarySync, LibrarySync, LibrarySync>
    with $Provider<LibrarySync> {
  LibrarySyncProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'librarySyncProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$librarySyncHash();

  @$internal
  @override
  $ProviderElement<LibrarySync> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  LibrarySync create(Ref ref) {
    return librarySync(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LibrarySync value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LibrarySync>(value),
    );
  }
}

String _$librarySyncHash() => r'bbd1d8c9226e8e1f95542b4bbf2f56a53a9bff6c';

@ProviderFor(downloadManager)
final downloadManagerProvider = DownloadManagerProvider._();

final class DownloadManagerProvider extends $FunctionalProvider<DownloadManager,
    DownloadManager, DownloadManager> with $Provider<DownloadManager> {
  DownloadManagerProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'downloadManagerProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$downloadManagerHash();

  @$internal
  @override
  $ProviderElement<DownloadManager> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DownloadManager create(Ref ref) {
    return downloadManager(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DownloadManager value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DownloadManager>(value),
    );
  }
}

String _$downloadManagerHash() => r'8b136d06a925a529922416dd416b57a83c5aed75';

@ProviderFor(playbackSession)
final playbackSessionProvider = PlaybackSessionProvider._();

final class PlaybackSessionProvider extends $FunctionalProvider<PlaybackSession,
    PlaybackSession, PlaybackSession> with $Provider<PlaybackSession> {
  PlaybackSessionProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'playbackSessionProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$playbackSessionHash();

  @$internal
  @override
  $ProviderElement<PlaybackSession> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PlaybackSession create(Ref ref) {
    return playbackSession(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PlaybackSession value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PlaybackSession>(value),
    );
  }
}

String _$playbackSessionHash() => r'86e9d0f4aae4e6cc69ccc78abd9b3d193c5c6068';

@ProviderFor(audioBridge)
final audioBridgeProvider = AudioBridgeProvider._();

final class AudioBridgeProvider extends $FunctionalProvider<AudioServiceBridge,
    AudioServiceBridge, AudioServiceBridge> with $Provider<AudioServiceBridge> {
  AudioBridgeProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'audioBridgeProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$audioBridgeHash();

  @$internal
  @override
  $ProviderElement<AudioServiceBridge> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AudioServiceBridge create(Ref ref) {
    return audioBridge(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AudioServiceBridge value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AudioServiceBridge>(value),
    );
  }
}

String _$audioBridgeHash() => r'c69d55316c9af253c7c0bbd74ca0b10903e2cfab';

@ProviderFor(appUpdater)
final appUpdaterProvider = AppUpdaterProvider._();

final class AppUpdaterProvider
    extends $FunctionalProvider<AppUpdater, AppUpdater, AppUpdater>
    with $Provider<AppUpdater> {
  AppUpdaterProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'appUpdaterProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$appUpdaterHash();

  @$internal
  @override
  $ProviderElement<AppUpdater> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppUpdater create(Ref ref) {
    return appUpdater(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppUpdater value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppUpdater>(value),
    );
  }
}

String _$appUpdaterHash() => r'4a51b2e85e59747eec3e9d66727b96a08dc260f6';

@ProviderFor(authState)
final authStateProvider = AuthStateProvider._();

final class AuthStateProvider extends $FunctionalProvider<AsyncValue<AuthState>,
        AuthState, Stream<AuthState>>
    with $FutureModifier<AuthState>, $StreamProvider<AuthState> {
  AuthStateProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'authStateProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$authStateHash();

  @$internal
  @override
  $StreamProviderElement<AuthState> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<AuthState> create(Ref ref) {
    return authState(ref);
  }
}

String _$authStateHash() => r'4b8e504e7b5f9f5c74d31c835646b42755a238e6';

/// 书架列表（未删除，最近收听在前）。

@ProviderFor(shelf)
final shelfProvider = ShelfProvider._();

/// 书架列表（未删除，最近收听在前）。

final class ShelfProvider extends $FunctionalProvider<AsyncValue<List<Series>>,
        List<Series>, Stream<List<Series>>>
    with $FutureModifier<List<Series>>, $StreamProvider<List<Series>> {
  /// 书架列表（未删除，最近收听在前）。
  ShelfProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'shelfProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$shelfHash();

  @$internal
  @override
  $StreamProviderElement<List<Series>> $createElement(
          $ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<List<Series>> create(Ref ref) {
    return shelf(ref);
  }
}

String _$shelfHash() => r'e17226bce500962b8ebe1befc1ada5330cb61454';

@ProviderFor(series)
final seriesProvider = SeriesFamily._();

final class SeriesProvider
    extends $FunctionalProvider<AsyncValue<Series?>, Series?, Stream<Series?>>
    with $FutureModifier<Series?>, $StreamProvider<Series?> {
  SeriesProvider._(
      {required SeriesFamily super.from, required String super.argument})
      : super(
          retry: null,
          name: r'seriesProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$seriesHash();

  @override
  String toString() {
    return r'seriesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<Series?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<Series?> create(Ref ref) {
    final argument = this.argument as String;
    return series(
      ref,
      argument,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SeriesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$seriesHash() => r'af24067fd0d7e154dc5cdcf58aec6191961379d2';

final class SeriesFamily extends $Family
    with $FunctionalFamilyOverride<Stream<Series?>, String> {
  SeriesFamily._()
      : super(
          retry: null,
          name: r'seriesProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  SeriesProvider call(
    String seriesId,
  ) =>
      SeriesProvider._(argument: seriesId, from: this);

  @override
  String toString() => r'seriesProvider';
}

@ProviderFor(episodes)
final episodesProvider = EpisodesFamily._();

final class EpisodesProvider extends $FunctionalProvider<
        AsyncValue<List<Episode>>, List<Episode>, Stream<List<Episode>>>
    with $FutureModifier<List<Episode>>, $StreamProvider<List<Episode>> {
  EpisodesProvider._(
      {required EpisodesFamily super.from, required String super.argument})
      : super(
          retry: null,
          name: r'episodesProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$episodesHash();

  @override
  String toString() {
    return r'episodesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<Episode>> $createElement(
          $ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<List<Episode>> create(Ref ref) {
    final argument = this.argument as String;
    return episodes(
      ref,
      argument,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is EpisodesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$episodesHash() => r'173dcc2ae9590d7da5db4fe904a61f266fdf40c2';

final class EpisodesFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<Episode>>, String> {
  EpisodesFamily._()
      : super(
          retry: null,
          name: r'episodesProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  EpisodesProvider call(
    String seriesId,
  ) =>
      EpisodesProvider._(argument: seriesId, from: this);

  @override
  String toString() => r'episodesProvider';
}

/// 首页续听入口（listening-progress 规格「首页续听入口」）。
///
/// 数据取自 books 表而不是 play_history：历史只存本机，换台设备就是空的，
/// 而合集进度会随 library.json 同步回来——首页续听在新设备上也得接得上。
/// 全程只读本地库，不碰网络：冷启动时 token 可能正在刷新，卡片仍要立刻可见。

@ProviderFor(continueListening)
final continueListeningProvider = ContinueListeningProvider._();

/// 首页续听入口（listening-progress 规格「首页续听入口」）。
///
/// 数据取自 books 表而不是 play_history：历史只存本机，换台设备就是空的，
/// 而合集进度会随 library.json 同步回来——首页续听在新设备上也得接得上。
/// 全程只读本地库，不碰网络：冷启动时 token 可能正在刷新，卡片仍要立刻可见。

final class ContinueListeningProvider extends $FunctionalProvider<
        AsyncValue<ContinueListening?>,
        ContinueListening?,
        FutureOr<ContinueListening?>>
    with
        $FutureModifier<ContinueListening?>,
        $FutureProvider<ContinueListening?> {
  /// 首页续听入口（listening-progress 规格「首页续听入口」）。
  ///
  /// 数据取自 books 表而不是 play_history：历史只存本机，换台设备就是空的，
  /// 而合集进度会随 library.json 同步回来——首页续听在新设备上也得接得上。
  /// 全程只读本地库，不碰网络：冷启动时 token 可能正在刷新，卡片仍要立刻可见。
  ContinueListeningProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'continueListeningProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$continueListeningHash();

  @$internal
  @override
  $FutureProviderElement<ContinueListening?> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<ContinueListening?> create(Ref ref) {
    return continueListening(ref);
  }
}

String _$continueListeningHash() => r'6cde76a5eaa2475a259351a91ce5c4b9f86779c2';

/// 目录浏览。目录在前、文件在后，各自按**自然序**排列。
///
/// 用字典序会把「第10章」排在「第1章」前面——认领之后条目是自然序的，
/// 浏览时却不是，同一批文件在两个界面顺序不一致，很难不让人以为排错了。

@ProviderFor(browse)
final browseProvider = BrowseFamily._();

/// 目录浏览。目录在前、文件在后，各自按**自然序**排列。
///
/// 用字典序会把「第10章」排在「第1章」前面——认领之后条目是自然序的，
/// 浏览时却不是，同一批文件在两个界面顺序不一致，很难不让人以为排错了。

final class BrowseProvider extends $FunctionalProvider<
        AsyncValue<List<DriveEntry>>,
        List<DriveEntry>,
        FutureOr<List<DriveEntry>>>
    with $FutureModifier<List<DriveEntry>>, $FutureProvider<List<DriveEntry>> {
  /// 目录浏览。目录在前、文件在后，各自按**自然序**排列。
  ///
  /// 用字典序会把「第10章」排在「第1章」前面——认领之后条目是自然序的，
  /// 浏览时却不是，同一批文件在两个界面顺序不一致，很难不让人以为排错了。
  BrowseProvider._(
      {required BrowseFamily super.from, required String super.argument})
      : super(
          retry: null,
          name: r'browseProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$browseHash();

  @override
  String toString() {
    return r'browseProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<DriveEntry>> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<DriveEntry>> create(Ref ref) {
    final argument = this.argument as String;
    return browse(
      ref,
      argument,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is BrowseProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$browseHash() => r'9660d37c2aa3cdabe7cffc52cbac438ea1e33897';

/// 目录浏览。目录在前、文件在后，各自按**自然序**排列。
///
/// 用字典序会把「第10章」排在「第1章」前面——认领之后条目是自然序的，
/// 浏览时却不是，同一批文件在两个界面顺序不一致，很难不让人以为排错了。

final class BrowseFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<DriveEntry>>, String> {
  BrowseFamily._()
      : super(
          retry: null,
          name: r'browseProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  /// 目录浏览。目录在前、文件在后，各自按**自然序**排列。
  ///
  /// 用字典序会把「第10章」排在「第1章」前面——认领之后条目是自然序的，
  /// 浏览时却不是，同一批文件在两个界面顺序不一致，很难不让人以为排错了。

  BrowseProvider call(
    String path,
  ) =>
      BrowseProvider._(argument: path, from: this);

  @override
  String toString() => r'browseProvider';
}

/// 网盘目录对应的书架条目（未删除的），用于浏览时显示「已在书架中」。

@ProviderFor(seriesAtFolder)
final seriesAtFolderProvider = SeriesAtFolderFamily._();

/// 网盘目录对应的书架条目（未删除的），用于浏览时显示「已在书架中」。

final class SeriesAtFolderProvider
    extends $FunctionalProvider<AsyncValue<Series?>, Series?, FutureOr<Series?>>
    with $FutureModifier<Series?>, $FutureProvider<Series?> {
  /// 网盘目录对应的书架条目（未删除的），用于浏览时显示「已在书架中」。
  SeriesAtFolderProvider._(
      {required SeriesAtFolderFamily super.from,
      required String super.argument})
      : super(
          retry: null,
          name: r'seriesAtFolderProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$seriesAtFolderHash();

  @override
  String toString() {
    return r'seriesAtFolderProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Series?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Series?> create(Ref ref) {
    final argument = this.argument as String;
    return seriesAtFolder(
      ref,
      argument,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SeriesAtFolderProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$seriesAtFolderHash() => r'8ec6f85e8d23239f739d70c5665af9ddd727fd41';

/// 网盘目录对应的书架条目（未删除的），用于浏览时显示「已在书架中」。

final class SeriesAtFolderFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Series?>, String> {
  SeriesAtFolderFamily._()
      : super(
          retry: null,
          name: r'seriesAtFolderProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  /// 网盘目录对应的书架条目（未删除的），用于浏览时显示「已在书架中」。

  SeriesAtFolderProvider call(
    String folderPath,
  ) =>
      SeriesAtFolderProvider._(argument: folderPath, from: this);

  @override
  String toString() => r'seriesAtFolderProvider';
}

@ProviderFor(history)
final historyProvider = HistoryProvider._();

final class HistoryProvider extends $FunctionalProvider<
        AsyncValue<List<PlayHistoryEntry>>,
        List<PlayHistoryEntry>,
        Stream<List<PlayHistoryEntry>>>
    with
        $FutureModifier<List<PlayHistoryEntry>>,
        $StreamProvider<List<PlayHistoryEntry>> {
  HistoryProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'historyProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$historyHash();

  @$internal
  @override
  $StreamProviderElement<List<PlayHistoryEntry>> $createElement(
          $ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<List<PlayHistoryEntry>> create(Ref ref) {
    return history(ref);
  }
}

String _$historyHash() => r'2104e7ce0f702dd5309bd352b7fe92877957e8e8';

@ProviderFor(cacheUsage)
final cacheUsageProvider = CacheUsageProvider._();

final class CacheUsageProvider extends $FunctionalProvider<
        AsyncValue<Map<String, int>>,
        Map<String, int>,
        Stream<Map<String, int>>>
    with $FutureModifier<Map<String, int>>, $StreamProvider<Map<String, int>> {
  CacheUsageProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'cacheUsageProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$cacheUsageHash();

  @$internal
  @override
  $StreamProviderElement<Map<String, int>> $createElement(
          $ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<Map<String, int>> create(Ref ref) {
    return cacheUsage(ref);
  }
}

String _$cacheUsageHash() => r'e81a0f8074e3e79bf967ea37a27b62d1001f6227';

/// 离线缓存上限（GB）。存在本地键值表，不进同步。

@ProviderFor(offlineQuotaGb)
final offlineQuotaGbProvider = OfflineQuotaGbProvider._();

/// 离线缓存上限（GB）。存在本地键值表，不进同步。

final class OfflineQuotaGbProvider
    extends $FunctionalProvider<AsyncValue<int>, int, Stream<int>>
    with $FutureModifier<int>, $StreamProvider<int> {
  /// 离线缓存上限（GB）。存在本地键值表，不进同步。
  OfflineQuotaGbProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'offlineQuotaGbProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$offlineQuotaGbHash();

  @$internal
  @override
  $StreamProviderElement<int> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<int> create(Ref ref) {
    return offlineQuotaGb(ref);
  }
}

String _$offlineQuotaGbHash() => r'2dd94b314e76b85ee44ab5d61c96ba0d228f4dfb';

@ProviderFor(lastSyncAt)
final lastSyncAtProvider = LastSyncAtProvider._();

final class LastSyncAtProvider extends $FunctionalProvider<
        AsyncValue<DateTime?>, DateTime?, Stream<DateTime?>>
    with $FutureModifier<DateTime?>, $StreamProvider<DateTime?> {
  LastSyncAtProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'lastSyncAtProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$lastSyncAtHash();

  @$internal
  @override
  $StreamProviderElement<DateTime?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<DateTime?> create(Ref ref) {
    return lastSyncAt(ref);
  }
}

String _$lastSyncAtHash() => r'4e2bb93d8b56f177f76f19f84e181fbab3c5a04a';

/// 播放会话状态。先给当前值，再跟流——新打开的页面不会先闪一下空状态。

@ProviderFor(playback)
final playbackProvider = PlaybackProvider._();

/// 播放会话状态。先给当前值，再跟流——新打开的页面不会先闪一下空状态。

final class PlaybackProvider extends $FunctionalProvider<
        AsyncValue<PlaybackSnapshot>,
        PlaybackSnapshot,
        Stream<PlaybackSnapshot>>
    with $FutureModifier<PlaybackSnapshot>, $StreamProvider<PlaybackSnapshot> {
  /// 播放会话状态。先给当前值，再跟流——新打开的页面不会先闪一下空状态。
  PlaybackProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'playbackProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$playbackHash();

  @$internal
  @override
  $StreamProviderElement<PlaybackSnapshot> $createElement(
          $ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<PlaybackSnapshot> create(Ref ref) {
    return playback(ref);
  }
}

String _$playbackHash() => r'ca3ebd274403c75f8d1dc0bdc9853262af864e3b';
