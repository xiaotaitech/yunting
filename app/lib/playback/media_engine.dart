import 'package:yun_audiobook/data/drive/cloud_drive_source.dart';

/// 播放器内核的处理状态。与 just_audio 的 ProcessingState 一一对应，
/// 但不依赖它——视频引擎（add-video-courses）要实现同一套接口。
enum EngineState { idle, loading, buffering, ready, completed }

/// 内核某一时刻的状态。
class EngineSnapshot {
  const EngineSnapshot({
    this.playing = false,
    this.state = EngineState.idle,
    this.position = Duration.zero,
    this.buffered = Duration.zero,
    this.duration,
    this.speed = 1.0,
  });

  final bool playing;
  final EngineState state;
  final Duration position;
  final Duration buffered;
  final Duration? duration;
  final double speed;

  static const initial = EngineSnapshot();
}

/// 播放器内核接口（refactor-app-foundation D6）。
///
/// PlaybackSession 只通过它驱动播放器，所以会话逻辑可以用假内核精确测试，
/// 音频与视频也只是两种实现。
abstract interface class MediaEngine {
  /// 当前状态。
  EngineSnapshot get current;

  /// 任何字段变化都推一条（位置变化约 200ms 一次）。
  Stream<EngineSnapshot> get snapshots;

  /// 当前媒体自然播完。
  Stream<void> get completed;

  /// 播放过程中的错误（流中断、链接失效等）。
  Stream<Object> get errors;

  /// 加载媒体并定位到 [initialPosition]。
  ///
  /// **可能永久挂住**（流迟迟不给数据时 just_audio 就会），
  /// 超时由调用方负责，见 PlaybackSession.loadTimeout。
  Future<void> load(ResolvedMedia media, {Duration initialPosition});

  /// 开始播放。just_audio 的实现要到暂停或播完才返回——**调用方绝不能 await**，
  /// 否则开播、切章、恢复流程都会被挂住。
  Future<void> play();

  Future<void> pause();

  Future<void> stop();

  Future<void> seek(Duration position);

  Future<void> setSpeed(double speed);

  Future<void> dispose();
}
