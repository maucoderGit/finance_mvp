import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class InfoSectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String actionText;
  final int index;
  final VoidCallback onTap;

  const InfoSectionTitle({
    super.key,
    required this.icon,
    required this.title,
    required this.index,
    required this.actionText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      heightFactor: 0.9,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 30),
        decoration: BoxDecoration(
          color: AppColors.stackCardBackground[index],
          borderRadius: BorderRadius.circular(16),
        ),
        child: GestureDetector(
          onTap: onTap,
          child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.textDark,
              child: Icon(icon, color: AppColors.background),
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const Spacer(),
            Text(
              actionText,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.primary, size: 20),
            const SizedBox(width: 50),
          ],
        )),
      )
    );
  }
}