/// 云盘数据源抽象（design.md D9）。
///
/// UI 层与播放层只依赖这个接口，百度网盘只是它的第一个实现。
/// 抽象成本极低，但把未来接入其他网盘的可能性留住了。
/// MVP 刻意不实现第二个 driver，避免为假想需求过度设计。
library;

class DriveEntry {
  const DriveEntry({
    required this.fsId,
    required this.path,
    required this.name,
    required this.isDirectory,
    required this.size,
    this.serverMtime,
    this.thumbnailUrl,
  });

  final String fsId;
  final String path;
  final String name;
  final bool isDirectory;
  final int size;
  final int? serverMtime;
  final String? thumbnailUrl;

  String get extension {
    final dot = name.lastIndexOf('.');
    if (dot < 0 || dot == name.length - 1) return '';
    return name.substring(dot + 1).toLowerCase();
  }

  String get nameWithoutExtension {
    final dot = name.lastIndexOf('.');
    return dot < 0 ? name : name.substring(0, dot);
  }
}

/// 播放地址的形态。
///
/// progressive 是整文件直链（dlink / 本地文件），播放器按 Range 流式读；
/// hls 是转码后的 M3U8（视频课程用，见 add-video-courses），只能在线播。
enum StreamKind { progressive, hls }

/// 一次可播放地址解析的结果。
/// [expiresAt] 是保守估计值——我们不信任服务端声明的有效期，
/// 宁可提前失效重取，也不要在播放中途才发现链接死了（design.md D3）。
class ResolvedMedia {
  const ResolvedMedia({
    required this.url,
    required this.isLocal,
    required this.expiresAt,
    this.kind = StreamKind.progressive,
    this.headers = const {},
  });

  final String url;
  final bool isLocal;
  final DateTime expiresAt;
  final StreamKind kind;
  final Map<String, String> headers;

  bool get isStale => !isLocal && DateTime.now().isAfter(expiresAt);
}

abstract class CloudDriveSource {
  /// 数据源标识，用于日志与将来的多网盘区分。
  String get id;

  /// 列出目录内容。只允许访问当前授权用户本人的文件。
  Future<List<DriveEntry>> listDirectory(String path);

  /// 取文件元信息（含可播放地址）。返回的地址有时效，禁止持久化。
  Future<ResolvedMedia> resolveMedia(String fsId);

  /// 批量取文件元信息，用于认领整个文件夹时减少往返。
  Future<Map<String, DriveEntry>> fetchMetadata(List<String> fsIds);

  /// 按 Range 读取文件的一段字节。ID3 解析依赖它。
  Future<List<int>> readRange(String fsId, int start, int endInclusive);

  /// 从 [start] 字节开始打开一个已解析地址的字节流。离线下载（断点续传）用它。
  Future<Stream<List<int>>> openStream(ResolvedMedia media, {int start = 0});

  /// 读取应用专属目录下的状态文件，不存在时返回 null。
  Future<String?> readAppStateFile(String path);

  /// 写入应用专属目录下的状态文件。
  Future<void> writeAppStateFile(String path, String content);
}
