// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'library_snapshot.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BookRecord {
  String get id;
  @JsonKey(name: 'folder_path')
  String get folderPath;
  String get title;
  String? get author;
  @JsonKey(name: 'cover_fs_id')
  String? get coverFsId;
  @JsonKey(name: 'current_chapter_index')
  int get currentChapterIndex;
  @JsonKey(name: 'current_position_ms')
  int get currentPositionMs;
  bool get finished;
  bool get deleted;
  @JsonKey(name: 'added_at')
  int get addedAt;
  @JsonKey(name: 'updated_at')
  int get updatedAt;
  @JsonKey(name: 'last_played_at')
  int? get lastPlayedAt;
  @JsonKey(name: 'updated_by_device')
  String get updatedByDevice;
  @JsonKey(name: 'title_edited')
  bool get titleEditedByUser;
  @JsonKey(name: 'author_edited')
  bool get authorEditedByUser;
  @JsonKey(name: 'order_edited')
  bool get orderEditedByUser;

  /// v2 新增。旧版本 App 合并后重新上传时会把它丢掉，所以它只用于
  /// 「新拉回来的合集」；本地已有的合集以本地类型为准（见 LibrarySync）。
  @JsonKey(unknownEnumValue: SeriesKind.audiobook)
  SeriesKind get kind;

  /// Create a copy of BookRecord
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $BookRecordCopyWith<BookRecord> get copyWith =>
      _$BookRecordCopyWithImpl<BookRecord>(this as BookRecord, _$identity);

  /// Serializes this BookRecord to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    final _this = this as BookRecord;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is BookRecord &&
            (identical(other.id, _this.id) || other.id == _this.id) &&
            (identical(other.folderPath, _this.folderPath) ||
                other.folderPath == _this.folderPath) &&
            (identical(other.title, _this.title) ||
                other.title == _this.title) &&
            (identical(other.author, _this.author) ||
                other.author == _this.author) &&
            (identical(other.coverFsId, _this.coverFsId) ||
                other.coverFsId == _this.coverFsId) &&
            (identical(other.currentChapterIndex, _this.currentChapterIndex) ||
                other.currentChapterIndex == _this.currentChapterIndex) &&
            (identical(other.currentPositionMs, _this.currentPositionMs) ||
                other.currentPositionMs == _this.currentPositionMs) &&
            (identical(other.finished, _this.finished) ||
                other.finished == _this.finished) &&
            (identical(other.deleted, _this.deleted) ||
                other.deleted == _this.deleted) &&
            (identical(other.addedAt, _this.addedAt) ||
                other.addedAt == _this.addedAt) &&
            (identical(other.updatedAt, _this.updatedAt) ||
                other.updatedAt == _this.updatedAt) &&
            (identical(other.lastPlayedAt, _this.lastPlayedAt) ||
                other.lastPlayedAt == _this.lastPlayedAt) &&
            (identical(other.updatedByDevice, _this.updatedByDevice) ||
                other.updatedByDevice == _this.updatedByDevice) &&
            (identical(other.titleEditedByUser, _this.titleEditedByUser) ||
                other.titleEditedByUser == _this.titleEditedByUser) &&
            (identical(other.authorEditedByUser, _this.authorEditedByUser) ||
                other.authorEditedByUser == _this.authorEditedByUser) &&
            (identical(other.orderEditedByUser, _this.orderEditedByUser) ||
                other.orderEditedByUser == _this.orderEditedByUser) &&
            (identical(other.kind, _this.kind) || other.kind == _this.kind));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    final _this = this as BookRecord;
    return Object.hash(
        runtimeType,
        _this.id,
        _this.folderPath,
        _this.title,
        _this.author,
        _this.coverFsId,
        _this.currentChapterIndex,
        _this.currentPositionMs,
        _this.finished,
        _this.deleted,
        _this.addedAt,
        _this.updatedAt,
        _this.lastPlayedAt,
        _this.updatedByDevice,
        _this.titleEditedByUser,
        _this.authorEditedByUser,
        _this.orderEditedByUser,
        _this.kind);
  }

  @override
  String toString() {
    final _this = this as BookRecord;
    return 'BookRecord(id: ${_this.id}, folderPath: ${_this.folderPath}, title: ${_this.title}, author: ${_this.author}, coverFsId: ${_this.coverFsId}, currentChapterIndex: ${_this.currentChapterIndex}, currentPositionMs: ${_this.currentPositionMs}, finished: ${_this.finished}, deleted: ${_this.deleted}, addedAt: ${_this.addedAt}, updatedAt: ${_this.updatedAt}, lastPlayedAt: ${_this.lastPlayedAt}, updatedByDevice: ${_this.updatedByDevice}, titleEditedByUser: ${_this.titleEditedByUser}, authorEditedByUser: ${_this.authorEditedByUser}, orderEditedByUser: ${_this.orderEditedByUser}, kind: ${_this.kind})';
  }
}

