import 'dart:io';

import 'package:finance_mvp/constants/app_colors.dart';
import 'package:finance_mvp/database/app_database.dart';
import 'package:finance_mvp/repositories/finance_repository.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

enum ProfileAvatarShape { circle, roundedRect }

/// User profile picture that follows [UserSetting.profilePicturePath].
/// Falls back to a placeholder while the picture is unset.
class ProfileAvatar extends StatelessWidget {
  final double size;
  final ProfileAvatarShape shape;
  final bool showEditBadge;
  final VoidCallback? onEdit;

  const ProfileAvatar({
    super.key,
    required this.size,
    this.shape = ProfileAvatarShape.circle,
    this.showEditBadge = false,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final repo = context.read<FinanceRepository>();
    return StreamBuilder<UserSetting?>(
      stream: repo.watchUserSettings(),
      builder: (context, snapshot) {
        final path = snapshot.data?.profilePicturePath;
        final file =
            (path != null && File(path).existsSync()) ? File(path) : null;

        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              if (shape == ProfileAvatarShape.roundedRect)
                ClipRRect(
                  borderRadius: BorderRadius.circular(size * 0.19),
                  child: _buildContent(file),
                )
              else
                ClipOval(child: _buildContent(file)),
              if (showEditBadge && onEdit != null)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: GestureDetector(
                    onTap: onEdit,
                    child: CircleAvatar(
                      radius: size * 0.14,
                      backgroundColor: context.colors.primary,
                      child:
                          const Icon(Icons.edit, color: Colors.white, size: 20),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContent(File? file) {
    if (file != null) {
      return Image.file(file, width: size, height: size, fit: BoxFit.cover);
    }
    return Container(
      width: size,
      height: size,
      color: const Color(0xFFFFEEFE),
      child: Icon(
        Icons.person_outline,
        size: size * 0.5,
        color: Colors.grey[400],
      ),
    );
  }
}