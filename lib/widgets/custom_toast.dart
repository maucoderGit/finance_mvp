import 'dart:async';

import 'package:finance_mvp/constants/app_colors.dart';
import 'package:flutter/material.dart';

enum ToastType { success, warning, error }

/// Shows a styled toast pinned to the bottom of the screen via [SnackBar].
void showToast(
  BuildContext context, {
  required String message,
  String? description,
  ToastType type = ToastType.success,
  Duration duration = const Duration(seconds: 3),
}) {
  if (MediaQuery.sizeOf(context).width >= 600) {
    _showCornerToast(
      context,
      message: message,
      description: description,
      type: type,
      duration: duration,
    );
    return;
  }
  final messenger = ScaffoldMessenger.of(context);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: CustomToast(
          title: message,
          description: description ?? '',
          type: type,
          onClose: () => messenger.hideCurrentSnackBar(),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        padding: EdgeInsets.zero,
        duration: duration,
      ),
    );
}

/// Wide screens: top-right corner overlay, auto-dismissed after [duration].
void _showCornerToast(
  BuildContext context, {
  required String message,
  String? description,
  required ToastType type,
  required Duration duration,
}) {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => Positioned(
      top: 12,
      right: 12,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 250),
        builder: (context, value, child) => Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, -8 * (1 - value)),
            child: child,
          ),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 360),
          child: CustomToast(
            title: message,
            description: description ?? '',
            type: type,
            onClose: () => entry.remove(),
          ),
        ),
      ),
    ),
  );
  overlay.insert(entry);
  Timer(duration, () {
    if (entry.mounted) entry.remove();
  });
}

class CustomToast extends StatelessWidget {
  final String title;
  final String description;
  final ToastType type;
  final VoidCallback? onClose;

  const CustomToast({
    super.key,
    required this.title,
    this.description = '',
    this.type = ToastType.success,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final Map<ToastType, _ToastStyle> styles = {
      ToastType.success: const _ToastStyle(
        accentColor: Color(0xFF76D7B1),
        icon: Icons.done_all_rounded,
        shadowColor: Color(0x4076D7B1),
      ),
      ToastType.warning: const _ToastStyle(
        accentColor: Color(0xFFF9BE7C),
        icon: Icons.warning_amber_rounded,
        shadowColor: Color(0x40F9BE7C),
      ),
      ToastType.error: const _ToastStyle(
        accentColor: Color(0xFFF29C93),
        icon: Icons.block_rounded,
        shadowColor: Color(0x40F29C93),
      ),
    };

    final style = styles[type]!;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: [
          BoxShadow(
            color: style.shadowColor,
            blurRadius: 16.0,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: style.accentColor,
              borderRadius: BorderRadius.circular(14.0),
            ),
            child: Icon(
              style.icon,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: const Icon(
              Icons.close_rounded,
              color: Colors.grey,
              size: 22,
            ),
            splashRadius: 20,
          ),
        ],
      ),
    );
  }
}

class _ToastStyle {
  final Color accentColor;
  final IconData icon;
  final Color shadowColor;

  const _ToastStyle({
    required this.accentColor,
    required this.icon,
    required this.shadowColor,
  });
}