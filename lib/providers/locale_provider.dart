import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the user's language choice. A null [locale] means "follow the
/// device", which is the default.
class LocaleProvider extends ChangeNotifier {
  static const _key = 'locale';

  final SharedPreferences _prefs;
  Locale? _locale;

  LocaleProvider(this._prefs, this._locale);

  Locale? get locale => _locale;

  Future<void> setLocale(Locale? locale) async {
    if (locale?.languageCode == _locale?.languageCode) return;
    _locale = locale;
    notifyListeners();
    if (locale == null) {
      await _prefs.remove(_key);
    } else {
      await _prefs.setString(_key, locale.languageCode);
    }
  }

  static Future<LocaleProvider> load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_key);
    return LocaleProvider(prefs, code == null ? null : Locale(code));
  }
}
