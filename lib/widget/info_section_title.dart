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
    return GestureDetector(
    onTap: onTap,
    child: Align(
    heightFactor: 0.9,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: context.colors.stackCardBackground[index],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
            children: [
              CircleAvatar(
                backgroundColor: context.colors.textDark,
                child: Icon(icon, color: context.colors.background),
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: context.colors.textDark,
                ),
              ),
              const Spacer(),
              // Text(
              //   actionText,
              //   style: const TextStyle(
              //     fontSize: 14,
              //     fontWeight: FontWeight.w600,
              //     color: context.colors.primary,
              //   ),
              // ),
              Icon(Icons.chevron_right,
                  color: context.colors.primary, size: 20),
              const SizedBox(width: 50),
            ],
          )),
    ));
  }
}
