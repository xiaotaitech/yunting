import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:yun_audiobook/core/logging.dart';
import 'package:yun_audiobook/data/drive/cloud_drive_source.dart';
import 'package:yun_audiobook/data/local/series_dao.dart';
import 'package:yun_audiobook/domain/entities.dart';
import 'package:yun_audiobook/domain/id3_parser.dart';
import 'package:yun_audiobook/domain/local_media.dart';

/// 自动封面（add-covers）。
///
/// 没有封面的合集，从它的前几个文件里找一张：
///   - 本机文件：系统读内嵌专辑图 / 取视频一帧
///   - 网盘音频（mp3）：只读 ID3 标签那一段（头部给了确切长度），取内嵌图
///   - 网盘视频：百度自己生成的缩略图
/// 结果存成本机文件（cover_local_path），不进同步——每台设备各自取一次。
/// 全程尽力而为：任何失败都只是继续用首字占位。
class CoverService {
  CoverService({
    required SeriesDao dao,
    required CloudDriveSource drive,
    required Future<Uint8List?> Function(String uri, MediaKind kind)
        extractLocal,
    http.Client? client,
    Future<Directory> Function()? dir,
  })  : _dao = dao,
        _drive = drive,
        _extractLocal = extractLocal,
        _http = client ?? http.Client(),
        _dir = dir ?? _defaultDir;

  final SeriesDao _dao;
  final CloudDriveSource _drive;
  final Future<Uint8List?> Function(String, MediaKind) _extractLocal;
  final http.Client _http;
  final Future<Directory> Function() _dir;
  final Set<String> _inFlight = {};

  /// ID3 标签超过这么大就不读了：封面通常几百 KB，几 MB 的标签在限速账号上不值得。
  static const int maxTagBytes = 3 * 1024 * 1024;

  /// 最多看前几个文件：第一集没带图、第二集带了的情况不少见，但没必要扫整本。
  static const probeFiles = 3;

  static Future<Directory> _defaultDir() async {
    final base = await getApplicationSupportDirectory();
    final dir = Directory(p.join(base.path, 'covers'));
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir;
  }

  /// 合集已经有可用封面（网盘封面图，或已存在的本机封面文件）。
  static bool hasCover(Series s) =>
      s.coverFsId != null ||
      (s.coverLocalPath != null && File(s.coverLocalPath!).existsSync());

  /// 给没有封面的合集补一张。重复调用安全（同一合集同时只跑一次）。
  Future<void> ensure(Series series) async {
    if (hasCover(series) || !_inFlight.add(series.id)) return;
    try {
      final episodes = await _dao.episodesOf(series.id);
      for (final e in episodes.take(probeFiles)) {
        final bytes = await _fromEpisode(e);
        if (bytes != null && bytes.isNotEmpty) {
          await _save(series.id, bytes);
          Log.d('cover', '已取到封面：${series.title}');
          return;
        }
      }
    } on Object catch (e) {
      Log.d('cover', '取封面失败（忽略）：${series.title} :: $e');
    } finally {
      _inFlight.remove(series.id);
    }
  }

  /// 依次给一批合集补封面（启动后对书架做一次）。一个一个来，不和播放抢带宽。
  Future<void> backfill(List<Series> shelf) async {
    for (final s in shelf) {
      await ensure(s);
    }
  }

  /// 用户手动选的图：覆盖任何自动封面。
  Future<void> setManual(String seriesId, String imagePath) async {
    await _save(seriesId, await File(imagePath).readAsBytes());
  }

  Future<Uint8List?> _fromEpisode(Episode e) async {
    final local = parseLocalFsId(e.fsId);
    if (local != null) {
      return _extractLocal(localContentUri(local.kind, local.id), local.kind);
    }
    if (e.mediaKind == MediaKind.video) {
      final url = (await _drive.fetchMetadata([e.fsId]))[e.fsId]?.thumbnailUrl;
      if (url == null) return null;
      final res = await _http.get(Uri.parse(url));
      return res.statusCode == 200 ? res.bodyBytes : null;
    }
    if (!e.fileName.toLowerCase().endsWith('.mp3')) return null;
    final header = Uint8List.fromList(await _drive.readRange(e.fsId, 0, 9));
    final length = Id3Parser.tagLength(header);
    if (length == null || length > maxTagBytes) return null;
    final tag =
        Uint8List.fromList(await _drive.readRange(e.fsId, 0, length - 1));
    return Id3Parser.picture(tag);
  }

  /// 每次写新文件名：同一路径覆盖写的话，Flutter 的图片缓存会继续显示旧图。
  Future<void> _save(String seriesId, Uint8List bytes) async {
    final dir = await _dir();
    for (final old in dir.listSync().whereType<File>()) {
      if (p.basename(old.path).startsWith('$seriesId-')) old.deleteSync();
    }
    final file = File(
      p.join(
          dir.path, '$seriesId-${DateTime.now().millisecondsSinceEpoch}.img'),
    )..writeAsBytesSync(bytes);
    await _dao.setCoverLocalPath(seriesId, file.path);
  }
}
