/// 本机媒体的标识约定（add-local-media）。
///
/// 本机书与网盘书存在同一张表里，靠路径 / fsId 上的 `local:` 前缀区分——
/// 不加库表列，就不用迁移老用户的数据。
library;

import 'package:yun_audiobook/domain/entities.dart';

const localPrefix = 'local:';

bool isLocalPath(String pathOrFsId) => pathOrFsId.startsWith(localPrefix);

/// `local:a:123` / `local:v:123`
String localFsId(MediaKind kind, String mediaStoreId) =>
    '$localPrefix${kind == MediaKind.video ? 'v' : 'a'}:$mediaStoreId';

({MediaKind kind, String id})? parseLocalFsId(String fsId) {
  final m = RegExp(r'^local:([av]):(\d+)$').firstMatch(fsId);
  if (m == null) return null;
  return (
    kind: m.group(1) == 'v' ? MediaKind.video : MediaKind.audio,
    id: m.group(2)!
  );
}

/// MediaStore 的 content:// 地址。just_audio 与 video_player 都能直接播。
String localContentUri(MediaKind kind, String id) =>
    'content://media/external/${kind == MediaKind.video ? 'video' : 'audio'}/media/$id';

/// 界面上显示的路径：去掉前缀。
String displayPath(String path) =>
    isLocalPath(path) ? path.substring(localPrefix.length) : path;

extension SeriesOriginX on Series {
  /// 来自本机（不进同步、不提供下载）。
  bool get isLocal => isLocalPath(folderPath);
}

extension EpisodeOriginX on Episode {
  bool get isLocal => isLocalPath(fsId);
}