/// @nodoc
abstract mixin class $BookRecordCopyWith<$Res> {
  factory $BookRecordCopyWith(
          BookRecord value, $Res Function(BookRecord) _then) =
      _$BookRecordCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'folder_path') String folderPath,
      String title,
      String? author,
      @JsonKey(name: 'cover_fs_id') String? coverFsId,
      @JsonKey(name: 'current_chapter_index') int currentChapterIndex,
      @JsonKey(name: 'current_position_ms') int currentPositionMs,
      bool finished,
      bool deleted,
      @JsonKey(name: 'added_at') int addedAt,
      @JsonKey(name: 'updated_at') int updatedAt,
      @JsonKey(name: 'last_played_at') int? lastPlayedAt,
      @JsonKey(name: 'updated_by_device') String updatedByDevice,
      @JsonKey(name: 'title_edited') bool titleEditedByUser,
      @JsonKey(name: 'author_edited') bool authorEditedByUser,
      @JsonKey(name: 'order_edited') bool orderEditedByUser,
      @JsonKey(unknownEnumValue: SeriesKind.audiobook) SeriesKind kind});
}

/// @nodoc
class _$BookRecordCopyWithImpl<$Res> implements $BookRecordCopyWith<$Res> {
  _$BookRecordCopyWithImpl(this._self, this._then);

  final BookRecord _self;
  final $Res Function(BookRecord) _then;

  /// Create a copy of BookRecord
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? folderPath = null,
    Object? title = null,
    Object? author = freezed,
    Object? coverFsId = freezed,
    Object? currentChapterIndex = null,
    Object? currentPositionMs = null,
    Object? finished = null,
    Object? deleted = null,
    Object? addedAt = null,
    Object? updatedAt = null,
    Object? lastPlayedAt = freezed,
    Object? updatedByDevice = null,
    Object? titleEditedByUser = null,
    Object? authorEditedByUser = null,
    Object? orderEditedByUser = null,
    Object? kind = null,
  }) {
    return _then(BookRecord(
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
      author: freezed == author
          ? _self.author
          : author // ignore: cast_nullable_to_non_nullable
              as String?,
      coverFsId: freezed == coverFsId
          ? _self.coverFsId
          : coverFsId // ignore: cast_nullable_to_non_nullable
              as String?,
      currentChapterIndex: null == currentChapterIndex
          ? _self.currentChapterIndex
          : currentChapterIndex // ignore: cast_nullable_to_non_nullable
              as int,
      currentPositionMs: null == currentPositionMs
          ? _self.currentPositionMs
          : currentPositionMs // ignore: cast_nullable_to_non_nullable
              as int,
      finished: null == finished
          ? _self.finished
          : finished // ignore: cast_nullable_to_non_nullable
              as bool,
      deleted: null == deleted
          ? _self.deleted
          : deleted // ignore: cast_nullable_to_non_nullable
              as bool,
      addedAt: null == addedAt
          ? _self.addedAt
          : addedAt // ignore: cast_nullable_to_non_nullable
              as int,
      updatedAt: null == updatedAt
          ? _self.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as int,
      lastPlayedAt: freezed == lastPlayedAt
          ? _self.lastPlayedAt
          : lastPlayedAt // ignore: cast_nullable_to_non_nullable
              as int?,
      updatedByDevice: null == updatedByDevice
          ? _self.updatedByDevice
          : updatedByDevice // ignore: cast_nullable_to_non_nullable
              as String,
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
      kind: null == kind
          ? _self.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as SeriesKind,
    ));
  }
}

