import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import 'package:yun_audiobook/core/config.dart';
import 'package:yun_audiobook/core/errors.dart';
import 'package:yun_audiobook/core/logging.dart';
import 'package:yun_audiobook/core/natural_sort.dart';
import 'package:yun_audiobook/data/drive/cloud_drive_source.dart';
import 'package:yun_audiobook/data/local/series_dao.dart';
import 'package:yun_audiobook/domain/entities.dart';
import 'package:yun_audiobook/domain/id3_parser.dart';

/// 由网盘路径派生出稳定的合集 ID。
///
/// 前缀仍是 `book-`：它进了同步文件，多设备之间必须一致，不能随改名而变。
///
/// 同一个文件夹在任何设备上都得到同一个 id，多设备同步就能走正常的记录合并，
/// 而不会因为 folder_path 的唯一约束把对方的书连同章节一起顶掉。
String seriesIdForFolder(String folderPath) {
  final digest = md5.convert(utf8.encode(folderPath)).toString();
  return 'book-${digest.substring(0, 16)}';
}

/// 认领一个文件夹时解析出来的候选内容。
class FolderScan {
  const FolderScan({
    required this.mediaFiles,
    required this.coverEntry,
    required this.subFolders,
  });

  final List<DriveEntry> mediaFiles;
  final DriveEntry? coverEntry;
  final List<DriveEntry> subFolders;

  bool get hasMedia => mediaFiles.isNotEmpty;
}

/// 书架与合集的业务逻辑（library-catalog 规格）。
///
/// 「文件夹即合集」是核心模型：用户主动认领，系统不做全盘扫描。
class LibraryRepository {
  LibraryRepository({
    required CloudDriveSource drive,
    required SeriesDao dao,
    required Future<String> Function() deviceId,
  })  : _drive = drive,
        _dao = dao,
        _deviceId = deviceId;

  final CloudDriveSource _drive;
  final SeriesDao _dao;
  final Future<String> Function() _deviceId;

  Future<List<DriveEntry>> browse(String path) => _drive.listDirectory(path);

  /// 本变更只识别音频；视频识别在 add-video-courses 里加。
  static MediaKind? mediaKindOf(DriveEntry e) {
    if (e.isDirectory) return null;
    if (AppConfig.audioExtensions.contains(e.extension)) return MediaKind.audio;
    return null;
  }

  static bool isMedia(DriveEntry e) => mediaKindOf(e) != null;

  static bool isCoverImage(DriveEntry e) {
    if (e.isDirectory) return false;
    if (!AppConfig.imageExtensions.contains(e.extension)) return false;
    return AppConfig.coverFileNames
        .contains(e.nameWithoutExtension.toLowerCase());
  }

  /// 扫描一个目录，判断它能否成为一个合集。
  Future<FolderScan> scanFolder(String path) async {
    final entries = await _drive.listDirectory(path);
    final media = entries.where(isMedia).toList();
    final covers = entries.where(isCoverImage).toList();
    // 没有约定名的封面时，退而求其次用目录里唯一的图片
    final images = entries
        .where((e) =>
            !e.isDirectory && AppConfig.imageExtensions.contains(e.extension))
        .toList();

    return FolderScan(
      mediaFiles: media,
      coverEntry: covers.isNotEmpty
          ? covers.first
          : (images.length == 1 ? images.first : null),
      subFolders: entries.where((e) => e.isDirectory).toList(),
    );
  }

  /// 收集一个合集目录下的全部媒体文件。
  ///
  /// 支持一层子目录（卷/季）：本层没有媒体文件时，子目录按名称自然序展开，
  /// 各子目录内的文件依次拼接为连续序列（规格「含子目录的书」）。
  /// 认领与刷新共用这一处，两边的展开规则不会再走样。
  Future<({List<DriveEntry> files, DriveEntry? cover})> _collect(
    String folderPath,
  ) async {
    final scan = await scanFolder(folderPath);
    final collected = <DriveEntry>[...scan.mediaFiles];
    var cover = scan.coverEntry;

    if (collected.isEmpty && scan.subFolders.isNotEmpty) {
      final subs = scan.subFolders.toList()
        ..sort((a, b) => compareNatural(a.name, b.name));
      for (final sub in subs) {
        final subScan = await scanFolder(sub.path);
        collected.addAll(subScan.mediaFiles);
        cover ??= subScan.coverEntry;
      }
    }
    return (files: collected, cover: cover);
  }

