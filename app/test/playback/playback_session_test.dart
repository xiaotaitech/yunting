import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yun_audiobook/core/errors.dart';
import 'package:yun_audiobook/domain/entities.dart';
import 'package:yun_audiobook/playback/media_engine.dart';
import 'package:yun_audiobook/playback/playback_session.dart';
import 'package:yun_audiobook/playback/playback_url_resolver.dart';

import '../support/playback_fakes.dart';

Series series({bool finished = false, int index = 1, int posMs = 12000}) =>
    Series(
      id: 's1',
      folderPath: '/书',
      title: '三体',
      addedAt: DateTime(2026),
      updatedAt: DateTime(2026),
      episodeCount: 3,
      currentEpisodeIndex: index,
      currentPositionMs: posMs,
      finished: finished,
    );

List<Episode> episodes() => [
      for (var i = 0; i < 3; i++)
        Episode(
          id: 's1-ch$i',
          seriesId: 's1',
          fsId: 'fs$i',
          path: '/书/$i.mp3',
          title: '第${i + 1}章',
          fileName: '$i.mp3',
          size: 100,
          orderIndex: i,
        ),
    ];

void main() {
  late FakeEngine engine;
  late FakeDrive drive;
  late RecordingSink sink;
  late PlaybackSession session;

  void setUpSession() {
    engine = FakeEngine();
    drive = FakeDrive();
    sink = RecordingSink();
    session = PlaybackSession(
      engine: engine,
      resolver: PlaybackUrlResolver(drive),
      sink: sink,
    );
  }

  group('开始播放', () {
    test('同步切到新的一集，加载完成后自动播放，从断点开始', () {
      fakeAsync((async) {
        setUpSession();
        engine.pendingLoad = Completer();
        unawaited(session.start(series(), episodes()));

        // 第一个 await 之前状态已经就位：界面可以立刻进播放页
        expect(session.current.series?.id, 's1');
        expect(session.current.index, 1);
        async.flushMicrotasks();
        expect(session.current.preparing, isTrue);
        expect(session.current.position, const Duration(seconds: 12));
        expect(engine.playCalls, 0);

        engine.pendingLoad!.complete();
        async.flushMicrotasks();
        expect(session.current.preparing, isFalse);
        expect(engine.loads.single.at, const Duration(seconds: 12));
        expect(engine.playCalls, 1);
      });
    });

    test('准备中按暂停：加载完成后不自动播放', () {
      fakeAsync((async) {
        setUpSession();
        engine.pendingLoad = Completer();
        unawaited(session.start(series(), episodes()));
        async.flushMicrotasks();
        unawaited(session.pause());
        engine.pendingLoad!.complete();
        async.flushMicrotasks();
        expect(engine.playCalls, 0);
      });
    });

    test('已听完的合集不指定集数时从第一集开头重来', () {
      fakeAsync((async) {
        setUpSession();
        unawaited(session.start(series(finished: true), episodes()));
        async.flushMicrotasks();
        expect(session.current.index, 0);
        expect(engine.loads.single.at, Duration.zero);
      });
    });

    test('连点两个：前一个晚到的加载作废，不会把后一个顶掉', () {
      fakeAsync((async) {
        setUpSession();
        final first = Completer<void>();
        engine.pendingLoad = first;
        unawaited(session.start(series(), episodes(), episodeIndex: 0));
        async.flushMicrotasks();

        engine.pendingLoad = null;
        unawaited(session.start(series(), episodes(), episodeIndex: 2));
        async.flushMicrotasks();
        expect(engine.playCalls, 1);

        first.complete();
        async.flushMicrotasks();
        expect(session.current.index, 2);
        expect(engine.playCalls, 1, reason: '第一次的加载晚到，不能再触发一次播放');
      });
    });

    test('准备期间不写进度（播放器里还是上一段）', () {
      fakeAsync((async) {
        setUpSession();
        unawaited(session.start(series(), episodes(), episodeIndex: 0));
        async.flushMicrotasks();
        sink.progress_.clear();

        engine.pendingLoad = Completer();
        unawaited(session.playAt(2));
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 10));
        engine.emit(position: const Duration(minutes: 40));
        async.flushMicrotasks();
        expect(sink.progress_, isEmpty);
      });
    });
  });

  group('加载超时与恢复', () {
    test('加载 30 秒没返回：进入恢复，重取地址后从原位置续播', () {
      fakeAsync((async) {
        setUpSession();
        engine.pendingLoad = Completer();
        unawaited(session.start(series(), episodes()));
        async.flushMicrotasks();
        engine.pendingLoad = null;

        async.elapse(PlaybackSession.loadTimeout);
        async.elapse(const Duration(milliseconds: 400));
        expect(engine.loads, hasLength(2));
        expect(engine.loads.last.at, const Duration(seconds: 12));
        expect(engine.loads.last.url, isNot(engine.loads.first.url));
        expect(engine.playCalls, 1);
      });
    });

    test('播放中链接失效：重取地址，回到中断位置', () {
      fakeAsync((async) {
        setUpSession();
        unawaited(session.start(series(), episodes()));
        async.flushMicrotasks();
        engine
          ..emit(position: const Duration(minutes: 12, seconds: 30))
          ..error(const DriveException(DriveErrorKind.linkExpired, '403'));
        async.elapse(const Duration(milliseconds: 400));
        expect(engine.loads.last.at, const Duration(minutes: 12, seconds: 30));
        expect(drive.current, 2);
      });
    });

    test('连续失败：指数退避 4 次后暂停并报可重试', () {
      fakeAsync((async) {
        setUpSession();
        final failures = <PlaybackFailure>[];
        session.failures.listen(failures.add);
        unawaited(session.start(series(), episodes()));
        async.flushMicrotasks();

        engine.failLoads.addAll([true, true, true, true]);
        engine.error(StateError('stream died'));
        async.elapse(const Duration(milliseconds: 400 + 800 + 1600 + 3199));
        expect(failures, isEmpty, reason: '第 4 次退避还没到');
        async.elapse(const Duration(milliseconds: 1));
        expect(engine.loads, hasLength(5));
        expect(failures.single.kind, isNull);
        expect(failures.single.canRetry, isTrue);
        expect(engine.current.playing, isFalse);
      });
    });

    test('鉴权失败不重试：通知退出登录，报不可重试', () {
      fakeAsync((async) {
        setUpSession();
        final failures = <PlaybackFailure>[];
        session.failures.listen(failures.add);
        unawaited(session.start(series(), episodes()));
        async.flushMicrotasks();

        drive.errors.add(
          const DriveException(DriveErrorKind.authExpired, 'errno=111'),
        );
        engine.error(StateError('403'));
        async.elapse(const Duration(seconds: 10));
        expect(sink.authFailures, 1);
        expect(failures.single.canRetry, isFalse);
        expect(drive.current, 2, reason: '只试了一次，没有继续退避');
      });
    });
  });

  group('卡死看门狗', () {
    test('自称在播但缓冲 25 秒不涨：走恢复', () {
      fakeAsync((async) {
        setUpSession();
        unawaited(session.start(series(), episodes()));
        async.flushMicrotasks();
        engine.emit(state: EngineState.buffering, buffered: Duration.zero);

        async.elapse(const Duration(seconds: 25));
        expect(drive.current, 1);
        async.elapse(const Duration(seconds: 5));
        async.elapse(const Duration(milliseconds: 400));
        expect(drive.current, 2);
      });
    });

    test('缓冲在涨（只是慢）：不算卡死', () {
      fakeAsync((async) {
        setUpSession();
        unawaited(session.start(series(), episodes()));
        async.flushMicrotasks();
        engine.emit(state: EngineState.buffering);
        for (var i = 1; i <= 12; i++) {
          async.elapse(const Duration(seconds: 5));
          engine.emit(buffered: Duration(seconds: i));
        }
        expect(drive.current, 1);
      });
    });
  });

  test('一分钟内缓冲 4 次：提示一次弱网', () {
    fakeAsync((async) {
      setUpSession();
      final hints = <PlaybackHint>[];
      session.hints.listen(hints.add);
      unawaited(session.start(series(), episodes()));
      async.flushMicrotasks();
      for (var i = 0; i < 6; i++) {
        engine
          ..emit(state: EngineState.buffering, buffered: Duration(seconds: i))
          ..emit(state: EngineState.ready);
        async.elapse(const Duration(seconds: 5));
      }
      expect(hints, [PlaybackHint.slowNetwork]);
    });
  });

  test('进度每 5 秒最多写一次', () {
    fakeAsync((async) {
      setUpSession();
      unawaited(session.start(series(), episodes()));
      async.flushMicrotasks();
      sink.progress_.clear();
      for (var i = 1; i <= 12; i++) {
        async.elapse(const Duration(seconds: 1));
        engine.emit(position: Duration(seconds: 12 + i));
      }
      async.flushMicrotasks();
      expect(sink.progress_.length, inInclusiveRange(2, 3));
    });
  });

  group('一集结束', () {
    test('先上报「播完」，再自动续下一集', () {
      fakeAsync((async) {
        setUpSession();
        unawaited(session.start(series(), episodes(), episodeIndex: 0));
        async.flushMicrotasks();
        engine.complete();
        async.flushMicrotasks();
        expect(
          sink.progress_
              .firstWhere((p) => p['episodeFinished'] == true)['index'],
          0,
        );
        expect(session.current.index, 1);
        expect(engine.loads.last.at, Duration.zero);
      });
    });

    test('「播完本集停止」优先于自动续播', () {
      fakeAsync((async) {
        setUpSession();
        unawaited(session.start(series(), episodes(), episodeIndex: 0));
        async.flushMicrotasks();
        session.sleepTimer.startEndOfChapter();
        engine.complete();
        async.flushMicrotasks();
        expect(session.current.index, 0);
        expect(engine.current.playing, isFalse);
      });
    });

    test('最后一集播完：标记整个合集已听完', () {
      fakeAsync((async) {
        setUpSession();
        unawaited(session.start(series(), episodes(), episodeIndex: 2));
        async.flushMicrotasks();
        engine.complete();
        async.flushMicrotasks();
        expect(sink.progress_.any((p) => p['finished'] == true), isTrue);
      });
    });
  });

  test('播放器报出时长：记进条目并写库一次；准备中报的不算', () {
    fakeAsync((async) {
      setUpSession();
      unawaited(session.start(series(), episodes(), episodeIndex: 0));
      async.flushMicrotasks();
      engine
        ..emit(duration: const Duration(minutes: 30))
        ..emit(duration: const Duration(minutes: 30));
      expect(sink.durations, {'s1-ch0': 1800000});
      expect(session.current.duration, const Duration(minutes: 30));

      engine.pendingLoad = Completer();
      unawaited(session.playAt(1));
      async.flushMicrotasks();
      engine.emit(duration: const Duration(minutes: 31));
      expect(sink.durations.containsKey('s1-ch1'), isFalse);
    });
  });
}
