import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yun_audiobook/data/local/database.dart';
import 'package:yun_audiobook/domain/entities.dart';

/// 刷新书架时章节按名字重排、整批重建，章节 id 与序号（`ch$i`）都会变。
///
/// 真机上的表现：hold 往「樊登讲书」目录同步来新的一期，按书名插进中间，
/// 后面每一章序号都往后挪一位——播放历史把正在听的那一章当成新章节，
/// 「最近收听」里同一章出现两条；书的当前章节也指到了别的章上。
///
/// 规则：重建章节时，书的当前章节与历史记录都按文件（fsId）跟到新位置。
void main() {
  late AppDatabase app;

  Episode ep(int index, String name) => Episode(
        id: 'b1-ch$index',
        seriesId: 'b1',
        fsId: 'fs-$name',
        path: '/有声书/樊登/$name.mp3',
        title: name,
        fileName: '$name.mp3',
        size: 100,
        orderIndex: index,
      );

  List<Episode> order(List<String> names) =>
      [for (var i = 0; i < names.length; i++) ep(i, names[i])];

  setUp(() async {
    app = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    await app.seriesDao.upsertSeries(
      Series(
        id: 'b1',
        folderPath: '/有声书/樊登',
        title: '樊登讲书',
        episodeCount: 3,
        addedAt: DateTime.fromMillisecondsSinceEpoch(1000),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(1000),
      ),
    );
    await app.seriesDao.replaceEpisodes('b1', order(['乙', '丙', '丁']));
  });

  tearDown(() => app.close());

  test('前面插进新的一期：书的当前章节跟着文件走', () async {
    await app.seriesDao.updateProgress(
      seriesId: 'b1',
      episodeIndex: 1, // 丙
      positionMs: 30000,
      deviceId: 'd',
    );

    await app.seriesDao.replaceEpisodes('b1', order(['甲', '乙', '丙', '丁']));

    final book = await app.seriesDao.seriesById('b1');
    expect(book!.currentEpisodeIndex, 2);
    expect(book.currentPositionMs, 30000);
  });

  test('前面插进新的一期：同一章继续听仍合并成一条历史', () async {
    await app.historyDao.record(
      seriesId: 'b1',
      episodeIndex: 1, // 丙
      positionMs: 5000,
    );

    await app.seriesDao.replaceEpisodes('b1', order(['甲', '乙', '丙', '丁']));
    // 丙现在是第 2 个
    await app.historyDao.record(
      seriesId: 'b1',
      episodeIndex: 2,
      positionMs: 10000,
    );

    final all = await app.historyDao.recent();
    expect(all.length, 1);
    expect(all.single.episodeTitle, '丙');
    // 点历史要播到丙，不是现在第 1 个的乙
    expect(all.single.episodeIndex, 2);
    expect(all.single.listenedMs, 5000);
  });

  test('按文件查当前序号：播放中刷新后上报以它为准', () async {
    await app.seriesDao.replaceEpisodes('b1', order(['甲', '乙', '丙', '丁']));
    expect(await app.seriesDao.indexOfFile('b1', 'fs-丙'), 2);
    expect(await app.seriesDao.indexOfFile('b1', 'fs-没有'), isNull);
  });

  test('文件从网盘删掉了：历史与进度保持原样，不报错', () async {
    await app.historyDao.record(
      seriesId: 'b1',
      episodeIndex: 0, // 乙
      positionMs: 5000,
    );

    await app.seriesDao.replaceEpisodes('b1', order(['丙', '丁']));

    final all = await app.historyDao.recent();
    expect(all.single.episodeTitle, '乙');
  });
}
