import 'package:finance_mvp/constants/app_colors.dart';
import 'package:finance_mvp/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AppearanceScreen extends StatelessWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: const Text('Appearance'),
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
            'THEME',
            style: TextStyle(
              color: context.colors.textLight,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          for (final mode in const [
            (ThemeMode.light, Icons.light_mode, 'Light'),
            (ThemeMode.dark, Icons.dark_mode, 'Dark'),
            (ThemeMode.system, Icons.brightness_auto, 'System'),
          ])
            RadioListTile<ThemeMode>(
              value: mode.$1,
              groupValue: theme.mode,
              onChanged: (m) => m != null ? theme.setMode(m) : null,
              activeColor: context.colors.primary,
              secondary: Icon(mode.$2, color: context.colors.textDark),
              title: Text(
                mode.$3,
                style: TextStyle(color: context.colors.textDark),
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
                  theme.dark ? 'Dark mode active' : 'Light mode active',
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