/// Adds pattern-matching-related methods to [BookRecord].
extension BookRecordPatterns on BookRecord {
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
    TResult Function(_BookRecord value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _BookRecord() when $default != null:
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
    TResult Function(_BookRecord value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _BookRecord():
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
    TResult? Function(_BookRecord value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _BookRecord() when $default != null:
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
            @JsonKey(name: 'folder_path') String folderPath,
            String title,
            String? author,
            @JsonKey(name: 'cover_fs_id') String? coverFsId,
            @JsonKey(name: 'current_chapter_index') int currentChapterIndex,
            @JsonKey(name: 'current_position_ms') int currentPositionMs,
            bool finished,
            bool deleted,
            @JsonKey(name: 'added_at') int addedAt,
            @JsonKey(name: 'updated_at') int updatedAt,
            @JsonKey(name: 'last_played_at') int? lastPlayedAt,
            @JsonKey(name: 'updated_by_device') String updatedByDevice,
            @JsonKey(name: 'title_edited') bool titleEditedByUser,
            @JsonKey(name: 'author_edited') bool authorEditedByUser,
            @JsonKey(name: 'order_edited') bool orderEditedByUser,
            @JsonKey(unknownEnumValue: SeriesKind.audiobook) SeriesKind kind)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _BookRecord() when $default != null:
        return $default(
            _that.id,
            _that.folderPath,
            _that.title,
            _that.author,
            _that.coverFsId,
            _that.currentChapterIndex,
            _that.currentPositionMs,
            _that.finished,
            _that.deleted,
            _that.addedAt,
            _that.updatedAt,
            _that.lastPlayedAt,
            _that.updatedByDevice,
            _that.titleEditedByUser,
            _that.authorEditedByUser,
            _that.orderEditedByUser,
            _that.kind);
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
            @JsonKey(name: 'folder_path') String folderPath,
            String title,
            String? author,
            @JsonKey(name: 'cover_fs_id') String? coverFsId,
            @JsonKey(name: 'current_chapter_index') int currentChapterIndex,
            @JsonKey(name: 'current_position_ms') int currentPositionMs,
            bool finished,
            bool deleted,
            @JsonKey(name: 'added_at') int addedAt,
            @JsonKey(name: 'updated_at') int updatedAt,
            @JsonKey(name: 'last_played_at') int? lastPlayedAt,
            @JsonKey(name: 'updated_by_device') String updatedByDevice,
            @JsonKey(name: 'title_edited') bool titleEditedByUser,
            @JsonKey(name: 'author_edited') bool authorEditedByUser,
            @JsonKey(name: 'order_edited') bool orderEditedByUser,
            @JsonKey(unknownEnumValue: SeriesKind.audiobook) SeriesKind kind)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _BookRecord():
        return $default(
            _that.id,
            _that.folderPath,
            _that.title,
            _that.author,
            _that.coverFsId,
            _that.currentChapterIndex,
            _that.currentPositionMs,
            _that.finished,
            _that.deleted,
            _that.addedAt,
            _that.updatedAt,
            _that.lastPlayedAt,
            _that.updatedByDevice,
            _that.titleEditedByUser,
            _that.authorEditedByUser,
            _that.orderEditedByUser,
            _that.kind);
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
            @JsonKey(name: 'folder_path') String folderPath,
            String title,
            String? author,
            @JsonKey(name: 'cover_fs_id') String? coverFsId,
            @JsonKey(name: 'current_chapter_index') int currentChapterIndex,
            @JsonKey(name: 'current_position_ms') int currentPositionMs,
            bool finished,
            bool deleted,
            @JsonKey(name: 'added_at') int addedAt,
            @JsonKey(name: 'updated_at') int updatedAt,
            @JsonKey(name: 'last_played_at') int? lastPlayedAt,
            @JsonKey(name: 'updated_by_device') String updatedByDevice,
            @JsonKey(name: 'title_edited') bool titleEditedByUser,
            @JsonKey(name: 'author_edited') bool authorEditedByUser,
            @JsonKey(name: 'order_edited') bool orderEditedByUser,
            @JsonKey(unknownEnumValue: SeriesKind.audiobook) SeriesKind kind)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _BookRecord() when $default != null:
        return $default(
            _that.id,
            _that.folderPath,
            _that.title,
            _that.author,
            _that.coverFsId,
            _that.currentChapterIndex,
            _that.currentPositionMs,
            _that.finished,
            _that.deleted,
            _that.addedAt,
            _that.updatedAt,
            _that.lastPlayedAt,
            _that.updatedByDevice,
            _that.titleEditedByUser,
            _that.authorEditedByUser,
            _that.orderEditedByUser,
            _that.kind);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _BookRecord extends BookRecord {
  const _BookRecord(
      {required this.id,
      @JsonKey(name: 'folder_path') required this.folderPath,
      required this.title,
      this.author,
      @JsonKey(name: 'cover_fs_id') this.coverFsId,
      @JsonKey(name: 'current_chapter_index') this.currentChapterIndex = 0,
      @JsonKey(name: 'current_position_ms') this.currentPositionMs = 0,
      this.finished = false,
      this.deleted = false,
      @JsonKey(name: 'added_at') this.addedAt = 0,
      @JsonKey(name: 'updated_at') this.updatedAt = 0,
      @JsonKey(name: 'last_played_at') this.lastPlayedAt,
      @JsonKey(name: 'updated_by_device') this.updatedByDevice = '',
      @JsonKey(name: 'title_edited') this.titleEditedByUser = false,
      @JsonKey(name: 'author_edited') this.authorEditedByUser = false,
      @JsonKey(name: 'order_edited') this.orderEditedByUser = false,
      @JsonKey(unknownEnumValue: SeriesKind.audiobook)
      this.kind = SeriesKind.audiobook})
      : super._();
  factory _BookRecord.fromJson(Map<String, dynamic> json) =>
      _$BookRecordFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'folder_path')
  final String folderPath;
  @override
  final String title;
  @override
  final String? author;
  @override
  @JsonKey(name: 'cover_fs_id')
  final String? coverFsId;
  @override
  @JsonKey(name: 'current_chapter_index')
  final int currentChapterIndex;
  @override
  @JsonKey(name: 'current_position_ms')
  final int currentPositionMs;
  @override
  @JsonKey()
  final bool finished;
  @override
  @JsonKey()
  final bool deleted;
  @override
  @JsonKey(name: 'added_at')
  final int addedAt;
  @override
  @JsonKey(name: 'updated_at')
  final int updatedAt;
  @override
  @JsonKey(name: 'last_played_at')
  final int? lastPlayedAt;
  @override
  @JsonKey(name: 'updated_by_device')
  final String updatedByDevice;
  @override
  @JsonKey(name: 'title_edited')
  final bool titleEditedByUser;
  @override
  @JsonKey(name: 'author_edited')
  final bool authorEditedByUser;
  @override
  @JsonKey(name: 'order_edited')
  final bool orderEditedByUser;

