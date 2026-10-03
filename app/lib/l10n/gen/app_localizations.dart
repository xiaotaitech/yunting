import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('zh')];

  /// No description provided for @appName.
  ///
  /// In zh, this message translates to:
  /// **'云听书'**
  String get appName;

  /// No description provided for @navShelf.
  ///
  /// In zh, this message translates to:
  /// **'书架'**
  String get navShelf;

  /// No description provided for @navHistory.
  ///
  /// In zh, this message translates to:
  /// **'历史'**
  String get navHistory;

  /// No description provided for @navMine.
  ///
  /// In zh, this message translates to:
  /// **'我的'**
  String get navMine;

  /// No description provided for @actionCancel.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get actionCancel;

  /// No description provided for @actionConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确定'**
  String get actionConfirm;

  /// No description provided for @actionRetry.
  ///
  /// In zh, this message translates to:
  /// **'重试'**
  String get actionRetry;

  /// No description provided for @actionDelete.
  ///
  /// In zh, this message translates to:
  /// **'删除'**
  String get actionDelete;

  /// No description provided for @splashLoading.
  ///
  /// In zh, this message translates to:
  /// **'正在准备…'**
  String get splashLoading;

  /// No description provided for @bootstrapFailed.
  ///
  /// In zh, this message translates to:
  /// **'启动失败：{detail}'**
  String bootstrapFailed(String detail);

  /// No description provided for @timeJustNow.
  ///
  /// In zh, this message translates to:
  /// **'刚刚'**
  String get timeJustNow;

  /// No description provided for @timeMinutesAgo.
  ///
  /// In zh, this message translates to:
  /// **'{n} 分钟前'**
  String timeMinutesAgo(int n);

  /// No description provided for @timeTodayAt.
  ///
  /// In zh, this message translates to:
  /// **'今天 {hm}'**
  String timeTodayAt(String hm);

  /// No description provided for @timeDaysAgo.
  ///
  /// In zh, this message translates to:
  /// **'{n} 天前'**
  String timeDaysAgo(int n);

  /// No description provided for @dayToday.
  ///
  /// In zh, this message translates to:
  /// **'今天'**
  String get dayToday;

  /// No description provided for @dayYesterday.
  ///
  /// In zh, this message translates to:
  /// **'昨天'**
  String get dayYesterday;

  /// No description provided for @dayThisYear.
  ///
  /// In zh, this message translates to:
  /// **'{month} 月 {day} 日'**
  String dayThisYear(String month, String day);

  /// No description provided for @dayOtherYear.
  ///
  /// In zh, this message translates to:
  /// **'{year} 年 {month} 月 {day} 日'**
  String dayOtherYear(int year, String month, String day);

  /// No description provided for @listenedJustStarted.
  ///
  /// In zh, this message translates to:
  /// **'刚开始'**
  String get listenedJustStarted;

  /// No description provided for @listenedSeconds.
  ///
  /// In zh, this message translates to:
  /// **'听了 {n} 秒'**
  String listenedSeconds(int n);

  /// No description provided for @listenedMinutes.
  ///
  /// In zh, this message translates to:
  /// **'听了 {n} 分钟'**
  String listenedMinutes(int n);

  /// No description provided for @listenedHours.
  ///
  /// In zh, this message translates to:
  /// **'听了 {h} 小时'**
  String listenedHours(int h);

  /// No description provided for @listenedHoursMinutes.
  ///
  /// In zh, this message translates to:
  /// **'听了 {h} 小时 {m} 分'**
  String listenedHoursMinutes(int h, int m);

  /// No description provided for @errorAuth.
  ///
  /// In zh, this message translates to:
  /// **'网盘授权已失效，请重新登录'**
  String get errorAuth;

  /// No description provided for @errorRateLimited.
  ///
  /// In zh, this message translates to:
  /// **'请求过于频繁，请稍后再试'**
  String get errorRateLimited;

  /// No description provided for @errorNotFound.
  ///
  /// In zh, this message translates to:
  /// **'网盘中找不到该文件，可能已被移动或删除'**
  String get errorNotFound;

  /// No description provided for @errorNoMedia.
  ///
  /// In zh, this message translates to:
  /// **'该文件夹下没有可识别的音频文件'**
  String get errorNoMedia;

  /// No description provided for @errorNetwork.
  ///
  /// In zh, this message translates to:
  /// **'网络连接不可用，请检查网络后重试'**
  String get errorNetwork;

  /// No description provided for @errorLinkExpired.
  ///
  /// In zh, this message translates to:
  /// **'播放地址已过期，正在重新获取'**
  String get errorLinkExpired;

  /// No description provided for @errorStorageFull.
  ///
  /// In zh, this message translates to:
  /// **'设备存储空间不足'**
  String get errorStorageFull;

  /// No description provided for @errorPlaybackExhausted.
  ///
  /// In zh, this message translates to:
  /// **'播放地址反复获取失败，请检查网络后重试'**
  String get errorPlaybackExhausted;

  /// No description provided for @hintSlowNetwork.
  ///
  /// In zh, this message translates to:
  /// **'网络较慢，反复缓冲。建议先下载本书再听。'**
  String get hintSlowNetwork;

  /// No description provided for @notReadySourceMissing.
  ///
  /// In zh, this message translates to:
  /// **'源文件在网盘里找不到了'**
  String get notReadySourceMissing;

  /// No description provided for @notReadyEpisodesPending.
  ///
  /// In zh, this message translates to:
  /// **'章节还在准备中'**
  String get notReadyEpisodesPending;

  /// No description provided for @notReadyEpisodeGone.
  ///
  /// In zh, this message translates to:
  /// **'这一章在网盘里已经找不到了'**
  String get notReadyEpisodeGone;

  /// No description provided for @unitEpisode.
  ///
  /// In zh, this message translates to:
  /// **'{kind, select, course{课} other{章}}'**
  String unitEpisode(String kind);

  /// No description provided for @episodeOfTotal.
  ///
  /// In zh, this message translates to:
  /// **'第 {index} / {total} {unit}'**
  String episodeOfTotal(int index, int total, String unit);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
