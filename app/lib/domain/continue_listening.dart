/// 首页续听入口的视图模型（listening-progress 规格「首页续听入口」）。
///
/// 选择逻辑刻意做成纯函数：它有一堆容易搞错的边界（没播过的书、章节没解析、
/// 序号越界），放在 provider 里就只能靠跑真机验证，放在这里能直接单测。
library;

import 'models.dart';

class ContinueListening {
  const ContinueListening({
    required this.book,
    required this.chapter,
    required this.notReadyReason,
  });

  final Book book;

  /// 断点所在的章节。为 null 表示章节还没就位，此时不能播。
  final Chapter? chapter;

  /// 不能播的原因；能播时为 null。展示在卡片上，让用户点之前就知道。
  final String? notReadyReason;

  bool get canPlay => notReadyReason == null;

  /// 章节内的断点位置。
  Duration get position => Duration(milliseconds: book.currentPositionMs);

  /// 已听完的书再点会从第一章开始（AudiobookHandler.openBook 的既有行为），
  /// 卡片要事先说明，而不是让用户点下去才发现回到了开头。
  bool get restartsFromBeginning => book.finished;

  /// 全书维度的进度，与书架卡片同一口径。
  double get bookProgress => book.chapterCount == 0
      ? 0.0
      : ((book.currentChapterIndex + 1) / book.chapterCount).clamp(0.0, 1.0);

  /// 挑出「最近收听」的那本书。
  ///
  /// 不能直接取书架第一本：`BookDao.allBooks` 按
  /// `COALESCE(last_played_at, added_at) DESC` 排序，一本刚加进来、
  /// 从没播过的书会排在真正在听的那本前面。必须显式筛 lastPlayedAt。
  static Book? mostRecentlyPlayed(List<Book> books) {
    Book? best;
    for (final b in books) {
      final at = b.lastPlayedAt;
      if (at == null) continue;
      if (best == null || at.isAfter(best.lastPlayedAt!)) best = b;
    }
    return best;
  }

  /// 把书与它的章节组装成卡片数据。
  ///
  /// 章节列表为空（刚从网盘同步回来、还没扫章节）或记录的序号越界
  /// （重新解析后章节变少）时，不抛异常，也不按序号盲目索引——
  /// 标成「未就绪」，卡片照常显示书名，只是不让点。
  static ContinueListening from(Book book, List<Chapter> chapters) {
    if (book.sourceMissing) {
      return ContinueListening(
        book: book,
        chapter: null,
        notReadyReason: '源文件在网盘里找不到了',
      );
    }
    if (chapters.isEmpty) {
      return ContinueListening(
        book: book,
        chapter: null,
        notReadyReason: '章节还在准备中',
      );
    }
    final index = book.finished ? 0 : book.currentChapterIndex;
    if (index < 0 || index >= chapters.length) {
      return ContinueListening(
        book: book,
        chapter: null,
        notReadyReason: '这一章在网盘里已经找不到了',
      );
    }
    return ContinueListening(
      book: book,
      chapter: chapters[index],
      notReadyReason: null,
    );
  }
}
