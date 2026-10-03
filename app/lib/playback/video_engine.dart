import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';
import 'package:yun_audiobook/data/drive/cloud_drive_source.dart';
import 'package:yun_audiobook/playback/media_engine.dart';

/// 视频内核：video_player（Android 上是 ExoPlayer）。
///
/// 选它而不是 media_kit：后者带一整套 libmpv，安装包要多十几 MB，
/// 会超过 jsDelivr 单文件 20MB 上限，国内更新线路就断了（add-video-courses）。
class VideoEngine implements MediaEngine {
  /// 当前的播放器。界面拿它画画面；换一课时会换成新的实例。
  final controller = ValueNotifier<VideoPlayerController?>(null);

  final _snapshots = StreamController<EngineSnapshot>.broadcast();
  final _completed = StreamController<void>.broadcast();
  final _errors = StreamController<Object>.broadcast();

  /// 每次 load 加一。上一次的初始化晚到（比如被会话的 30 秒超时放弃后才完成）
  /// 时据此丢弃，不能把新一课的播放器顶掉。
  int _gen = 0;
  bool _completedFired = false;
  String? _lastError;

  /// 每课一个新的播放器实例，倍速得自己记着、加载后补上，否则每换一课都回到 1.0x。
  double _speed = 1;

  @override
  Stream<EngineSnapshot> get snapshots => _snapshots.stream;

  @override
  Stream<void> get completed => _completed.stream;

  @override
  Stream<Object> get errors => _errors.stream;

  @override
  EngineSnapshot get current {
    final c = controller.value;
    if (c == null) return EngineSnapshot.initial;
    final v = c.value;
    final atEnd = v.isInitialized &&
        v.duration > Duration.zero &&
        v.position >= v.duration &&
        !v.isPlaying;
    return EngineSnapshot(
      playing: v.isPlaying,
      state: !v.isInitialized
          ? EngineState.loading
          : atEnd
              ? EngineState.completed
              : v.isBuffering
                  ? EngineState.buffering
                  : EngineState.ready,
      position: v.position,
      buffered: v.buffered.fold<Duration>(
        Duration.zero,
        (max, r) => r.end > max ? r.end : max,
      ),
      duration: v.isInitialized ? v.duration : null,
      speed: v.playbackSpeed,
    );
  }

  @override
  Future<void> load(
    ResolvedMedia media, {
    Duration initialPosition = Duration.zero,
  }) async {
    final gen = ++_gen;
    final previous = controller.value;
    controller.value = null;
    previous?.removeListener(_onValue);
    unawaited(previous?.dispose());

    final next = VideoPlayerController.networkUrl(
      Uri.parse(media.url),
      // 播放列表是本地 file:// 的 .m3u8，没有扩展名推断时也要明确告诉它是 HLS
      formatHint: media.kind == StreamKind.hls ? VideoFormat.hls : null,
      httpHeaders: media.headers,
      // 退到后台声音继续：课程常被当音频听（add-video-courses「后台听课」）
      videoPlayerOptions: VideoPlayerOptions(allowBackgroundPlayback: true),
    );
    try {
      await next.initialize();
      if (initialPosition > Duration.zero) await next.seekTo(initialPosition);
      if (_speed != 1) await next.setPlaybackSpeed(_speed);
    } on Object {
      unawaited(next.dispose());
      rethrow;
    }
    if (gen != _gen) {
      unawaited(next.dispose());
      return;
    }
    _completedFired = false;
    _lastError = null;
    next.addListener(_onValue);
    controller.value = next;
    _onValue();
  }

  void _onValue() {
    final c = controller.value;
    if (c == null || _snapshots.isClosed) return;
    final v = c.value;
    if (v.hasError && v.errorDescription != _lastError) {
      _lastError = v.errorDescription;
      _errors.add(StateError('视频播放出错：${v.errorDescription}'));
    }
    final snap = current;
    _snapshots.add(snap);
    // video_player 没有「播完」事件，按位置到头且停下来判定，只报一次
    if (snap.state == EngineState.completed && !_completedFired) {
      _completedFired = true;
      _completed.add(null);
    }
  }

  @override
  Future<void> play() async {
    final c = controller.value;
    if (c == null) return;
    _completedFired = false;
    await c.play();
  }

  @override
  Future<void> pause() async => controller.value?.pause();

  @override
  Future<void> stop() async => controller.value?.pause();

  @override
  Future<void> seek(Duration position) async {
    _completedFired = false;
    await controller.value?.seekTo(position);
  }

  @override
  Future<void> setSpeed(double speed) async {
    _speed = speed;
    await controller.value?.setPlaybackSpeed(speed);
  }

  @override
  Future<void> dispose() async {
    _gen++;
    final c = controller.value;
    controller.value = null;
    c?.removeListener(_onValue);
    await c?.dispose();
    controller.dispose();
    await _snapshots.close();
    await _completed.close();
    await _errors.close();
  }
}
