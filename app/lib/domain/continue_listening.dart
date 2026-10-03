/// 首页续听入口的视图模型（listening-progress 规格「首页续听入口」）。
///
/// 选择逻辑刻意做成纯函数：它有一堆容易搞错的边界（没播过的书、章节没解析、
/// 序号越界），放在 provider 里就只能靠跑真机验证，放在这里能直接单测。
library;

import 'package:yun_audiobook/domain/entities.dart';

/// 续听卡片不能播的原因。文案在 l10n 里按枚举取。
enum NotReadyReason {
  /// 源文件在网盘里找不到了
  sourceMissing,

  /// 条目还在准备中（刚从网盘同步回来、还没扫章节）
  episodesPending,

  /// 记录的那一集在网盘里已经找不到了（重新解析后条目变少）
  episodeGone,
}

class ContinueListening {
  const ContinueListening({
    required this.series,
    required this.episode,
    required this.notReadyReason,
  });

  final Series series;

  /// 断点所在的条目。为 null 表示条目还没就位，此时不能播。
  final Episode? episode;

  /// 不能播的原因；能播时为 null。展示在卡片上，让用户点之前就知道。
  final NotReadyReason? notReadyReason;

  bool get canPlay => notReadyReason == null;

  /// 条目内的断点位置。
  Duration get position => series.position;

  /// 已听完的合集再点会从第一集开始（PlaybackSession.start 的既有行为），
  /// 卡片要事先说明，而不是让用户点下去才发现回到了开头。
  bool get restartsFromBeginning => series.finished;

  /// 全合集维度的进度，与书架卡片同一口径。
  double get progress => series.progress;

  /// 挑出「最近收听」的那一个。
  ///
  /// 不能直接取书架第一个：书架按 `COALESCE(last_played_at, added_at) DESC`
  /// 排序，一本刚加进来、从没播过的书会排在真正在听的那本前面。
  /// 必须显式筛 lastPlayedAt。
  static Series? mostRecentlyPlayed(List<Series> shelf) {
    Series? best;
    for (final s in shelf) {
      final at = s.lastPlayedAt;
      if (at == null) continue;
      if (best == null || at.isAfter(best.lastPlayedAt!)) best = s;
    }
    return best;
  }

  /// 把合集与它的条目组装成卡片数据。
  ///
  /// 条目列表为空或记录的序号越界时，不抛异常，也不按序号盲目索引——
  /// 标成「未就绪」，卡片照常显示标题，只是不让点。
  static ContinueListening from(Series series, List<Episode> episodes) {
    NotReadyReason? reason;
    Episode? episode;
    final index = series.finished ? 0 : series.currentEpisodeIndex;
    if (series.sourceMissing) {
      reason = NotReadyReason.sourceMissing;
    } else if (episodes.isEmpty) {
      reason = NotReadyReason.episodesPending;
    } else if (index < 0 || index >= episodes.length) {
      reason = NotReadyReason.episodeGone;
    } else {
      episode = episodes[index];
    }
    return ContinueListening(
      series: series,
      episode: episode,
      notReadyReason: reason,
    );
  }
}