  /// v2 新增。旧版本 App 合并后重新上传时会把它丢掉，所以它只用于
  /// 「新拉回来的合集」；本地已有的合集以本地类型为准（见 LibrarySync）。
  @override
  @JsonKey(unknownEnumValue: SeriesKind.audiobook)
  final SeriesKind kind;

  /// Create a copy of BookRecord
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$BookRecordCopyWith<_BookRecord> get copyWith =>
      __$BookRecordCopyWithImpl<_BookRecord>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$BookRecordToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _BookRecord &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.folderPath, folderPath) ||
                other.folderPath == folderPath) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.author, author) || other.author == author) &&
            (identical(other.coverFsId, coverFsId) ||
                other.coverFsId == coverFsId) &&
            (identical(other.currentChapterIndex, currentChapterIndex) ||
                other.currentChapterIndex == currentChapterIndex) &&
            (identical(other.currentPositionMs, currentPositionMs) ||
                other.currentPositionMs == currentPositionMs) &&
            (identical(other.finished, finished) ||
                other.finished == finished) &&
            (identical(other.deleted, deleted) || other.deleted == deleted) &&
            (identical(other.addedAt, addedAt) || other.addedAt == addedAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.lastPlayedAt, lastPlayedAt) ||
                other.lastPlayedAt == lastPlayedAt) &&
            (identical(other.updatedByDevice, updatedByDevice) ||
                other.updatedByDevice == updatedByDevice) &&
            (identical(other.titleEditedByUser, titleEditedByUser) ||
                other.titleEditedByUser == titleEditedByUser) &&
            (identical(other.authorEditedByUser, authorEditedByUser) ||
                other.authorEditedByUser == authorEditedByUser) &&
            (identical(other.orderEditedByUser, orderEditedByUser) ||
                other.orderEditedByUser == orderEditedByUser) &&
            (identical(other.kind, kind) || other.kind == kind));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    return Object.hash(
        runtimeType,
        id,
        folderPath,
        title,
        author,
        coverFsId,
        currentChapterIndex,
        currentPositionMs,
        finished,
        deleted,
        addedAt,
        updatedAt,
        lastPlayedAt,
        updatedByDevice,
        titleEditedByUser,
        authorEditedByUser,
        orderEditedByUser,
        kind);
  }

  @override
  String toString() {
    return 'BookRecord(id: $id, folderPath: $folderPath, title: $title, author: $author, coverFsId: $coverFsId, currentChapterIndex: $currentChapterIndex, currentPositionMs: $currentPositionMs, finished: $finished, deleted: $deleted, addedAt: $addedAt, updatedAt: $updatedAt, lastPlayedAt: $lastPlayedAt, updatedByDevice: $updatedByDevice, titleEditedByUser: $titleEditedByUser, authorEditedByUser: $authorEditedByUser, orderEditedByUser: $orderEditedByUser, kind: $kind)';
  }
}

