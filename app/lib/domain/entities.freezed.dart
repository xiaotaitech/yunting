// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'entities.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Episode {
  String get id;
  String get seriesId;
  String get fsId;
  String get path;
  String get title;
  String get fileName;
  int get size;

  /// 最终展示顺序。用户手动拖动后这里会被改写并持久化。
  int get orderIndex;
  MediaKind get mediaKind;

  /// 音频标签里的 track 号，排序时优先于文件名（library-catalog 规格）。
  int? get trackNumber;
  int? get durationMs;
  CacheState get cacheState;
  String? get localPath;
  int get downloadedBytes;

  /// Create a copy of Episode
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $EpisodeCopyWith<Episode> get copyWith =>
      _$EpisodeCopyWithImpl<Episode>(this as Episode, _$identity);

  @override
  bool operator ==(Object other) {
    final _this = this as Episode;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is Episode &&
            (identical(other.id, _this.id) || other.id == _this.id) &&
            (identical(other.seriesId, _this.seriesId) ||
                other.seriesId == _this.seriesId) &&
            (identical(other.fsId, _this.fsId) || other.fsId == _this.fsId) &&
            (identical(other.path, _this.path) || other.path == _this.path) &&
            (identical(other.title, _this.title) ||
                other.title == _this.title) &&
            (identical(other.fileName, _this.fileName) ||
                other.fileName == _this.fileName) &&
            (identical(other.size, _this.size) || other.size == _this.size) &&
            (identical(other.orderIndex, _this.orderIndex) ||
                other.orderIndex == _this.orderIndex) &&
            (identical(other.mediaKind, _this.mediaKind) ||
                other.mediaKind == _this.mediaKind) &&
            (identical(other.trackNumber, _this.trackNumber) ||
                other.trackNumber == _this.trackNumber) &&
            (identical(other.durationMs, _this.durationMs) ||
                other.durationMs == _this.durationMs) &&
            (identical(other.cacheState, _this.cacheState) ||
                other.cacheState == _this.cacheState) &&
            (identical(other.localPath, _this.localPath) ||
                other.localPath == _this.localPath) &&
            (identical(other.downloadedBytes, _this.downloadedBytes) ||
                other.downloadedBytes == _this.downloadedBytes));
  }

  @override
  int get hashCode {
    final _this = this as Episode;
    return Object.hash(
        runtimeType,
        _this.id,
        _this.seriesId,
        _this.fsId,
        _this.path,
        _this.title,
        _this.fileName,
        _this.size,
        _this.orderIndex,
        _this.mediaKind,
        _this.trackNumber,
        _this.durationMs,
        _this.cacheState,
        _this.localPath,
        _this.downloadedBytes);
  }

  @override
  String toString() {
    final _this = this as Episode;
    return 'Episode(id: ${_this.id}, seriesId: ${_this.seriesId}, fsId: ${_this.fsId}, path: ${_this.path}, title: ${_this.title}, fileName: ${_this.fileName}, size: ${_this.size}, orderIndex: ${_this.orderIndex}, mediaKind: ${_this.mediaKind}, trackNumber: ${_this.trackNumber}, durationMs: ${_this.durationMs}, cacheState: ${_this.cacheState}, localPath: ${_this.localPath}, downloadedBytes: ${_this.downloadedBytes})';
  }
}

/// @nodoc
abstract mixin class $EpisodeCopyWith<$Res> {
  factory $EpisodeCopyWith(Episode value, $Res Function(Episode) _then) =
      _$EpisodeCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      String seriesId,
      String fsId,
      String path,
      String title,
      String fileName,
      int size,
      int orderIndex,
      MediaKind mediaKind,
      int? trackNumber,
      int? durationMs,
      CacheState cacheState,
      String? localPath,
      int downloadedBytes});
}

/// @nodoc
class _$EpisodeCopyWithImpl<$Res> implements $EpisodeCopyWith<$Res> {
  _$EpisodeCopyWithImpl(this._self, this._then);

  final Episode _self;
  final $Res Function(Episode) _then;

