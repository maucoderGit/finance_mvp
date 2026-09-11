import 'package:finance_mvp/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:finance_mvp/screens/currency_screen.dart';
import 'package:finance_mvp/screens/dashboard_screen.dart';
import 'package:finance_mvp/screens/profile_screen.dart';
import 'package:finance_mvp/screens/revaluation_screen.dart';

class ConfigScreen extends StatelessWidget {
  const ConfigScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Configuration'),
        centerTitle: true,
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
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
              // TODO: Navigate to Appearance Settings
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
            title: 'About Atelier Finance',
            subtitle: 'App version and information',
            onTap: () {
              // TODO: Show About Dialog
            },
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
        style: const TextStyle(
          color: AppColors.textLight,
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

  const _SettingTile({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textDark),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: const TextStyle(color: AppColors.textLight)),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }
}