  /// 认领文件夹为一个合集。
  Future<Series> claimFolder(String folderPath, {String? titleOverride}) async {
    final existing = await _dao.seriesByFolder(folderPath);
    if (existing != null) {
      // 重复认领不创建新条目，直接返回已有的（规格「重复认领同一文件夹」）
      Log.d('library', '文件夹已在书架中：$folderPath');
      return existing;
    }

    final (:files, :cover) = await _collect(folderPath);
    final collected = files;
    if (collected.isEmpty) {
      throw const DriveException(DriveErrorKind.noMedia, '该文件夹下没有可识别的音频文件');
    }

    final now = DateTime.now();
    // 用路径派生 ID，而不是时间戳：两台设备各自认领同一个文件夹时会得到
    // 同一个 id，同步时走正常的记录合并，而不是撞 folder_path 唯一约束、
    // 互相把对方的书连同章节一起顶掉。
    // 移出书架后重新认领：沿用原来那一行（upsert 会把 deleted 置回 0）
    final seriesId = await _dao.idByFolderIncludingDeleted(folderPath) ??
        seriesIdForFolder(folderPath);
    final device = await _deviceId();

    // 先用文件名建立章节，随后再尽力用标签修正标题与顺序。
    final tags = await _probeTags(collected);
    final episodes = _buildEpisodes(seriesId, collected, tags);

    final folderName = folderPath.split('/').where((s) => s.isNotEmpty).last;
    final firstTags = tags[collected.first.fsId] ?? AudioTags.empty;

    final series = Series(
      id: seriesId,
      folderPath: folderPath,
      // 元数据优先级：手动 > 标签 > 文件夹名（library-catalog 规格）
      title: titleOverride ?? firstTags.album ?? folderName,
      author: firstTags.artist,
      coverFsId: cover?.fsId,
      episodeCount: episodes.length,
      addedAt: now,
      updatedAt: now,
      updatedByDevice: device,
      titleEditedByUser: titleOverride != null,
    );

    await _dao.upsertSeries(series);
    await _dao.replaceEpisodes(seriesId, episodes);
    Log.d('library', '已认领《${series.title}》，共 ${episodes.length} 集');
    return series;
  }

  List<Episode> _buildEpisodes(
    String seriesId,
    List<DriveEntry> files,
    Map<String, AudioTags> tags,
  ) {
    // track 号只有在**每一个**章节都有的时候才作为排序依据。
    // 只有部分章节带 track 时混着比，比较器会失去传递性，
    // 排出来的顺序是随机的——那比老老实实按文件名排还糟。
    final allHaveTrack = canSortByTrack(files.map((f) => tags[f.fsId]?.track));

    // 二级排序：先按所在目录，再按文件名。
    //
    // 一本书跨多个子目录时（卷/季，或「每期一个目录」的连载），序号往往在
    // 目录名上而不是文件名上——真实数据里就是
    // `0404 一个人的疗愈/一个人的疗愈.mp3` 这种。把所有文件平铺后只按文件名排，
    // 得到的顺序毫无意义（实测排出了 0411 → 0404 → 0516）。
    // 单目录的书里所有文件同属一个目录，这一层比较恒等，行为不变。
    final sorted = files.toList()
      ..sort((a, b) {
        final dirA = parentDirOf(a.path);
        final dirB = parentDirOf(b.path);
        if (dirA != dirB) return compareNatural(dirA, dirB);
        return compareChapters(
          nameA: a.name,
          nameB: b.name,
          trackA: allHaveTrack ? tags[a.fsId]?.track : null,
          trackB: allHaveTrack ? tags[b.fsId]?.track : null,
        );
      });

    return [
      for (var i = 0; i < sorted.length; i++)
        Episode(
          // id 形如 `book-xxx-chN`：沿用老格式，历史与同步里都存着它
          id: '$seriesId-ch$i',
          seriesId: seriesId,
          mediaKind: mediaKindOf(sorted[i]) ?? MediaKind.audio,
          fsId: sorted[i].fsId,
          path: sorted[i].path,
          title: tags[sorted[i].fsId]?.title ?? sorted[i].nameWithoutExtension,
          fileName: sorted[i].name,
          size: sorted[i].size,
          orderIndex: i,
          trackNumber: tags[sorted[i].fsId]?.track,
        ),
    ];
  }

