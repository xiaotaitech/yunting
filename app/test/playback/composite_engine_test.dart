import 'package:flutter_test/flutter_test.dart';
import 'package:yun_audiobook/data/drive/cloud_drive_source.dart';
import 'package:yun_audiobook/domain/entities.dart';
import 'package:yun_audiobook/playback/composite_engine.dart';
import 'package:yun_audiobook/playback/media_engine.dart';

import '../support/playback_fakes.dart';

ResolvedMedia media(MediaKind kind) => ResolvedMedia(
      url: 'file:///x',
      isLocal: false,
      expiresAt: DateTime(2100),
      mediaKind: kind,
    );

void main() {
  late FakeEngine audio;
  late FakeEngine video;
  late FakeEngine localAudio;
  late CompositeEngine engine;
  late List<EngineSnapshot> seen;
  late int completions;

  setUp(() {
    audio = FakeEngine();
    video = FakeEngine();
    localAudio = FakeEngine();
    engine =
        CompositeEngine(audio: audio, video: video, localAudio: localAudio);
    seen = [];
    completions = 0;
    engine.snapshots.listen(seen.add);
    engine.completed.listen((_) => completions++);
  });

  test('按媒体类型切内核', () async {
    await engine.load(media(MediaKind.video));
    expect(video.loads, hasLength(1));
    expect(audio.loads, isEmpty);
    expect(identical(engine.active, video), isTrue);

    await engine.load(media(MediaKind.audio));
    expect(audio.loads, hasLength(1));
    expect(identical(engine.active, audio), isTrue);
  });

  test('切走时停下原来的内核，免得两个同时响', () async {
    await engine.load(media(MediaKind.audio));
    await engine.play();
    await engine.load(media(MediaKind.video));
    expect(audio.pauseCalls, 1);
  });

  test('只转发当前内核的事件', () async {
    await engine.load(media(MediaKind.video));
    seen.clear();
    audio
      ..emit(position: const Duration(seconds: 99))
      ..complete();
    expect(seen, isEmpty);
    expect(completions, 0);

    video
      ..emit(position: const Duration(seconds: 5))
      ..complete();
    expect(seen.single.position, const Duration(seconds: 5));
    expect(completions, 1);
  });

  test('传输控制作用在当前内核上', () async {
    await engine.load(media(MediaKind.video));
    await engine.play();
    expect(video.playCalls, 1);
    expect(audio.playCalls, 0);
  });

  test('本机 content:// 音频走不设 UA 的内核（避开 just_audio 的回环代理）', () async {
    await engine.load(
      ResolvedMedia(
        url: 'content://media/external/audio/media/11',
        isLocal: true,
        expiresAt: DateTime(9999),
      ),
    );
    expect(localAudio.loads, hasLength(1));
    expect(audio.loads, isEmpty);
  });
}
