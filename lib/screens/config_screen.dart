import 'package:finance_mvp/constants/app_colors.dart';
import 'package:finance_mvp/repositories/finance_repository.dart';
import 'package:flutter/material.dart';
import 'package:finance_mvp/screens/about_screen.dart';
import 'package:finance_mvp/screens/appearance_screen.dart';
import 'package:finance_mvp/screens/currency_screen.dart';
import 'package:finance_mvp/screens/dashboard_screen.dart';
import 'package:finance_mvp/screens/profile_screen.dart';
import 'package:finance_mvp/screens/revaluation_screen.dart';
import 'package:provider/provider.dart';

class ConfigScreen extends StatelessWidget {
  const ConfigScreen({super.key});

  Future<void> _confirmWipe(BuildContext context) async {
    final repository = context.read<FinanceRepository>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear all data?'),
        content: const Text(
          'This permanently deletes your accounts, transactions, rates and '
          'preferences, and restarts the app from onboarding. This cannot be '
          'undone.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete everything',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed != true) return;

    await repository.wipeAllData();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All data cleared.')),
    );
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: const Text('Configuration'),
        centerTitle: true,
        backgroundColor: context.colors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.colors.textDark),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        children: [
          const _SectionTitle(title: 'General'),
          _SettingTile(
            icon: Icons.person_outline,
            title: 'Profile',
            subtitle: 'Manage your user profile',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
          _SettingTile(
            icon: Icons.monetization_on_outlined,
            title: 'Currencies',
            subtitle: 'Manage currencies and base currency',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CurrencyScreen()),
              );
            },
          ),
          _SettingTile(
            icon: Icons.pie_chart_outline,
            title: 'Dashboard',
            subtitle: 'Overview charts and analytics',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DashboardScreen()),
              );
            },
          ),
          _SettingTile(
            icon: Icons.trending_up,
            title: 'Revaluation',
            subtitle: 'FX gains/losses and purchasing power',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RevaluationScreen()),
              );
            },
          ),
          const SizedBox(height: 16),
          const _SectionTitle(title: 'Preferences'),
          _SettingTile(
            icon: Icons.palette_outlined,
            title: 'Appearance',
            subtitle: 'Customize theme and appearance',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AppearanceScreen()),
              );
            },
          ),
          _SettingTile(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            subtitle: 'Manage notification settings',
            onTap: () {
              // TODO: Navigate to Notification Settings
            },
          ),
          const SizedBox(height: 16),
          const _SectionTitle(title: 'About'),
          _SettingTile(
            icon: Icons.info_outline,
            title: 'About Finance',
            subtitle: 'App version and information',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AboutScreen()),
              );
            },
          ),
          const SizedBox(height: 16),
          const _SectionTitle(title: 'Danger zone'),
          _SettingTile(
            icon: Icons.delete_forever_outlined,
            title: 'Clear all data',
            subtitle: 'Wipe everything and start over',
            onTap: () => _confirmWipe(context),
            iconColor: Colors.red,
            textColor: Colors.red,
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0, left: 8.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: context.colors.textLight,
          fontWeight: FontWeight.bold,
          fontSize: 12,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? textColor;

  const _SettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? context.colors.textDark),
      title: Text(title,
          style: TextStyle(
              fontWeight: FontWeight.w500, color: textColor)),
      subtitle: Text(subtitle, style: TextStyle(color: context.colors.textLight)),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }
}