/// @nodoc
abstract mixin class _$BookRecordCopyWith<$Res>
    implements $BookRecordCopyWith<$Res> {
  factory _$BookRecordCopyWith(
          _BookRecord value, $Res Function(_BookRecord) _then) =
      __$BookRecordCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'folder_path') String folderPath,
      String title,
      String? author,
      @JsonKey(name: 'cover_fs_id') String? coverFsId,
      @JsonKey(name: 'current_chapter_index') int currentChapterIndex,
      @JsonKey(name: 'current_position_ms') int currentPositionMs,
      bool finished,
      bool deleted,
      @JsonKey(name: 'added_at') int addedAt,
      @JsonKey(name: 'updated_at') int updatedAt,
      @JsonKey(name: 'last_played_at') int? lastPlayedAt,
      @JsonKey(name: 'updated_by_device') String updatedByDevice,
      @JsonKey(name: 'title_edited') bool titleEditedByUser,
      @JsonKey(name: 'author_edited') bool authorEditedByUser,
      @JsonKey(name: 'order_edited') bool orderEditedByUser,
      @JsonKey(unknownEnumValue: SeriesKind.audiobook) SeriesKind kind});
}

/// @nodoc
class __$BookRecordCopyWithImpl<$Res> implements _$BookRecordCopyWith<$Res> {
  __$BookRecordCopyWithImpl(this._self, this._then);

