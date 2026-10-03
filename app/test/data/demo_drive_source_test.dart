import 'package:flutter_test/flutter_test.dart';
import 'package:yun_audiobook/core/errors.dart';
import 'package:yun_audiobook/core/natural_sort.dart';
import 'package:yun_audiobook/data/drive/cloud_drive_source.dart';
import 'package:yun_audiobook/data/drive/demo/demo_drive_source.dart';
import 'package:yun_audiobook/data/repositories/library_repository.dart';

void main() {
  late DemoDriveSource drive;

  setUp(() => drive = DemoDriveSource());

  group('演示网盘目录', () {
    test('根目录能列出来', () async {
      final entries = await drive.listDirectory('/');
      expect(entries.map((e) => e.name), contains('我的有声书'));
      expect(entries.every((e) => e.isDirectory), isTrue);
    });

    test('书籍目录里既有音频也有封面图', () async {
      final entries = await drive.listDirectory('/我的有声书/三体');
      final audio = entries.where(LibraryRepository.isMedia).toList();
      final cover = entries.where(LibraryRepository.isCoverImage).toList();

      expect(audio.length, 5);
      expect(cover.single.name, 'cover.jpg');
    });

    test('空目录返回空列表，而不是报错', () async {
      expect(await drive.listDirectory('/我的有声书/未整理'), isEmpty);
    });

    test('不存在的目录抛 notFound', () async {
      await expectLater(
        drive.listDirectory('/不存在'),
        throwsA(
          isA<DriveException>()
              .having((e) => e.kind, 'kind', DriveErrorKind.notFound),
        ),
      );
    });
  });

  group('演示数据能试出自然序', () {
    test('第10章必须排在第2章后面', () async {
      final entries = await drive.listDirectory('/我的有声书/三体');
      final names = entries
          .where(LibraryRepository.isMedia)
          .map((e) => e.name)
          .toList()
        ..sort(compareNatural);

      expect(names.first, startsWith('第1章'));
      expect(names[1], startsWith('第2章'));
      expect(names[2], startsWith('第3章'));
      expect(names[3], startsWith('第10章'));
      expect(names.last, startsWith('第11章'));
    });
  });

  group('演示音频', () {
    test('元数据能按 fs_id 批量取回', () async {
      final entries = await drive.listDirectory('/我的有声书/小王子');
      final ids = entries.map((e) => e.fsId).toList();
      final metas = await drive.fetchMetadata(ids);

      expect(metas.keys.toSet(), ids.toSet());
    });

    test('取不存在的文件抛 notFound', () async {
      await expectLater(
        drive.resolveMedia('999999'),
        throwsA(
          isA<DriveException>()
              .having((e) => e.kind, 'kind', DriveErrorKind.notFound),
        ),
      );
    });
  });

  group('接口契约', () {
    test('实现了 CloudDriveSource，可以直接替换百度实现', () {
      expect(drive, isA<CloudDriveSource>());
      expect(drive.id, 'demo');
    });
  });
}