  /// Create a copy of Episode
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? seriesId = null,
    Object? fsId = null,
    Object? path = null,
    Object? title = null,
    Object? fileName = null,
    Object? size = null,
    Object? orderIndex = null,
    Object? mediaKind = null,
    Object? trackNumber = freezed,
    Object? durationMs = freezed,
    Object? cacheState = null,
    Object? localPath = freezed,
    Object? downloadedBytes = null,
  }) {
    return _then(Episode(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      seriesId: null == seriesId
          ? _self.seriesId
          : seriesId // ignore: cast_nullable_to_non_nullable
              as String,
      fsId: null == fsId
          ? _self.fsId
          : fsId // ignore: cast_nullable_to_non_nullable
              as String,
      path: null == path
          ? _self.path
          : path // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _self.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      fileName: null == fileName
          ? _self.fileName
          : fileName // ignore: cast_nullable_to_non_nullable
              as String,
      size: null == size
          ? _self.size
          : size // ignore: cast_nullable_to_non_nullable
              as int,
      orderIndex: null == orderIndex
          ? _self.orderIndex
          : orderIndex // ignore: cast_nullable_to_non_nullable
              as int,
      mediaKind: null == mediaKind
          ? _self.mediaKind
          : mediaKind // ignore: cast_nullable_to_non_nullable
              as MediaKind,
      trackNumber: freezed == trackNumber
          ? _self.trackNumber
          : trackNumber // ignore: cast_nullable_to_non_nullable
              as int?,
      durationMs: freezed == durationMs
          ? _self.durationMs
          : durationMs // ignore: cast_nullable_to_non_nullable
              as int?,
      cacheState: null == cacheState
          ? _self.cacheState
          : cacheState // ignore: cast_nullable_to_non_nullable
              as CacheState,
      localPath: freezed == localPath
          ? _self.localPath
          : localPath // ignore: cast_nullable_to_non_nullable
              as String?,
      downloadedBytes: null == downloadedBytes
          ? _self.downloadedBytes
          : downloadedBytes // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// Adds pattern-matching-related methods to [Episode].
extension EpisodePatterns on Episode {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_Episode value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Episode() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_Episode value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Episode():
        return $default(_that);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_Episode value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Episode() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(
            String id,
            String seriesId,
            String fsId,
            String path,
            String title,
            String fileName,
            int size,
            int orderIndex,
            MediaKind mediaKind,
            int? trackNumber,
            int? durationMs,
            CacheState cacheState,
            String? localPath,
            int downloadedBytes)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Episode() when $default != null:
        return $default(
            _that.id,
            _that.seriesId,
            _that.fsId,
            _that.path,
            _that.title,
            _that.fileName,
            _that.size,
            _that.orderIndex,
            _that.mediaKind,
            _that.trackNumber,
            _that.durationMs,
            _that.cacheState,
            _that.localPath,
            _that.downloadedBytes);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(
            String id,
            String seriesId,
            String fsId,
            String path,
            String title,
            String fileName,
            int size,
            int orderIndex,
            MediaKind mediaKind,
            int? trackNumber,
            int? durationMs,
            CacheState cacheState,
            String? localPath,
            int downloadedBytes)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Episode():
        return $default(
            _that.id,
            _that.seriesId,
            _that.fsId,
            _that.path,
            _that.title,
            _that.fileName,
            _that.size,
            _that.orderIndex,
            _that.mediaKind,
            _that.trackNumber,
            _that.durationMs,
            _that.cacheState,
            _that.localPath,
            _that.downloadedBytes);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(
            String id,
            String seriesId,
            String fsId,
            String path,
            String title,
            String fileName,
            int size,
            int orderIndex,
            MediaKind mediaKind,
            int? trackNumber,
            int? durationMs,
            CacheState cacheState,
            String? localPath,
            int downloadedBytes)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Episode() when $default != null:
        return $default(
            _that.id,
            _that.seriesId,
            _that.fsId,
            _that.path,
            _that.title,
            _that.fileName,
            _that.size,
            _that.orderIndex,
            _that.mediaKind,
            _that.trackNumber,
            _that.durationMs,
            _that.cacheState,
            _that.localPath,
            _that.downloadedBytes);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _Episode extends Episode {
  const _Episode(
      {required this.id,
      required this.seriesId,
      required this.fsId,
      required this.path,
      required this.title,
      required this.fileName,
      required this.size,
      required this.orderIndex,
      this.mediaKind = MediaKind.audio,
      this.trackNumber,
      this.durationMs,
      this.cacheState = CacheState.none,
      this.localPath,
      this.downloadedBytes = 0})
      : super._();

  @override
  final String id;
  @override
  final String seriesId;
  @override
  final String fsId;
  @override
  final String path;
  @override
  final String title;
  @override
  final String fileName;
  @override
  final int size;

  /// 最终展示顺序。用户手动拖动后这里会被改写并持久化。
  @override
  final int orderIndex;
  @override
  @JsonKey()
  final MediaKind mediaKind;

  /// 音频标签里的 track 号，排序时优先于文件名（library-catalog 规格）。
  @override
  final int? trackNumber;
  @override
  final int? durationMs;
  @override
  @JsonKey()
  final CacheState cacheState;
  @override
  final String? localPath;
  @override
  @JsonKey()
  final int downloadedBytes;

  /// Create a copy of Episode
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$EpisodeCopyWith<_Episode> get copyWith =>
      __$EpisodeCopyWithImpl<_Episode>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _Episode &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.seriesId, seriesId) ||
                other.seriesId == seriesId) &&
            (identical(other.fsId, fsId) || other.fsId == fsId) &&
            (identical(other.path, path) || other.path == path) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.fileName, fileName) ||
                other.fileName == fileName) &&
            (identical(other.size, size) || other.size == size) &&
            (identical(other.orderIndex, orderIndex) ||
                other.orderIndex == orderIndex) &&
            (identical(other.mediaKind, mediaKind) ||
                other.mediaKind == mediaKind) &&
            (identical(other.trackNumber, trackNumber) ||
                other.trackNumber == trackNumber) &&
            (identical(other.durationMs, durationMs) ||
                other.durationMs == durationMs) &&
            (identical(other.cacheState, cacheState) ||
                other.cacheState == cacheState) &&
            (identical(other.localPath, localPath) ||
                other.localPath == localPath) &&
            (identical(other.downloadedBytes, downloadedBytes) ||
                other.downloadedBytes == downloadedBytes));
  }

  @override
  int get hashCode {
    return Object.hash(
        runtimeType,
        id,
        seriesId,
        fsId,
        path,
        title,
        fileName,
        size,
        orderIndex,
        mediaKind,
        trackNumber,
        durationMs,
        cacheState,
        localPath,
        downloadedBytes);
  }

  @override
  String toString() {
    return 'Episode(id: $id, seriesId: $seriesId, fsId: $fsId, path: $path, title: $title, fileName: $fileName, size: $size, orderIndex: $orderIndex, mediaKind: $mediaKind, trackNumber: $trackNumber, durationMs: $durationMs, cacheState: $cacheState, localPath: $localPath, downloadedBytes: $downloadedBytes)';
  }
}

/// @nodoc
abstract mixin class _$EpisodeCopyWith<$Res> implements $EpisodeCopyWith<$Res> {
  factory _$EpisodeCopyWith(_Episode value, $Res Function(_Episode) _then) =
      __$EpisodeCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      String seriesId,
      String fsId,
      String path,
      String title,
      String fileName,
      int size,
      int orderIndex,
      MediaKind mediaKind,
      int? trackNumber,
      int? durationMs,
      CacheState cacheState,
      String? localPath,
      int downloadedBytes});
}

/// @nodoc
class __$EpisodeCopyWithImpl<$Res> implements _$EpisodeCopyWith<$Res> {
  __$EpisodeCopyWithImpl(this._self, this._then);

  final _Episode _self;
  final $Res Function(_Episode) _then;

