import 'package:finance_mvp/constants/app_colors.dart';
import 'package:finance_mvp/l10n/l10n.dart';
import 'package:finance_mvp/repositories/finance_repository.dart';
import 'package:flutter/material.dart';
import 'package:finance_mvp/screens/settings/about_screen.dart';
import 'package:finance_mvp/widgets/custom_toast.dart';
import 'package:finance_mvp/screens/settings/appearance_screen.dart';
import 'package:finance_mvp/screens/settings/notifications_screen.dart';
import 'package:finance_mvp/screens/settings/currency_screen.dart';
import 'package:finance_mvp/screens/overview/dashboard_screen.dart';
import 'package:finance_mvp/screens/settings/profile_screen.dart';
import 'package:finance_mvp/screens/revaluation/revaluation_screen.dart';
import 'package:finance_mvp/screens/contacts/contacts_screen.dart';
import 'package:finance_mvp/screens/debts/debts_screen.dart';
import 'package:finance_mvp/screens/goals/goals_screen.dart';
import 'package:provider/provider.dart';

class ConfigScreen extends StatelessWidget {
  const ConfigScreen({super.key});

  Future<void> _confirmWipe(BuildContext context) async {
    final repository = context.read<FinanceRepository>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.configClearTitle),
        content: Text(context.l10n.configClearBody),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(context.l10n.cancel)),
          TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(context.l10n.configDeleteEverything,
                  style: const TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed != true) return;

    await repository.wipeAllData();
    if (!context.mounted) return;
    showToast(context, message: context.l10n.configDataCleared);
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: Text(context.l10n.configTitle),
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
          _SectionTitle(title: context.l10n.configSectionGeneral),
          _SettingTile(
            icon: Icons.person_outline,
            title: context.l10n.profileTitle,
            subtitle: context.l10n.configProfileSubtitle,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
          _SettingTile(
            icon: Icons.monetization_on_outlined,
            title: context.l10n.configCurrencies,
            subtitle: context.l10n.configCurrenciesSubtitle,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CurrencyScreen()),
              );
            },
          ),
          _SettingTile(
            icon: Icons.contacts_outlined,
            title: context.l10n.configContacts,
            subtitle: context.l10n.configContactsSubtitle,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ContactsScreen()),
              );
            },
          ),
          _SettingTile(
            icon: Icons.handshake_outlined,
            title: context.l10n.configDebts,
            subtitle: context.l10n.configDebtsSubtitle,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DebtsScreen()),
              );
            },
          ),
          _SettingTile(
            icon: Icons.flag_outlined,
            title: context.l10n.configGoals,
            subtitle: context.l10n.configGoalsSubtitle,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const GoalsScreen()),
              );
            },
          ),
          _SettingTile(
            icon: Icons.pie_chart_outline,
            title: context.l10n.dashboardTitle,
            subtitle: context.l10n.configDashboardSubtitle,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DashboardScreen()),
              );
            },
          ),
          _SettingTile(
            icon: Icons.trending_up,
            title: context.l10n.configRevaluation,
            subtitle: context.l10n.configRevaluationSubtitle,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RevaluationScreen()),
              );
            },
          ),
          const SizedBox(height: 16),
          _SectionTitle(title: context.l10n.configSectionPreferences),
          _SettingTile(
            icon: Icons.palette_outlined,
            title: context.l10n.appearanceTitle,
            subtitle: context.l10n.configAppearanceSubtitle,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AppearanceScreen()),
              );
            },
          ),
          _SettingTile(
            icon: Icons.notifications_outlined,
            title: context.l10n.configNotifications,
            subtitle: context.l10n.configNotificationsSubtitle,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const NotificationsScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          _SectionTitle(title: context.l10n.configSectionAbout),
          _SettingTile(
            icon: Icons.info_outline,
            title: context.l10n.configAbout,
            subtitle: context.l10n.configAboutSubtitle,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AboutScreen()),
              );
            },
          ),
          const SizedBox(height: 16),
          _SectionTitle(title: context.l10n.configSectionDanger),
          _SettingTile(
            icon: Icons.delete_forever_outlined,
            title: context.l10n.configClearAllData,
            subtitle: context.l10n.configClearAllDataSubtitle,
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