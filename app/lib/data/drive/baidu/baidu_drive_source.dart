import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:yun_audiobook/core/config.dart';
import 'package:yun_audiobook/core/errors.dart';
import 'package:yun_audiobook/core/logging.dart';
import 'package:yun_audiobook/data/drive/baidu/baidu_api_client.dart';
import 'package:yun_audiobook/data/drive/cloud_drive_source.dart';
import 'package:yun_audiobook/domain/entities.dart';

/// 百度网盘的 [CloudDriveSource] 实现。
///
/// 合规边界（design.md D8）：本类只调用「读取当前授权用户本人文件」的接口。
/// 代码里刻意不存在任何分享类接口、分享链接解析或访问他人网盘的路径。
class BaiduDriveSource implements CloudDriveSource {
  BaiduDriveSource(
    this._api, {
    Future<String> Function()? videoQuality,
    Future<Directory> Function()? hlsDir,
    Future<void> Function(Duration)? sleep,
  })  : _videoQuality = videoQuality ?? (() async => '720'),
        _hlsDir = hlsDir ?? _defaultHlsDir,
        _sleep = sleep ?? Future<void>.delayed;

  final BaiduApiClient _api;
  final Future<String> Function() _videoQuality;
  final Future<Directory> Function() _hlsDir;
  final Future<void> Function(Duration) _sleep;

  /// 转码流的分片地址实测约 8 小时失效，保守按 7 小时算。
  static const Duration hlsTtl = Duration(hours: 7);

  /// 取转码流用的 UA。百度的视频接口按「xpanvideo;应用;版本;平台;系统版本;ts」识别客户端。
  static const videoUserAgent = 'xpanvideo;yunting;1.0;android-android;14;ts';

  static Future<Directory> _defaultHlsDir() async {
    final dir = Directory(p.join((await getTemporaryDirectory()).path, 'hls'));
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir;
  }

  /// dlink 的保守有效期。百度声明的时效更长，但我们宁可提前重取，
  /// 也不要在播放中途才发现链接已死（design.md D3）。
  static const Duration dlinkTtl = Duration(minutes: 25);

  @override
  String get id => 'baidu';

  @override
  Future<List<DriveEntry>> listDirectory(String path) async {
    final entries = <DriveEntry>[];
    var start = 0;
    const pageSize = 1000;

    // 分页取完，避免大目录被截断。
    while (true) {
      final json = await _api.getJson('/xpan/file', {
        'method': 'list',
        'dir': path,
        'order': 'name',
        'start': '$start',
        'limit': '$pageSize',
        'web': '1',
      });
      final list = (json['list'] as List?) ?? const [];
      entries.addAll(list.map((e) => _toEntry(e as Map<String, dynamic>)));
      if (list.length < pageSize) break;
      start += pageSize;
    }
    return entries;
  }

  @override
  Future<List<DriveEntry>> listMediaFiles(MediaKind kind) async {
    final files = <DriveEntry>[];
    var start = 0;
    const pageSize = 1000;
    while (true) {
      final json = await _api.getJson('/xpan/multimedia', {
        'method': 'categorylist',
        // 百度的类别编号：1 视频，2 音频
        'category': kind == MediaKind.video ? '1' : '2',
        'parent_path': '/',
        'recursion': '1',
        'start': '$start',
        'limit': '$pageSize',
      });
      final list = (json['list'] as List?) ?? const [];
      files.addAll(list.map((e) => _toEntry(e as Map<String, dynamic>)));
      final hasMore = (json['has_more'] as num?)?.toInt() == 1;
      if (!hasMore || list.isEmpty) break;
      start += pageSize;
    }
    return files;
  }

  @override
  Future<Map<String, DriveEntry>> fetchMetadata(List<String> fsIds) async {
    if (fsIds.isEmpty) return {};
    final result = <String, DriveEntry>{};
    // filemetas 一次不宜要太多，分批更稳。
    for (var i = 0; i < fsIds.length; i += 50) {
      final batch = fsIds.sublist(i, (i + 50).clamp(0, fsIds.length));
      final json = await _metas(batch, wantDlink: false);
      for (final raw in (json['list'] as List?) ?? const []) {
        final map = raw as Map<String, dynamic>;
        final entry = _toEntry(map);
        result[entry.fsId] = entry;
      }
    }
    return result;
  }

