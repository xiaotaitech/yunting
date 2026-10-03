import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:yun_audiobook/core/errors.dart';
import 'package:yun_audiobook/core/logging.dart';
import 'package:yun_audiobook/data/drive/cloud_drive_source.dart';
import 'package:yun_audiobook/domain/entities.dart';
import 'package:yun_audiobook/domain/media_files.dart';

/// 演示用的假网盘（design.md D9 的第二个 driver）。
///
/// 存在的理由很实际：百度 AppKey 要实名认证才能拿到，在那之前没人能试用这个 App。
/// 这个实现让完整流程——浏览目录、认领成书、章节排序、播放、进度记忆、倍速、
/// 睡眠定时、书架同步——全都能真跑，只是音频是本地生成的正弦波而不是有声书。
///
/// 它同时也是那层 [CloudDriveSource] 抽象的实证：换掉数据源，UI 与播放层一行不用改。
class DemoDriveSource implements CloudDriveSource {
  DemoDriveSource();

  /// 每章时长。够长到能试倍速和拖动进度，又不至于生成太大的文件。
  static const int chapterSeconds = 40;
  static const int _sampleRate = 22050;

  /// 目录树。路径 -> 子项，模拟一个装着有声书的网盘。
  static final Map<String, List<_Node>> _tree = {
    '/': [
      _Node.dir('/我的有声书'),
      _Node.dir('/照片'),
    ],
    '/我的有声书': [
      _Node.dir('/我的有声书/三体'),
      _Node.dir('/我的有声书/小王子'),
      _Node.dir('/我的有声书/未整理'),
    ],
    // 刻意用「第2章 / 第10章」这种命名，好当场看出自然序排对了没有
    '/我的有声书/三体': [
      _Node.file('/我的有声书/三体/第1章 科学边界.mp3', 1001),
      _Node.file('/我的有声书/三体/第2章 台球.mp3', 1002),
      _Node.file('/我的有声书/三体/第3章 射手和农场主.mp3', 1003),
      _Node.file('/我的有声书/三体/第10章 红岸之一.mp3', 1010),
      _Node.file('/我的有声书/三体/第11章 红岸之二.mp3', 1011),
      _Node.file('/我的有声书/三体/cover.jpg', 1099, isImage: true),
    ],
    '/我的有声书/小王子': [
      _Node.file('/我的有声书/小王子/01 序.mp3', 2001),
      _Node.file('/我的有声书/小王子/02 玫瑰.mp3', 2002),
      _Node.file('/我的有声书/小王子/03 狐狸.mp3', 2003),
    ],
    // 空目录，用来看「本文件夹没有可识别的音频文件」这条空状态
    '/我的有声书/未整理': [],
    '/照片': [
      _Node.file('/照片/IMG_0001.jpg', 3001, isImage: true),
    ],
  };

  /// 同步状态文件写在本地，这样重启后书架还在，跟真实行为一致。
  final Map<String, String> _stateFiles = {};

  @override
  String get id => 'demo';

  @override
  Future<List<DriveEntry>> listDirectory(String path) async {
    // 假装有网络延迟，好让 loading 态真的能被看到
    await Future<void>.delayed(const Duration(milliseconds: 220));
    final nodes = _tree[path];
    if (nodes == null) {
      throw DriveException(DriveErrorKind.notFound, '演示网盘里没有这个目录：$path');
    }
    return nodes.map((n) => n.toEntry()).toList();
  }

  @override
  Future<Map<String, DriveEntry>> fetchMetadata(List<String> fsIds) async {
    final wanted = fsIds.toSet();
    return {
      for (final nodes in _tree.values)
        for (final n in nodes)
          if (wanted.contains(n.fsId)) n.fsId: n.toEntry(),
    };
  }

  @override
  Future<ResolvedMedia> resolveMedia(String fsId) async {
    final node = _find(fsId);
    if (node == null || node.isDirectory) {
      throw DriveException(DriveErrorKind.notFound, '演示网盘里没有这个文件（$fsId）');
    }
    final file = await _ensureAudio(node);
    return ResolvedMedia(
      url: Uri.file(file.path).toString(),
      // 演示音频本来就在本地，标成 local 让播放与下载都走本地路径
      isLocal: true,
      expiresAt: DateTime.now().add(const Duration(days: 3650)),
    );
  }

  @override
  Future<List<int>> readRange(String fsId, int start, int endInclusive) async {
    final node = _find(fsId);
    if (node == null) {
      throw DriveException(DriveErrorKind.notFound, '演示网盘里没有这个文件（$fsId）');
    }
    final file = await _ensureAudio(node);
    final bytes = await file.readAsBytes();
    final end = math.min(endInclusive + 1, bytes.length);
    if (start >= end) return const [];
    return bytes.sublist(start, end);
  }

  /// 演示网盘就在内存里：逐层走一遍目录树即可。
  @override
  Future<List<DriveEntry>> listMediaFiles(MediaKind kind) async {
    final result = <DriveEntry>[];
    Future<void> walk(String dir) async {
      for (final e in await listDirectory(dir)) {
        if (e.isDirectory) {
          await walk(e.path);
        } else if (mediaKindOf(e) == kind) {
          result.add(e);
        }
      }
    }

    await walk('/');
    return result;
  }