  final _BookRecord _self;
  final $Res Function(_BookRecord) _then;

  /// Create a copy of BookRecord
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? folderPath = null,
    Object? title = null,
    Object? author = freezed,
    Object? coverFsId = freezed,
    Object? currentChapterIndex = null,
    Object? currentPositionMs = null,
    Object? finished = null,
    Object? deleted = null,
    Object? addedAt = null,
    Object? updatedAt = null,
    Object? lastPlayedAt = freezed,
    Object? updatedByDevice = null,
    Object? titleEditedByUser = null,
    Object? authorEditedByUser = null,
    Object? orderEditedByUser = null,
    Object? kind = null,
  }) {
    return _then(_BookRecord(
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
      author: freezed == author
          ? _self.author
          : author // ignore: cast_nullable_to_non_nullable
              as String?,
      coverFsId: freezed == coverFsId
          ? _self.coverFsId
          : coverFsId // ignore: cast_nullable_to_non_nullable
              as String?,
      currentChapterIndex: null == currentChapterIndex
          ? _self.currentChapterIndex
          : currentChapterIndex // ignore: cast_nullable_to_non_nullable
              as int,
      currentPositionMs: null == currentPositionMs
          ? _self.currentPositionMs
          : currentPositionMs // ignore: cast_nullable_to_non_nullable
              as int,
      finished: null == finished
          ? _self.finished
          : finished // ignore: cast_nullable_to_non_nullable
              as bool,
      deleted: null == deleted
          ? _self.deleted
          : deleted // ignore: cast_nullable_to_non_nullable
              as bool,
      addedAt: null == addedAt
          ? _self.addedAt
          : addedAt // ignore: cast_nullable_to_non_nullable
              as int,
      updatedAt: null == updatedAt
          ? _self.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as int,
      lastPlayedAt: freezed == lastPlayedAt
          ? _self.lastPlayedAt
          : lastPlayedAt // ignore: cast_nullable_to_non_nullable
              as int?,
      updatedByDevice: null == updatedByDevice
          ? _self.updatedByDevice
          : updatedByDevice // ignore: cast_nullable_to_non_nullable
              as String,
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
      kind: null == kind
          ? _self.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as SeriesKind,
    ));
  }
}

/// @nodoc
mixin _$LibrarySnapshot {
  int get version;
  List<BookRecord> get books;

  /// Create a copy of LibrarySnapshot
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $LibrarySnapshotCopyWith<LibrarySnapshot> get copyWith =>
      _$LibrarySnapshotCopyWithImpl<LibrarySnapshot>(
          this as LibrarySnapshot, _$identity);

  /// Serializes this LibrarySnapshot to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    final _this = this as LibrarySnapshot;
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is LibrarySnapshot &&
            (identical(other.version, _this.version) ||
                other.version == _this.version) &&
            const DeepCollectionEquality().equals(other.books, _this.books));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    final _this = this as LibrarySnapshot;
    return Object.hash(runtimeType, _this.version,
        const DeepCollectionEquality().hash(_this.books));
  }

  @override
  String toString() {
    final _this = this as LibrarySnapshot;
    return 'LibrarySnapshot(version: ${_this.version}, books: ${_this.books})';
  }
}

/// @nodoc
abstract mixin class $LibrarySnapshotCopyWith<$Res> {
  factory $LibrarySnapshotCopyWith(
          LibrarySnapshot value, $Res Function(LibrarySnapshot) _then) =
      _$LibrarySnapshotCopyWithImpl;
  @useResult
  $Res call({int version, List<BookRecord> books});
}

