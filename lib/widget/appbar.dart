import 'package:finance_mvp/constants/app_colors.dart';
import 'package:flutter/material.dart';

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  const HomeAppBar({super.key, this.title});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: title,
      centerTitle: true,
      backgroundColor: AppColors.background,
      elevation: 0,
      toolbarHeight: 64,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: CircleAvatar(
            radius: 22,
            backgroundColor: Colors.white,
            child: IconButton(
              icon: const Icon(Icons.add, color: AppColors.primary, size: 26),
              onPressed: () {
                Navigator.pushNamed(context, '/v1/transactions/create');
              },
              padding: EdgeInsets.zero,
              iconSize: 26,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.primary,
            child: IconButton(
              icon: const Icon(Icons.settings, color: Colors.white, size: 26),
              onPressed: () {
                Navigator.pushNamed(context, '/v1/config');
              },
              padding: EdgeInsets.zero,
              iconSize: 26,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(64);
}