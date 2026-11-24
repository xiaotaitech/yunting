import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yun_audiobook/features/library/synced_label.dart';
import 'package:yun_audiobook/l10n/l10n.dart';

/// 章节行的「M月D日同步」（add-episode-time-order）。
void main() {
  final l = lookupAppLocalizations(const Locale('zh'));
  final now = DateTime(2026, 11, 24);

  test('今年的只写月日', () {
    expect(syncedLabel(l, DateTime(2026, 11, 21), now: now), '11月21日同步');
  });

  test('不是今年的带上年份', () {
    expect(
      syncedLabel(l, DateTime(2025, 11, 21), now: now),
      '2025年11月21日同步',
    );
  });

  test('时间未知不显示', () {
    expect(syncedLabel(l, null, now: now), isNull);
  });
}