  /// Create a copy of Episode
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? seriesId = null,
    Object? fsId = null,
    Object? path = null,
    Object? title = null,
    Object? fileName = null,
    Object? size = null,
    Object? orderIndex = null,
    Object? mediaKind = null,
    Object? trackNumber = freezed,
    Object? durationMs = freezed,
    Object? cacheState = null,
    Object? localPath = freezed,
    Object? downloadedBytes = null,
  }) {
    return _then(_Episode(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      seriesId: null == seriesId
          ? _self.seriesId
          : seriesId // ignore: cast_nullable_to_non_nullable
              as String,
      fsId: null == fsId
          ? _self.fsId
          : fsId // ignore: cast_nullable_to_non_nullable
              as String,
      path: null == path
          ? _self.path
          : path // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _self.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      fileName: null == fileName
          ? _self.fileName
          : fileName // ignore: cast_nullable_to_non_nullable
              as String,
      size: null == size
          ? _self.size
          : size // ignore: cast_nullable_to_non_nullable
              as int,
      orderIndex: null == orderIndex
          ? _self.orderIndex
          : orderIndex // ignore: cast_nullable_to_non_nullable
              as int,
      mediaKind: null == mediaKind
          ? _self.mediaKind
          : mediaKind // ignore: cast_nullable_to_non_nullable
              as MediaKind,
      trackNumber: freezed == trackNumber
          ? _self.trackNumber
          : trackNumber // ignore: cast_nullable_to_non_nullable
              as int?,
      durationMs: freezed == durationMs
          ? _self.durationMs
          : durationMs // ignore: cast_nullable_to_non_nullable
              as int?,
      cacheState: null == cacheState
          ? _self.cacheState
          : cacheState // ignore: cast_nullable_to_non_nullable
              as CacheState,
      localPath: freezed == localPath
          ? _self.localPath
          : localPath // ignore: cast_nullable_to_non_nullable
              as String?,
      downloadedBytes: null == downloadedBytes
          ? _self.downloadedBytes
          : downloadedBytes // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
mixin _$Series {
  String get id;

  /// 网盘中的目录路径。这是合集的身份，用于去重认领。
  String get folderPath;
  String get title;
  DateTime get addedAt;
  DateTime get updatedAt;
  SeriesKind get kind;
  String? get author;
  String? get coverFsId;
  String? get coverLocalPath;
  int get episodeCount;
  int get currentEpisodeIndex;
  int get currentPositionMs;
  bool get finished;

  /// 网盘路径消失时置位。条目与进度都保留（library-catalog 规格）。
  bool get sourceMissing;

  /// 用户手动编辑过的字段不允许被自动识别结果覆盖。
  bool get titleEditedByUser;
  bool get authorEditedByUser;
  bool get orderEditedByUser;
  DateTime? get lastPlayedAt;

  /// 同步时的 LWW 合并依据（listening-progress 规格）。
  String get updatedByDevice;

  /// Create a copy of Series
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $SeriesCopyWith<Series> get copyWith =>
      _$SeriesCopyWithImpl<Series>(this as Series, _$identity);

  @override
  bool operator ==(Object other) {
    final _this = this as Series;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is Series &&
            (identical(other.id, _this.id) || other.id == _this.id) &&
            (identical(other.folderPath, _this.folderPath) ||
                other.folderPath == _this.folderPath) &&
            (identical(other.title, _this.title) ||
                other.title == _this.title) &&
            (identical(other.addedAt, _this.addedAt) ||
                other.addedAt == _this.addedAt) &&
            (identical(other.updatedAt, _this.updatedAt) ||
                other.updatedAt == _this.updatedAt) &&
            (identical(other.kind, _this.kind) || other.kind == _this.kind) &&
            (identical(other.author, _this.author) ||
                other.author == _this.author) &&
            (identical(other.coverFsId, _this.coverFsId) ||
                other.coverFsId == _this.coverFsId) &&
            (identical(other.coverLocalPath, _this.coverLocalPath) ||
                other.coverLocalPath == _this.coverLocalPath) &&
            (identical(other.episodeCount, _this.episodeCount) ||
                other.episodeCount == _this.episodeCount) &&
            (identical(other.currentEpisodeIndex, _this.currentEpisodeIndex) ||
                other.currentEpisodeIndex == _this.currentEpisodeIndex) &&
            (identical(other.currentPositionMs, _this.currentPositionMs) ||
                other.currentPositionMs == _this.currentPositionMs) &&
            (identical(other.finished, _this.finished) ||
                other.finished == _this.finished) &&
            (identical(other.sourceMissing, _this.sourceMissing) ||
                other.sourceMissing == _this.sourceMissing) &&
            (identical(other.titleEditedByUser, _this.titleEditedByUser) ||
                other.titleEditedByUser == _this.titleEditedByUser) &&
            (identical(other.authorEditedByUser, _this.authorEditedByUser) ||
                other.authorEditedByUser == _this.authorEditedByUser) &&
            (identical(other.orderEditedByUser, _this.orderEditedByUser) ||
                other.orderEditedByUser == _this.orderEditedByUser) &&
            (identical(other.lastPlayedAt, _this.lastPlayedAt) ||
                other.lastPlayedAt == _this.lastPlayedAt) &&
            (identical(other.updatedByDevice, _this.updatedByDevice) ||
                other.updatedByDevice == _this.updatedByDevice));
  }

  @override
  int get hashCode {
    final _this = this as Series;
    return Object.hashAll([
      runtimeType,
      _this.id,
      _this.folderPath,
      _this.title,
      _this.addedAt,
      _this.updatedAt,
      _this.kind,
      _this.author,
      _this.coverFsId,
      _this.coverLocalPath,
      _this.episodeCount,
      _this.currentEpisodeIndex,
      _this.currentPositionMs,
      _this.finished,
      _this.sourceMissing,
      _this.titleEditedByUser,
      _this.authorEditedByUser,
      _this.orderEditedByUser,
      _this.lastPlayedAt,
      _this.updatedByDevice
    ]);
  }

  @override
  String toString() {
    final _this = this as Series;
    return 'Series(id: ${_this.id}, folderPath: ${_this.folderPath}, title: ${_this.title}, addedAt: ${_this.addedAt}, updatedAt: ${_this.updatedAt}, kind: ${_this.kind}, author: ${_this.author}, coverFsId: ${_this.coverFsId}, coverLocalPath: ${_this.coverLocalPath}, episodeCount: ${_this.episodeCount}, currentEpisodeIndex: ${_this.currentEpisodeIndex}, currentPositionMs: ${_this.currentPositionMs}, finished: ${_this.finished}, sourceMissing: ${_this.sourceMissing}, titleEditedByUser: ${_this.titleEditedByUser}, authorEditedByUser: ${_this.authorEditedByUser}, orderEditedByUser: ${_this.orderEditedByUser}, lastPlayedAt: ${_this.lastPlayedAt}, updatedByDevice: ${_this.updatedByDevice})';
  }
}

/// @nodoc
abstract mixin class $SeriesCopyWith<$Res> {
  factory $SeriesCopyWith(Series value, $Res Function(Series) _then) =
      _$SeriesCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      String folderPath,
      String title,
      DateTime addedAt,
      DateTime updatedAt,
      SeriesKind kind,
      String? author,
      String? coverFsId,
      String? coverLocalPath,
      int episodeCount,
      int currentEpisodeIndex,
      int currentPositionMs,
      bool finished,
      bool sourceMissing,
      bool titleEditedByUser,
      bool authorEditedByUser,
      bool orderEditedByUser,
      DateTime? lastPlayedAt,
      String updatedByDevice});
}

/// @nodoc
class _$SeriesCopyWithImpl<$Res> implements $SeriesCopyWith<$Res> {
  _$SeriesCopyWithImpl(this._self, this._then);

  final Series _self;
  final $Res Function(Series) _then;

