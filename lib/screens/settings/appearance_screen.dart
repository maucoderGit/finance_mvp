import 'package:finance_mvp/constants/app_colors.dart';
import 'package:finance_mvp/l10n/l10n.dart';
import 'package:finance_mvp/providers/locale_provider.dart';
import 'package:finance_mvp/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AppearanceScreen extends StatelessWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final localeProvider = context.watch<LocaleProvider>();
    final modes = [
      (ThemeMode.light, Icons.light_mode, context.l10n.themeLight),
      (ThemeMode.dark, Icons.dark_mode, context.l10n.themeDark),
      (ThemeMode.system, Icons.brightness_auto, context.l10n.themeSystem),
    ];
    final languages = [
      (null, Icons.language, context.l10n.languageSystem),
      (const Locale('en'), Icons.language, context.l10n.languageEnglish),
      (const Locale('es'), Icons.language, context.l10n.languageSpanish),
    ];
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: Text(context.l10n.appearanceTitle),
        centerTitle: true,
        backgroundColor: context.colors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.colors.textDark),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        children: [
          Text(
            context.l10n.appearanceTheme,
            style: TextStyle(
              color: context.colors.textLight,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          RadioGroup<ThemeMode>(
            groupValue: theme.mode,
            onChanged: (m) => m != null ? theme.setMode(m) : null,
            child: Column(
              children: [
                for (final mode in modes)
                  RadioListTile<ThemeMode>(
                    value: mode.$1,
                    activeColor: context.colors.primary,
                    secondary: Icon(mode.$2, color: context.colors.textDark),
                    title: Text(
                      mode.$3,
                      style: TextStyle(color: context.colors.textDark),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            context.l10n.languageSectionTitle.toUpperCase(),
            style: TextStyle(
              color: context.colors.textLight,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          RadioGroup<String>(
            groupValue: localeProvider.locale?.languageCode ?? '',
            onChanged: (code) => localeProvider
                .setLocale(code == null || code.isEmpty ? null : Locale(code)),
            child: Column(
              children: [
                for (final language in languages)
                  RadioListTile<String>(
                    value: language.$1?.languageCode ?? '',
                    activeColor: context.colors.primary,
                    secondary:
                        Icon(language.$2, color: context.colors.textDark),
                    title: Text(
                      language.$3,
                      style: TextStyle(color: context.colors.textDark),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.colors.cardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.colors.cardBorder),
            ),
            child: Row(
              children: [
                Icon(
                  theme.dark ? Icons.dark_mode : Icons.light_mode,
                  color: context.colors.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  theme.dark
                      ? context.l10n.appearanceDarkActive
                      : context.l10n.appearanceLightActive,
                  style: TextStyle(color: context.colors.textDark),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
