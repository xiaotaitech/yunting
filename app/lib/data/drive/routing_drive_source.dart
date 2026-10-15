import 'package:yun_audiobook/data/drive/cloud_drive_source.dart';
import 'package:yun_audiobook/domain/entities.dart';

/// 多个数据源合成一个 [CloudDriveSource]（add-local-media；多网盘的接入点）。
///
/// 路径与 fsId 用前缀标明来源：`local:` 是本机，将来接的网盘各占一个
/// `<id>:` 前缀（如 `aliyun:`）；不带前缀的属于 [primary]（百度网盘——
/// 老用户库里的路径都没有前缀，所以它只能是「无前缀」那一个）。
/// 书架、认领、播放、下载各层只认这一个合成源，不用知道来源有几个。
///
/// 接入新网盘的完整步骤见 README「接入其他网盘」。
class RoutingDriveSource implements CloudDriveSource {
  RoutingDriveSource({
    required this.primary,
    Map<String, CloudDriveSource> byPrefix = const {},
  }) : _byPrefix = byPrefix;

  /// 无前缀路径的归属，也是「添加书籍」网盘栏整盘扫描的对象。
  final CloudDriveSource primary;

  /// 前缀（含冒号，如 `local:`）→ 数据源。
  final Map<String, CloudDriveSource> _byPrefix;

  @override
  String get id => primary.id;

  CloudDriveSource _byPath(String pathOrFsId) {
    for (final e in _byPrefix.entries) {
      if (pathOrFsId.startsWith(e.key)) return e.value;
    }
    return primary;
  }

  CloudDriveSource _byId(String? id) =>
      _byPrefix.values.where((s) => s.id == id).firstOrNull ?? primary;

  @override
  Future<List<DriveEntry>> listDirectory(String path) =>
      _byPath(path).listDirectory(path);

  /// 「添加书籍」的网盘栏用它；本机栏直接用本机源。
  @override
  Future<List<DriveEntry>> listMediaFiles(MediaKind kind) =>
      primary.listMediaFiles(kind);

  /// 结果记上来源，[openStream] 才知道该交给谁（下载时只拿得到这个对象）。
  @override
  Future<ResolvedMedia> resolveMedia(
    String fsId, {
    String? path,
    MediaKind kind = MediaKind.audio,
  }) async {
    final source = _byPath(fsId);
    final media = await source.resolveMedia(fsId, path: path, kind: kind);
    return media.from(source.id);
  }

  @override
  Future<Map<String, DriveEntry>> fetchMetadata(List<String> fsIds) async {
    final groups = <CloudDriveSource, List<String>>{};
    for (final f in fsIds) {
      (groups[_byPath(f)] ??= []).add(f);
    }
    return {
      for (final g in groups.entries) ...await g.key.fetchMetadata(g.value),
    };
  }

  @override
  Future<List<int>> readRange(String fsId, int start, int endInclusive) =>
      _byPath(fsId).readRange(fsId, start, endInclusive);

  @override
  Future<Stream<List<int>>> openStream(ResolvedMedia media, {int start = 0}) =>
      _byId(media.sourceId).openStream(media, start: start);
}
