import 'package:finance_mvp/constants/app_colors.dart';
import 'package:finance_mvp/database/app_database.dart';
import 'package:finance_mvp/repositories/finance_repository.dart';
import 'package:finance_mvp/services/profile_picture_service.dart';
import 'package:finance_mvp/widgets/profile_avatar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _saving = false;

  Future<void> _changePicture() async {
    if (_saving) return;
    setState(() => _saving = true);
    final path = await pickImageFromGallery();
    if (path != null && mounted) {
      await context.read<FinanceRepository>().saveProfilePicturePath(path);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture updated')),
        );
      }
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<FinanceRepository>();
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
        backgroundColor: context.colors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.colors.textDark),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: StreamBuilder<UserSetting?>(
        stream: repo.watchUserSettings(),
        builder: (context, snapshot) {
          final username = snapshot.data?.username;
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ProfileAvatar(
                    size: 160,
                    showEditBadge: true,
                    onEdit: _changePicture,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    username?.trim().isNotEmpty == true ? username! : 'User',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: context.colors.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the edit icon to change your profile picture',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: context.colors.textLight),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}