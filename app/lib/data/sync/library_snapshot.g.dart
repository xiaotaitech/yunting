// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'library_snapshot.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BookRecord _$BookRecordFromJson(Map<String, dynamic> json) => _BookRecord(
      id: json['id'] as String,
      folderPath: json['folder_path'] as String,
      title: json['title'] as String,
      author: json['author'] as String?,
      coverFsId: json['cover_fs_id'] as String?,
      currentChapterIndex:
          (json['current_chapter_index'] as num?)?.toInt() ?? 0,
      currentPositionMs: (json['current_position_ms'] as num?)?.toInt() ?? 0,
      finished: json['finished'] as bool? ?? false,
      deleted: json['deleted'] as bool? ?? false,
      addedAt: (json['added_at'] as num?)?.toInt() ?? 0,
      updatedAt: (json['updated_at'] as num?)?.toInt() ?? 0,
      lastPlayedAt: (json['last_played_at'] as num?)?.toInt(),
      updatedByDevice: json['updated_by_device'] as String? ?? '',
      titleEditedByUser: json['title_edited'] as bool? ?? false,
      authorEditedByUser: json['author_edited'] as bool? ?? false,
      orderEditedByUser: json['order_edited'] as bool? ?? false,
      kind: $enumDecodeNullable(_$SeriesKindEnumMap, json['kind'],
              unknownValue: SeriesKind.audiobook) ??
          SeriesKind.audiobook,
    );

Map<String, dynamic> _$BookRecordToJson(_BookRecord instance) =>
    <String, dynamic>{
      'id': instance.id,
      'folder_path': instance.folderPath,
      'title': instance.title,
      'author': instance.author,
      'cover_fs_id': instance.coverFsId,
      'current_chapter_index': instance.currentChapterIndex,
      'current_position_ms': instance.currentPositionMs,
      'finished': instance.finished,
      'deleted': instance.deleted,
      'added_at': instance.addedAt,
      'updated_at': instance.updatedAt,
      'last_played_at': instance.lastPlayedAt,
      'updated_by_device': instance.updatedByDevice,
      'title_edited': instance.titleEditedByUser,
      'author_edited': instance.authorEditedByUser,
      'order_edited': instance.orderEditedByUser,
      'kind': _$SeriesKindEnumMap[instance.kind]!,
    };

const _$SeriesKindEnumMap = {
  SeriesKind.audiobook: 'audiobook',
  SeriesKind.course: 'course',
};

_LibrarySnapshot _$LibrarySnapshotFromJson(Map<String, dynamic> json) =>
    _LibrarySnapshot(
      version:
          (json['version'] as num?)?.toInt() ?? LibrarySnapshot.currentVersion,
      books: (json['books'] as List<dynamic>?)
              ?.map((e) => BookRecord.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <BookRecord>[],
    );

Map<String, dynamic> _$LibrarySnapshotToJson(_LibrarySnapshot instance) =>
    <String, dynamic>{
      'version': instance.version,
      'books': instance.books.map((e) => e.toJson()).toList(),
    };
