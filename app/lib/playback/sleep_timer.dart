import 'dart:async';

/// 睡眠定时器（audio-playback 规格「睡眠定时器」）。
///
/// 两种模式：固定时长，以及「播完本章后停止」。
enum SleepTimerMode { off, duration, endOfChapter }

class SleepTimerState {
  const SleepTimerState({
    required this.mode,
    this.remaining,
  });

  final SleepTimerMode mode;
  final Duration? remaining;

  static const off = SleepTimerState(mode: SleepTimerMode.off);

  bool get isActive => mode != SleepTimerMode.off;
}

class SleepTimer {
  SleepTimer(this._onFire);

  final void Function() _onFire;

  Timer? _ticker;
  Duration _remaining = Duration.zero;
  SleepTimerMode _mode = SleepTimerMode.off;

  final _controller = StreamController<SleepTimerState>.broadcast();
  Stream<SleepTimerState> get changes => _controller.stream;

  SleepTimerState get state => SleepTimerState(
        mode: _mode,
        remaining: _mode == SleepTimerMode.duration ? _remaining : null,
      );

  bool get stopsAtChapterEnd => _mode == SleepTimerMode.endOfChapter;

  void startDuration(Duration total) {
    cancel();
    _mode = SleepTimerMode.duration;
    _remaining = total;
    _emit();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      _remaining -= const Duration(seconds: 1);
      if (_remaining <= Duration.zero) {
        cancel();
        _onFire();
      } else {
        _emit();
      }
    });
  }

  void startEndOfChapter() {
    cancel();
    _mode = SleepTimerMode.endOfChapter;
    _emit();
  }

  /// 章节自然结束时由播放控制器调用。返回 true 表示应当停止而非续播。
  bool consumeChapterEnd() {
    if (_mode != SleepTimerMode.endOfChapter) return false;
    cancel();
    return true;
  }

  void cancel() {
    _ticker?.cancel();
    _ticker = null;
    _mode = SleepTimerMode.off;
    _remaining = Duration.zero;
    _emit();
  }

  void _emit() {
    if (!_controller.isClosed) _controller.add(state);
  }

  void dispose() {
    _ticker?.cancel();
    unawaited(_controller.close());
  }
}