  @override
  Future<ResolvedMedia> resolveMedia(
    String fsId, {
    String? path,
    MediaKind kind = MediaKind.audio,
  }) async {
    if (kind == MediaKind.video) {
      if (path == null) {
        throw const DriveException(DriveErrorKind.api, '视频取流需要文件路径');
      }
      return _resolveVideo(fsId, path);
    }
    final json = await _metas([fsId], wantDlink: true);
    final list = (json['list'] as List?) ?? const [];
    if (list.isEmpty) {
      throw DriveException(DriveErrorKind.notFound, '网盘中找不到该文件（fs_id=$fsId）');
    }
    final dlink = (list.first as Map<String, dynamic>)['dlink'] as String?;
    if (dlink == null || dlink.isEmpty) {
      throw const DriveException(
        DriveErrorKind.api,
        'filemetas 未返回 dlink，请确认应用已开通下载权限',
      );
    }
    return ResolvedMedia(
      url: await _api.authorizedUrl(dlink),
      isLocal: false,
      expiresAt: DateTime.now().add(dlinkTtl),
      // 播放器必须用同一个 UA 请求，否则大文件会被拒。
      headers: const {'User-Agent': AppConfig.panUserAgent},
    );
  }

  /// 视频走转码流（add-video-courses D1）。
  ///
  /// 原文件 dlink 对非会员只有约 94 KB/s，而课程原片约 2.2 Mbps，根本播不动；
  /// 转码后的 720p 约 240 kbps，实测下载速度是播放所需的 7 倍。
  ///
  /// 非会员第一次请求拿不到 M3U8，而是 `errno=133` + `adTime`（秒）+ `adToken`：
  /// 等够 adTime 再带上 adToken 重请求才给。会员直接给 M3U8。
  ///
  /// M3U8 写成本地文件交给播放器，分片地址仍指向百度——不在本机起 HTTP 代理，
  /// 那会撞上 Android 9+ 禁止明文流量（音频那边就踩过）。
  Future<ResolvedMedia> _resolveVideo(String fsId, String path) async {
    final query = {
      'method': 'streaming',
      'path': path,
      'type': 'M3U8_AUTO_${await _videoQuality()}',
    };
    const headers = {'User-Agent': videoUserAgent};
    var body = await _api.getText('/xpan/file', query, headers: headers);
    if (!_isPlaylist(body)) {
      final j = _decode(body);
      final errno = (j['errno'] as num?)?.toInt() ?? -1;
      final adToken = j['adToken'] as String?;
      if (errno != 133 || adToken == null) {
        throw _streamingError(errno, j);
      }
      final adTime = (j['adTime'] as num?)?.toInt() ?? 0;
      Log.d('baidu', '非会员取流：等待 $adTime 秒');
      await _sleep(Duration(milliseconds: adTime * 1000 + 300));
      body = await _api.getText(
        '/xpan/file',
        {...query, 'adToken': adToken, 'nom3u8': '0'},
        headers: headers,
      );
      if (!_isPlaylist(body)) {
        final j2 = _decode(body);
        throw _streamingError((j2['errno'] as num?)?.toInt() ?? -1, j2);
      }
    }
    final file = File(p.join((await _hlsDir()).path, '$fsId.m3u8'))
      ..writeAsStringSync(body);
    return ResolvedMedia(
      url: Uri.file(file.path).toString(),
      // 播放列表在本地，分片是远程的、会过期：不能当本地文件对待
      isLocal: false,
      expiresAt: DateTime.now().add(hlsTtl),
      kind: StreamKind.hls,
      mediaKind: MediaKind.video,
    );
  }

  static bool _isPlaylist(String body) => body.trimLeft().startsWith('#EXTM3U');

