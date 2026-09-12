import 'dart:ui';

import 'package:flutter/widgets.dart';

/// Two-palette theme. Widgets keep reading `AppColors.x`; flipping
/// [current] swaps the whole app at once (set from ThemeProvider).
class AppColors {
  final Color _background;
  final Color _primary;
  final Color _primaryLight;
  final Color _textDark;
  final Color _textLight;
  final Color _cardBackground;
  final Color _fieldsBackground;
  final Color _segmentedControlBackground;
  final Color _segmentedControlActive;
  final Color _cardBorder;
  final List<Color> _stackCardBackground;

  const AppColors._({
    required Color background,
    required Color primary,
    required Color primaryLight,
    required Color textDark,
    required Color textLight,
    required Color cardBackground,
    required Color fieldsBackground,
    required Color segmentedControlBackground,
    required Color segmentedControlActive,
    required Color cardBorder,
    required List<Color> stackCardBackground,
  })  : _background = background,
        _primary = primary,
        _primaryLight = primaryLight,
        _textDark = textDark,
        _textLight = textLight,
        _cardBackground = cardBackground,
        _fieldsBackground = fieldsBackground,
        _segmentedControlBackground = segmentedControlBackground,
        _segmentedControlActive = segmentedControlActive,
        _cardBorder = cardBorder,
        _stackCardBackground = stackCardBackground;

  static const AppColors _light = AppColors._(
    background: Color(0xFFF1F5EC),
    primary: Color(0xFF0c3c15),
    primaryLight: Color(0xFFa8e665),
    textDark: Color(0xFF333333),
    textLight: Color(0xFF666666),
    cardBackground: Color(0xFFFFFFFF),
    fieldsBackground: Color.fromARGB(255, 254, 255, 252),
    segmentedControlBackground: Color(0xFFE0E0E0),
    segmentedControlActive: Color(0xFFFFFFFF),
    cardBorder: Color.fromARGB(255, 156, 156, 156),
    stackCardBackground: [
      Color(0xFFF7FAF5),
      Color(0xFFF3F5F1),
      Color(0xFFECEEEA)
    ],
  );

  static const AppColors _dark = AppColors._(
    background: Color(0xFF121212),
    primary: Color(0xFFBB86FC),
    primaryLight: Color(0xFFBB86FC),
    textDark: Color(0xFFE0E0E0),
    textLight: Color(0xFFB0B0B0),
    cardBackground: Color(0xFF1E1E1E),
    fieldsBackground: Color(0xFF2C2C2C),
    segmentedControlBackground: Color(0xFF2C2C2C),
    segmentedControlActive: Color(0xFF3A3A3A),
    cardBorder: Color(0xFF3A3A3A),
    stackCardBackground: [
      Color(0xFF1E1E1E),
      Color(0xFF2C2C2C),
      Color(0xFF3A3A3A)
    ],
  );

  /// Active palette; assigned by ThemeProvider on mode change.
  static AppColors current = _light;

  static void useDark(bool dark) => current = dark ? _dark : _light;

  // The 8-bit about screen is always dark.
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkPrimary = Color(0xFFBB86FC);
  static const Color darkPrimaryLight = Color(0xFFBB86FC);
  static const Color darkTextDark = Color(0xFFE0E0E0);
  static const Color darkTextLight = Color(0xFFB0B0B0);
  static const Color darkCardBackground = Color(0xFF1E1E1E);
  static const Color darkFieldsBackground = Color(0xFF2C2C2C);
  static const Color darkSegmentedControlBackground = Color(0xFF2C2C2C);
  static const Color darkSegmentedControlActive = Color(0xFF3A3A3A);
  static const List<Color> darkStackCardBackground = [
    Color(0xFF1E1E1E),
    Color(0xFF2C2C2C),
    Color(0xFF3A3A3A),
  ];

  static Color get background => current._background;
  static Color get primary => current._primary;
  static Color get primaryLight => current._primaryLight;
  static Color get textDark => current._textDark;
  static Color get textLight => current._textLight;
  static Color get cardBackground => current._cardBackground;
  static Color get fieldsBackground => current._fieldsBackground;
  static Color get segmentedControlBackground =>
      current._segmentedControlBackground;
  static Color get segmentedControlActive => current._segmentedControlActive;
  static Color get cardBorder => current._cardBorder;
  static List<Color> get stackCardBackground => current._stackCardBackground;
}

/// Instance view over a palette, so UI reads `context.colors.background` etc.
class Palette {
  final AppColors _c;
  const Palette(this._c);

  Color get background => _c._background;
  Color get primary => _c._primary;
  Color get primaryLight => _c._primaryLight;
  Color get textDark => _c._textDark;
  Color get textLight => _c._textLight;
  Color get cardBackground => _c._cardBackground;
  Color get fieldsBackground => _c._fieldsBackground;
  Color get segmentedControlBackground => _c._segmentedControlBackground;
  Color get segmentedControlActive => _c._segmentedControlActive;
  Color get cardBorder => _c._cardBorder;
  List<Color> get stackCardBackground => _c._stackCardBackground;
}

/// Injected around the Navigator so UI widgets can *depend* on the palette and
/// rebuild when it flips, even through `const` parents.
class AppPalette extends InheritedWidget {
  final AppColors colors;
  const AppPalette({super.key, required this.colors, required super.child});

  static Palette of(BuildContext context) => Palette(
        context.dependOnInheritedWidgetOfExactType<AppPalette>()?.colors ??
            AppColors.current,
      );

  @override
  bool updateShouldNotify(AppPalette oldWidget) => oldWidget.colors != colors;
}

extension AppColorsContext on BuildContext {
  Palette get colors => AppPalette.of(this);
}
