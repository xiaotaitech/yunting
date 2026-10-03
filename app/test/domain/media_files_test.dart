import 'package:flutter_test/flutter_test.dart';
import 'package:yun_audiobook/data/drive/cloud_drive_source.dart';
import 'package:yun_audiobook/domain/entities.dart';
import 'package:yun_audiobook/domain/media_files.dart';

DriveEntry f(String name, {bool dir = false}) => DriveEntry(
      fsId: name,
      path: '/x/$name',
      name: name,
      isDirectory: dir,
      size: 1,
    );

void main() {
  test('按扩展名识别音频与视频，大小写不敏感', () {
    expect(mediaKindOf(f('a.MP3')), MediaKind.audio);
    expect(mediaKindOf(f('E01亮解单词.mp4')), MediaKind.video);
    expect(mediaKindOf(f('lecture.MKV')), MediaKind.video);
    expect(mediaKindOf(f('cover.jpg')), isNull);
    expect(mediaKindOf(f('三体', dir: true)), isNull);
  });

  test('含视频即课程', () {
    expect(
        seriesKindOf([MediaKind.audio, MediaKind.audio]), SeriesKind.audiobook);
    expect(seriesKindOf([MediaKind.audio, MediaKind.video]), SeriesKind.course);
    expect(seriesKindOf(const []), SeriesKind.audiobook);
  });
}
