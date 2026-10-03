import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:yun_audiobook/core/logging.dart';
import 'package:yun_audiobook/playback/media_engine.dart';
import 'package:yun_audiobook/playback/playback_session.dart';

/// 系统媒体通知 / 锁屏 / 耳机按键 与 [PlaybackSession] 之间的桥。
///
/// 只做两件事：把系统发来的操作转给会话；把会话状态映射成
/// audio_service 的 PlaybackState 与 MediaItem。业务逻辑一行不放这里。
class AudioServiceBridge extends BaseAudioHandler with SeekHandler {
  AudioServiceBridge(this.session) {
    _sub = session.states.listen(_publish);
    _publish(session.current);
  }

  final PlaybackSession session;
  late final StreamSubscription<PlaybackSnapshot> _sub;

  bool _pausedByInterruption = false;

  /// 中断结束后是否自动恢复播放，由设置页控制。
  bool resumeAfterInterruption = true;

  Future<void> configureAudioSession() async {
    final audio = await AudioSession.instance;
    await audio.configure(const AudioSessionConfiguration.speech());

    // 耳机拔出 / 蓝牙断开自动暂停（规格「耳机拔出」）
    audio.becomingNoisyEventStream.listen((_) {
      Log.d('player', '音频输出被拔出，自动暂停');
      unawaited(session.pause());
    });

    // 音频焦点：来电等场景暂停，归还后恢复（规格「音频焦点处理」）
    audio.interruptionEventStream.listen((event) {
      if (event.begin) {
        if (session.current.engine.playing) {
          _pausedByInterruption = true;
          unawaited(session.pause());
        }
      } else if (_pausedByInterruption) {
        _pausedByInterruption = false;
        if (resumeAfterInterruption) unawaited(session.play());
      }
    });
  }

  void _publish(PlaybackSnapshot s) {
    final series = s.series;
    final episode = s.episode;
    if (series != null && episode != null) {
      // 通知栏与锁屏展示的条目。准备中就发出新的一集：标题、封面立刻换过来，
      // 而不是停在上一集不动；库里存过时长就先用上，进度条不用等加载完才出现。
      final item = MediaItem(
        id: episode.id,
        album: series.title,
        title: episode.title,
        artist: series.author,
        duration: s.duration,
        artUri: series.coverLocalPath == null
            ? null
            : Uri.file(series.coverLocalPath!),
        extras: {'seriesId': series.id, 'episodeIndex': s.index},
      );
      // 内容不变时不重复推：否则通知栏会随位置变化每 200ms 刷一次。
      // MediaItem 的 == 只比 id，时长回填、改名这类变化要逐字段比。
      final prev = mediaItem.valueOrNull;
      if (prev == null ||
          prev.id != item.id ||
          prev.duration != item.duration ||
          prev.title != item.title ||
          prev.album != item.album ||
          prev.artUri != item.artUri) {
        mediaItem.add(item);
      }
    }

    final e = s.engine;
    playbackState.add(
      PlaybackState(
        controls: [
          MediaControl.skipToPrevious,
          if (s.playing) MediaControl.pause else MediaControl.play,
          MediaControl.skipToNext,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
          MediaAction.setSpeed,
        },
        androidCompactActionIndices: const [0, 1, 2],
        processingState: s.preparing
            ? AudioProcessingState.loading
            : switch (e.state) {
                EngineState.idle => AudioProcessingState.idle,
                EngineState.loading => AudioProcessingState.loading,
                EngineState.buffering => AudioProcessingState.buffering,
                EngineState.ready => AudioProcessingState.ready,
                EngineState.completed => AudioProcessingState.completed,
              },
        playing: e.playing,
        updatePosition: e.position,
        bufferedPosition: e.buffered,
        speed: e.speed,
        queueIndex: s.index,
      ),
    );
  }

  @override
  Future<void> play() => session.play();

  @override
  Future<void> pause() => session.pause();

  @override
  Future<void> stop() async {
    await session.stop();
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) => session.seek(position);

  @override
  Future<void> setSpeed(double speed) => session.setSpeed(speed);

  @override
  Future<void> skipToNext() => session.next();

  @override
  Future<void> skipToPrevious() => session.previous();

  @override
  Future<void> fastForward() => session.forward();

  @override
  Future<void> rewind() => session.rewind();

  Future<void> dispose() => _sub.cancel();
}
