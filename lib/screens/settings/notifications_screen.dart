import 'package:finance_mvp/constants/app_colors.dart';
import 'package:finance_mvp/l10n/l10n.dart';
import 'package:finance_mvp/providers/notification_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  String _hm(int hour, int minute) =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  Future<void> _configure(BuildContext context, {bool? enabled, int? hour, int? minute}) async {
    final provider = context.read<NotificationProvider>();
    await provider.configure(
      enabled: enabled ?? provider.enabled,
      hour: hour ?? provider.hour,
      minute: minute ?? provider.minute,
      title: context.l10n.notificationReminderTitle,
      body: context.l10n.notificationReminderBody,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: Text(context.l10n.notificationsTitle),
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
          Material(
            color: context.colors.cardBackground,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: context.colors.cardBorder),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  value: provider.enabled,
                  activeThumbColor: context.colors.primary,
                  title: Text(
                    context.l10n.notificationReminderToggle,
                    style: TextStyle(color: context.colors.textDark),
                  ),
                  subtitle: Text(
                    context.l10n.notificationReminderToggleSubtitle,
                    style: TextStyle(color: context.colors.textLight),
                  ),
                  onChanged: (value) async {
                    if (value) {
                      await _configure(context, enabled: true);
                    } else {
                      await _configure(context, enabled: false);
                    }
                  },
                ),
                if (provider.enabled)
                  ListTile(
                    title: Text(
                      context.l10n.notificationReminderTime,
                      style: TextStyle(color: context.colors.textDark),
                    ),
                    trailing: Text(
                      _hm(provider.hour, provider.minute),
                      style: TextStyle(
                        color: context.colors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialEntryMode: TimePickerEntryMode.input,
                        initialTime: TimeOfDay(
                            hour: provider.hour, minute: provider.minute),
                      );
                      if (picked != null && context.mounted) {
                        await _configure(
                          context,
                          hour: picked.hour,
                          minute: picked.minute,
                        );
                      }
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}