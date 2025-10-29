
import 'package:flutter/material.dart';
import '../widget/settings_list_item.dart';

class ConfigScreen extends StatelessWidget {
  const ConfigScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          const _SettingsSection(title: 'General'),
          SettingsListItem(
            icon: Icons.account_balance_wallet,
            title: 'Accounts',
            onTap: () {},
          ),
          SettingsListItem(
            icon: Icons.payments,
            title: 'Currency',
            onTap: () {
              Navigator.pushNamed(context, "/v1/config/currency");
            },
          ),
          SettingsListItem(
            icon: Icons.notifications,
            title: 'Notifications',
            onTap: () {},
          ),
          const _SettingsSection(title: 'Organization'),
          SettingsListItem(
            icon: Icons.label,
            title: 'Tags / Categories',
            onTap: () {},
          ),
          SettingsListItem(
            icon: Icons.donut_small,
            title: 'Budgets',
            onTap: () {},
          ),
          const _SettingsSection(title: 'App'),
          SettingsListItem(
            icon: Icons.palette,
            title: 'Appearance',
            onTap: () {},
          ),
          SettingsListItem(
            icon: Icons.shield,
            title: 'Security',
            onTap: () {},
          ),
          SettingsListItem(
            icon: Icons.help_outline,
            title: 'Help & Support',
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}
