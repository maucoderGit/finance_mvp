import 'package:finance_mvp/l10n/app_localizations.dart';
import 'package:finance_mvp/l10n/app_localizations_en.dart';
import 'package:flutter/widgets.dart';

export 'package:finance_mvp/l10n/app_localizations.dart';

/// Shorthand for `AppLocalizations.of(context)`.
///
/// Falls back to English when the tree has no localization delegates (tests
/// mounting `MaterialApp` without them), instead of throwing on the null.
extension L10nX on BuildContext {
  AppLocalizations get l10n =>
      Localizations.of<AppLocalizations>(this, AppLocalizations) ??
      AppLocalizationsEn();
}