  /// Create a copy of Series
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? folderPath = null,
    Object? title = null,
    Object? addedAt = null,
    Object? updatedAt = null,
    Object? kind = null,
    Object? author = freezed,
    Object? coverFsId = freezed,
    Object? coverLocalPath = freezed,
    Object? episodeCount = null,
    Object? currentEpisodeIndex = null,
    Object? currentPositionMs = null,
    Object? finished = null,
    Object? sourceMissing = null,
    Object? titleEditedByUser = null,
    Object? authorEditedByUser = null,
    Object? orderEditedByUser = null,
    Object? lastPlayedAt = freezed,
    Object? updatedByDevice = null,
  }) {
    return _then(Series(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      folderPath: null == folderPath
          ? _self.folderPath
          : folderPath // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _self.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      addedAt: null == addedAt
          ? _self.addedAt
          : addedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _self.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      kind: null == kind
          ? _self.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as SeriesKind,
      author: freezed == author
          ? _self.author
          : author // ignore: cast_nullable_to_non_nullable
              as String?,
      coverFsId: freezed == coverFsId
          ? _self.coverFsId
          : coverFsId // ignore: cast_nullable_to_non_nullable
              as String?,
      coverLocalPath: freezed == coverLocalPath
          ? _self.coverLocalPath
          : coverLocalPath // ignore: cast_nullable_to_non_nullable
              as String?,
      episodeCount: null == episodeCount
          ? _self.episodeCount
          : episodeCount // ignore: cast_nullable_to_non_nullable
              as int,
      currentEpisodeIndex: null == currentEpisodeIndex
          ? _self.currentEpisodeIndex
          : currentEpisodeIndex // ignore: cast_nullable_to_non_nullable
              as int,
      currentPositionMs: null == currentPositionMs
          ? _self.currentPositionMs
          : currentPositionMs // ignore: cast_nullable_to_non_nullable
              as int,
      finished: null == finished
          ? _self.finished
          : finished // ignore: cast_nullable_to_non_nullable
              as bool,
      sourceMissing: null == sourceMissing
          ? _self.sourceMissing
          : sourceMissing // ignore: cast_nullable_to_non_nullable
              as bool,
      titleEditedByUser: null == titleEditedByUser
          ? _self.titleEditedByUser
          : titleEditedByUser // ignore: cast_nullable_to_non_nullable
              as bool,
      authorEditedByUser: null == authorEditedByUser
          ? _self.authorEditedByUser
          : authorEditedByUser // ignore: cast_nullable_to_non_nullable
              as bool,
      orderEditedByUser: null == orderEditedByUser
          ? _self.orderEditedByUser
          : orderEditedByUser // ignore: cast_nullable_to_non_nullable
              as bool,
      lastPlayedAt: freezed == lastPlayedAt
          ? _self.lastPlayedAt
          : lastPlayedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedByDevice: null == updatedByDevice
          ? _self.updatedByDevice
          : updatedByDevice // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// Adds pattern-matching-related methods to [Series].
extension SeriesPatterns on Series {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_Series value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Series() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_Series value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Series():
        return $default(_that);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_Series value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Series() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(
            String id,
            String folderPath,
            String title,
            DateTime addedAt,
            DateTime updatedAt,
            SeriesKind kind,
            String? author,
            String? coverFsId,
            String? coverLocalPath,
            int episodeCount,
            int currentEpisodeIndex,
            int currentPositionMs,
            bool finished,
            bool sourceMissing,
            bool titleEditedByUser,
            bool authorEditedByUser,
            bool orderEditedByUser,
            DateTime? lastPlayedAt,
            String updatedByDevice)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Series() when $default != null:
        return $default(
            _that.id,
            _that.folderPath,
            _that.title,
            _that.addedAt,
            _that.updatedAt,
            _that.kind,
            _that.author,
            _that.coverFsId,
            _that.coverLocalPath,
            _that.episodeCount,
            _that.currentEpisodeIndex,
            _that.currentPositionMs,
            _that.finished,
            _that.sourceMissing,
            _that.titleEditedByUser,
            _that.authorEditedByUser,
            _that.orderEditedByUser,
            _that.lastPlayedAt,
            _that.updatedByDevice);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(
            String id,
            String folderPath,
            String title,
            DateTime addedAt,
            DateTime updatedAt,
            SeriesKind kind,
            String? author,
            String? coverFsId,
            String? coverLocalPath,
            int episodeCount,
            int currentEpisodeIndex,
            int currentPositionMs,
            bool finished,
            bool sourceMissing,
            bool titleEditedByUser,
            bool authorEditedByUser,
            bool orderEditedByUser,
            DateTime? lastPlayedAt,
            String updatedByDevice)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Series():
        return $default(
            _that.id,
            _that.folderPath,
            _that.title,
            _that.addedAt,
            _that.updatedAt,
            _that.kind,
            _that.author,
            _that.coverFsId,
            _that.coverLocalPath,
            _that.episodeCount,
            _that.currentEpisodeIndex,
            _that.currentPositionMs,
            _that.finished,
            _that.sourceMissing,
            _that.titleEditedByUser,
            _that.authorEditedByUser,
            _that.orderEditedByUser,
            _that.lastPlayedAt,
            _that.updatedByDevice);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(
            String id,
            String folderPath,
            String title,
            DateTime addedAt,
            DateTime updatedAt,
            SeriesKind kind,
            String? author,
            String? coverFsId,
            String? coverLocalPath,
            int episodeCount,
            int currentEpisodeIndex,
            int currentPositionMs,
            bool finished,
            bool sourceMissing,
            bool titleEditedByUser,
            bool authorEditedByUser,
            bool orderEditedByUser,
            DateTime? lastPlayedAt,
            String updatedByDevice)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Series() when $default != null:
        return $default(
            _that.id,
            _that.folderPath,
            _that.title,
            _that.addedAt,
            _that.updatedAt,
            _that.kind,
            _that.author,
            _that.coverFsId,
            _that.coverLocalPath,
            _that.episodeCount,
            _that.currentEpisodeIndex,
            _that.currentPositionMs,
            _that.finished,
            _that.sourceMissing,
            _that.titleEditedByUser,
            _that.authorEditedByUser,
            _that.orderEditedByUser,
            _that.lastPlayedAt,
            _that.updatedByDevice);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _Series extends Series {
  const _Series(
      {required this.id,
      required this.folderPath,
      required this.title,
      required this.addedAt,
      required this.updatedAt,
      this.kind = SeriesKind.audiobook,
      this.author,
      this.coverFsId,
      this.coverLocalPath,
      this.episodeCount = 0,
      this.currentEpisodeIndex = 0,
      this.currentPositionMs = 0,
      this.finished = false,
      this.sourceMissing = false,
      this.titleEditedByUser = false,
      this.authorEditedByUser = false,
      this.orderEditedByUser = false,
      this.lastPlayedAt,
      this.updatedByDevice = ''})
      : super._();

  @override
  final String id;

  /// 网盘中的目录路径。这是合集的身份，用于去重认领。
  @override
  final String folderPath;
  @override
  final String title;
  @override
  final DateTime addedAt;
  @override
  final DateTime updatedAt;
  @override
  @JsonKey()
  final SeriesKind kind;
  @override
  final String? author;
  @override
  final String? coverFsId;
  @override
  final String? coverLocalPath;
  @override
  @JsonKey()
  final int episodeCount;
  @override
  @JsonKey()
  final int currentEpisodeIndex;
  @override
  @JsonKey()
  final int currentPositionMs;
  @override
  @JsonKey()
  final bool finished;

  /// 网盘路径消失时置位。条目与进度都保留（library-catalog 规格）。
  @override
  @JsonKey()
  final bool sourceMissing;

  /// 用户手动编辑过的字段不允许被自动识别结果覆盖。
  @override
  @JsonKey()
  final bool titleEditedByUser;
  @override
  @JsonKey()
  final bool authorEditedByUser;
  @override
  @JsonKey()
  final bool orderEditedByUser;
  @override
  final DateTime? lastPlayedAt;

  /// 同步时的 LWW 合并依据（listening-progress 规格）。
  @override
  @JsonKey()
  final String updatedByDevice;

  /// Create a copy of Series
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$SeriesCopyWith<_Series> get copyWith =>
      __$SeriesCopyWithImpl<_Series>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _Series &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.folderPath, folderPath) ||
                other.folderPath == folderPath) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.addedAt, addedAt) || other.addedAt == addedAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.kind, kind) || other.kind == kind) &&
            (identical(other.author, author) || other.author == author) &&
            (identical(other.coverFsId, coverFsId) ||
                other.coverFsId == coverFsId) &&
            (identical(other.coverLocalPath, coverLocalPath) ||
                other.coverLocalPath == coverLocalPath) &&
            (identical(other.episodeCount, episodeCount) ||
                other.episodeCount == episodeCount) &&
            (identical(other.currentEpisodeIndex, currentEpisodeIndex) ||
                other.currentEpisodeIndex == currentEpisodeIndex) &&
            (identical(other.currentPositionMs, currentPositionMs) ||
                other.currentPositionMs == currentPositionMs) &&
            (identical(other.finished, finished) ||
                other.finished == finished) &&
            (identical(other.sourceMissing, sourceMissing) ||
                other.sourceMissing == sourceMissing) &&
            (identical(other.titleEditedByUser, titleEditedByUser) ||
                other.titleEditedByUser == titleEditedByUser) &&
            (identical(other.authorEditedByUser, authorEditedByUser) ||
                other.authorEditedByUser == authorEditedByUser) &&
            (identical(other.orderEditedByUser, orderEditedByUser) ||
                other.orderEditedByUser == orderEditedByUser) &&
            (identical(other.lastPlayedAt, lastPlayedAt) ||
                other.lastPlayedAt == lastPlayedAt) &&
            (identical(other.updatedByDevice, updatedByDevice) ||
                other.updatedByDevice == updatedByDevice));
  }

  @override
  int get hashCode {
    return Object.hashAll([
      runtimeType,
      id,
      folderPath,
      title,
      addedAt,
      updatedAt,
      kind,
      author,
      coverFsId,
      coverLocalPath,
      episodeCount,
      currentEpisodeIndex,
      currentPositionMs,
      finished,
      sourceMissing,
      titleEditedByUser,
      authorEditedByUser,
      orderEditedByUser,
      lastPlayedAt,
      updatedByDevice
    ]);
  }

  @override
  String toString() {
    return 'Series(id: $id, folderPath: $folderPath, title: $title, addedAt: $addedAt, updatedAt: $updatedAt, kind: $kind, author: $author, coverFsId: $coverFsId, coverLocalPath: $coverLocalPath, episodeCount: $episodeCount, currentEpisodeIndex: $currentEpisodeIndex, currentPositionMs: $currentPositionMs, finished: $finished, sourceMissing: $sourceMissing, titleEditedByUser: $titleEditedByUser, authorEditedByUser: $authorEditedByUser, orderEditedByUser: $orderEditedByUser, lastPlayedAt: $lastPlayedAt, updatedByDevice: $updatedByDevice)';
  }
}