/// @nodoc
class _$LibrarySnapshotCopyWithImpl<$Res>
    implements $LibrarySnapshotCopyWith<$Res> {
  _$LibrarySnapshotCopyWithImpl(this._self, this._then);

  final LibrarySnapshot _self;
  final $Res Function(LibrarySnapshot) _then;

  /// Create a copy of LibrarySnapshot
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? version = null,
    Object? books = null,
  }) {
    return _then(LibrarySnapshot(
      version: null == version
          ? _self.version
          : version // ignore: cast_nullable_to_non_nullable
              as int,
      books: null == books
          ? _self.books
          : books // ignore: cast_nullable_to_non_nullable
              as List<BookRecord>,
    ));
  }
}

/// Adds pattern-matching-related methods to [LibrarySnapshot].
extension LibrarySnapshotPatterns on LibrarySnapshot {
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
    TResult Function(_LibrarySnapshot value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _LibrarySnapshot() when $default != null:
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
    TResult Function(_LibrarySnapshot value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _LibrarySnapshot():
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
    TResult? Function(_LibrarySnapshot value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _LibrarySnapshot() when $default != null:
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
    TResult Function(int version, List<BookRecord> books)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _LibrarySnapshot() when $default != null:
        return $default(_that.version, _that.books);
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
    TResult Function(int version, List<BookRecord> books) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _LibrarySnapshot():
        return $default(_that.version, _that.books);
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
    TResult? Function(int version, List<BookRecord> books)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _LibrarySnapshot() when $default != null:
        return $default(_that.version, _that.books);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _LibrarySnapshot implements LibrarySnapshot {
  const _LibrarySnapshot(
      {this.version = LibrarySnapshot.currentVersion,
      List<BookRecord> books = const <BookRecord>[]})
      : _books = books;
  factory _LibrarySnapshot.fromJson(Map<String, dynamic> json) =>
      _$LibrarySnapshotFromJson(json);

  @override
  @JsonKey()
  final int version;
  final List<BookRecord> _books;
  @override
  @JsonKey()
  List<BookRecord> get books {
    if (_books is EqualUnmodifiableListView) return _books;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_books);
  }

  /// Create a copy of LibrarySnapshot
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$LibrarySnapshotCopyWith<_LibrarySnapshot> get copyWith =>
      __$LibrarySnapshotCopyWithImpl<_LibrarySnapshot>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$LibrarySnapshotToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _LibrarySnapshot &&
            (identical(other.version, version) || other.version == version) &&
            const DeepCollectionEquality().equals(other.books, _books));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode {
    return Object.hash(
        runtimeType, version, const DeepCollectionEquality().hash(_books));
  }

  @override
  String toString() {
    return 'LibrarySnapshot(version: $version, books: $books)';
  }
}

/// @nodoc
abstract mixin class _$LibrarySnapshotCopyWith<$Res>
    implements $LibrarySnapshotCopyWith<$Res> {
  factory _$LibrarySnapshotCopyWith(
          _LibrarySnapshot value, $Res Function(_LibrarySnapshot) _then) =
      __$LibrarySnapshotCopyWithImpl;
  @override
  @useResult
  $Res call({int version, List<BookRecord> books});
}

/// @nodoc
class __$LibrarySnapshotCopyWithImpl<$Res>
    implements _$LibrarySnapshotCopyWith<$Res> {
  __$LibrarySnapshotCopyWithImpl(this._self, this._then);

  final _LibrarySnapshot _self;
  final $Res Function(_LibrarySnapshot) _then;

  /// Create a copy of LibrarySnapshot
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? version = null,
    Object? books = null,
  }) {
    return _then(_LibrarySnapshot(
      version: null == version
          ? _self.version
          : version // ignore: cast_nullable_to_non_nullable
              as int,
      books: null == books
          ? _self._books
          : books // ignore: cast_nullable_to_non_nullable
              as List<BookRecord>,
    ));
  }
}

// dart format on
