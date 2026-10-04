import 'package:flutter/services.dart';
import 'package:yun_audiobook/core/errors.dart';
import 'package:yun_audiobook/data/drive/cloud_drive_source.dart';
import 'package:yun_audiobook/domain/entities.dart';
import 'package:yun_audiobook/domain/local_media.dart';

/// 读 MediaStore 的一行：路径是「/相对目录/文件名」。
typedef LocalMediaRow = ({
  String id,
  String name,
  String path,
  int size,
  int mtime,
});

/// 本机媒体数据源（add-local-media）：手机里的音频 / 视频，经 MediaStore 读取。
///
/// 路径与 fsId 都带 `local:` 前缀，好和网盘的混在同一张表里而互不冲突：
///   - 路径 `local:/Music/三体/1.mp3`
///   - fsId `local:a:123`（a 音频 / v 视频 + MediaStore id），播放地址据此直接拼出，
///     重启后不必重新查询。
///
/// 不复制文件：播放直接用 content:// 地址，所以也不提供离线下载。
class LocalMediaSource implements CloudDriveSource {
  LocalMediaSource({
    Future<List<LocalMediaRow>> Function(MediaKind kind)? query,
    Future<bool> Function(MediaKind kind)? hasPermission,
    Future<bool> Function(MediaKind kind)? requestPermission,
  })  : _query = query ?? _channelQuery,
        _hasPermission = hasPermission ?? _channelHas,
        _requestPermission = requestPermission ?? _channelRequest;

  static const _channel = MethodChannel('yun/media');

  final Future<List<LocalMediaRow>> Function(MediaKind) _query;
  final Future<bool> Function(MediaKind) _hasPermission;
  final Future<bool> Function(MediaKind) _requestPermission;

  Future<bool> hasPermission(MediaKind kind) => _hasPermission(kind);

  /// 弹系统授权框；已授权直接返回 true。
  Future<bool> requestPermission(MediaKind kind) => _requestPermission(kind);

  /// 本机文件的封面字节（音频内嵌图 / 视频一帧）；没有返回 null。
  Future<Uint8List?> extractCover(String uri, MediaKind kind) async {
    try {
      return await _channel.invokeMethod<Uint8List>(
        'cover',
        {'uri': uri, 'kind': kind.name},
      );
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  /// 系统照片选择器挑一张图，返回拷到缓存里的路径；取消返回 null。不需要任何权限。
  Future<String?> pickImage() async {
    try {
      return await _channel.invokeMethod<String>('pickImage');
    } on MissingPluginException {
      return null;
    }
  }

  @override
  String get id => 'local';

  @override
  Future<List<DriveEntry>> listMediaFiles(MediaKind kind) async {
    if (!await _hasPermission(kind)) return const [];
    return [for (final r in await _query(kind)) _toEntry(r, kind)];
  }

  /// 目录内容由全部媒体文件推出来：直接在 [path] 下的文件，加上含媒体的下一级子目录。
  /// 认领与刷新（含一层子目录展开）都走这里，规则与网盘一致。
  @override
  Future<List<DriveEntry>> listDirectory(String path) async {
    final dir = _stripTrailing(path);
    final all = [
      ...await listMediaFiles(MediaKind.audio),
      ...await listMediaFiles(MediaKind.video),
    ];
    final files = <DriveEntry>[];
    final subdirs = <String>{};
    for (final f in all) {
      if (!f.path.startsWith('$dir/')) continue;
      final rest = f.path.substring(dir.length + 1);
      final slash = rest.indexOf('/');
      if (slash < 0) {
        files.add(f);
      } else {
        subdirs.add('$dir/${rest.substring(0, slash)}');
      }
    }
    return [
      for (final d in subdirs)
        DriveEntry(
          fsId: '$localPrefix$d',
          path: d,
          name: d.substring(d.lastIndexOf('/') + 1),
          isDirectory: true,
          size: 0,
        ),
      ...files,
    ];
  }

  @override
  Future<ResolvedMedia> resolveMedia(
    String fsId, {
    String? path,
    MediaKind kind = MediaKind.audio,
  }) async {
    final ref = parseLocalFsId(fsId);
    if (ref == null) {
      throw DriveException(DriveErrorKind.notFound, '不是本机文件：$fsId');
    }
    return ResolvedMedia(
      url: localContentUri(ref.kind, ref.id),
      // 文件就在手机上，永不过期
      isLocal: true,
      expiresAt: DateTime(9999),
      mediaKind: ref.kind,
    );
  }

  @override
  Future<Map<String, DriveEntry>> fetchMetadata(List<String> fsIds) async {
    final wanted = fsIds.toSet();
    final all = [
      ...await listMediaFiles(MediaKind.audio),
      ...await listMediaFiles(MediaKind.video),
    ];
    return {
      for (final f in all)
        if (wanted.contains(f.fsId)) f.fsId: f,
    };
  }

  /// 本机文件不读 ID3：认领时标签探测失败会自动退回文件名（library-catalog 规格的优先级链）。
  @override
  Future<List<int>> readRange(String fsId, int start, int endInclusive) =>
      throw const DriveException(DriveErrorKind.api, '本机文件不支持按字节读取');

  @override
  Future<Stream<List<int>>> openStream(ResolvedMedia media, {int start = 0}) =>
      throw const DriveException(DriveErrorKind.api, '本机文件无需下载');

  /// 同步文件只在网盘上；本机书不进同步。
  @override
  Future<String?> readAppStateFile(String path) async => null;

  @override
  Future<void> writeAppStateFile(String path, String content) async {}

  static DriveEntry _toEntry(LocalMediaRow r, MediaKind kind) => DriveEntry(
        fsId: localFsId(kind, r.id),
        path: '$localPrefix${r.path}',
        name: r.name,
        isDirectory: false,
        size: r.size,
        serverMtime: r.mtime,
      );

  static String _stripTrailing(String p) =>
      p.length > 1 && p.endsWith('/') ? p.substring(0, p.length - 1) : p;

  static Future<List<LocalMediaRow>> _channelQuery(MediaKind kind) async {
    try {
      final rows = await _channel.invokeListMethod<Map<Object?, Object?>>(
            'query',
            {'kind': kind.name},
          ) ??
          const [];
      return [
        for (final r in rows)
          (
            id: r['id']! as String,
            name: r['name']! as String,
            path: r['path']! as String,
            size: (r['size'] as num?)?.toInt() ?? 0,
            mtime: (r['mtime'] as num?)?.toInt() ?? 0,
          ),
      ];
    } on PlatformException catch (e) {
      throw DriveException(DriveErrorKind.api, '读取本机媒体失败：${e.message}');
    } on MissingPluginException {
      // 非 Android（iOS、测试环境）没有这个通道：当作没有本机媒体
      return const [];
    }
  }

  static Future<bool> _channelHas(MediaKind kind) async {
    try {
      return await _channel
              .invokeMethod<bool>('hasPermission', {'kind': kind.name}) ??
          false;
    } on MissingPluginException {
      return false;
    }
  }

  static Future<bool> _channelRequest(MediaKind kind) async {
    try {
      return await _channel
              .invokeMethod<bool>('requestPermission', {'kind': kind.name}) ??
          false;
    } on MissingPluginException {
      return false;
    }
  }
}
