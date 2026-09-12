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
      backgroundColor: context.colors.background,
      elevation: 0,
      toolbarHeight: 64,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: Colors.white,
                child: IconButton(
                  icon: Icon(Icons.add, color: context.colors.primary, size: 26),
                  onPressed: () {
                    Navigator.pushNamed(context, '/v1/transactions/create');
                  },
                  padding: EdgeInsets.zero,
                  iconSize: 26,
                ),
              ),
              const SizedBox(width: 4),
              CircleAvatar(
                radius: 22,
                backgroundColor: context.colors.primary,
                child: IconButton(
                  icon: const Icon(Icons.settings, color: Colors.white, size: 26),
                  onPressed: () {
                    Navigator.pushNamed(context, '/v1/config');
                  },
                  padding: EdgeInsets.zero,
                  iconSize: 26,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(64);
}