  /// 演示数据源解析出来的都是本地文件，下载管理器会直接标记为已缓存，
  /// 走不到这里；仍按接口语义实现，免得将来有人依赖它时踩空。
  @override
  Future<Stream<List<int>>> openStream(
    ResolvedMedia media, {
    int start = 0,
  }) async =>
      File(Uri.parse(media.url).toFilePath()).openRead(start);

  @override
  Future<String?> readAppStateFile(String path) async {
    final cached = _stateFiles[path];
    if (cached != null) return cached;
    final file = File(p.join((await _demoDir()).path, 'state.json'));
    if (!file.existsSync()) return null;
    return file.readAsString();
  }

  @override
  Future<void> writeAppStateFile(String path, String content) async {
    _stateFiles[path] = content;
    final file = File(p.join((await _demoDir()).path, 'state.json'));
    await file.writeAsString(content);
    Log.d('demo', '演示网盘已保存状态文件（${content.length} 字节）');
  }

  // ------------------------------------------------------------ 音频生成

  Future<Directory> _demoDir() async {
    final base = await getApplicationSupportDirectory();
    final dir = Directory(p.join(base.path, 'demo'));
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir;
  }

  /// 按需生成章节音频，已生成过就直接复用。
  ///
  /// 生成一段 40 秒的 PCM 要跑近百万次三角函数——放在主 isolate 会把 UI 卡死
  /// （实测「加入书架」时 Choreographer 报 Skipped 153 frames）。用 compute
  /// 丢到后台 isolate，界面就能一直转着 loading 而不是假死。
  Future<File> _ensureAudio(_Node node) async {
    final file = File(p.join((await _demoDir()).path, '${node.fsId}.wav'));
    if (file.existsSync() && file.lengthSync() > 44) return file;

    // 每章一个不同音高，切章时能立刻听出来换了。
    // 用 fs_id 的数值而不是 hashCode——后者在相邻 id 上会撞，
    // 撞了就听不出换章，演示效果打折。
    final semitone = (int.tryParse(node.fsId) ?? 0) % 12;
    final freq = 220.0 * math.pow(2, semitone / 12);
    await file.writeAsBytes(await compute(_buildWav, freq));
    Log.d('demo', '已生成演示音频：${node.name}（${freq.toStringAsFixed(1)} Hz）');
    return file;
  }

  /// 生成一段单声道 16-bit PCM 的 WAV。
  ///
  /// 不是纯音——每两秒有一次短促的「嘀」，这样即使音量小也能听出播放在推进，
  /// 拖动进度条和倍速的效果都能分辨出来。
  ///
  /// 顶层函数（而非实例方法），因为 compute 只能跑不捕获 this 的函数。
  static Uint8List _buildWav(double freq) {
    const totalSamples = _sampleRate * chapterSeconds;
    final data = BytesBuilder();

    for (var i = 0; i < totalSamples; i++) {
      final t = i / _sampleRate;
      // 每 2 秒响 0.15 秒
      final inBeep = (t % 2.0) < 0.15;
      final envelope = inBeep ? 0.35 : 0.06;
      final sample = math.sin(2 * math.pi * freq * t) * envelope;
      final value = (sample * 32767).round().clamp(-32768, 32767);
      data.addByte(value & 0xff);
      data.addByte((value >> 8) & 0xff);
    }

    final pcm = data.takeBytes();
    return _wrapWavHeader(pcm);
  }

  static Uint8List _wrapWavHeader(Uint8List pcm) {
    const channels = 1;
    const bitsPerSample = 16;
    const byteRate = _sampleRate * channels * bitsPerSample ~/ 8;
    const blockAlign = channels * bitsPerSample ~/ 8;

    final header = BytesBuilder();
    void ascii(String s) => header.add(s.codeUnits);
    void u32(int v) => header.add([
          v & 0xff,
          (v >> 8) & 0xff,
          (v >> 16) & 0xff,
          (v >> 24) & 0xff,
        ]);
    void u16(int v) => header.add([v & 0xff, (v >> 8) & 0xff]);

    ascii('RIFF');
    u32(36 + pcm.length);
    ascii('WAVE');
    ascii('fmt ');
    u32(16); // PCM 格式块大小
    u16(1); // PCM
    u16(channels);
    u32(_sampleRate);
    u32(byteRate);
    u16(blockAlign);
    u16(bitsPerSample);
    ascii('data');
    u32(pcm.length);

    return Uint8List.fromList([...header.takeBytes(), ...pcm]);
  }

  _Node? _find(String fsId) {
    for (final nodes in _tree.values) {
      for (final n in nodes) {
        if (n.fsId == fsId) return n;
      }
    }
    return null;
  }
}

class _Node {
  _Node.dir(this.path)
      : fsId = 'dir-${path.hashCode}',
        isDirectory = true,
        size = 0;

  _Node.file(this.path, int id, {bool isImage = false})
      : fsId = '$id',
        isDirectory = false,
        // 音频给一个像样的体积，界面上显示出来才不违和
        size = isImage ? 180 * 1024 : 22050 * 2 * DemoDriveSource.chapterSeconds + 44;

  final String path;
  final String fsId;
  final bool isDirectory;
  final int size;

  String get name => path.split('/').last;

  DriveEntry toEntry() => DriveEntry(
        fsId: fsId,
        path: path,
        name: name,
        isDirectory: isDirectory,
        size: size,
      );
}