  /// 读取每个文件头部的若干 KB 解析 ID3。
  ///
  /// 这是纯增强：任何一个文件读失败都只是少一份标签，绝不能让加书流程失败。
  /// 每个文件要花一次 dlink 解析 + 一次 Range 读取，在限速账号上并不便宜，
  /// 所以章节多时只探测前若干个——书名/作者取自首个文件就够了，
  /// 而 track 排序本来就要求全员齐备（见 [_buildEpisodes]），探不全时自然回退文件名。
  Future<Map<String, AudioTags>> _probeTags(List<DriveEntry> files,
      {int maxProbe = 8}) async {
    final result = <String, AudioTags>{};
    final probe = files.take(maxProbe);
    for (final f in probe) {
      if (f.extension != 'mp3') continue; // 目前只解析 ID3（mp3）
      try {
        final upper = (Id3Parser.headerProbeBytes - 1)
            .clamp(0, f.size > 0 ? f.size - 1 : 0);
        if (upper <= 0) continue;
        final bytes = await _drive.readRange(f.fsId, 0, upper);
        final tags = Id3Parser.parse(Uint8List.fromList(bytes));
        if (!tags.isEmpty) result[f.fsId] = tags;
      } catch (e) {
        Log.d('library', '读取标签失败（忽略）：${f.name} :: $e');
      }
    }
    return result;
  }

  /// 刷新一个合集的条目。用户编辑过的字段与手动排序都必须保住。
  Future<void> refresh(Series series) async {
    try {
      final collected = (await _collect(series.folderPath)).files;
      if (collected.isEmpty) {
        await _markMissing(series, missing: true);
        return;
      }

      if (series.orderEditedByUser) {
        // 用户排过序：只补新增条目，不重排已有顺序（规格「手动调整顺序」）
        final existing = await _dao.episodesOf(series.id);
        final knownFsIds = existing.map((c) => c.fsId).toSet();
        final added = collected.where((e) => !knownFsIds.contains(e.fsId));
        var index = existing.length;
        final merged = [
          ...existing,
          for (final e in added)
            Episode(
              id: '${series.id}-ch${index++}',
              seriesId: series.id,
              mediaKind: mediaKindOf(e) ?? MediaKind.audio,
              fsId: e.fsId,
              path: e.path,
              title: e.nameWithoutExtension,
              fileName: e.name,
              size: e.size,
              orderIndex: index - 1,
            ),
        ];
        await _dao.replaceEpisodes(series.id, merged);
      } else {
        final tags = await _probeTags(collected);
        await _dao.replaceEpisodes(
          series.id,
          _buildEpisodes(series.id, collected, tags),
        );
      }
      if (series.sourceMissing) await _markMissing(series, missing: false);
    } on DriveException catch (e) {
      if (e.kind == DriveErrorKind.notFound) {
        // 网盘路径消失：保留书架条目与进度，只做标记（规格「网盘文件已被删除」）
        await _markMissing(series, missing: true);
        return;
      }
      rethrow;
    }
  }

  Future<void> _markMissing(Series series, {required bool missing}) async {
    await _dao.upsertSeries(
      series.copyWith(
        sourceMissing: missing,
        updatedAt: DateTime.now(),
        updatedByDevice: await _deviceId(),
      ),
    );
  }

  /// 用户手动编辑合集信息。被编辑过的字段之后不再被自动识别覆盖。
  Future<Series> edit(Series series, {String? title, String? author}) async {
    final updated = series.copyWith(
      title: title ?? series.title,
      author: author ?? series.author,
      titleEditedByUser: title != null || series.titleEditedByUser,
      authorEditedByUser: author != null || series.authorEditedByUser,
      updatedAt: DateTime.now(),
      updatedByDevice: await _deviceId(),
    );
    await _dao.upsertSeries(updated);
    return updated;
  }

  Future<void> reorder(Series series, List<Episode> ordered) async {
    await _dao.updateOrder(ordered);
    await _dao.upsertSeries(
      series.copyWith(
        orderEditedByUser: true,
        updatedAt: DateTime.now(),
        updatedByDevice: await _deviceId(),
      ),
    );
  }

  /// 移出书架。只删本地记录与缓存，绝不动网盘原文件（规格「移除书籍」）。
  Future<void> remove(String seriesId) async {
    await _dao.markDeleted(seriesId, await _deviceId());
  }
}
