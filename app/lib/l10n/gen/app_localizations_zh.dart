// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appName => '云听书';

  @override
  String get navShelf => '书架';

  @override
  String get navHistory => '历史';

  @override
  String get navMine => '我的';

  @override
  String get actionCancel => '取消';

  @override
  String get actionConfirm => '确定';

  @override
  String get actionRetry => '重试';

  @override
  String get actionDelete => '删除';

  @override
  String get splashLoading => '正在准备…';

  @override
  String bootstrapFailed(String detail) {
    return '启动失败：$detail';
  }

  @override
  String get timeJustNow => '刚刚';

  @override
  String timeMinutesAgo(int n) {
    return '$n 分钟前';
  }

  @override
  String timeTodayAt(String hm) {
    return '今天 $hm';
  }

  @override
  String timeDaysAgo(int n) {
    return '$n 天前';
  }

  @override
  String get dayToday => '今天';

  @override
  String get dayYesterday => '昨天';

  @override
  String dayThisYear(String month, String day) {
    return '$month 月 $day 日';
  }

  @override
  String dayOtherYear(int year, String month, String day) {
    return '$year 年 $month 月 $day 日';
  }

  @override
  String get listenedJustStarted => '刚开始';

  @override
  String listenedSeconds(int n) {
    return '听了 $n 秒';
  }

  @override
  String listenedMinutes(int n) {
    return '听了 $n 分钟';
  }

  @override
  String listenedHours(int h) {
    return '听了 $h 小时';
  }

  @override
  String listenedHoursMinutes(int h, int m) {
    return '听了 $h 小时 $m 分';
  }

  @override
  String get errorAuth => '网盘授权已失效，请重新登录';

  @override
  String get errorRateLimited => '请求过于频繁，请稍后再试';

  @override
  String get errorNotFound => '网盘中找不到该文件，可能已被移动或删除';

  @override
  String get errorNoMedia => '该文件夹下没有可识别的音频文件';

  @override
  String get errorNetwork => '网络连接不可用，请检查网络后重试';

  @override
  String get errorLinkExpired => '播放地址已过期，正在重新获取';

  @override
  String get errorStorageFull => '设备存储空间不足';

  @override
  String get errorPlaybackExhausted => '播放地址反复获取失败，请检查网络后重试';

  @override
  String get hintSlowNetwork => '网络较慢，反复缓冲。建议先下载本书再听。';

  @override
  String get notReadySourceMissing => '源文件在网盘里找不到了';

  @override
  String get notReadyEpisodesPending => '章节还在准备中';

  @override
  String get notReadyEpisodeGone => '这一章在网盘里已经找不到了';

  @override
  String unitEpisode(String kind) {
    String _temp0 = intl.Intl.selectLogic(
      kind,
      {
        'course': '课',
        'other': '章',
      },
    );
    return '$_temp0';
  }

  @override
  String episodeOfTotal(int index, int total, String unit) {
    return '第 $index / $total $unit';
  }
}
