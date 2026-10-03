import 'package:flutter/widgets.dart';
import 'package:yun_audiobook/l10n/gen/app_localizations.dart';

export 'package:yun_audiobook/l10n/gen/app_localizations.dart';

extension L10nX on BuildContext {
  /// 文案入口：`context.l10n.navShelf`。
  AppLocalizations get l10n => AppLocalizations.of(this);
}