/// @nodoc
abstract mixin class _$SeriesCopyWith<$Res> implements $SeriesCopyWith<$Res> {
  factory _$SeriesCopyWith(_Series value, $Res Function(_Series) _then) =
      __$SeriesCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      String folderPath,
      String title,
      DateTime addedAt,
      DateTime updatedAt,
      SeriesKind kind,
      String? author,
      String? coverFsId,
      String? coverLocalPath,
      int episodeCount,
      int currentEpisodeIndex,
      int currentPositionMs,
      bool finished,
      bool sourceMissing,
      bool titleEditedByUser,
      bool authorEditedByUser,
      bool orderEditedByUser,
      DateTime? lastPlayedAt,
      String updatedByDevice});
}

/// @nodoc
class __$SeriesCopyWithImpl<$Res> implements _$SeriesCopyWith<$Res> {
  __$SeriesCopyWithImpl(this._self, this._then);

  final _Series _self;
  final $Res Function(_Series) _then;

  /// Create a copy of Series
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? folderPath = null,
    Object? title = null,
    Object? addedAt = null,
    Object? updatedAt = null,
    Object? kind = null,
    Object? author = freezed,
    Object? coverFsId = freezed,
    Object? coverLocalPath = freezed,
    Object? episodeCount = null,
    Object? currentEpisodeIndex = null,
    Object? currentPositionMs = null,
    Object? finished = null,
    Object? sourceMissing = null,
    Object? titleEditedByUser = null,
    Object? authorEditedByUser = null,
    Object? orderEditedByUser = null,
    Object? lastPlayedAt = freezed,
    Object? updatedByDevice = null,
  }) {
    return _then(_Series(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      folderPath: null == folderPath
          ? _self.folderPath
          : folderPath // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _self.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      addedAt: null == addedAt
          ? _self.addedAt
          : addedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _self.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      kind: null == kind
          ? _self.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as SeriesKind,
      author: freezed == author
          ? _self.author
          : author // ignore: cast_nullable_to_non_nullable
              as String?,
      coverFsId: freezed == coverFsId
          ? _self.coverFsId
          : coverFsId // ignore: cast_nullable_to_non_nullable
              as String?,
      coverLocalPath: freezed == coverLocalPath
          ? _self.coverLocalPath
          : coverLocalPath // ignore: cast_nullable_to_non_nullable
              as String?,
      episodeCount: null == episodeCount
          ? _self.episodeCount
          : episodeCount // ignore: cast_nullable_to_non_nullable
              as int,
      currentEpisodeIndex: null == currentEpisodeIndex
          ? _self.currentEpisodeIndex
          : currentEpisodeIndex // ignore: cast_nullable_to_non_nullable
              as int,
      currentPositionMs: null == currentPositionMs
          ? _self.currentPositionMs
          : currentPositionMs // ignore: cast_nullable_to_non_nullable
              as int,
      finished: null == finished
          ? _self.finished
          : finished // ignore: cast_nullable_to_non_nullable
              as bool,
      sourceMissing: null == sourceMissing
          ? _self.sourceMissing
          : sourceMissing // ignore: cast_nullable_to_non_nullable
              as bool,
      titleEditedByUser: null == titleEditedByUser
          ? _self.titleEditedByUser
          : titleEditedByUser // ignore: cast_nullable_to_non_nullable
              as bool,
      authorEditedByUser: null == authorEditedByUser
          ? _self.authorEditedByUser
          : authorEditedByUser // ignore: cast_nullable_to_non_nullable
              as bool,
      orderEditedByUser: null == orderEditedByUser
          ? _self.orderEditedByUser
          : orderEditedByUser // ignore: cast_nullable_to_non_nullable
              as bool,
      lastPlayedAt: freezed == lastPlayedAt
          ? _self.lastPlayedAt
          : lastPlayedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedByDevice: null == updatedByDevice
          ? _self.updatedByDevice
          : updatedByDevice // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
mixin _$AudioTags {
  String? get title;
  String? get album;
  String? get artist;
  int? get track;

  /// Create a copy of AudioTags
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $AudioTagsCopyWith<AudioTags> get copyWith =>
      _$AudioTagsCopyWithImpl<AudioTags>(this as AudioTags, _$identity);

  @override
  bool operator ==(Object other) {
    final _this = this as AudioTags;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is AudioTags &&
            (identical(other.title, _this.title) ||
                other.title == _this.title) &&
            (identical(other.album, _this.album) ||
                other.album == _this.album) &&
            (identical(other.artist, _this.artist) ||
                other.artist == _this.artist) &&
            (identical(other.track, _this.track) ||
                other.track == _this.track));
  }

  @override
  int get hashCode {
    final _this = this as AudioTags;
    return Object.hash(
        runtimeType, _this.title, _this.album, _this.artist, _this.track);
  }

  @override
  String toString() {
    final _this = this as AudioTags;
    return 'AudioTags(title: ${_this.title}, album: ${_this.album}, artist: ${_this.artist}, track: ${_this.track})';
  }
}

/// @nodoc
abstract mixin class $AudioTagsCopyWith<$Res> {
  factory $AudioTagsCopyWith(AudioTags value, $Res Function(AudioTags) _then) =
      _$AudioTagsCopyWithImpl;
  @useResult
  $Res call({String? title, String? album, String? artist, int? track});
}

/// @nodoc
class _$AudioTagsCopyWithImpl<$Res> implements $AudioTagsCopyWith<$Res> {
  _$AudioTagsCopyWithImpl(this._self, this._then);

  final AudioTags _self;
  final $Res Function(AudioTags) _then;

  /// Create a copy of AudioTags
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? title = freezed,
    Object? album = freezed,
    Object? artist = freezed,
    Object? track = freezed,
  }) {
    return _then(AudioTags(
      title: freezed == title
          ? _self.title
          : title // ignore: cast_nullable_to_non_nullable
              as String?,
      album: freezed == album
          ? _self.album
          : album // ignore: cast_nullable_to_non_nullable
              as String?,
      artist: freezed == artist
          ? _self.artist
          : artist // ignore: cast_nullable_to_non_nullable
              as String?,
      track: freezed == track
          ? _self.track
          : track // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// Adds pattern-matching-related methods to [AudioTags].
extension AudioTagsPatterns on AudioTags {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_AudioTags value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _AudioTags() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_AudioTags value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AudioTags():
        return $default(_that);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_AudioTags value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AudioTags() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(String? title, String? album, String? artist, int? track)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _AudioTags() when $default != null:
        return $default(_that.title, _that.album, _that.artist, _that.track);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(String? title, String? album, String? artist, int? track)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AudioTags():
        return $default(_that.title, _that.album, _that.artist, _that.track);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(String? title, String? album, String? artist, int? track)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AudioTags() when $default != null:
        return $default(_that.title, _that.album, _that.artist, _that.track);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _AudioTags extends AudioTags {
  const _AudioTags({this.title, this.album, this.artist, this.track})
      : super._();

  @override
  final String? title;
  @override
  final String? album;
  @override
  final String? artist;
  @override
  final int? track;

  /// Create a copy of AudioTags
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$AudioTagsCopyWith<_AudioTags> get copyWith =>
      __$AudioTagsCopyWithImpl<_AudioTags>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _AudioTags &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.album, album) || other.album == album) &&
            (identical(other.artist, artist) || other.artist == artist) &&
            (identical(other.track, track) || other.track == track));
  }

  @override
  int get hashCode {
    return Object.hash(runtimeType, title, album, artist, track);
  }

  @override
  String toString() {
    return 'AudioTags(title: $title, album: $album, artist: $artist, track: $track)';
  }
}

/// @nodoc
abstract mixin class _$AudioTagsCopyWith<$Res>
    implements $AudioTagsCopyWith<$Res> {
  factory _$AudioTagsCopyWith(
          _AudioTags value, $Res Function(_AudioTags) _then) =
      __$AudioTagsCopyWithImpl;
  @override
  @useResult
  $Res call({String? title, String? album, String? artist, int? track});
}

/// @nodoc
class __$AudioTagsCopyWithImpl<$Res> implements _$AudioTagsCopyWith<$Res> {
  __$AudioTagsCopyWithImpl(this._self, this._then);

  final _AudioTags _self;
  final $Res Function(_AudioTags) _then;

  /// Create a copy of AudioTags
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? title = freezed,
    Object? album = freezed,
    Object? artist = freezed,
    Object? track = freezed,
  }) {
    return _then(_AudioTags(
      title: freezed == title
          ? _self.title
          : title // ignore: cast_nullable_to_non_nullable
              as String?,
      album: freezed == album
          ? _self.album
          : album // ignore: cast_nullable_to_non_nullable
              as String?,
      artist: freezed == artist
          ? _self.artist
          : artist // ignore: cast_nullable_to_non_nullable
              as String?,
      track: freezed == track
          ? _self.track
          : track // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc
mixin _$PlayHistoryEntry {
  int get id;
  String get seriesId;
  String get episodeId;

  /// 认领时的条目序号。用它跳回去续播；合集被刷新过就可能对不上，
  /// 所以跳转前要校验范围。
  int get episodeIndex;
  String get seriesTitle;
  String get episodeTitle;
  DateTime get startedAt;
  DateTime get lastAt;

  /// 最后一次上报的播放位置，用于跳回去接着听，也用于累计时长时算增量。
  int get lastPositionMs;

  /// 累计实际收听时长。只累加「像是在正常播放」的增量，
  /// 拖动进度条跳过去的部分不算（见 HistoryDao）。
  int get listenedMs;
  bool get finished;
  String? get coverFsId;

  /// Create a copy of PlayHistoryEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $PlayHistoryEntryCopyWith<PlayHistoryEntry> get copyWith =>
      _$PlayHistoryEntryCopyWithImpl<PlayHistoryEntry>(
          this as PlayHistoryEntry, _$identity);

  @override
  bool operator ==(Object other) {
    final _this = this as PlayHistoryEntry;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is PlayHistoryEntry &&
            (identical(other.id, _this.id) || other.id == _this.id) &&
            (identical(other.seriesId, _this.seriesId) ||
                other.seriesId == _this.seriesId) &&
            (identical(other.episodeId, _this.episodeId) ||
                other.episodeId == _this.episodeId) &&
            (identical(other.episodeIndex, _this.episodeIndex) ||
                other.episodeIndex == _this.episodeIndex) &&
            (identical(other.seriesTitle, _this.seriesTitle) ||
                other.seriesTitle == _this.seriesTitle) &&
            (identical(other.episodeTitle, _this.episodeTitle) ||
                other.episodeTitle == _this.episodeTitle) &&
            (identical(other.startedAt, _this.startedAt) ||
                other.startedAt == _this.startedAt) &&
            (identical(other.lastAt, _this.lastAt) ||
                other.lastAt == _this.lastAt) &&
            (identical(other.lastPositionMs, _this.lastPositionMs) ||
                other.lastPositionMs == _this.lastPositionMs) &&
            (identical(other.listenedMs, _this.listenedMs) ||
                other.listenedMs == _this.listenedMs) &&
            (identical(other.finished, _this.finished) ||
                other.finished == _this.finished) &&
            (identical(other.coverFsId, _this.coverFsId) ||
                other.coverFsId == _this.coverFsId));
  }

  @override
  int get hashCode {
    final _this = this as PlayHistoryEntry;
    return Object.hash(
        runtimeType,
        _this.id,
        _this.seriesId,
        _this.episodeId,
        _this.episodeIndex,
        _this.seriesTitle,
        _this.episodeTitle,
        _this.startedAt,
        _this.lastAt,
        _this.lastPositionMs,
        _this.listenedMs,
        _this.finished,
        _this.coverFsId);
  }

  @override
  String toString() {
    final _this = this as PlayHistoryEntry;
    return 'PlayHistoryEntry(id: ${_this.id}, seriesId: ${_this.seriesId}, episodeId: ${_this.episodeId}, episodeIndex: ${_this.episodeIndex}, seriesTitle: ${_this.seriesTitle}, episodeTitle: ${_this.episodeTitle}, startedAt: ${_this.startedAt}, lastAt: ${_this.lastAt}, lastPositionMs: ${_this.lastPositionMs}, listenedMs: ${_this.listenedMs}, finished: ${_this.finished}, coverFsId: ${_this.coverFsId})';
  }
}

/// @nodoc
abstract mixin class $PlayHistoryEntryCopyWith<$Res> {
  factory $PlayHistoryEntryCopyWith(
          PlayHistoryEntry value, $Res Function(PlayHistoryEntry) _then) =
      _$PlayHistoryEntryCopyWithImpl;
  @useResult
  $Res call(
      {int id,
      String seriesId,
      String episodeId,
      int episodeIndex,
      String seriesTitle,
      String episodeTitle,
      DateTime startedAt,
      DateTime lastAt,
      int lastPositionMs,
      int listenedMs,
      bool finished,
      String? coverFsId});
}

/// @nodoc
class _$PlayHistoryEntryCopyWithImpl<$Res>
    implements $PlayHistoryEntryCopyWith<$Res> {
  _$PlayHistoryEntryCopyWithImpl(this._self, this._then);

  final PlayHistoryEntry _self;
  final $Res Function(PlayHistoryEntry) _then;

  /// Create a copy of PlayHistoryEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? seriesId = null,
    Object? episodeId = null,
    Object? episodeIndex = null,
    Object? seriesTitle = null,
    Object? episodeTitle = null,
    Object? startedAt = null,
    Object? lastAt = null,
    Object? lastPositionMs = null,
    Object? listenedMs = null,
    Object? finished = null,
    Object? coverFsId = freezed,
  }) {
    return _then(PlayHistoryEntry(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      seriesId: null == seriesId
          ? _self.seriesId
          : seriesId // ignore: cast_nullable_to_non_nullable
              as String,
      episodeId: null == episodeId
          ? _self.episodeId
          : episodeId // ignore: cast_nullable_to_non_nullable
              as String,
      episodeIndex: null == episodeIndex
          ? _self.episodeIndex
          : episodeIndex // ignore: cast_nullable_to_non_nullable
              as int,
      seriesTitle: null == seriesTitle
          ? _self.seriesTitle
          : seriesTitle // ignore: cast_nullable_to_non_nullable
              as String,
      episodeTitle: null == episodeTitle
          ? _self.episodeTitle
          : episodeTitle // ignore: cast_nullable_to_non_nullable
              as String,
      startedAt: null == startedAt
          ? _self.startedAt
          : startedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      lastAt: null == lastAt
          ? _self.lastAt
          : lastAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      lastPositionMs: null == lastPositionMs
          ? _self.lastPositionMs
          : lastPositionMs // ignore: cast_nullable_to_non_nullable
              as int,
      listenedMs: null == listenedMs
          ? _self.listenedMs
          : listenedMs // ignore: cast_nullable_to_non_nullable
              as int,
      finished: null == finished
          ? _self.finished
          : finished // ignore: cast_nullable_to_non_nullable
              as bool,
      coverFsId: freezed == coverFsId
          ? _self.coverFsId
          : coverFsId // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// Adds pattern-matching-related methods to [PlayHistoryEntry].
extension PlayHistoryEntryPatterns on PlayHistoryEntry {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_PlayHistoryEntry value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _PlayHistoryEntry() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_PlayHistoryEntry value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PlayHistoryEntry():
        return $default(_that);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_PlayHistoryEntry value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PlayHistoryEntry() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(
            int id,
            String seriesId,
            String episodeId,
            int episodeIndex,
            String seriesTitle,
            String episodeTitle,
            DateTime startedAt,
            DateTime lastAt,
            int lastPositionMs,
            int listenedMs,
            bool finished,
            String? coverFsId)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _PlayHistoryEntry() when $default != null:
        return $default(
            _that.id,
            _that.seriesId,
            _that.episodeId,
            _that.episodeIndex,
            _that.seriesTitle,
            _that.episodeTitle,
            _that.startedAt,
            _that.lastAt,
            _that.lastPositionMs,
            _that.listenedMs,
            _that.finished,
            _that.coverFsId);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(
            int id,
            String seriesId,
            String episodeId,
            int episodeIndex,
            String seriesTitle,
            String episodeTitle,
            DateTime startedAt,
            DateTime lastAt,
            int lastPositionMs,
            int listenedMs,
            bool finished,
            String? coverFsId)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PlayHistoryEntry():
        return $default(
            _that.id,
            _that.seriesId,
            _that.episodeId,
            _that.episodeIndex,
            _that.seriesTitle,
            _that.episodeTitle,
            _that.startedAt,
            _that.lastAt,
            _that.lastPositionMs,
            _that.listenedMs,
            _that.finished,
            _that.coverFsId);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(
            int id,
            String seriesId,
            String episodeId,
            int episodeIndex,
            String seriesTitle,
            String episodeTitle,
            DateTime startedAt,
            DateTime lastAt,
            int lastPositionMs,
            int listenedMs,
            bool finished,
            String? coverFsId)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PlayHistoryEntry() when $default != null:
        return $default(
            _that.id,
            _that.seriesId,
            _that.episodeId,
            _that.episodeIndex,
            _that.seriesTitle,
            _that.episodeTitle,
            _that.startedAt,
            _that.lastAt,
            _that.lastPositionMs,
            _that.listenedMs,
            _that.finished,
            _that.coverFsId);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _PlayHistoryEntry implements PlayHistoryEntry {
  const _PlayHistoryEntry(
      {required this.id,
      required this.seriesId,
      required this.episodeId,
      required this.episodeIndex,
      required this.seriesTitle,
      required this.episodeTitle,
      required this.startedAt,
      required this.lastAt,
      required this.lastPositionMs,
      required this.listenedMs,
      required this.finished,
      this.coverFsId});

  @override
  final int id;
  @override
  final String seriesId;
  @override
  final String episodeId;

  /// 认领时的条目序号。用它跳回去续播；合集被刷新过就可能对不上，
  /// 所以跳转前要校验范围。
  @override
  final int episodeIndex;
  @override
  final String seriesTitle;
  @override
  final String episodeTitle;
  @override
  final DateTime startedAt;
  @override
  final DateTime lastAt;

  /// 最后一次上报的播放位置，用于跳回去接着听，也用于累计时长时算增量。
  @override
  final int lastPositionMs;

  /// 累计实际收听时长。只累加「像是在正常播放」的增量，
  /// 拖动进度条跳过去的部分不算（见 HistoryDao）。
  @override
  final int listenedMs;
  @override
  final bool finished;
  @override
  final String? coverFsId;

  /// Create a copy of PlayHistoryEntry
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$PlayHistoryEntryCopyWith<_PlayHistoryEntry> get copyWith =>
      __$PlayHistoryEntryCopyWithImpl<_PlayHistoryEntry>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _PlayHistoryEntry &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.seriesId, seriesId) ||
                other.seriesId == seriesId) &&
            (identical(other.episodeId, episodeId) ||
                other.episodeId == episodeId) &&
            (identical(other.episodeIndex, episodeIndex) ||
                other.episodeIndex == episodeIndex) &&
            (identical(other.seriesTitle, seriesTitle) ||
                other.seriesTitle == seriesTitle) &&
            (identical(other.episodeTitle, episodeTitle) ||
                other.episodeTitle == episodeTitle) &&
            (identical(other.startedAt, startedAt) ||
                other.startedAt == startedAt) &&
            (identical(other.lastAt, lastAt) || other.lastAt == lastAt) &&
            (identical(other.lastPositionMs, lastPositionMs) ||
                other.lastPositionMs == lastPositionMs) &&
            (identical(other.listenedMs, listenedMs) ||
                other.listenedMs == listenedMs) &&
            (identical(other.finished, finished) ||
                other.finished == finished) &&
            (identical(other.coverFsId, coverFsId) ||
                other.coverFsId == coverFsId));
  }

  @override
  int get hashCode {
    return Object.hash(
        runtimeType,
        id,
        seriesId,
        episodeId,
        episodeIndex,
        seriesTitle,
        episodeTitle,
        startedAt,
        lastAt,
        lastPositionMs,
        listenedMs,
        finished,
        coverFsId);
  }

  @override
  String toString() {
    return 'PlayHistoryEntry(id: $id, seriesId: $seriesId, episodeId: $episodeId, episodeIndex: $episodeIndex, seriesTitle: $seriesTitle, episodeTitle: $episodeTitle, startedAt: $startedAt, lastAt: $lastAt, lastPositionMs: $lastPositionMs, listenedMs: $listenedMs, finished: $finished, coverFsId: $coverFsId)';
  }
}

/// @nodoc
abstract mixin class _$PlayHistoryEntryCopyWith<$Res>
    implements $PlayHistoryEntryCopyWith<$Res> {
  factory _$PlayHistoryEntryCopyWith(
          _PlayHistoryEntry value, $Res Function(_PlayHistoryEntry) _then) =
      __$PlayHistoryEntryCopyWithImpl;
  @override
  @useResult
  $Res call(
      {int id,
      String seriesId,
      String episodeId,
      int episodeIndex,
      String seriesTitle,
      String episodeTitle,
      DateTime startedAt,
      DateTime lastAt,
      int lastPositionMs,
      int listenedMs,
      bool finished,
      String? coverFsId});
}

/// @nodoc
class __$PlayHistoryEntryCopyWithImpl<$Res>
    implements _$PlayHistoryEntryCopyWith<$Res> {
  __$PlayHistoryEntryCopyWithImpl(this._self, this._then);

  final _PlayHistoryEntry _self;
  final $Res Function(_PlayHistoryEntry) _then;

  /// Create a copy of PlayHistoryEntry
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? seriesId = null,
    Object? episodeId = null,
    Object? episodeIndex = null,
    Object? seriesTitle = null,
    Object? episodeTitle = null,
    Object? startedAt = null,
    Object? lastAt = null,
    Object? lastPositionMs = null,
    Object? listenedMs = null,
    Object? finished = null,
    Object? coverFsId = freezed,
  }) {
    return _then(_PlayHistoryEntry(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      seriesId: null == seriesId
          ? _self.seriesId
          : seriesId // ignore: cast_nullable_to_non_nullable
              as String,
      episodeId: null == episodeId
          ? _self.episodeId
          : episodeId // ignore: cast_nullable_to_non_nullable
              as String,
      episodeIndex: null == episodeIndex
          ? _self.episodeIndex
          : episodeIndex // ignore: cast_nullable_to_non_nullable
              as int,
      seriesTitle: null == seriesTitle
          ? _self.seriesTitle
          : seriesTitle // ignore: cast_nullable_to_non_nullable
              as String,
      episodeTitle: null == episodeTitle
          ? _self.episodeTitle
          : episodeTitle // ignore: cast_nullable_to_non_nullable
              as String,
      startedAt: null == startedAt
          ? _self.startedAt
          : startedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      lastAt: null == lastAt
          ? _self.lastAt
          : lastAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      lastPositionMs: null == lastPositionMs
          ? _self.lastPositionMs
          : lastPositionMs // ignore: cast_nullable_to_non_nullable
              as int,
      listenedMs: null == listenedMs
          ? _self.listenedMs
          : listenedMs // ignore: cast_nullable_to_non_nullable
              as int,
      finished: null == finished
          ? _self.finished
          : finished // ignore: cast_nullable_to_non_nullable
              as bool,
      coverFsId: freezed == coverFsId
          ? _self.coverFsId
          : coverFsId // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

// dart format on
