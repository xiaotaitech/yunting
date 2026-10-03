/// 展示层的格式化辅助。带文字的都从 [AppLocalizations] 取。
library;

import 'package:yun_audiobook/l10n/l10n.dart';

String formatDuration(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return h > 0 ? '$h:$m:$s' : '$m:$s';
}

String formatBytes(int bytes) {
  if (bytes >= 1 << 30) return '${(bytes / (1 << 30)).toStringAsFixed(2)} GB';
  if (bytes >= 1 << 20) return '${(bytes / (1 << 20)).toStringAsFixed(1)} MB';
  if (bytes >= 1 << 10) return '${(bytes / (1 << 10)).toStringAsFixed(0)} KB';
  return '$bytes B';
}

String formatSpeed(double speed) {
  final text = speed.toStringAsFixed(2);
  return '${text.endsWith('0') ? text.substring(0, text.length - 1) : text}x';
}

/// 同步时间。
///
/// 原来直接把 `DateTime` 塞进字符串，界面上就是
/// `2026-09-02 14:30:42.414`——毫秒对用户毫无意义，还暴露实现细节。
/// 刚同步过的时候「几分钟前」比绝对时间好读；隔天了再给日期。
String formatSyncTime(AppLocalizations l, DateTime at, {DateTime? now}) {
  final ref = now ?? DateTime.now();
  final diff = ref.difference(at);

  if (diff.isNegative || diff.inMinutes < 1) return l.timeJustNow;
  if (diff.inMinutes < 60) return l.timeMinutesAgo(diff.inMinutes);
  if (diff.inHours < 24 && at.day == ref.day) {
    return l.timeTodayAt(formatClock(at));
  }
  if (diff.inDays < 7) return l.timeDaysAgo(diff.inDays == 0 ? 1 : diff.inDays);
  return '${_two(at.month)}-${_two(at.day)} ${_two(at.hour)}:${_two(at.minute)}';
}

String _two(int n) => n.toString().padLeft(2, '0');

/// 历史列表的日期分组标题。今天 / 昨天 / 本年内不带年 / 跨年带年。
String formatHistoryDay(AppLocalizations l, DateTime at, {DateTime? now}) {
  final ref = now ?? DateTime.now();
  final day = DateTime(at.year, at.month, at.day);
  final today = DateTime(ref.year, ref.month, ref.day);
  final diff = today.difference(day).inDays;

  if (diff == 0) return l.dayToday;
  if (diff == 1) return l.dayYesterday;
  if (at.year == ref.year) return l.dayThisYear(_two(at.month), _two(at.day));
  return l.dayOtherYear(at.year, _two(at.month), _two(at.day));
}

String formatClock(DateTime at) => '${_two(at.hour)}:${_two(at.minute)}';

/// 实际收听时长。不足一分钟的说秒，否则说分钟；超过一小时补上小时。
///
/// 刻意不显示「0 分钟」：刚点开还没听就上报的那一笔说「刚开始」更准。
String formatListened(AppLocalizations l, int ms) {
  final total = Duration(milliseconds: ms);
  if (total.inSeconds < 10) return l.listenedJustStarted;
  if (total.inMinutes < 1) return l.listenedSeconds(total.inSeconds);
  if (total.inHours < 1) return l.listenedMinutes(total.inMinutes);
  final mins = total.inMinutes.remainder(60);
  return mins == 0
      ? l.listenedHours(total.inHours)
      : l.listenedHoursMinutes(total.inHours, mins);
}
