// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $BooksTable extends Books with TableInfo<$BooksTable, BookRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BooksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _folderPathMeta =
      const VerificationMeta('folderPath');
  @override
  late final GeneratedColumn<String> folderPath = GeneratedColumn<String>(
      'folder_path', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _authorMeta = const VerificationMeta('author');
  @override
  late final GeneratedColumn<String> author = GeneratedColumn<String>(
      'author', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _coverFsIdMeta =
      const VerificationMeta('coverFsId');
  @override
  late final GeneratedColumn<String> coverFsId = GeneratedColumn<String>(
      'cover_fs_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _coverLocalPathMeta =
      const VerificationMeta('coverLocalPath');
  @override
  late final GeneratedColumn<String> coverLocalPath = GeneratedColumn<String>(
      'cover_local_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _chapterCountMeta =
      const VerificationMeta('chapterCount');
  @override
  late final GeneratedColumn<int> chapterCount = GeneratedColumn<int>(
      'chapter_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _currentChapterIndexMeta =
      const VerificationMeta('currentChapterIndex');
  @override
  late final GeneratedColumn<int> currentChapterIndex = GeneratedColumn<int>(
      'current_chapter_index', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _currentPositionMsMeta =
      const VerificationMeta('currentPositionMs');
  @override
  late final GeneratedColumn<int> currentPositionMs = GeneratedColumn<int>(
      'current_position_ms', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _finishedMeta =
      const VerificationMeta('finished');
  @override
  late final GeneratedColumn<bool> finished = GeneratedColumn<bool>(
      'finished', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("finished" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _sourceMissingMeta =
      const VerificationMeta('sourceMissing');
  @override
  late final GeneratedColumn<bool> sourceMissing = GeneratedColumn<bool>(
      'source_missing', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("source_missing" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _titleEditedMeta =
      const VerificationMeta('titleEdited');
  @override
  late final GeneratedColumn<bool> titleEdited = GeneratedColumn<bool>(
      'title_edited', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("title_edited" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _authorEditedMeta =
      const VerificationMeta('authorEdited');
  @override
  late final GeneratedColumn<bool> authorEdited = GeneratedColumn<bool>(
      'author_edited', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("author_edited" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _orderEditedMeta =
      const VerificationMeta('orderEdited');
  @override
  late final GeneratedColumn<bool> orderEdited = GeneratedColumn<bool>(
      'order_edited', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("order_edited" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _addedAtMeta =
      const VerificationMeta('addedAt');
  @override
  late final GeneratedColumn<int> addedAt = GeneratedColumn<int>(
      'added_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _lastPlayedAtMeta =
      const VerificationMeta('lastPlayedAt');
  @override
  late final GeneratedColumn<int> lastPlayedAt = GeneratedColumn<int>(
      'last_played_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _updatedByDeviceMeta =
      const VerificationMeta('updatedByDevice');
  @override
  late final GeneratedColumn<String> updatedByDevice = GeneratedColumn<String>(
      'updated_by_device', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _deletedMeta =
      const VerificationMeta('deleted');
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
      'deleted', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("deleted" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
      'kind', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('audiobook'));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        folderPath,
        title,
        author,
        coverFsId,
        coverLocalPath,
        chapterCount,
        currentChapterIndex,
        currentPositionMs,
        finished,
        sourceMissing,
        titleEdited,
        authorEdited,
        orderEdited,
        addedAt,
        updatedAt,
        lastPlayedAt,
        updatedByDevice,
        deleted,
        kind
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'books';
  @override
  VerificationContext validateIntegrity(Insertable<BookRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('folder_path')) {
      context.handle(
          _folderPathMeta,
          folderPath.isAcceptableOrUnknown(
              data['folder_path']!, _folderPathMeta));
    } else if (isInserting) {
      context.missing(_folderPathMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('author')) {
      context.handle(_authorMeta,
          author.isAcceptableOrUnknown(data['author']!, _authorMeta));
    }
    if (data.containsKey('cover_fs_id')) {
      context.handle(
          _coverFsIdMeta,
          coverFsId.isAcceptableOrUnknown(
              data['cover_fs_id']!, _coverFsIdMeta));
    }
    if (data.containsKey('cover_local_path')) {
      context.handle(
          _coverLocalPathMeta,
          coverLocalPath.isAcceptableOrUnknown(
              data['cover_local_path']!, _coverLocalPathMeta));
    }
    if (data.containsKey('chapter_count')) {
      context.handle(
          _chapterCountMeta,
          chapterCount.isAcceptableOrUnknown(
              data['chapter_count']!, _chapterCountMeta));
    }
    if (data.containsKey('current_chapter_index')) {
      context.handle(
          _currentChapterIndexMeta,
          currentChapterIndex.isAcceptableOrUnknown(
              data['current_chapter_index']!, _currentChapterIndexMeta));
    }
    if (data.containsKey('current_position_ms')) {
      context.handle(
          _currentPositionMsMeta,
          currentPositionMs.isAcceptableOrUnknown(
              data['current_position_ms']!, _currentPositionMsMeta));
    }
    if (data.containsKey('finished')) {
      context.handle(_finishedMeta,
          finished.isAcceptableOrUnknown(data['finished']!, _finishedMeta));
    }
    if (data.containsKey('source_missing')) {
      context.handle(
          _sourceMissingMeta,
          sourceMissing.isAcceptableOrUnknown(
              data['source_missing']!, _sourceMissingMeta));
    }
    if (data.containsKey('title_edited')) {
      context.handle(
          _titleEditedMeta,
          titleEdited.isAcceptableOrUnknown(
              data['title_edited']!, _titleEditedMeta));
    }
    if (data.containsKey('author_edited')) {
      context.handle(
          _authorEditedMeta,
          authorEdited.isAcceptableOrUnknown(
              data['author_edited']!, _authorEditedMeta));
    }
    if (data.containsKey('order_edited')) {
      context.handle(
          _orderEditedMeta,
          orderEdited.isAcceptableOrUnknown(
              data['order_edited']!, _orderEditedMeta));
    }
    if (data.containsKey('added_at')) {
      context.handle(_addedAtMeta,
          addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta));
    } else if (isInserting) {
      context.missing(_addedAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('last_played_at')) {
      context.handle(
          _lastPlayedAtMeta,
          lastPlayedAt.isAcceptableOrUnknown(
              data['last_played_at']!, _lastPlayedAtMeta));
    }
    if (data.containsKey('updated_by_device')) {
      context.handle(
          _updatedByDeviceMeta,
          updatedByDevice.isAcceptableOrUnknown(
              data['updated_by_device']!, _updatedByDeviceMeta));
    }
    if (data.containsKey('deleted')) {
      context.handle(_deletedMeta,
          deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta));
    }
    if (data.containsKey('kind')) {
      context.handle(
          _kindMeta, kind.isAcceptableOrUnknown(data['kind']!, _kindMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BookRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BookRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      folderPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}folder_path'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      author: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}author']),
      coverFsId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cover_fs_id']),
      coverLocalPath: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}cover_local_path']),
      chapterCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}chapter_count'])!,
      currentChapterIndex: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}current_chapter_index'])!,
      currentPositionMs: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}current_position_ms'])!,
      finished: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}finished'])!,
      sourceMissing: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}source_missing'])!,
      titleEdited: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}title_edited'])!,
      authorEdited: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}author_edited'])!,
      orderEdited: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}order_edited'])!,
      addedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}added_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!,
      lastPlayedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}last_played_at']),
      updatedByDevice: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}updated_by_device'])!,
      deleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}deleted'])!,
      kind: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}kind'])!,
    );
  }

  @override
  $BooksTable createAlias(String alias) {
    return $BooksTable(attachedDatabase, alias);
  }
}

class BookRow extends DataClass implements Insertable<BookRow> {
  final String id;
  final String folderPath;
  final String title;
  final String? author;
  final String? coverFsId;
  final String? coverLocalPath;
  final int chapterCount;
  final int currentChapterIndex;
  final int currentPositionMs;
  final bool finished;
  final bool sourceMissing;
  final bool titleEdited;
  final bool authorEdited;
  final bool orderEdited;
  final int addedAt;
  final int updatedAt;
  final int? lastPlayedAt;
  final String updatedByDevice;
  final bool deleted;

  /// v3：合集类型（SeriesKind.name）。老数据全部是有声书。
  final String kind;
  const BookRow(
      {required this.id,
      required this.folderPath,
      required this.title,
      this.author,
      this.coverFsId,
      this.coverLocalPath,
      required this.chapterCount,
      required this.currentChapterIndex,
      required this.currentPositionMs,
      required this.finished,
      required this.sourceMissing,
      required this.titleEdited,
      required this.authorEdited,
      required this.orderEdited,
      required this.addedAt,
      required this.updatedAt,
      this.lastPlayedAt,
      required this.updatedByDevice,
      required this.deleted,
      required this.kind});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['folder_path'] = Variable<String>(folderPath);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || author != null) {
      map['author'] = Variable<String>(author);
    }
    if (!nullToAbsent || coverFsId != null) {
      map['cover_fs_id'] = Variable<String>(coverFsId);
    }
    if (!nullToAbsent || coverLocalPath != null) {
      map['cover_local_path'] = Variable<String>(coverLocalPath);
    }
    map['chapter_count'] = Variable<int>(chapterCount);
    map['current_chapter_index'] = Variable<int>(currentChapterIndex);
    map['current_position_ms'] = Variable<int>(currentPositionMs);
    map['finished'] = Variable<bool>(finished);
    map['source_missing'] = Variable<bool>(sourceMissing);
    map['title_edited'] = Variable<bool>(titleEdited);
    map['author_edited'] = Variable<bool>(authorEdited);
    map['order_edited'] = Variable<bool>(orderEdited);
    map['added_at'] = Variable<int>(addedAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || lastPlayedAt != null) {
      map['last_played_at'] = Variable<int>(lastPlayedAt);
    }
    map['updated_by_device'] = Variable<String>(updatedByDevice);
    map['deleted'] = Variable<bool>(deleted);
    map['kind'] = Variable<String>(kind);
    return map;
  }

  BooksCompanion toCompanion(bool nullToAbsent) {
    return BooksCompanion(
      id: Value(id),
      folderPath: Value(folderPath),
      title: Value(title),
      author:
          author == null && nullToAbsent ? const Value.absent() : Value(author),
      coverFsId: coverFsId == null && nullToAbsent
          ? const Value.absent()
          : Value(coverFsId),
      coverLocalPath: coverLocalPath == null && nullToAbsent
          ? const Value.absent()
          : Value(coverLocalPath),
      chapterCount: Value(chapterCount),
      currentChapterIndex: Value(currentChapterIndex),
      currentPositionMs: Value(currentPositionMs),
      finished: Value(finished),
      sourceMissing: Value(sourceMissing),
      titleEdited: Value(titleEdited),
      authorEdited: Value(authorEdited),
      orderEdited: Value(orderEdited),
      addedAt: Value(addedAt),
      updatedAt: Value(updatedAt),
      lastPlayedAt: lastPlayedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastPlayedAt),
      updatedByDevice: Value(updatedByDevice),
      deleted: Value(deleted),
      kind: Value(kind),
    );
  }

  factory BookRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BookRow(
      id: serializer.fromJson<String>(json['id']),
      folderPath: serializer.fromJson<String>(json['folderPath']),
      title: serializer.fromJson<String>(json['title']),
      author: serializer.fromJson<String?>(json['author']),
      coverFsId: serializer.fromJson<String?>(json['coverFsId']),
      coverLocalPath: serializer.fromJson<String?>(json['coverLocalPath']),
      chapterCount: serializer.fromJson<int>(json['chapterCount']),
      currentChapterIndex:
          serializer.fromJson<int>(json['currentChapterIndex']),
      currentPositionMs: serializer.fromJson<int>(json['currentPositionMs']),
      finished: serializer.fromJson<bool>(json['finished']),
      sourceMissing: serializer.fromJson<bool>(json['sourceMissing']),
      titleEdited: serializer.fromJson<bool>(json['titleEdited']),
      authorEdited: serializer.fromJson<bool>(json['authorEdited']),
      orderEdited: serializer.fromJson<bool>(json['orderEdited']),
      addedAt: serializer.fromJson<int>(json['addedAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      lastPlayedAt: serializer.fromJson<int?>(json['lastPlayedAt']),
      updatedByDevice: serializer.fromJson<String>(json['updatedByDevice']),
      deleted: serializer.fromJson<bool>(json['deleted']),
      kind: serializer.fromJson<String>(json['kind']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'folderPath': serializer.toJson<String>(folderPath),
      'title': serializer.toJson<String>(title),
      'author': serializer.toJson<String?>(author),
      'coverFsId': serializer.toJson<String?>(coverFsId),
      'coverLocalPath': serializer.toJson<String?>(coverLocalPath),
      'chapterCount': serializer.toJson<int>(chapterCount),
      'currentChapterIndex': serializer.toJson<int>(currentChapterIndex),
      'currentPositionMs': serializer.toJson<int>(currentPositionMs),
      'finished': serializer.toJson<bool>(finished),
      'sourceMissing': serializer.toJson<bool>(sourceMissing),
      'titleEdited': serializer.toJson<bool>(titleEdited),
      'authorEdited': serializer.toJson<bool>(authorEdited),
      'orderEdited': serializer.toJson<bool>(orderEdited),
      'addedAt': serializer.toJson<int>(addedAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'lastPlayedAt': serializer.toJson<int?>(lastPlayedAt),
      'updatedByDevice': serializer.toJson<String>(updatedByDevice),
      'deleted': serializer.toJson<bool>(deleted),
      'kind': serializer.toJson<String>(kind),
    };
  }

  BookRow copyWith(
          {String? id,
          String? folderPath,
          String? title,
          Value<String?> author = const Value.absent(),
          Value<String?> coverFsId = const Value.absent(),
          Value<String?> coverLocalPath = const Value.absent(),
          int? chapterCount,
          int? currentChapterIndex,
          int? currentPositionMs,
          bool? finished,
          bool? sourceMissing,
          bool? titleEdited,
          bool? authorEdited,
          bool? orderEdited,
          int? addedAt,
          int? updatedAt,
          Value<int?> lastPlayedAt = const Value.absent(),
          String? updatedByDevice,
          bool? deleted,
          String? kind}) =>
      BookRow(
        id: id ?? this.id,
        folderPath: folderPath ?? this.folderPath,
        title: title ?? this.title,
        author: author.present ? author.value : this.author,
        coverFsId: coverFsId.present ? coverFsId.value : this.coverFsId,
        coverLocalPath:
            coverLocalPath.present ? coverLocalPath.value : this.coverLocalPath,
        chapterCount: chapterCount ?? this.chapterCount,
        currentChapterIndex: currentChapterIndex ?? this.currentChapterIndex,
        currentPositionMs: currentPositionMs ?? this.currentPositionMs,
        finished: finished ?? this.finished,
        sourceMissing: sourceMissing ?? this.sourceMissing,
        titleEdited: titleEdited ?? this.titleEdited,
        authorEdited: authorEdited ?? this.authorEdited,
        orderEdited: orderEdited ?? this.orderEdited,
        addedAt: addedAt ?? this.addedAt,
        updatedAt: updatedAt ?? this.updatedAt,
        lastPlayedAt:
            lastPlayedAt.present ? lastPlayedAt.value : this.lastPlayedAt,
        updatedByDevice: updatedByDevice ?? this.updatedByDevice,
        deleted: deleted ?? this.deleted,
        kind: kind ?? this.kind,
      );
  BookRow copyWithCompanion(BooksCompanion data) {
    return BookRow(
      id: data.id.present ? data.id.value : this.id,
      folderPath:
          data.folderPath.present ? data.folderPath.value : this.folderPath,
      title: data.title.present ? data.title.value : this.title,
      author: data.author.present ? data.author.value : this.author,
      coverFsId: data.coverFsId.present ? data.coverFsId.value : this.coverFsId,
      coverLocalPath: data.coverLocalPath.present
          ? data.coverLocalPath.value
          : this.coverLocalPath,
      chapterCount: data.chapterCount.present
          ? data.chapterCount.value
          : this.chapterCount,
      currentChapterIndex: data.currentChapterIndex.present
          ? data.currentChapterIndex.value
          : this.currentChapterIndex,
      currentPositionMs: data.currentPositionMs.present
          ? data.currentPositionMs.value
          : this.currentPositionMs,
      finished: data.finished.present ? data.finished.value : this.finished,
      sourceMissing: data.sourceMissing.present
          ? data.sourceMissing.value
          : this.sourceMissing,
      titleEdited:
          data.titleEdited.present ? data.titleEdited.value : this.titleEdited,
      authorEdited: data.authorEdited.present
          ? data.authorEdited.value
          : this.authorEdited,
      orderEdited:
          data.orderEdited.present ? data.orderEdited.value : this.orderEdited,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      lastPlayedAt: data.lastPlayedAt.present
          ? data.lastPlayedAt.value
          : this.lastPlayedAt,
      updatedByDevice: data.updatedByDevice.present
          ? data.updatedByDevice.value
          : this.updatedByDevice,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      kind: data.kind.present ? data.kind.value : this.kind,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BookRow(')
          ..write('id: $id, ')
          ..write('folderPath: $folderPath, ')
          ..write('title: $title, ')
          ..write('author: $author, ')
          ..write('coverFsId: $coverFsId, ')
          ..write('coverLocalPath: $coverLocalPath, ')
          ..write('chapterCount: $chapterCount, ')
          ..write('currentChapterIndex: $currentChapterIndex, ')
          ..write('currentPositionMs: $currentPositionMs, ')
          ..write('finished: $finished, ')
          ..write('sourceMissing: $sourceMissing, ')
          ..write('titleEdited: $titleEdited, ')
          ..write('authorEdited: $authorEdited, ')
          ..write('orderEdited: $orderEdited, ')
          ..write('addedAt: $addedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('lastPlayedAt: $lastPlayedAt, ')
          ..write('updatedByDevice: $updatedByDevice, ')
          ..write('deleted: $deleted, ')
          ..write('kind: $kind')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      folderPath,
      title,
      author,
      coverFsId,
      coverLocalPath,
      chapterCount,
      currentChapterIndex,
      currentPositionMs,
      finished,
      sourceMissing,
      titleEdited,
      authorEdited,
      orderEdited,
      addedAt,
      updatedAt,
      lastPlayedAt,
      updatedByDevice,
      deleted,
      kind);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BookRow &&
          other.id == this.id &&
          other.folderPath == this.folderPath &&
          other.title == this.title &&
          other.author == this.author &&
          other.coverFsId == this.coverFsId &&
          other.coverLocalPath == this.coverLocalPath &&
          other.chapterCount == this.chapterCount &&
          other.currentChapterIndex == this.currentChapterIndex &&
          other.currentPositionMs == this.currentPositionMs &&
          other.finished == this.finished &&
          other.sourceMissing == this.sourceMissing &&
          other.titleEdited == this.titleEdited &&
          other.authorEdited == this.authorEdited &&
          other.orderEdited == this.orderEdited &&
          other.addedAt == this.addedAt &&
          other.updatedAt == this.updatedAt &&
          other.lastPlayedAt == this.lastPlayedAt &&
          other.updatedByDevice == this.updatedByDevice &&
          other.deleted == this.deleted &&
          other.kind == this.kind);
}

class BooksCompanion extends UpdateCompanion<BookRow> {
  final Value<String> id;
  final Value<String> folderPath;
  final Value<String> title;
  final Value<String?> author;
  final Value<String?> coverFsId;
  final Value<String?> coverLocalPath;
  final Value<int> chapterCount;
  final Value<int> currentChapterIndex;
  final Value<int> currentPositionMs;
  final Value<bool> finished;
  final Value<bool> sourceMissing;
  final Value<bool> titleEdited;
  final Value<bool> authorEdited;
  final Value<bool> orderEdited;
  final Value<int> addedAt;
  final Value<int> updatedAt;
  final Value<int?> lastPlayedAt;
  final Value<String> updatedByDevice;
  final Value<bool> deleted;
  final Value<String> kind;
  final Value<int> rowid;
  const BooksCompanion({
    this.id = const Value.absent(),
    this.folderPath = const Value.absent(),
    this.title = const Value.absent(),
    this.author = const Value.absent(),
    this.coverFsId = const Value.absent(),
    this.coverLocalPath = const Value.absent(),
    this.chapterCount = const Value.absent(),
    this.currentChapterIndex = const Value.absent(),
    this.currentPositionMs = const Value.absent(),
    this.finished = const Value.absent(),
    this.sourceMissing = const Value.absent(),
    this.titleEdited = const Value.absent(),
    this.authorEdited = const Value.absent(),
    this.orderEdited = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.lastPlayedAt = const Value.absent(),
    this.updatedByDevice = const Value.absent(),
    this.deleted = const Value.absent(),
    this.kind = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BooksCompanion.insert({
    required String id,
    required String folderPath,
    required String title,
    this.author = const Value.absent(),
    this.coverFsId = const Value.absent(),
    this.coverLocalPath = const Value.absent(),
    this.chapterCount = const Value.absent(),
    this.currentChapterIndex = const Value.absent(),
    this.currentPositionMs = const Value.absent(),
    this.finished = const Value.absent(),
    this.sourceMissing = const Value.absent(),
    this.titleEdited = const Value.absent(),
    this.authorEdited = const Value.absent(),
    this.orderEdited = const Value.absent(),
    required int addedAt,
    required int updatedAt,
    this.lastPlayedAt = const Value.absent(),
    this.updatedByDevice = const Value.absent(),
    this.deleted = const Value.absent(),
    this.kind = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        folderPath = Value(folderPath),
        title = Value(title),
        addedAt = Value(addedAt),
        updatedAt = Value(updatedAt);
  static Insertable<BookRow> custom({
    Expression<String>? id,
    Expression<String>? folderPath,
    Expression<String>? title,
    Expression<String>? author,
    Expression<String>? coverFsId,
    Expression<String>? coverLocalPath,
    Expression<int>? chapterCount,
    Expression<int>? currentChapterIndex,
    Expression<int>? currentPositionMs,
    Expression<bool>? finished,
    Expression<bool>? sourceMissing,
    Expression<bool>? titleEdited,
    Expression<bool>? authorEdited,
    Expression<bool>? orderEdited,
    Expression<int>? addedAt,
    Expression<int>? updatedAt,
    Expression<int>? lastPlayedAt,
    Expression<String>? updatedByDevice,
    Expression<bool>? deleted,
    Expression<String>? kind,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (folderPath != null) 'folder_path': folderPath,
      if (title != null) 'title': title,
      if (author != null) 'author': author,
      if (coverFsId != null) 'cover_fs_id': coverFsId,
      if (coverLocalPath != null) 'cover_local_path': coverLocalPath,
      if (chapterCount != null) 'chapter_count': chapterCount,
      if (currentChapterIndex != null)
        'current_chapter_index': currentChapterIndex,
      if (currentPositionMs != null) 'current_position_ms': currentPositionMs,
      if (finished != null) 'finished': finished,
      if (sourceMissing != null) 'source_missing': sourceMissing,
      if (titleEdited != null) 'title_edited': titleEdited,
      if (authorEdited != null) 'author_edited': authorEdited,
      if (orderEdited != null) 'order_edited': orderEdited,
      if (addedAt != null) 'added_at': addedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (lastPlayedAt != null) 'last_played_at': lastPlayedAt,
      if (updatedByDevice != null) 'updated_by_device': updatedByDevice,
      if (deleted != null) 'deleted': deleted,
      if (kind != null) 'kind': kind,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BooksCompanion copyWith(
      {Value<String>? id,
      Value<String>? folderPath,
      Value<String>? title,
      Value<String?>? author,
      Value<String?>? coverFsId,
      Value<String?>? coverLocalPath,
      Value<int>? chapterCount,
      Value<int>? currentChapterIndex,
      Value<int>? currentPositionMs,
      Value<bool>? finished,
      Value<bool>? sourceMissing,
      Value<bool>? titleEdited,
      Value<bool>? authorEdited,
      Value<bool>? orderEdited,
      Value<int>? addedAt,
      Value<int>? updatedAt,
      Value<int?>? lastPlayedAt,
      Value<String>? updatedByDevice,
      Value<bool>? deleted,
      Value<String>? kind,
      Value<int>? rowid}) {
    return BooksCompanion(
      id: id ?? this.id,
      folderPath: folderPath ?? this.folderPath,
      title: title ?? this.title,
      author: author ?? this.author,
      coverFsId: coverFsId ?? this.coverFsId,
      coverLocalPath: coverLocalPath ?? this.coverLocalPath,
      chapterCount: chapterCount ?? this.chapterCount,
      currentChapterIndex: currentChapterIndex ?? this.currentChapterIndex,
      currentPositionMs: currentPositionMs ?? this.currentPositionMs,
      finished: finished ?? this.finished,
      sourceMissing: sourceMissing ?? this.sourceMissing,
      titleEdited: titleEdited ?? this.titleEdited,
      authorEdited: authorEdited ?? this.authorEdited,
      orderEdited: orderEdited ?? this.orderEdited,
      addedAt: addedAt ?? this.addedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
      updatedByDevice: updatedByDevice ?? this.updatedByDevice,
      deleted: deleted ?? this.deleted,
      kind: kind ?? this.kind,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (folderPath.present) {
      map['folder_path'] = Variable<String>(folderPath.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (author.present) {
      map['author'] = Variable<String>(author.value);
    }
    if (coverFsId.present) {
      map['cover_fs_id'] = Variable<String>(coverFsId.value);
    }
    if (coverLocalPath.present) {
      map['cover_local_path'] = Variable<String>(coverLocalPath.value);
    }
    if (chapterCount.present) {
      map['chapter_count'] = Variable<int>(chapterCount.value);
    }
    if (currentChapterIndex.present) {
      map['current_chapter_index'] = Variable<int>(currentChapterIndex.value);
    }
    if (currentPositionMs.present) {
      map['current_position_ms'] = Variable<int>(currentPositionMs.value);
    }
    if (finished.present) {
      map['finished'] = Variable<bool>(finished.value);
    }
    if (sourceMissing.present) {
      map['source_missing'] = Variable<bool>(sourceMissing.value);
    }
    if (titleEdited.present) {
      map['title_edited'] = Variable<bool>(titleEdited.value);
    }
    if (authorEdited.present) {
      map['author_edited'] = Variable<bool>(authorEdited.value);
    }
    if (orderEdited.present) {
      map['order_edited'] = Variable<bool>(orderEdited.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<int>(addedAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (lastPlayedAt.present) {
      map['last_played_at'] = Variable<int>(lastPlayedAt.value);
    }
    if (updatedByDevice.present) {
      map['updated_by_device'] = Variable<String>(updatedByDevice.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BooksCompanion(')
          ..write('id: $id, ')
          ..write('folderPath: $folderPath, ')
          ..write('title: $title, ')
          ..write('author: $author, ')
          ..write('coverFsId: $coverFsId, ')
          ..write('coverLocalPath: $coverLocalPath, ')
          ..write('chapterCount: $chapterCount, ')
          ..write('currentChapterIndex: $currentChapterIndex, ')
          ..write('currentPositionMs: $currentPositionMs, ')
          ..write('finished: $finished, ')
          ..write('sourceMissing: $sourceMissing, ')
          ..write('titleEdited: $titleEdited, ')
          ..write('authorEdited: $authorEdited, ')
          ..write('orderEdited: $orderEdited, ')
          ..write('addedAt: $addedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('lastPlayedAt: $lastPlayedAt, ')
          ..write('updatedByDevice: $updatedByDevice, ')
          ..write('deleted: $deleted, ')
          ..write('kind: $kind, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ChaptersTable extends Chapters
    with TableInfo<$ChaptersTable, ChapterRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChaptersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _bookIdMeta = const VerificationMeta('bookId');
  @override
  late final GeneratedColumn<String> bookId = GeneratedColumn<String>(
      'book_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES books (id) ON DELETE CASCADE'));
  static const VerificationMeta _fsIdMeta = const VerificationMeta('fsId');
  @override
  late final GeneratedColumn<String> fsId = GeneratedColumn<String>(
      'fs_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _pathMeta = const VerificationMeta('path');
  @override
  late final GeneratedColumn<String> path = GeneratedColumn<String>(
      'path', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _fileNameMeta =
      const VerificationMeta('fileName');
  @override
  late final GeneratedColumn<String> fileName = GeneratedColumn<String>(
      'file_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sizeMeta = const VerificationMeta('size');
  @override
  late final GeneratedColumn<int> size = GeneratedColumn<int>(
      'size', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _orderIndexMeta =
      const VerificationMeta('orderIndex');
  @override
  late final GeneratedColumn<int> orderIndex = GeneratedColumn<int>(
      'order_index', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _trackNumberMeta =
      const VerificationMeta('trackNumber');
  @override
  late final GeneratedColumn<int> trackNumber = GeneratedColumn<int>(
      'track_number', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _durationMsMeta =
      const VerificationMeta('durationMs');
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
      'duration_ms', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _cacheStateMeta =
      const VerificationMeta('cacheState');
  @override
  late final GeneratedColumn<int> cacheState = GeneratedColumn<int>(
      'cache_state', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _localPathMeta =
      const VerificationMeta('localPath');
  @override
  late final GeneratedColumn<String> localPath = GeneratedColumn<String>(
      'local_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _downloadedBytesMeta =
      const VerificationMeta('downloadedBytes');
  @override
  late final GeneratedColumn<int> downloadedBytes = GeneratedColumn<int>(
      'downloaded_bytes', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _mediaKindMeta =
      const VerificationMeta('mediaKind');
  @override
  late final GeneratedColumn<String> mediaKind = GeneratedColumn<String>(
      'media_kind', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('audio'));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        bookId,
        fsId,
        path,
        title,
        fileName,
        size,
        orderIndex,
        trackNumber,
        durationMs,
        cacheState,
        localPath,
        downloadedBytes,
        mediaKind
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'chapters';
  @override
  VerificationContext validateIntegrity(Insertable<ChapterRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('book_id')) {
      context.handle(_bookIdMeta,
          bookId.isAcceptableOrUnknown(data['book_id']!, _bookIdMeta));
    } else if (isInserting) {
      context.missing(_bookIdMeta);
    }
    if (data.containsKey('fs_id')) {
      context.handle(
          _fsIdMeta, fsId.isAcceptableOrUnknown(data['fs_id']!, _fsIdMeta));
    } else if (isInserting) {
      context.missing(_fsIdMeta);
    }
    if (data.containsKey('path')) {
      context.handle(
          _pathMeta, path.isAcceptableOrUnknown(data['path']!, _pathMeta));
    } else if (isInserting) {
      context.missing(_pathMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('file_name')) {
      context.handle(_fileNameMeta,
          fileName.isAcceptableOrUnknown(data['file_name']!, _fileNameMeta));
    } else if (isInserting) {
      context.missing(_fileNameMeta);
    }
    if (data.containsKey('size')) {
      context.handle(
          _sizeMeta, size.isAcceptableOrUnknown(data['size']!, _sizeMeta));
    } else if (isInserting) {
      context.missing(_sizeMeta);
    }
    if (data.containsKey('order_index')) {
      context.handle(
          _orderIndexMeta,
          orderIndex.isAcceptableOrUnknown(
              data['order_index']!, _orderIndexMeta));
    } else if (isInserting) {
      context.missing(_orderIndexMeta);
    }
    if (data.containsKey('track_number')) {
      context.handle(
          _trackNumberMeta,
          trackNumber.isAcceptableOrUnknown(
              data['track_number']!, _trackNumberMeta));
    }
    if (data.containsKey('duration_ms')) {
      context.handle(
          _durationMsMeta,
          durationMs.isAcceptableOrUnknown(
              data['duration_ms']!, _durationMsMeta));
    }
    if (data.containsKey('cache_state')) {
      context.handle(
          _cacheStateMeta,
          cacheState.isAcceptableOrUnknown(
              data['cache_state']!, _cacheStateMeta));
    }
    if (data.containsKey('local_path')) {
      context.handle(_localPathMeta,
          localPath.isAcceptableOrUnknown(data['local_path']!, _localPathMeta));
    }
    if (data.containsKey('downloaded_bytes')) {
      context.handle(
          _downloadedBytesMeta,
          downloadedBytes.isAcceptableOrUnknown(
              data['downloaded_bytes']!, _downloadedBytesMeta));
    }
    if (data.containsKey('media_kind')) {
      context.handle(_mediaKindMeta,
          mediaKind.isAcceptableOrUnknown(data['media_kind']!, _mediaKindMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ChapterRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChapterRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      bookId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}book_id'])!,
      fsId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}fs_id'])!,
      path: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}path'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      fileName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}file_name'])!,
      size: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}size'])!,
      orderIndex: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}order_index'])!,
      trackNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}track_number']),
      durationMs: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}duration_ms']),
      cacheState: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}cache_state'])!,
      localPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}local_path']),
      downloadedBytes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}downloaded_bytes'])!,
      mediaKind: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}media_kind'])!,
    );
  }

  @override
  $ChaptersTable createAlias(String alias) {
    return $ChaptersTable(attachedDatabase, alias);
  }
}

class ChapterRow extends DataClass implements Insertable<ChapterRow> {
  final String id;
  final String bookId;
  final String fsId;
  final String path;
  final String title;
  final String fileName;
  final int size;
  final int orderIndex;
  final int? trackNumber;
  final int? durationMs;

  /// CacheState.index
  final int cacheState;
  final String? localPath;
  final int downloadedBytes;

  /// v3：媒体类型（MediaKind.name）。老数据全部是音频。
  final String mediaKind;
  const ChapterRow(
      {required this.id,
      required this.bookId,
      required this.fsId,
      required this.path,
      required this.title,
      required this.fileName,
      required this.size,
      required this.orderIndex,
      this.trackNumber,
      this.durationMs,
      required this.cacheState,
      this.localPath,
      required this.downloadedBytes,
      required this.mediaKind});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['book_id'] = Variable<String>(bookId);
    map['fs_id'] = Variable<String>(fsId);
    map['path'] = Variable<String>(path);
    map['title'] = Variable<String>(title);
    map['file_name'] = Variable<String>(fileName);
    map['size'] = Variable<int>(size);
    map['order_index'] = Variable<int>(orderIndex);
    if (!nullToAbsent || trackNumber != null) {
      map['track_number'] = Variable<int>(trackNumber);
    }
    if (!nullToAbsent || durationMs != null) {
      map['duration_ms'] = Variable<int>(durationMs);
    }
    map['cache_state'] = Variable<int>(cacheState);
    if (!nullToAbsent || localPath != null) {
      map['local_path'] = Variable<String>(localPath);
    }
    map['downloaded_bytes'] = Variable<int>(downloadedBytes);
    map['media_kind'] = Variable<String>(mediaKind);
    return map;
  }

  ChaptersCompanion toCompanion(bool nullToAbsent) {
    return ChaptersCompanion(
      id: Value(id),
      bookId: Value(bookId),
      fsId: Value(fsId),
      path: Value(path),
      title: Value(title),
      fileName: Value(fileName),
      size: Value(size),
      orderIndex: Value(orderIndex),
      trackNumber: trackNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(trackNumber),
      durationMs: durationMs == null && nullToAbsent
          ? const Value.absent()
          : Value(durationMs),
      cacheState: Value(cacheState),
      localPath: localPath == null && nullToAbsent
          ? const Value.absent()
          : Value(localPath),
      downloadedBytes: Value(downloadedBytes),
      mediaKind: Value(mediaKind),
    );
  }

  factory ChapterRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChapterRow(
      id: serializer.fromJson<String>(json['id']),
      bookId: serializer.fromJson<String>(json['bookId']),
      fsId: serializer.fromJson<String>(json['fsId']),
      path: serializer.fromJson<String>(json['path']),
      title: serializer.fromJson<String>(json['title']),
      fileName: serializer.fromJson<String>(json['fileName']),
      size: serializer.fromJson<int>(json['size']),
      orderIndex: serializer.fromJson<int>(json['orderIndex']),
      trackNumber: serializer.fromJson<int?>(json['trackNumber']),
      durationMs: serializer.fromJson<int?>(json['durationMs']),
      cacheState: serializer.fromJson<int>(json['cacheState']),
      localPath: serializer.fromJson<String?>(json['localPath']),
      downloadedBytes: serializer.fromJson<int>(json['downloadedBytes']),
      mediaKind: serializer.fromJson<String>(json['mediaKind']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'bookId': serializer.toJson<String>(bookId),
      'fsId': serializer.toJson<String>(fsId),
      'path': serializer.toJson<String>(path),
      'title': serializer.toJson<String>(title),
      'fileName': serializer.toJson<String>(fileName),
      'size': serializer.toJson<int>(size),
      'orderIndex': serializer.toJson<int>(orderIndex),
      'trackNumber': serializer.toJson<int?>(trackNumber),
      'durationMs': serializer.toJson<int?>(durationMs),
      'cacheState': serializer.toJson<int>(cacheState),
      'localPath': serializer.toJson<String?>(localPath),
      'downloadedBytes': serializer.toJson<int>(downloadedBytes),
      'mediaKind': serializer.toJson<String>(mediaKind),
    };
  }

  ChapterRow copyWith(
          {String? id,
          String? bookId,
          String? fsId,
          String? path,
          String? title,
          String? fileName,
          int? size,
          int? orderIndex,
          Value<int?> trackNumber = const Value.absent(),
          Value<int?> durationMs = const Value.absent(),
          int? cacheState,
          Value<String?> localPath = const Value.absent(),
          int? downloadedBytes,
          String? mediaKind}) =>
      ChapterRow(
        id: id ?? this.id,
        bookId: bookId ?? this.bookId,
        fsId: fsId ?? this.fsId,
        path: path ?? this.path,
        title: title ?? this.title,
        fileName: fileName ?? this.fileName,
        size: size ?? this.size,
        orderIndex: orderIndex ?? this.orderIndex,
        trackNumber: trackNumber.present ? trackNumber.value : this.trackNumber,
        durationMs: durationMs.present ? durationMs.value : this.durationMs,
        cacheState: cacheState ?? this.cacheState,
        localPath: localPath.present ? localPath.value : this.localPath,
        downloadedBytes: downloadedBytes ?? this.downloadedBytes,
        mediaKind: mediaKind ?? this.mediaKind,
      );
  ChapterRow copyWithCompanion(ChaptersCompanion data) {
    return ChapterRow(
      id: data.id.present ? data.id.value : this.id,
      bookId: data.bookId.present ? data.bookId.value : this.bookId,
      fsId: data.fsId.present ? data.fsId.value : this.fsId,
      path: data.path.present ? data.path.value : this.path,
      title: data.title.present ? data.title.value : this.title,
      fileName: data.fileName.present ? data.fileName.value : this.fileName,
      size: data.size.present ? data.size.value : this.size,
      orderIndex:
          data.orderIndex.present ? data.orderIndex.value : this.orderIndex,
      trackNumber:
          data.trackNumber.present ? data.trackNumber.value : this.trackNumber,
      durationMs:
          data.durationMs.present ? data.durationMs.value : this.durationMs,
      cacheState:
          data.cacheState.present ? data.cacheState.value : this.cacheState,
      localPath: data.localPath.present ? data.localPath.value : this.localPath,
      downloadedBytes: data.downloadedBytes.present
          ? data.downloadedBytes.value
          : this.downloadedBytes,
      mediaKind: data.mediaKind.present ? data.mediaKind.value : this.mediaKind,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChapterRow(')
          ..write('id: $id, ')
          ..write('bookId: $bookId, ')
          ..write('fsId: $fsId, ')
          ..write('path: $path, ')
          ..write('title: $title, ')
          ..write('fileName: $fileName, ')
          ..write('size: $size, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('trackNumber: $trackNumber, ')
          ..write('durationMs: $durationMs, ')
          ..write('cacheState: $cacheState, ')
          ..write('localPath: $localPath, ')
          ..write('downloadedBytes: $downloadedBytes, ')
          ..write('mediaKind: $mediaKind')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      bookId,
      fsId,
      path,
      title,
      fileName,
      size,
      orderIndex,
      trackNumber,
      durationMs,
      cacheState,
      localPath,
      downloadedBytes,
      mediaKind);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChapterRow &&
          other.id == this.id &&
          other.bookId == this.bookId &&
          other.fsId == this.fsId &&
          other.path == this.path &&
          other.title == this.title &&
          other.fileName == this.fileName &&
          other.size == this.size &&
          other.orderIndex == this.orderIndex &&
          other.trackNumber == this.trackNumber &&
          other.durationMs == this.durationMs &&
          other.cacheState == this.cacheState &&
          other.localPath == this.localPath &&
          other.downloadedBytes == this.downloadedBytes &&
          other.mediaKind == this.mediaKind);
}

class ChaptersCompanion extends UpdateCompanion<ChapterRow> {
  final Value<String> id;
  final Value<String> bookId;
  final Value<String> fsId;
  final Value<String> path;
  final Value<String> title;
  final Value<String> fileName;
  final Value<int> size;
  final Value<int> orderIndex;
  final Value<int?> trackNumber;
  final Value<int?> durationMs;
  final Value<int> cacheState;
  final Value<String?> localPath;
  final Value<int> downloadedBytes;
  final Value<String> mediaKind;
  final Value<int> rowid;
  const ChaptersCompanion({
    this.id = const Value.absent(),
    this.bookId = const Value.absent(),
    this.fsId = const Value.absent(),
    this.path = const Value.absent(),
    this.title = const Value.absent(),
    this.fileName = const Value.absent(),
    this.size = const Value.absent(),
    this.orderIndex = const Value.absent(),
    this.trackNumber = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.cacheState = const Value.absent(),
    this.localPath = const Value.absent(),
    this.downloadedBytes = const Value.absent(),
    this.mediaKind = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ChaptersCompanion.insert({
    required String id,
    required String bookId,
    required String fsId,
    required String path,
    required String title,
    required String fileName,
    required int size,
    required int orderIndex,
    this.trackNumber = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.cacheState = const Value.absent(),
    this.localPath = const Value.absent(),
    this.downloadedBytes = const Value.absent(),
    this.mediaKind = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        bookId = Value(bookId),
        fsId = Value(fsId),
        path = Value(path),
        title = Value(title),
        fileName = Value(fileName),
        size = Value(size),
        orderIndex = Value(orderIndex);
  static Insertable<ChapterRow> custom({
    Expression<String>? id,
    Expression<String>? bookId,
    Expression<String>? fsId,
    Expression<String>? path,
    Expression<String>? title,
    Expression<String>? fileName,
    Expression<int>? size,
    Expression<int>? orderIndex,
    Expression<int>? trackNumber,
    Expression<int>? durationMs,
    Expression<int>? cacheState,
    Expression<String>? localPath,
    Expression<int>? downloadedBytes,
    Expression<String>? mediaKind,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (bookId != null) 'book_id': bookId,
      if (fsId != null) 'fs_id': fsId,
      if (path != null) 'path': path,
      if (title != null) 'title': title,
      if (fileName != null) 'file_name': fileName,
      if (size != null) 'size': size,
      if (orderIndex != null) 'order_index': orderIndex,
      if (trackNumber != null) 'track_number': trackNumber,
      if (durationMs != null) 'duration_ms': durationMs,
      if (cacheState != null) 'cache_state': cacheState,
      if (localPath != null) 'local_path': localPath,
      if (downloadedBytes != null) 'downloaded_bytes': downloadedBytes,
      if (mediaKind != null) 'media_kind': mediaKind,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ChaptersCompanion copyWith(
      {Value<String>? id,
      Value<String>? bookId,
      Value<String>? fsId,
      Value<String>? path,
      Value<String>? title,
      Value<String>? fileName,
      Value<int>? size,
      Value<int>? orderIndex,
      Value<int?>? trackNumber,
      Value<int?>? durationMs,
      Value<int>? cacheState,
      Value<String?>? localPath,
      Value<int>? downloadedBytes,
      Value<String>? mediaKind,
      Value<int>? rowid}) {
    return ChaptersCompanion(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      fsId: fsId ?? this.fsId,
      path: path ?? this.path,
      title: title ?? this.title,
      fileName: fileName ?? this.fileName,
      size: size ?? this.size,
      orderIndex: orderIndex ?? this.orderIndex,
      trackNumber: trackNumber ?? this.trackNumber,
      durationMs: durationMs ?? this.durationMs,
      cacheState: cacheState ?? this.cacheState,
      localPath: localPath ?? this.localPath,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      mediaKind: mediaKind ?? this.mediaKind,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (bookId.present) {
      map['book_id'] = Variable<String>(bookId.value);
    }
    if (fsId.present) {
      map['fs_id'] = Variable<String>(fsId.value);
    }
    if (path.present) {
      map['path'] = Variable<String>(path.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (fileName.present) {
      map['file_name'] = Variable<String>(fileName.value);
    }
    if (size.present) {
      map['size'] = Variable<int>(size.value);
    }
    if (orderIndex.present) {
      map['order_index'] = Variable<int>(orderIndex.value);
    }
    if (trackNumber.present) {
      map['track_number'] = Variable<int>(trackNumber.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (cacheState.present) {
      map['cache_state'] = Variable<int>(cacheState.value);
    }
    if (localPath.present) {
      map['local_path'] = Variable<String>(localPath.value);
    }
    if (downloadedBytes.present) {
      map['downloaded_bytes'] = Variable<int>(downloadedBytes.value);
    }
    if (mediaKind.present) {
      map['media_kind'] = Variable<String>(mediaKind.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChaptersCompanion(')
          ..write('id: $id, ')
          ..write('bookId: $bookId, ')
          ..write('fsId: $fsId, ')
          ..write('path: $path, ')
          ..write('title: $title, ')
          ..write('fileName: $fileName, ')
          ..write('size: $size, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('trackNumber: $trackNumber, ')
          ..write('durationMs: $durationMs, ')
          ..write('cacheState: $cacheState, ')
          ..write('localPath: $localPath, ')
          ..write('downloadedBytes: $downloadedBytes, ')
          ..write('mediaKind: $mediaKind, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncMetaTable extends SyncMeta
    with TableInfo<$SyncMetaTable, SyncMetaData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncMetaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
      'key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
      'value', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_meta';
  @override
  VerificationContext validateIntegrity(Insertable<SyncMetaData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
          _keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SyncMetaData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncMetaData(
      key: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}value'])!,
    );
  }

  @override
  $SyncMetaTable createAlias(String alias) {
    return $SyncMetaTable(attachedDatabase, alias);
  }
}

class SyncMetaData extends DataClass implements Insertable<SyncMetaData> {
  final String key;
  final String value;
  const SyncMetaData({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SyncMetaCompanion toCompanion(bool nullToAbsent) {
    return SyncMetaCompanion(
      key: Value(key),
      value: Value(value),
    );
  }

  factory SyncMetaData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncMetaData(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  SyncMetaData copyWith({String? key, String? value}) => SyncMetaData(
        key: key ?? this.key,
        value: value ?? this.value,
      );
  SyncMetaData copyWithCompanion(SyncMetaCompanion data) {
    return SyncMetaData(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncMetaData(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncMetaData &&
          other.key == this.key &&
          other.value == this.value);
}

class SyncMetaCompanion extends UpdateCompanion<SyncMetaData> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SyncMetaCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncMetaCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  })  : key = Value(key),
        value = Value(value);
  static Insertable<SyncMetaData> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncMetaCompanion copyWith(
      {Value<String>? key, Value<String>? value, Value<int>? rowid}) {
    return SyncMetaCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncMetaCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlayHistoryTable extends PlayHistory
    with TableInfo<$PlayHistoryTable, HistoryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlayHistoryTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _bookIdMeta = const VerificationMeta('bookId');
  @override
  late final GeneratedColumn<String> bookId = GeneratedColumn<String>(
      'book_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _chapterIdMeta =
      const VerificationMeta('chapterId');
  @override
  late final GeneratedColumn<String> chapterId = GeneratedColumn<String>(
      'chapter_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _chapterIndexMeta =
      const VerificationMeta('chapterIndex');
  @override
  late final GeneratedColumn<int> chapterIndex = GeneratedColumn<int>(
      'chapter_index', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _bookTitleMeta =
      const VerificationMeta('bookTitle');
  @override
  late final GeneratedColumn<String> bookTitle = GeneratedColumn<String>(
      'book_title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _chapterTitleMeta =
      const VerificationMeta('chapterTitle');
  @override
  late final GeneratedColumn<String> chapterTitle = GeneratedColumn<String>(
      'chapter_title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _coverFsIdMeta =
      const VerificationMeta('coverFsId');
  @override
  late final GeneratedColumn<String> coverFsId = GeneratedColumn<String>(
      'cover_fs_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _startedAtMeta =
      const VerificationMeta('startedAt');
  @override
  late final GeneratedColumn<int> startedAt = GeneratedColumn<int>(
      'started_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _lastAtMeta = const VerificationMeta('lastAt');
  @override
  late final GeneratedColumn<int> lastAt = GeneratedColumn<int>(
      'last_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _lastPositionMsMeta =
      const VerificationMeta('lastPositionMs');
  @override
  late final GeneratedColumn<int> lastPositionMs = GeneratedColumn<int>(
      'last_position_ms', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _listenedMsMeta =
      const VerificationMeta('listenedMs');
  @override
  late final GeneratedColumn<int> listenedMs = GeneratedColumn<int>(
      'listened_ms', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _finishedMeta =
      const VerificationMeta('finished');
  @override
  late final GeneratedColumn<bool> finished = GeneratedColumn<bool>(
      'finished', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("finished" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        bookId,
        chapterId,
        chapterIndex,
        bookTitle,
        chapterTitle,
        coverFsId,
        startedAt,
        lastAt,
        lastPositionMs,
        listenedMs,
        finished
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'play_history';
  @override
  VerificationContext validateIntegrity(Insertable<HistoryRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('book_id')) {
      context.handle(_bookIdMeta,
          bookId.isAcceptableOrUnknown(data['book_id']!, _bookIdMeta));
    } else if (isInserting) {
      context.missing(_bookIdMeta);
    }
    if (data.containsKey('chapter_id')) {
      context.handle(_chapterIdMeta,
          chapterId.isAcceptableOrUnknown(data['chapter_id']!, _chapterIdMeta));
    } else if (isInserting) {
      context.missing(_chapterIdMeta);
    }
    if (data.containsKey('chapter_index')) {
      context.handle(
          _chapterIndexMeta,
          chapterIndex.isAcceptableOrUnknown(
              data['chapter_index']!, _chapterIndexMeta));
    } else if (isInserting) {
      context.missing(_chapterIndexMeta);
    }
    if (data.containsKey('book_title')) {
      context.handle(_bookTitleMeta,
          bookTitle.isAcceptableOrUnknown(data['book_title']!, _bookTitleMeta));
    } else if (isInserting) {
      context.missing(_bookTitleMeta);
    }
    if (data.containsKey('chapter_title')) {
      context.handle(
          _chapterTitleMeta,
          chapterTitle.isAcceptableOrUnknown(
              data['chapter_title']!, _chapterTitleMeta));
    } else if (isInserting) {
      context.missing(_chapterTitleMeta);
    }
    if (data.containsKey('cover_fs_id')) {
      context.handle(
          _coverFsIdMeta,
          coverFsId.isAcceptableOrUnknown(
              data['cover_fs_id']!, _coverFsIdMeta));
    }
    if (data.containsKey('started_at')) {
      context.handle(_startedAtMeta,
          startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta));
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('last_at')) {
      context.handle(_lastAtMeta,
          lastAt.isAcceptableOrUnknown(data['last_at']!, _lastAtMeta));
    } else if (isInserting) {
      context.missing(_lastAtMeta);
    }
    if (data.containsKey('last_position_ms')) {
      context.handle(
          _lastPositionMsMeta,
          lastPositionMs.isAcceptableOrUnknown(
              data['last_position_ms']!, _lastPositionMsMeta));
    }
    if (data.containsKey('listened_ms')) {
      context.handle(
          _listenedMsMeta,
          listenedMs.isAcceptableOrUnknown(
              data['listened_ms']!, _listenedMsMeta));
    }
    if (data.containsKey('finished')) {
      context.handle(_finishedMeta,
          finished.isAcceptableOrUnknown(data['finished']!, _finishedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  HistoryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HistoryRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      bookId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}book_id'])!,
      chapterId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}chapter_id'])!,
      chapterIndex: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}chapter_index'])!,
      bookTitle: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}book_title'])!,
      chapterTitle: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}chapter_title'])!,
      coverFsId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cover_fs_id']),
      startedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}started_at'])!,
      lastAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}last_at'])!,
      lastPositionMs: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}last_position_ms'])!,
      listenedMs: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}listened_ms'])!,
      finished: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}finished'])!,
    );
  }

  @override
  $PlayHistoryTable createAlias(String alias) {
    return $PlayHistoryTable(attachedDatabase, alias);
  }
}

class HistoryRow extends DataClass implements Insertable<HistoryRow> {
  final int id;
  final String bookId;
  final String chapterId;
  final int chapterIndex;
  final String bookTitle;
  final String chapterTitle;
  final String? coverFsId;
  final int startedAt;
  final int lastAt;
  final int lastPositionMs;
  final int listenedMs;
  final bool finished;
  const HistoryRow(
      {required this.id,
      required this.bookId,
      required this.chapterId,
      required this.chapterIndex,
      required this.bookTitle,
      required this.chapterTitle,
      this.coverFsId,
      required this.startedAt,
      required this.lastAt,
      required this.lastPositionMs,
      required this.listenedMs,
      required this.finished});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['book_id'] = Variable<String>(bookId);
    map['chapter_id'] = Variable<String>(chapterId);
    map['chapter_index'] = Variable<int>(chapterIndex);
    map['book_title'] = Variable<String>(bookTitle);
    map['chapter_title'] = Variable<String>(chapterTitle);
    if (!nullToAbsent || coverFsId != null) {
      map['cover_fs_id'] = Variable<String>(coverFsId);
    }
    map['started_at'] = Variable<int>(startedAt);
    map['last_at'] = Variable<int>(lastAt);
    map['last_position_ms'] = Variable<int>(lastPositionMs);
    map['listened_ms'] = Variable<int>(listenedMs);
    map['finished'] = Variable<bool>(finished);
    return map;
  }

  PlayHistoryCompanion toCompanion(bool nullToAbsent) {
    return PlayHistoryCompanion(
      id: Value(id),
      bookId: Value(bookId),
      chapterId: Value(chapterId),
      chapterIndex: Value(chapterIndex),
      bookTitle: Value(bookTitle),
      chapterTitle: Value(chapterTitle),
      coverFsId: coverFsId == null && nullToAbsent
          ? const Value.absent()
          : Value(coverFsId),
      startedAt: Value(startedAt),
      lastAt: Value(lastAt),
      lastPositionMs: Value(lastPositionMs),
      listenedMs: Value(listenedMs),
      finished: Value(finished),
    );
  }

  factory HistoryRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HistoryRow(
      id: serializer.fromJson<int>(json['id']),
      bookId: serializer.fromJson<String>(json['bookId']),
      chapterId: serializer.fromJson<String>(json['chapterId']),
      chapterIndex: serializer.fromJson<int>(json['chapterIndex']),
      bookTitle: serializer.fromJson<String>(json['bookTitle']),
      chapterTitle: serializer.fromJson<String>(json['chapterTitle']),
      coverFsId: serializer.fromJson<String?>(json['coverFsId']),
      startedAt: serializer.fromJson<int>(json['startedAt']),
      lastAt: serializer.fromJson<int>(json['lastAt']),
      lastPositionMs: serializer.fromJson<int>(json['lastPositionMs']),
      listenedMs: serializer.fromJson<int>(json['listenedMs']),
      finished: serializer.fromJson<bool>(json['finished']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'bookId': serializer.toJson<String>(bookId),
      'chapterId': serializer.toJson<String>(chapterId),
      'chapterIndex': serializer.toJson<int>(chapterIndex),
      'bookTitle': serializer.toJson<String>(bookTitle),
      'chapterTitle': serializer.toJson<String>(chapterTitle),
      'coverFsId': serializer.toJson<String?>(coverFsId),
      'startedAt': serializer.toJson<int>(startedAt),
      'lastAt': serializer.toJson<int>(lastAt),
      'lastPositionMs': serializer.toJson<int>(lastPositionMs),
      'listenedMs': serializer.toJson<int>(listenedMs),
      'finished': serializer.toJson<bool>(finished),
    };
  }

  HistoryRow copyWith(
          {int? id,
          String? bookId,
          String? chapterId,
          int? chapterIndex,
          String? bookTitle,
          String? chapterTitle,
          Value<String?> coverFsId = const Value.absent(),
          int? startedAt,
          int? lastAt,
          int? lastPositionMs,
          int? listenedMs,
          bool? finished}) =>
      HistoryRow(
        id: id ?? this.id,
        bookId: bookId ?? this.bookId,
        chapterId: chapterId ?? this.chapterId,
        chapterIndex: chapterIndex ?? this.chapterIndex,
        bookTitle: bookTitle ?? this.bookTitle,
        chapterTitle: chapterTitle ?? this.chapterTitle,
        coverFsId: coverFsId.present ? coverFsId.value : this.coverFsId,
        startedAt: startedAt ?? this.startedAt,
        lastAt: lastAt ?? this.lastAt,
        lastPositionMs: lastPositionMs ?? this.lastPositionMs,
        listenedMs: listenedMs ?? this.listenedMs,
        finished: finished ?? this.finished,
      );
  HistoryRow copyWithCompanion(PlayHistoryCompanion data) {
    return HistoryRow(
      id: data.id.present ? data.id.value : this.id,
      bookId: data.bookId.present ? data.bookId.value : this.bookId,
      chapterId: data.chapterId.present ? data.chapterId.value : this.chapterId,
      chapterIndex: data.chapterIndex.present
          ? data.chapterIndex.value
          : this.chapterIndex,
      bookTitle: data.bookTitle.present ? data.bookTitle.value : this.bookTitle,
      chapterTitle: data.chapterTitle.present
          ? data.chapterTitle.value
          : this.chapterTitle,
      coverFsId: data.coverFsId.present ? data.coverFsId.value : this.coverFsId,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      lastAt: data.lastAt.present ? data.lastAt.value : this.lastAt,
      lastPositionMs: data.lastPositionMs.present
          ? data.lastPositionMs.value
          : this.lastPositionMs,
      listenedMs:
          data.listenedMs.present ? data.listenedMs.value : this.listenedMs,
      finished: data.finished.present ? data.finished.value : this.finished,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HistoryRow(')
          ..write('id: $id, ')
          ..write('bookId: $bookId, ')
          ..write('chapterId: $chapterId, ')
          ..write('chapterIndex: $chapterIndex, ')
          ..write('bookTitle: $bookTitle, ')
          ..write('chapterTitle: $chapterTitle, ')
          ..write('coverFsId: $coverFsId, ')
          ..write('startedAt: $startedAt, ')
          ..write('lastAt: $lastAt, ')
          ..write('lastPositionMs: $lastPositionMs, ')
          ..write('listenedMs: $listenedMs, ')
          ..write('finished: $finished')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      bookId,
      chapterId,
      chapterIndex,
      bookTitle,
      chapterTitle,
      coverFsId,
      startedAt,
      lastAt,
      lastPositionMs,
      listenedMs,
      finished);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HistoryRow &&
          other.id == this.id &&
          other.bookId == this.bookId &&
          other.chapterId == this.chapterId &&
          other.chapterIndex == this.chapterIndex &&
          other.bookTitle == this.bookTitle &&
          other.chapterTitle == this.chapterTitle &&
          other.coverFsId == this.coverFsId &&
          other.startedAt == this.startedAt &&
          other.lastAt == this.lastAt &&
          other.lastPositionMs == this.lastPositionMs &&
          other.listenedMs == this.listenedMs &&
          other.finished == this.finished);
}

class PlayHistoryCompanion extends UpdateCompanion<HistoryRow> {
  final Value<int> id;
  final Value<String> bookId;
  final Value<String> chapterId;
  final Value<int> chapterIndex;
  final Value<String> bookTitle;
  final Value<String> chapterTitle;
  final Value<String?> coverFsId;
  final Value<int> startedAt;
  final Value<int> lastAt;
  final Value<int> lastPositionMs;
  final Value<int> listenedMs;
  final Value<bool> finished;
  const PlayHistoryCompanion({
    this.id = const Value.absent(),
    this.bookId = const Value.absent(),
    this.chapterId = const Value.absent(),
    this.chapterIndex = const Value.absent(),
    this.bookTitle = const Value.absent(),
    this.chapterTitle = const Value.absent(),
    this.coverFsId = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.lastAt = const Value.absent(),
    this.lastPositionMs = const Value.absent(),
    this.listenedMs = const Value.absent(),
    this.finished = const Value.absent(),
  });
  PlayHistoryCompanion.insert({
    this.id = const Value.absent(),
    required String bookId,
    required String chapterId,
    required int chapterIndex,
    required String bookTitle,
    required String chapterTitle,
    this.coverFsId = const Value.absent(),
    required int startedAt,
    required int lastAt,
    this.lastPositionMs = const Value.absent(),
    this.listenedMs = const Value.absent(),
    this.finished = const Value.absent(),
  })  : bookId = Value(bookId),
        chapterId = Value(chapterId),
        chapterIndex = Value(chapterIndex),
        bookTitle = Value(bookTitle),
        chapterTitle = Value(chapterTitle),
        startedAt = Value(startedAt),
        lastAt = Value(lastAt);
  static Insertable<HistoryRow> custom({
    Expression<int>? id,
    Expression<String>? bookId,
    Expression<String>? chapterId,
    Expression<int>? chapterIndex,
    Expression<String>? bookTitle,
    Expression<String>? chapterTitle,
    Expression<String>? coverFsId,
    Expression<int>? startedAt,
    Expression<int>? lastAt,
    Expression<int>? lastPositionMs,
    Expression<int>? listenedMs,
    Expression<bool>? finished,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (bookId != null) 'book_id': bookId,
      if (chapterId != null) 'chapter_id': chapterId,
      if (chapterIndex != null) 'chapter_index': chapterIndex,
      if (bookTitle != null) 'book_title': bookTitle,
      if (chapterTitle != null) 'chapter_title': chapterTitle,
      if (coverFsId != null) 'cover_fs_id': coverFsId,
      if (startedAt != null) 'started_at': startedAt,
      if (lastAt != null) 'last_at': lastAt,
      if (lastPositionMs != null) 'last_position_ms': lastPositionMs,
      if (listenedMs != null) 'listened_ms': listenedMs,
      if (finished != null) 'finished': finished,
    });
  }

  PlayHistoryCompanion copyWith(
      {Value<int>? id,
      Value<String>? bookId,
      Value<String>? chapterId,
      Value<int>? chapterIndex,
      Value<String>? bookTitle,
      Value<String>? chapterTitle,
      Value<String?>? coverFsId,
      Value<int>? startedAt,
      Value<int>? lastAt,
      Value<int>? lastPositionMs,
      Value<int>? listenedMs,
      Value<bool>? finished}) {
    return PlayHistoryCompanion(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      chapterId: chapterId ?? this.chapterId,
      chapterIndex: chapterIndex ?? this.chapterIndex,
      bookTitle: bookTitle ?? this.bookTitle,
      chapterTitle: chapterTitle ?? this.chapterTitle,
      coverFsId: coverFsId ?? this.coverFsId,
      startedAt: startedAt ?? this.startedAt,
      lastAt: lastAt ?? this.lastAt,
      lastPositionMs: lastPositionMs ?? this.lastPositionMs,
      listenedMs: listenedMs ?? this.listenedMs,
      finished: finished ?? this.finished,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (bookId.present) {
      map['book_id'] = Variable<String>(bookId.value);
    }
    if (chapterId.present) {
      map['chapter_id'] = Variable<String>(chapterId.value);
    }
    if (chapterIndex.present) {
      map['chapter_index'] = Variable<int>(chapterIndex.value);
    }
    if (bookTitle.present) {
      map['book_title'] = Variable<String>(bookTitle.value);
    }
    if (chapterTitle.present) {
      map['chapter_title'] = Variable<String>(chapterTitle.value);
    }
    if (coverFsId.present) {
      map['cover_fs_id'] = Variable<String>(coverFsId.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<int>(startedAt.value);
    }
    if (lastAt.present) {
      map['last_at'] = Variable<int>(lastAt.value);
    }
    if (lastPositionMs.present) {
      map['last_position_ms'] = Variable<int>(lastPositionMs.value);
    }
    if (listenedMs.present) {
      map['listened_ms'] = Variable<int>(listenedMs.value);
    }
    if (finished.present) {
      map['finished'] = Variable<bool>(finished.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlayHistoryCompanion(')
          ..write('id: $id, ')
          ..write('bookId: $bookId, ')
          ..write('chapterId: $chapterId, ')
          ..write('chapterIndex: $chapterIndex, ')
          ..write('bookTitle: $bookTitle, ')
          ..write('chapterTitle: $chapterTitle, ')
          ..write('coverFsId: $coverFsId, ')
          ..write('startedAt: $startedAt, ')
          ..write('lastAt: $lastAt, ')
          ..write('lastPositionMs: $lastPositionMs, ')
          ..write('listenedMs: $listenedMs, ')
          ..write('finished: $finished')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $BooksTable books = $BooksTable(this);
  late final $ChaptersTable chapters = $ChaptersTable(this);
  late final $SyncMetaTable syncMeta = $SyncMetaTable(this);
  late final $PlayHistoryTable playHistory = $PlayHistoryTable(this);
  late final Index idxChaptersBook = Index('idx_chapters_book',
      'CREATE INDEX idx_chapters_book ON chapters (book_id, order_index)');
  late final Index idxHistoryLastAt = Index('idx_history_last_at',
      'CREATE INDEX idx_history_last_at ON play_history (last_at DESC)');
  late final SeriesDao seriesDao = SeriesDao(this as AppDatabase);
  late final HistoryDao historyDao = HistoryDao(this as AppDatabase);
  late final SettingsDao settingsDao = SettingsDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        books,
        chapters,
        syncMeta,
        playHistory,
        idxChaptersBook,
        idxHistoryLastAt
      ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules(
        [
          WritePropagation(
            on: TableUpdateQuery.onTableName('books',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('chapters', kind: UpdateKind.delete),
            ],
          ),
        ],
      );
}

typedef $$BooksTableCreateCompanionBuilder = BooksCompanion Function({
  required String id,
  required String folderPath,
  required String title,
  Value<String?> author,
  Value<String?> coverFsId,
  Value<String?> coverLocalPath,
  Value<int> chapterCount,
  Value<int> currentChapterIndex,
  Value<int> currentPositionMs,
  Value<bool> finished,
  Value<bool> sourceMissing,
  Value<bool> titleEdited,
  Value<bool> authorEdited,
  Value<bool> orderEdited,
  required int addedAt,
  required int updatedAt,
  Value<int?> lastPlayedAt,
  Value<String> updatedByDevice,
  Value<bool> deleted,
  Value<String> kind,
  Value<int> rowid,
});
typedef $$BooksTableUpdateCompanionBuilder = BooksCompanion Function({
  Value<String> id,
  Value<String> folderPath,
  Value<String> title,
  Value<String?> author,
  Value<String?> coverFsId,
  Value<String?> coverLocalPath,
  Value<int> chapterCount,
  Value<int> currentChapterIndex,
  Value<int> currentPositionMs,
  Value<bool> finished,
  Value<bool> sourceMissing,
  Value<bool> titleEdited,
  Value<bool> authorEdited,
  Value<bool> orderEdited,
  Value<int> addedAt,
  Value<int> updatedAt,
  Value<int?> lastPlayedAt,
  Value<String> updatedByDevice,
  Value<bool> deleted,
  Value<String> kind,
  Value<int> rowid,
});

final class $$BooksTableReferences
    extends BaseReferences<_$AppDatabase, $BooksTable, BookRow> {
  $$BooksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ChaptersTable, List<ChapterRow>>
      _chaptersRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.chapters,
              aliasName: 'books__id__chapters__book_id');

  $$ChaptersTableProcessedTableManager get chaptersRefs {
    final manager = $$ChaptersTableTableManager($_db, $_db.chapters)
        .filter((f) => f.bookId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_chaptersRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$BooksTableFilterComposer extends Composer<_$AppDatabase, $BooksTable> {
  $$BooksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get folderPath => $composableBuilder(
      column: $table.folderPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get author => $composableBuilder(
      column: $table.author, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get coverFsId => $composableBuilder(
      column: $table.coverFsId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get coverLocalPath => $composableBuilder(
      column: $table.coverLocalPath,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get chapterCount => $composableBuilder(
      column: $table.chapterCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get currentChapterIndex => $composableBuilder(
      column: $table.currentChapterIndex,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get currentPositionMs => $composableBuilder(
      column: $table.currentPositionMs,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get finished => $composableBuilder(
      column: $table.finished, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get sourceMissing => $composableBuilder(
      column: $table.sourceMissing, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get titleEdited => $composableBuilder(
      column: $table.titleEdited, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get authorEdited => $composableBuilder(
      column: $table.authorEdited, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get orderEdited => $composableBuilder(
      column: $table.orderEdited, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get addedAt => $composableBuilder(
      column: $table.addedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get lastPlayedAt => $composableBuilder(
      column: $table.lastPlayedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get updatedByDevice => $composableBuilder(
      column: $table.updatedByDevice,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get deleted => $composableBuilder(
      column: $table.deleted, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnFilters(column));

  Expression<bool> chaptersRefs(
      Expression<bool> Function($$ChaptersTableFilterComposer f) f) {
    final $$ChaptersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.chapters,
        getReferencedColumn: (t) => t.bookId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ChaptersTableFilterComposer(
              $db: $db,
              $table: $db.chapters,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$BooksTableOrderingComposer
    extends Composer<_$AppDatabase, $BooksTable> {
  $$BooksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get folderPath => $composableBuilder(
      column: $table.folderPath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get author => $composableBuilder(
      column: $table.author, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get coverFsId => $composableBuilder(
      column: $table.coverFsId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get coverLocalPath => $composableBuilder(
      column: $table.coverLocalPath,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get chapterCount => $composableBuilder(
      column: $table.chapterCount,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get currentChapterIndex => $composableBuilder(
      column: $table.currentChapterIndex,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get currentPositionMs => $composableBuilder(
      column: $table.currentPositionMs,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get finished => $composableBuilder(
      column: $table.finished, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get sourceMissing => $composableBuilder(
      column: $table.sourceMissing,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get titleEdited => $composableBuilder(
      column: $table.titleEdited, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get authorEdited => $composableBuilder(
      column: $table.authorEdited,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get orderEdited => $composableBuilder(
      column: $table.orderEdited, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get addedAt => $composableBuilder(
      column: $table.addedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get lastPlayedAt => $composableBuilder(
      column: $table.lastPlayedAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get updatedByDevice => $composableBuilder(
      column: $table.updatedByDevice,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get deleted => $composableBuilder(
      column: $table.deleted, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnOrderings(column));
}

class $$BooksTableAnnotationComposer
    extends Composer<_$AppDatabase, $BooksTable> {
  $$BooksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get folderPath => $composableBuilder(
      column: $table.folderPath, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get author =>
      $composableBuilder(column: $table.author, builder: (column) => column);

  GeneratedColumn<String> get coverFsId =>
      $composableBuilder(column: $table.coverFsId, builder: (column) => column);

  GeneratedColumn<String> get coverLocalPath => $composableBuilder(
      column: $table.coverLocalPath, builder: (column) => column);

  GeneratedColumn<int> get chapterCount => $composableBuilder(
      column: $table.chapterCount, builder: (column) => column);

  GeneratedColumn<int> get currentChapterIndex => $composableBuilder(
      column: $table.currentChapterIndex, builder: (column) => column);

  GeneratedColumn<int> get currentPositionMs => $composableBuilder(
      column: $table.currentPositionMs, builder: (column) => column);

  GeneratedColumn<bool> get finished =>
      $composableBuilder(column: $table.finished, builder: (column) => column);

  GeneratedColumn<bool> get sourceMissing => $composableBuilder(
      column: $table.sourceMissing, builder: (column) => column);

  GeneratedColumn<bool> get titleEdited => $composableBuilder(
      column: $table.titleEdited, builder: (column) => column);

  GeneratedColumn<bool> get authorEdited => $composableBuilder(
      column: $table.authorEdited, builder: (column) => column);

  GeneratedColumn<bool> get orderEdited => $composableBuilder(
      column: $table.orderEdited, builder: (column) => column);

  GeneratedColumn<int> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get lastPlayedAt => $composableBuilder(
      column: $table.lastPlayedAt, builder: (column) => column);

  GeneratedColumn<String> get updatedByDevice => $composableBuilder(
      column: $table.updatedByDevice, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  Expression<T> chaptersRefs<T extends Object>(
      Expression<T> Function($$ChaptersTableAnnotationComposer a) f) {
    final $$ChaptersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.chapters,
        getReferencedColumn: (t) => t.bookId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ChaptersTableAnnotationComposer(
              $db: $db,
              $table: $db.chapters,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$BooksTableTableManager extends RootTableManager<
    _$AppDatabase,
    $BooksTable,
    BookRow,
    $$BooksTableFilterComposer,
    $$BooksTableOrderingComposer,
    $$BooksTableAnnotationComposer,
    $$BooksTableCreateCompanionBuilder,
    $$BooksTableUpdateCompanionBuilder,
    (BookRow, $$BooksTableReferences),
    BookRow,
    PrefetchHooks Function({bool chaptersRefs})> {
  $$BooksTableTableManager(_$AppDatabase db, $BooksTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BooksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BooksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BooksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> folderPath = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String?> author = const Value.absent(),
            Value<String?> coverFsId = const Value.absent(),
            Value<String?> coverLocalPath = const Value.absent(),
            Value<int> chapterCount = const Value.absent(),
            Value<int> currentChapterIndex = const Value.absent(),
            Value<int> currentPositionMs = const Value.absent(),
            Value<bool> finished = const Value.absent(),
            Value<bool> sourceMissing = const Value.absent(),
            Value<bool> titleEdited = const Value.absent(),
            Value<bool> authorEdited = const Value.absent(),
            Value<bool> orderEdited = const Value.absent(),
            Value<int> addedAt = const Value.absent(),
            Value<int> updatedAt = const Value.absent(),
            Value<int?> lastPlayedAt = const Value.absent(),
            Value<String> updatedByDevice = const Value.absent(),
            Value<bool> deleted = const Value.absent(),
            Value<String> kind = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              BooksCompanion(
            id: id,
            folderPath: folderPath,
            title: title,
            author: author,
            coverFsId: coverFsId,
            coverLocalPath: coverLocalPath,
            chapterCount: chapterCount,
            currentChapterIndex: currentChapterIndex,
            currentPositionMs: currentPositionMs,
            finished: finished,
            sourceMissing: sourceMissing,
            titleEdited: titleEdited,
            authorEdited: authorEdited,
            orderEdited: orderEdited,
            addedAt: addedAt,
            updatedAt: updatedAt,
            lastPlayedAt: lastPlayedAt,
            updatedByDevice: updatedByDevice,
            deleted: deleted,
            kind: kind,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String folderPath,
            required String title,
            Value<String?> author = const Value.absent(),
            Value<String?> coverFsId = const Value.absent(),
            Value<String?> coverLocalPath = const Value.absent(),
            Value<int> chapterCount = const Value.absent(),
            Value<int> currentChapterIndex = const Value.absent(),
            Value<int> currentPositionMs = const Value.absent(),
            Value<bool> finished = const Value.absent(),
            Value<bool> sourceMissing = const Value.absent(),
            Value<bool> titleEdited = const Value.absent(),
            Value<bool> authorEdited = const Value.absent(),
            Value<bool> orderEdited = const Value.absent(),
            required int addedAt,
            required int updatedAt,
            Value<int?> lastPlayedAt = const Value.absent(),
            Value<String> updatedByDevice = const Value.absent(),
            Value<bool> deleted = const Value.absent(),
            Value<String> kind = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              BooksCompanion.insert(
            id: id,
            folderPath: folderPath,
            title: title,
            author: author,
            coverFsId: coverFsId,
            coverLocalPath: coverLocalPath,
            chapterCount: chapterCount,
            currentChapterIndex: currentChapterIndex,
            currentPositionMs: currentPositionMs,
            finished: finished,
            sourceMissing: sourceMissing,
            titleEdited: titleEdited,
            authorEdited: authorEdited,
            orderEdited: orderEdited,
            addedAt: addedAt,
            updatedAt: updatedAt,
            lastPlayedAt: lastPlayedAt,
            updatedByDevice: updatedByDevice,
            deleted: deleted,
            kind: kind,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$BooksTable, BookRow>(table),
                    $$BooksTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({chaptersRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (chaptersRefs) db.chapters],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (chaptersRefs)
                    await $_getPrefetchedData<BookRow, $BooksTable, ChapterRow>(
                        currentTable: table,
                        referencedTable:
                            $$BooksTableReferences._chaptersRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$BooksTableReferences(db, table, p0).chaptersRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.bookId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$BooksTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $BooksTable,
    BookRow,
    $$BooksTableFilterComposer,
    $$BooksTableOrderingComposer,
    $$BooksTableAnnotationComposer,
    $$BooksTableCreateCompanionBuilder,
    $$BooksTableUpdateCompanionBuilder,
    (BookRow, $$BooksTableReferences),
    BookRow,
    PrefetchHooks Function({bool chaptersRefs})>;
typedef $$ChaptersTableCreateCompanionBuilder = ChaptersCompanion Function({
  required String id,
  required String bookId,
  required String fsId,
  required String path,
  required String title,
  required String fileName,
  required int size,
  required int orderIndex,
  Value<int?> trackNumber,
  Value<int?> durationMs,
  Value<int> cacheState,
  Value<String?> localPath,
  Value<int> downloadedBytes,
  Value<String> mediaKind,
  Value<int> rowid,
});
typedef $$ChaptersTableUpdateCompanionBuilder = ChaptersCompanion Function({
  Value<String> id,
  Value<String> bookId,
  Value<String> fsId,
  Value<String> path,
  Value<String> title,
  Value<String> fileName,
  Value<int> size,
  Value<int> orderIndex,
  Value<int?> trackNumber,
  Value<int?> durationMs,
  Value<int> cacheState,
  Value<String?> localPath,
  Value<int> downloadedBytes,
  Value<String> mediaKind,
  Value<int> rowid,
});

final class $$ChaptersTableReferences
    extends BaseReferences<_$AppDatabase, $ChaptersTable, ChapterRow> {
  $$ChaptersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $BooksTable _bookIdTable(_$AppDatabase db) =>
      db.books.createAlias('chapters__book_id__books__id');

  $$BooksTableProcessedTableManager get bookId {
    final $_column = $_itemColumn<String>('book_id')!;

    final manager = $$BooksTableTableManager($_db, $_db.books)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_bookIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$ChaptersTableFilterComposer
    extends Composer<_$AppDatabase, $ChaptersTable> {
  $$ChaptersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get fsId => $composableBuilder(
      column: $table.fsId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get path => $composableBuilder(
      column: $table.path, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get fileName => $composableBuilder(
      column: $table.fileName, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get size => $composableBuilder(
      column: $table.size, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get orderIndex => $composableBuilder(
      column: $table.orderIndex, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get trackNumber => $composableBuilder(
      column: $table.trackNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get durationMs => $composableBuilder(
      column: $table.durationMs, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get cacheState => $composableBuilder(
      column: $table.cacheState, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get localPath => $composableBuilder(
      column: $table.localPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get downloadedBytes => $composableBuilder(
      column: $table.downloadedBytes,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get mediaKind => $composableBuilder(
      column: $table.mediaKind, builder: (column) => ColumnFilters(column));

  $$BooksTableFilterComposer get bookId {
    final $$BooksTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.bookId,
        referencedTable: $db.books,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BooksTableFilterComposer(
              $db: $db,
              $table: $db.books,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ChaptersTableOrderingComposer
    extends Composer<_$AppDatabase, $ChaptersTable> {
  $$ChaptersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fsId => $composableBuilder(
      column: $table.fsId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get path => $composableBuilder(
      column: $table.path, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fileName => $composableBuilder(
      column: $table.fileName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get size => $composableBuilder(
      column: $table.size, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get orderIndex => $composableBuilder(
      column: $table.orderIndex, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get trackNumber => $composableBuilder(
      column: $table.trackNumber, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get durationMs => $composableBuilder(
      column: $table.durationMs, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get cacheState => $composableBuilder(
      column: $table.cacheState, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get localPath => $composableBuilder(
      column: $table.localPath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get downloadedBytes => $composableBuilder(
      column: $table.downloadedBytes,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mediaKind => $composableBuilder(
      column: $table.mediaKind, builder: (column) => ColumnOrderings(column));

  $$BooksTableOrderingComposer get bookId {
    final $$BooksTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.bookId,
        referencedTable: $db.books,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BooksTableOrderingComposer(
              $db: $db,
              $table: $db.books,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ChaptersTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChaptersTable> {
  $$ChaptersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get fsId =>
      $composableBuilder(column: $table.fsId, builder: (column) => column);

  GeneratedColumn<String> get path =>
      $composableBuilder(column: $table.path, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get fileName =>
      $composableBuilder(column: $table.fileName, builder: (column) => column);

  GeneratedColumn<int> get size =>
      $composableBuilder(column: $table.size, builder: (column) => column);

  GeneratedColumn<int> get orderIndex => $composableBuilder(
      column: $table.orderIndex, builder: (column) => column);

  GeneratedColumn<int> get trackNumber => $composableBuilder(
      column: $table.trackNumber, builder: (column) => column);

  GeneratedColumn<int> get durationMs => $composableBuilder(
      column: $table.durationMs, builder: (column) => column);

  GeneratedColumn<int> get cacheState => $composableBuilder(
      column: $table.cacheState, builder: (column) => column);

  GeneratedColumn<String> get localPath =>
      $composableBuilder(column: $table.localPath, builder: (column) => column);

  GeneratedColumn<int> get downloadedBytes => $composableBuilder(
      column: $table.downloadedBytes, builder: (column) => column);

  GeneratedColumn<String> get mediaKind =>
      $composableBuilder(column: $table.mediaKind, builder: (column) => column);

  $$BooksTableAnnotationComposer get bookId {
    final $$BooksTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.bookId,
        referencedTable: $db.books,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BooksTableAnnotationComposer(
              $db: $db,
              $table: $db.books,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ChaptersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ChaptersTable,
    ChapterRow,
    $$ChaptersTableFilterComposer,
    $$ChaptersTableOrderingComposer,
    $$ChaptersTableAnnotationComposer,
    $$ChaptersTableCreateCompanionBuilder,
    $$ChaptersTableUpdateCompanionBuilder,
    (ChapterRow, $$ChaptersTableReferences),
    ChapterRow,
    PrefetchHooks Function({bool bookId})> {
  $$ChaptersTableTableManager(_$AppDatabase db, $ChaptersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChaptersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChaptersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChaptersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> bookId = const Value.absent(),
            Value<String> fsId = const Value.absent(),
            Value<String> path = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> fileName = const Value.absent(),
            Value<int> size = const Value.absent(),
            Value<int> orderIndex = const Value.absent(),
            Value<int?> trackNumber = const Value.absent(),
            Value<int?> durationMs = const Value.absent(),
            Value<int> cacheState = const Value.absent(),
            Value<String?> localPath = const Value.absent(),
            Value<int> downloadedBytes = const Value.absent(),
            Value<String> mediaKind = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ChaptersCompanion(
            id: id,
            bookId: bookId,
            fsId: fsId,
            path: path,
            title: title,
            fileName: fileName,
            size: size,
            orderIndex: orderIndex,
            trackNumber: trackNumber,
            durationMs: durationMs,
            cacheState: cacheState,
            localPath: localPath,
            downloadedBytes: downloadedBytes,
            mediaKind: mediaKind,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String bookId,
            required String fsId,
            required String path,
            required String title,
            required String fileName,
            required int size,
            required int orderIndex,
            Value<int?> trackNumber = const Value.absent(),
            Value<int?> durationMs = const Value.absent(),
            Value<int> cacheState = const Value.absent(),
            Value<String?> localPath = const Value.absent(),
            Value<int> downloadedBytes = const Value.absent(),
            Value<String> mediaKind = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ChaptersCompanion.insert(
            id: id,
            bookId: bookId,
            fsId: fsId,
            path: path,
            title: title,
            fileName: fileName,
            size: size,
            orderIndex: orderIndex,
            trackNumber: trackNumber,
            durationMs: durationMs,
            cacheState: cacheState,
            localPath: localPath,
            downloadedBytes: downloadedBytes,
            mediaKind: mediaKind,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$ChaptersTable, ChapterRow>(table),
                    $$ChaptersTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({bookId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (bookId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.bookId,
                    referencedTable: $$ChaptersTableReferences._bookIdTable(db),
                    referencedColumn:
                        $$ChaptersTableReferences._bookIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$ChaptersTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ChaptersTable,
    ChapterRow,
    $$ChaptersTableFilterComposer,
    $$ChaptersTableOrderingComposer,
    $$ChaptersTableAnnotationComposer,
    $$ChaptersTableCreateCompanionBuilder,
    $$ChaptersTableUpdateCompanionBuilder,
    (ChapterRow, $$ChaptersTableReferences),
    ChapterRow,
    PrefetchHooks Function({bool bookId})>;
typedef $$SyncMetaTableCreateCompanionBuilder = SyncMetaCompanion Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$SyncMetaTableUpdateCompanionBuilder = SyncMetaCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$SyncMetaTableFilterComposer
    extends Composer<_$AppDatabase, $SyncMetaTable> {
  $$SyncMetaTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnFilters(column));
}

class $$SyncMetaTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncMetaTable> {
  $$SyncMetaTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnOrderings(column));
}

class $$SyncMetaTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncMetaTable> {
  $$SyncMetaTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SyncMetaTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SyncMetaTable,
    SyncMetaData,
    $$SyncMetaTableFilterComposer,
    $$SyncMetaTableOrderingComposer,
    $$SyncMetaTableAnnotationComposer,
    $$SyncMetaTableCreateCompanionBuilder,
    $$SyncMetaTableUpdateCompanionBuilder,
    (SyncMetaData, BaseReferences<_$AppDatabase, $SyncMetaTable, SyncMetaData>),
    SyncMetaData,
    PrefetchHooks Function()> {
  $$SyncMetaTableTableManager(_$AppDatabase db, $SyncMetaTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncMetaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncMetaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncMetaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SyncMetaCompanion(
            key: key,
            value: value,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) =>
              SyncMetaCompanion.insert(
            key: key,
            value: value,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$SyncMetaTable, SyncMetaData>(table),
                    BaseReferences<_$AppDatabase, $SyncMetaTable, SyncMetaData>(
                        db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SyncMetaTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SyncMetaTable,
    SyncMetaData,
    $$SyncMetaTableFilterComposer,
    $$SyncMetaTableOrderingComposer,
    $$SyncMetaTableAnnotationComposer,
    $$SyncMetaTableCreateCompanionBuilder,
    $$SyncMetaTableUpdateCompanionBuilder,
    (SyncMetaData, BaseReferences<_$AppDatabase, $SyncMetaTable, SyncMetaData>),
    SyncMetaData,
    PrefetchHooks Function()>;
typedef $$PlayHistoryTableCreateCompanionBuilder = PlayHistoryCompanion
    Function({
  Value<int> id,
  required String bookId,
  required String chapterId,
  required int chapterIndex,
  required String bookTitle,
  required String chapterTitle,
  Value<String?> coverFsId,
  required int startedAt,
  required int lastAt,
  Value<int> lastPositionMs,
  Value<int> listenedMs,
  Value<bool> finished,
});
typedef $$PlayHistoryTableUpdateCompanionBuilder = PlayHistoryCompanion
    Function({
  Value<int> id,
  Value<String> bookId,
  Value<String> chapterId,
  Value<int> chapterIndex,
  Value<String> bookTitle,
  Value<String> chapterTitle,
  Value<String?> coverFsId,
  Value<int> startedAt,
  Value<int> lastAt,
  Value<int> lastPositionMs,
  Value<int> listenedMs,
  Value<bool> finished,
});

class $$PlayHistoryTableFilterComposer
    extends Composer<_$AppDatabase, $PlayHistoryTable> {
  $$PlayHistoryTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get bookId => $composableBuilder(
      column: $table.bookId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get chapterId => $composableBuilder(
      column: $table.chapterId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get chapterIndex => $composableBuilder(
      column: $table.chapterIndex, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get bookTitle => $composableBuilder(
      column: $table.bookTitle, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get chapterTitle => $composableBuilder(
      column: $table.chapterTitle, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get coverFsId => $composableBuilder(
      column: $table.coverFsId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get startedAt => $composableBuilder(
      column: $table.startedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get lastAt => $composableBuilder(
      column: $table.lastAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get lastPositionMs => $composableBuilder(
      column: $table.lastPositionMs,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get listenedMs => $composableBuilder(
      column: $table.listenedMs, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get finished => $composableBuilder(
      column: $table.finished, builder: (column) => ColumnFilters(column));
}

class $$PlayHistoryTableOrderingComposer
    extends Composer<_$AppDatabase, $PlayHistoryTable> {
  $$PlayHistoryTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get bookId => $composableBuilder(
      column: $table.bookId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get chapterId => $composableBuilder(
      column: $table.chapterId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get chapterIndex => $composableBuilder(
      column: $table.chapterIndex,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get bookTitle => $composableBuilder(
      column: $table.bookTitle, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get chapterTitle => $composableBuilder(
      column: $table.chapterTitle,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get coverFsId => $composableBuilder(
      column: $table.coverFsId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get startedAt => $composableBuilder(
      column: $table.startedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get lastAt => $composableBuilder(
      column: $table.lastAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get lastPositionMs => $composableBuilder(
      column: $table.lastPositionMs,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get listenedMs => $composableBuilder(
      column: $table.listenedMs, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get finished => $composableBuilder(
      column: $table.finished, builder: (column) => ColumnOrderings(column));
}

class $$PlayHistoryTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlayHistoryTable> {
  $$PlayHistoryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get bookId =>
      $composableBuilder(column: $table.bookId, builder: (column) => column);

  GeneratedColumn<String> get chapterId =>
      $composableBuilder(column: $table.chapterId, builder: (column) => column);

  GeneratedColumn<int> get chapterIndex => $composableBuilder(
      column: $table.chapterIndex, builder: (column) => column);

  GeneratedColumn<String> get bookTitle =>
      $composableBuilder(column: $table.bookTitle, builder: (column) => column);

  GeneratedColumn<String> get chapterTitle => $composableBuilder(
      column: $table.chapterTitle, builder: (column) => column);

  GeneratedColumn<String> get coverFsId =>
      $composableBuilder(column: $table.coverFsId, builder: (column) => column);

  GeneratedColumn<int> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<int> get lastAt =>
      $composableBuilder(column: $table.lastAt, builder: (column) => column);

  GeneratedColumn<int> get lastPositionMs => $composableBuilder(
      column: $table.lastPositionMs, builder: (column) => column);

  GeneratedColumn<int> get listenedMs => $composableBuilder(
      column: $table.listenedMs, builder: (column) => column);

  GeneratedColumn<bool> get finished =>
      $composableBuilder(column: $table.finished, builder: (column) => column);
}

class $$PlayHistoryTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PlayHistoryTable,
    HistoryRow,
    $$PlayHistoryTableFilterComposer,
    $$PlayHistoryTableOrderingComposer,
    $$PlayHistoryTableAnnotationComposer,
    $$PlayHistoryTableCreateCompanionBuilder,
    $$PlayHistoryTableUpdateCompanionBuilder,
    (HistoryRow, BaseReferences<_$AppDatabase, $PlayHistoryTable, HistoryRow>),
    HistoryRow,
    PrefetchHooks Function()> {
  $$PlayHistoryTableTableManager(_$AppDatabase db, $PlayHistoryTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlayHistoryTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlayHistoryTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlayHistoryTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> bookId = const Value.absent(),
            Value<String> chapterId = const Value.absent(),
            Value<int> chapterIndex = const Value.absent(),
            Value<String> bookTitle = const Value.absent(),
            Value<String> chapterTitle = const Value.absent(),
            Value<String?> coverFsId = const Value.absent(),
            Value<int> startedAt = const Value.absent(),
            Value<int> lastAt = const Value.absent(),
            Value<int> lastPositionMs = const Value.absent(),
            Value<int> listenedMs = const Value.absent(),
            Value<bool> finished = const Value.absent(),
          }) =>
              PlayHistoryCompanion(
            id: id,
            bookId: bookId,
            chapterId: chapterId,
            chapterIndex: chapterIndex,
            bookTitle: bookTitle,
            chapterTitle: chapterTitle,
            coverFsId: coverFsId,
            startedAt: startedAt,
            lastAt: lastAt,
            lastPositionMs: lastPositionMs,
            listenedMs: listenedMs,
            finished: finished,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String bookId,
            required String chapterId,
            required int chapterIndex,
            required String bookTitle,
            required String chapterTitle,
            Value<String?> coverFsId = const Value.absent(),
            required int startedAt,
            required int lastAt,
            Value<int> lastPositionMs = const Value.absent(),
            Value<int> listenedMs = const Value.absent(),
            Value<bool> finished = const Value.absent(),
          }) =>
              PlayHistoryCompanion.insert(
            id: id,
            bookId: bookId,
            chapterId: chapterId,
            chapterIndex: chapterIndex,
            bookTitle: bookTitle,
            chapterTitle: chapterTitle,
            coverFsId: coverFsId,
            startedAt: startedAt,
            lastAt: lastAt,
            lastPositionMs: lastPositionMs,
            listenedMs: listenedMs,
            finished: finished,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$PlayHistoryTable, HistoryRow>(table),
                    BaseReferences<_$AppDatabase, $PlayHistoryTable,
                        HistoryRow>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PlayHistoryTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PlayHistoryTable,
    HistoryRow,
    $$PlayHistoryTableFilterComposer,
    $$PlayHistoryTableOrderingComposer,
    $$PlayHistoryTableAnnotationComposer,
    $$PlayHistoryTableCreateCompanionBuilder,
    $$PlayHistoryTableUpdateCompanionBuilder,
    (HistoryRow, BaseReferences<_$AppDatabase, $PlayHistoryTable, HistoryRow>),
    HistoryRow,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$BooksTableTableManager get books =>
      $$BooksTableTableManager(_db, _db.books);
  $$ChaptersTableTableManager get chapters =>
      $$ChaptersTableTableManager(_db, _db.chapters);
  $$SyncMetaTableTableManager get syncMeta =>
      $$SyncMetaTableTableManager(_db, _db.syncMeta);
  $$PlayHistoryTableTableManager get playHistory =>
      $$PlayHistoryTableTableManager(_db, _db.playHistory);
}