  static Map<String, dynamic> _decode(String body) {
    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } on Object {
      return const {};
    }
  }

  static DriveException _streamingError(int errno, Map<String, dynamic> j) {
    // 31341：视频还在转码（刚上传的大文件常见），稍后再试即可
    if (errno == 31341) {
      return DriveException(
        DriveErrorKind.rateLimited,
        '视频正在转码，请稍后再试（errno=$errno）',
        errno: errno,
      );
    }
    if (errno > 0 || errno < -1) {
      return DriveException.fromErrno(errno, context: '转码流');
    }
    return DriveException(
      DriveErrorKind.api,
      '转码流返回了非预期内容：${j.isEmpty ? '非 JSON' : j}',
    );
  }

  @override
  Future<List<int>> readRange(String fsId, int start, int endInclusive) async {
    final media = await resolveMedia(fsId);
    return _api.readRange(media.url, start, endInclusive);
  }

  @override
  Future<Stream<List<int>>> openStream(
    ResolvedMedia media, {
    int start = 0,
  }) async {
    final res = await _api.openStream(
      media.url,
      range: start > 0 ? 'bytes=$start-' : null,
    );
    return res.stream;
  }

  // ------------------------------------------------------- 应用状态文件

  @override
  Future<String?> readAppStateFile(String path) async {
    try {
      final dir = path.substring(0, path.lastIndexOf('/'));
      final name = path.substring(path.lastIndexOf('/') + 1);
      final entries = await listDirectory(dir);
      final target = entries.where((e) => e.name == name && !e.isDirectory);
      if (target.isEmpty) return null;
      final media = await resolveMedia(target.first.fsId);
      final bytes = await _api.readRange(media.url, 0, target.first.size - 1);
      return utf8.decode(bytes);
    } on DriveException catch (e) {
      // 目录还不存在是正常的首次状态，不该当作错误冒泡。
      if (e.kind == DriveErrorKind.notFound) return null;
      rethrow;
    }
  }

  /// 上传状态文件。走 precreate → superfile2 → create 三步，
  /// rtype=3 表示同名文件直接覆盖。
  @override
  Future<void> writeAppStateFile(String path, String content) async {
    final bytes = Uint8List.fromList(utf8.encode(content));
    final blockMd5 = md5.convert(bytes).toString();
    final blockList = jsonEncode([blockMd5]);

    final pre = await _api.postForm(
      '/xpan/file',
      {'method': 'precreate'},
      {
        'path': path,
        'size': '${bytes.length}',
        'isdir': '0',
        'autoinit': '1',
        'rtype': '3',
        'block_list': blockList,
      },
    );
    final uploadId = pre['uploadid'] as String?;
    if (uploadId == null) {
      throw const DriveException(DriveErrorKind.api, 'precreate 未返回 uploadid');
    }

    await _api.uploadSlice(
      path: path,
      uploadId: uploadId,
      partSeq: 0,
      bytes: bytes,
    );

    await _api.postForm(
      '/xpan/file',
      {'method': 'create'},
      {
        'path': path,
        'size': '${bytes.length}',
        'isdir': '0',
        'rtype': '3',
        'uploadid': uploadId,
        'block_list': blockList,
      },
    );
    Log.d('baidu', '状态文件已同步至 $path（${bytes.length} 字节）');
  }

  // ------------------------------------------------------- 内部

  Future<Map<String, dynamic>> _metas(
    List<String> fsIds, {
    required bool wantDlink,
  }) {
    return _api.getJson('/xpan/multimedia', {
      'method': 'filemetas',
      'fsids': jsonEncode(fsIds.map(int.parse).toList()),
      'dlink': wantDlink ? '1' : '0',
      'thumb': '1',
      'extra': '1',
    });
  }

  DriveEntry _toEntry(Map<String, dynamic> raw) {
    final thumbs = raw['thumbs'];
    String? thumb;
    if (thumbs is Map) {
      thumb = (thumbs['url3'] ?? thumbs['url2'] ?? thumbs['url1']) as String?;
    }
    return DriveEntry(
      fsId: '${raw['fs_id']}',
      path: raw['path'] as String? ?? '',
      name: (raw['server_filename'] ?? raw['filename'] ?? '') as String,
      isDirectory: (raw['isdir'] as num?)?.toInt() == 1,
      size: (raw['size'] as num?)?.toInt() ?? 0,
      serverMtime: (raw['server_mtime'] as num?)?.toInt(),
      thumbnailUrl: thumb,
    );
  }
}
