import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yun_audiobook/app/providers.dart';
import 'package:yun_audiobook/core/errors.dart';
import 'package:yun_audiobook/data/drive/cloud_drive_source.dart';
import 'package:yun_audiobook/data/local/database.dart';
import 'package:yun_audiobook/data/repositories/library_repository.dart';

DriveEntry entry(String name, {bool dir = false}) => DriveEntry(
      fsId: name,
      path: '/书/$name',
      name: name,
      isDirectory: dir,
      size: 10,
      serverMtime: 1,
    );

/// 只实现 browse 的书库：按调用次数返回不同结果，或直接失败。
class ScriptedLibrary implements LibraryRepository {
  ScriptedLibrary(this.script);

  final List<Object> script;
  int calls = 0;

  @override
  Future<List<DriveEntry>> browse(String path) async {
    final next = script[calls++ % script.length];
    if (next is DriveException) throw next;
    return next as List<DriveEntry>;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
  });
  tearDown(() => db.close());

  ProviderContainer containerWith(LibraryRepository library) {
    final c = ProviderContainer(
      // Riverpod 3 默认自动重试失败的 provider，测试里要立刻看到错误
      retry: (_, __) => null,
      overrides: [
        databaseProvider.overrideWithValue(db),
        libraryRepositoryProvider.overrideWithValue(library),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  group('DriveCacheDao', () {
    test('没缓存过返回 null，空目录返回空列表', () async {
      expect(await db.driveCacheDao.read('dir:/a'), isNull);
      await db.driveCacheDao.write('dir:/a', const []);
      expect(await db.driveCacheDao.read('dir:/a'), isEmpty);
    });

    test('条目往返不丢字段', () async {
      await db.driveCacheDao.write('dir:/书', [entry('三体', dir: true)]);
      final e = (await db.driveCacheDao.read('dir:/书'))!.single;
      expect(
        (e.fsId, e.path, e.name, e.isDirectory, e.size, e.serverMtime),
        ('三体', '/书/三体', '三体', true, 10, 1),
      );
    });

    test('清空', () async {
      await db.driveCacheDao.write('dir:/a', [entry('x')]);
      await db.driveCacheDao.clear();
      expect(await db.driveCacheDao.read('dir:/a'), isNull);
    });
  });

  group('目录浏览先缓存后刷新', () {
    test('首次没缓存：等网盘，并写入缓存', () async {
      final c = containerWith(ScriptedLibrary([
        [entry('a.mp3')],
      ]));
      final list = await c.read(browseProvider('/书').future);
      expect(list.map((e) => e.name), ['a.mp3']);
      expect(await db.driveCacheDao.read('dir:/书'), hasLength(1));
    });

    test('有缓存：立即给缓存，后台刷新后换成新结果', () async {
      await db.driveCacheDao.write('dir:/书', [entry('旧.mp3')]);
      final c = containerWith(ScriptedLibrary([
        [entry('新.mp3')],
      ]));
      final sub = c.listen(browseProvider('/书'), (_, __) {});
      addTearDown(sub.close);
      expect((await c.read(browseProvider('/书').future)).single.name, '旧.mp3');
      await pumpEventQueue();
      expect(c.read(browseProvider('/书')).value!.single.name, '新.mp3');
    });

    test('有缓存时网盘失败：继续显示缓存，不报错', () async {
      await db.driveCacheDao.write('dir:/书', [entry('旧.mp3')]);
      final c = containerWith(ScriptedLibrary([
        const DriveException(DriveErrorKind.network, '断网'),
      ]));
      final sub = c.listen(browseProvider('/书'), (_, __) {});
      addTearDown(sub.close);
      await c.read(browseProvider('/书').future);
      await pumpEventQueue();
      final state = c.read(browseProvider('/书'));
      expect(state.hasError, isFalse);
      expect(state.value!.single.name, '旧.mp3');
      expect(await c.read(browseProvider('/书').notifier).refresh(), isFalse);
    });

    test('没缓存时网盘失败：照常报错', () async {
      final c = containerWith(ScriptedLibrary([
        const DriveException(DriveErrorKind.network, '断网'),
      ]));
      final sub = c.listen(browseProvider('/书'), (_, __) {});
      addTearDown(sub.close);
      await expectLater(
        c.read(browseProvider('/书').future),
        throwsA(isA<DriveException>()),
      );
    });
  });
}
