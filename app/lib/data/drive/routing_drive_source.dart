import 'package:yun_audiobook/data/drive/cloud_drive_source.dart';
import 'package:yun_audiobook/data/drive/local/local_media_source.dart';
import 'package:yun_audiobook/domain/entities.dart';
import 'package:yun_audiobook/domain/local_media.dart';

/// 网盘 + 本机 合成一个 [CloudDriveSource]（add-local-media）。
///
/// 按路径 / fsId 的 `local:` 前缀分派，书架、认领、播放、恢复各层都不用知道
/// 来源有两个。同步文件、按类型列全盘这类「网盘才有」的操作走网盘那一路。
class RoutingDriveSource implements CloudDriveSource {
  RoutingDriveSource({required this.remote, required this.local});

  final CloudDriveSource remote;
  final LocalMediaSource local;

  @override
  String get id => remote.id;

  CloudDriveSource _byPath(String path) => isLocalPath(path) ? local : remote;

  @override
  Future<List<DriveEntry>> listDirectory(String path) =>
      _byPath(path).listDirectory(path);

  /// 「添加书籍」的网盘栏用它；本机栏直接用 [local]。
  @override
  Future<List<DriveEntry>> listMediaFiles(MediaKind kind) =>
      remote.listMediaFiles(kind);

  @override
  Future<ResolvedMedia> resolveMedia(
    String fsId, {
    String? path,
    MediaKind kind = MediaKind.audio,
  }) =>
      _byPath(fsId).resolveMedia(fsId, path: path, kind: kind);

  @override
  Future<Map<String, DriveEntry>> fetchMetadata(List<String> fsIds) async {
    final locals = fsIds.where(isLocalPath).toList();
    final remotes = fsIds.where((f) => !isLocalPath(f)).toList();
    return {
      if (locals.isNotEmpty) ...await local.fetchMetadata(locals),
      if (remotes.isNotEmpty) ...await remote.fetchMetadata(remotes),
    };
  }

  @override
  Future<List<int>> readRange(String fsId, int start, int endInclusive) =>
      _byPath(fsId).readRange(fsId, start, endInclusive);

  @override
  Future<Stream<List<int>>> openStream(ResolvedMedia media, {int start = 0}) =>
      remote.openStream(media, start: start);

  @override
  Future<String?> readAppStateFile(String path) =>
      remote.readAppStateFile(path);

  @override
  Future<void> writeAppStateFile(String path, String content) =>
      remote.writeAppStateFile(path, content);
}
