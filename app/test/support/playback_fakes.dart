import 'dart:async';

import 'package:yun_audiobook/core/errors.dart';
import 'package:yun_audiobook/data/drive/cloud_drive_source.dart';
import 'package:yun_audiobook/playback/media_engine.dart';
import 'package:yun_audiobook/playback/playback_session.dart';

/// 可精确驱动的假内核：加载何时完成、何时报状态都由测试决定。
class FakeEngine implements MediaEngine {
  final _snapshots = StreamController<EngineSnapshot>.broadcast(sync: true);
  final _completed = StreamController<void>.broadcast(sync: true);
  final _errors = StreamController<Object>.broadcast(sync: true);

  EngineSnapshot _current = EngineSnapshot.initial;
  final loads = <({String url, Duration at})>[];
  int playCalls = 0;
  int pauseCalls = 0;

  /// 不为 null 时，load 挂在这个 completer 上，直到测试完成它。
  Completer<void>? pendingLoad;

  /// 依次消费：true 表示这次 load 抛错。
  final failLoads = <bool>[];

  void emit({
    bool? playing,
    EngineState? state,
    Duration? position,
    Duration? buffered,
    Duration? duration,
  }) {
    _current = EngineSnapshot(
      playing: playing ?? _current.playing,
      state: state ?? _current.state,
      position: position ?? _current.position,
      buffered: buffered ?? _current.buffered,
      duration: duration ?? _current.duration,
      speed: _current.speed,
    );
    _snapshots.add(_current);
  }

  void complete() => _completed.add(null);
  void error(Object e) => _errors.add(e);

  @override
  EngineSnapshot get current => _current;
  @override
  Stream<EngineSnapshot> get snapshots => _snapshots.stream;
  @override
  Stream<void> get completed => _completed.stream;
  @override
  Stream<Object> get errors => _errors.stream;

  @override
  Future<void> load(
    ResolvedMedia media, {
    Duration initialPosition = Duration.zero,
  }) async {
    loads.add((url: media.url, at: initialPosition));
    if (failLoads.isNotEmpty && failLoads.removeAt(0)) {
      throw const DriveException(DriveErrorKind.linkExpired, 'boom');
    }
    final p = pendingLoad;
    if (p != null) await p.future;
    _current = EngineSnapshot(
      state: EngineState.ready,
      position: initialPosition,
      speed: _current.speed,
    );
  }

  @override
  Future<void> play() async {
    playCalls++;
    emit(playing: true);
  }

  @override
  Future<void> pause() async {
    pauseCalls++;
    emit(playing: false);
  }

  @override
  Future<void> stop() async => emit(playing: false);
  @override
  Future<void> seek(Duration position) async => emit(position: position);
  @override
  Future<void> setSpeed(double speed) async {}
  @override
  Future<void> dispose() async {}
}

/// 只实现 resolveMedia 的假网盘；可注入错误。
class FakeDrive implements CloudDriveSource {
  int resolves = 0;
  final byFsId = <String, int>{};
  final errors = <DriveException?>[];

  /// 当前这一集（fs1）被解析了几次。不含预取下一集那一次。
  int get current => byFsId['fs1'] ?? 0;

  @override
  Future<ResolvedMedia> resolveMedia(String fsId) async {
    resolves++;
    byFsId[fsId] = (byFsId[fsId] ?? 0) + 1;
    if (errors.isNotEmpty) {
      final e = errors.removeAt(0);
      if (e != null) throw e;
    }
    return ResolvedMedia(
      url: 'https://d.pcs/$fsId?v=$resolves',
      isLocal: false,
      expiresAt: DateTime(2100),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class RecordingSink implements PlaybackSink {
  final progress_ = <Map<String, Object?>>[];
  final durations = <String, int>{};
  int authFailures = 0;

  @override
  Future<void> progress({
    required String seriesId,
    required int episodeIndex,
    required int positionMs,
    bool? finished,
    bool episodeFinished = false,
  }) async =>
      progress_.add({
        'series': seriesId,
        'index': episodeIndex,
        'pos': positionMs,
        'finished': finished,
        'episodeFinished': episodeFinished,
      });

  @override
  Future<void> duration(String episodeId, int durationMs) async =>
      durations[episodeId] = durationMs;

  @override
  Future<void> authFailed() async => authFailures++;
}
