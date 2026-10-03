import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yun_audiobook/features/common/format.dart';
import 'package:yun_audiobook/l10n/l10n.dart';

/// 设置页原来直接把 `DateTime` 塞进字符串，界面上是
/// `2026-09-02 14:30:42.414`——毫秒对用户没有意义。
void main() {
  final l = lookupAppLocalizations(const Locale('zh'));
  final now = DateTime(2026, 9, 2, 14, 30);

  test('刚同步完说「刚刚」，不给一串数字', () {
    expect(formatSyncTime(l, now, now: now), '刚刚');
    expect(
        formatSyncTime(l, now.subtract(const Duration(seconds: 40)), now: now),
        '刚刚',);
  });

  test('一小时内按分钟', () {
    expect(formatSyncTime(l, now.subtract(const Duration(minutes: 1)), now: now),
        '1 分钟前',);
    expect(formatSyncTime(l, now.subtract(const Duration(minutes: 59)), now: now),
        '59 分钟前',);
  });

  test('同一天内给时刻，补零', () {
    expect(formatSyncTime(l, DateTime(2026, 9, 2, 9, 5), now: now), '今天 09:05');
  });

  test('跨天但一周内按天数（不足整天的余数向下取整）', () {
    // 8-31 22:00 到 9-2 14:30 是 40 小时，算 1 天
    expect(formatSyncTime(l, DateTime(2026, 8, 31, 22), now: now), '1 天前');
    expect(formatSyncTime(l, DateTime(2026, 8, 30, 10), now: now), '3 天前');
  });

  test('超过一周给日期时刻', () {
    expect(formatSyncTime(l, DateTime(2026, 8, 3, 7, 8), now: now), '08-03 07:08');
  });

  test('时钟偏移导致的未来时间不显示成负数', () {
    expect(formatSyncTime(l, now.add(const Duration(minutes: 5)), now: now), '刚刚');
  });

  test('跨天但不满 24 小时不会被当成「今天」', () {
    // 昨天 23:50 到今天 14:30 只隔 14 小时多，但已经不是同一天了，
    // 说「今天 23:50」会是错的。
    final at = DateTime(2026, 9, 1, 23, 50);
    expect(formatSyncTime(l, at, now: now), isNot(contains('今天')));
  });
}
