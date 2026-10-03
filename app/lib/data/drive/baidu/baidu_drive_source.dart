import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import '../../../core/config.dart';
import '../../../core/errors.dart';
import '../../../core/logging.dart';
import '../cloud_drive_source.dart';
import 'baidu_api_client.dart';

/// 百度网盘的 [CloudDriveSource] 实现。
///
/// 合规边界（design.md D8）：本类只调用「读取当前授权用户本人文件」的接口。
/// 代码里刻意不存在任何分享类接口、分享链接解析或访问他人网盘的路径。
class BaiduDriveSource implements CloudDriveSource {
  BaiduDriveSource(this._api);

  final BaiduApiClient _api;

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
  Future<ResolvedMedia> resolveMedia(String fsId) async {
    final json = await _metas([fsId], wantDlink: true);
    final list = (json['list'] as List?) ?? const [];
    if (list.isEmpty) {
      throw DriveException(DriveErrorKind.notFound, '网盘中找不到该文件（fs_id=$fsId）');
    }
    final dlink = (list.first as Map<String, dynamic>)['dlink'] as String?;
    if (dlink == null || dlink.isEmpty) {
      throw DriveException(
          DriveErrorKind.api, 'filemetas 未返回 dlink，请确认应用已开通下载权限');
    }
    return ResolvedMedia(
      url: await _api.authorizedUrl(dlink),
      isLocal: false,
      expiresAt: DateTime.now().add(dlinkTtl),
      // 播放器必须用同一个 UA 请求，否则大文件会被拒。
      headers: const {'User-Agent': AppConfig.panUserAgent},
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
      throw DriveException(DriveErrorKind.api, 'precreate 未返回 uploadid');
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

  Future<Map<String, dynamic>> _metas(List<String> fsIds,
      {required bool wantDlink}) {
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
