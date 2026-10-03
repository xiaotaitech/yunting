import 'dart:async';

import 'package:just_audio/just_audio.dart';
import 'package:yun_audiobook/core/config.dart';
import 'package:yun_audiobook/data/drive/cloud_drive_source.dart';
import 'package:yun_audiobook/playback/media_engine.dart';

/// 音频内核：just_audio（ExoPlayer / AVPlayer）。
class JustAudioEngine implements MediaEngine {
  JustAudioEngine()
      // UA 在这里设一次就够，而且必须在这里设：
      // 百度对 dlink 的 Range 请求校验 UA，而流播全程都是 Range。
      //
      // 刻意不给 AudioSource 传 headers——那会让 just_audio 起一个本地回环 HTTP
      // 代理来注入请求头，而 Android 9+ 默认禁明文，直接报
      // 「Cleartext HTTP traffic not permitted」播不出声。
      // UA 已经由 userAgent 参数走 ExoPlayer 原生通道设好了，headers 是多余的。
      : _player = AudioPlayer(userAgent: AppConfig.panUserAgent) {
    _subs.addAll([
      _player.playbackEventStream.listen(
        (_) => _emit(),
        onError: (Object e, StackTrace _) => _errors.add(e),
      ),
      _player.playingStream.listen((_) => _emit()),
      _player.positionStream.listen((_) => _emit()),
      _player.durationStream.listen((_) => _emit()),
      _player.processingStateStream.listen((s) {
        _emit();
        if (s == ProcessingState.completed) _completed.add(null);
      }),
    ]);
  }

  final AudioPlayer _player;
  final _subs = <StreamSubscription<Object?>>[];
  final _snapshots = StreamController<EngineSnapshot>.broadcast();
  final _completed = StreamController<void>.broadcast();
  final _errors = StreamController<Object>.broadcast();

  void _emit() {
    if (!_snapshots.isClosed) _snapshots.add(current);
  }

  @override
  EngineSnapshot get current => EngineSnapshot(
        playing: _player.playing,
        state: switch (_player.processingState) {
          ProcessingState.idle => EngineState.idle,
          ProcessingState.loading => EngineState.loading,
          ProcessingState.buffering => EngineState.buffering,
          ProcessingState.ready => EngineState.ready,
          ProcessingState.completed => EngineState.completed,
        },
        position: _player.position,
        buffered: _player.bufferedPosition,
        duration: _player.duration,
        speed: _player.speed,
      );

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
  }) =>
      _player.setAudioSource(
        AudioSource.uri(Uri.parse(media.url)),
        initialPosition: initialPosition,
      );

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> setSpeed(double speed) => _player.setSpeed(speed);

  @override
  Future<void> dispose() async {
    for (final s in _subs) {
      await s.cancel();
    }
    await _snapshots.close();
    await _completed.close();
    await _errors.close();
    await _player.dispose();
  }
}
