import 'dart:async';

import 'package:yun_audiobook/data/drive/cloud_drive_source.dart';
import 'package:yun_audiobook/domain/entities.dart';
import 'package:yun_audiobook/playback/media_engine.dart';

/// 音频内核 + 视频内核组合成一个 [MediaEngine]（add-video-courses D2）。
///
/// 按每次 load 的媒体类型切到对应内核，只转发「当前内核」的事件；切走时
/// 先停下另一个。PlaybackSession 因此完全不感知视频——进度、恢复、看门狗、
/// 睡眠定时对两种媒体是同一套逻辑。
class CompositeEngine implements MediaEngine {
  CompositeEngine({required this.audio, required this.video})
      : _active = audio {
    for (final e in [audio, video]) {
      _subs.addAll([
        e.snapshots.listen((s) {
          if (identical(e, _active)) _snapshots.add(s);
        }),
        e.completed.listen((_) {
          if (identical(e, _active)) _completed.add(null);
        }),
        e.errors.listen((err) {
          if (identical(e, _active)) _errors.add(err);
        }),
      ]);
    }
  }

  final MediaEngine audio;
  final MediaEngine video;
  MediaEngine _active;

  final _subs = <StreamSubscription<Object?>>[];
  final _snapshots = StreamController<EngineSnapshot>.broadcast(sync: true);
  final _completed = StreamController<void>.broadcast(sync: true);
  final _errors = StreamController<Object>.broadcast(sync: true);

  MediaEngine get active => _active;

  @override
  EngineSnapshot get current => _active.current;

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
    final target = media.mediaKind == MediaKind.video ? video : audio;
    if (!identical(target, _active)) {
      final previous = _active;
      // 先切换再停旧的：旧内核停下时报的 playing=false 不该再转发出去
      _active = target;
      await previous.pause();
    }
    await target.load(media, initialPosition: initialPosition);
  }

  @override
  Future<void> play() => _active.play();

  @override
  Future<void> pause() => _active.pause();

  @override
  Future<void> stop() => _active.stop();

  @override
  Future<void> seek(Duration position) => _active.seek(position);

  @override
  Future<void> setSpeed(double speed) async {
    // 两个都设：切到另一种媒体时倍速保持一致
    await audio.setSpeed(speed);
    await video.setSpeed(speed);
  }

  @override
  Future<void> dispose() async {
    for (final s in _subs) {
      await s.cancel();
    }
    await audio.dispose();
    await video.dispose();
    await _snapshots.close();
    await _completed.close();
    await _errors.close();
  }
}
