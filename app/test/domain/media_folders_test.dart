import 'package:flutter_test/flutter_test.dart';
import 'package:yun_audiobook/data/drive/cloud_drive_source.dart';
import 'package:yun_audiobook/domain/media_folders.dart';

DriveEntry file(String path, {int size = 100, int? mtime}) => DriveEntry(
      fsId: path,
      path: path,
      name: path.substring(path.lastIndexOf('/') + 1),
      isDirectory: false,
      size: size,
      serverMtime: mtime,
    );

void main() {
  group('按文件夹分组', () {
    test('同一文件夹的文件合成一项，计数与大小累加', () {
      final folders = groupIntoFolders([
        file('/书/三体/1.mp3', size: 10, mtime: 5),
        file('/书/三体/2.mp3', size: 20, mtime: 9),
        file('/书/小王子/1.mp3', size: 7, mtime: 3),
      ]);
      expect(folders.map((f) => f.path), ['/书/三体', '/书/小王子']);
      expect(folders.first.mediaCount, 2);
      expect(folders.first.totalBytes, 30);
      expect(folders.first.latestMtime, 9);
    });

    test('最近更新的排前面：刚传上去的书一进来就能看到', () {
      final folders = groupIntoFolders([
        file('/旧/a.mp3', mtime: 100),
        file('/新/a.mp3', mtime: 900),
        file('/中/a.mp3', mtime: 500),
      ]);
      expect(folders.map((f) => f.name), ['新', '中', '旧']);
    });

    test('根目录下的文件归到「/」，目录项被忽略', () {
      final folders = groupIntoFolders([
        file('/a.mp3'),
        const DriveEntry(
          fsId: 'd',
          path: '/书',
          name: '书',
          isDirectory: true,
          size: 0,
        ),
      ]);
      expect(folders.single.path, '/');
      expect(folders.single.parentPath, '/');
    });

    test('名字与上一级路径', () {
      const f = MediaFolder(path: '/书/三体/卷一', mediaCount: 1, totalBytes: 0);
      expect(f.name, '卷一');
      expect(f.parentPath, '/书/三体');
    });
  });

  group('关键字筛选', () {
    final folders = [
      const MediaFolder(path: '/书/三体/卷一', mediaCount: 1, totalBytes: 0),
      const MediaFolder(path: '/书/三体/卷二', mediaCount: 1, totalBytes: 0),
      const MediaFolder(path: '/英语/Reign S03', mediaCount: 1, totalBytes: 0),
    ];

    test('空关键字返回全部', () {
      expect(filterFolders(folders, '  '), folders);
    });

    test('匹配整条路径：搜合集名能找到它的子卷', () {
      expect(filterFolders(folders, '三体'), hasLength(2));
    });

    test('多个词须全部命中，顺序不限', () {
      expect(
        filterFolders(folders, '卷二 三体').single.path,
        '/书/三体/卷二',
      );
    });

    test('大小写不敏感', () {
      expect(filterFolders(folders, 'reign').single.name, 'Reign S03');
    });
  });
}
