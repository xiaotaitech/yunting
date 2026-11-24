import 'package:yun_audiobook/l10n/l10n.dart';

/// 章节行上的同步日期：「11月21日同步」，不是今年的带年份；时间未知返回 null。
String? syncedLabel(AppLocalizations l, DateTime? syncedAt, {DateTime? now}) {
  if (syncedAt == null) return null;
  final t = syncedAt.toLocal();
  return t.year == (now ?? DateTime.now()).year
      ? l.detailSyncedOn(t.month, t.day)
      : l.detailSyncedOnYear(t.year, t.month, t.day);
}
