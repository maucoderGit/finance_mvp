import 'dart:io';

import 'package:finance_mvp/constants/app_colors.dart';
import 'package:finance_mvp/widget/appbar.dart';
import 'package:finance_mvp/widget/info_section_title.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';


class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const HomeAppBar(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              const _UserGreeting(),
              const SizedBox(height: 30),
              const _ActionButtons(),
              const SizedBox(height: 40),
              InfoSectionTitle(
                icon: Icons.arrow_downward_rounded,
                title: 'Recent withdrawals',
                index: 0,
                actionText: 'View all',
                onTap: () {},
              ),
              InfoSectionTitle(
                icon: Icons.arrow_upward_rounded,
                title: 'Upcoming payments',
                index: 1,
                actionText: 'Get paid',
                onTap: () {},
              ),
              InfoSectionTitle(
                icon: Icons.account_balance_wallet_outlined,
                title: 'My balance',
                index: 2,
                actionText: 'Review',
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserGreeting extends StatefulWidget {
  const _UserGreeting();

  @override
  State<_UserGreeting> createState() => _UserGreetingState();
}

class _UserGreetingState extends State<_UserGreeting> {
  final ImagePicker _picker = ImagePicker();
  String? _imagePath;

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
  }

  /// Loads the saved image path from SharedPreferences.
  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _imagePath = prefs.getString('profileImagePath');
    });
  }

  /// Opens the image gallery and saves the selected image path.
  Future<void> _pickImage() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _imagePath = prefs.getString('profileImagePath');
    });
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      await prefs.setString('profileImagePath', image.path);
      setState(() {
        _imagePath = image.path;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: _imagePath != null
                  ? FileImage(File(_imagePath!))
                  : const NetworkImage(
                          'https://placehold.co/100x100/4A6A54/FFFFFF?text=JP')
                      as ImageProvider,
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: _pickImage,
                child: const CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primary,
                  child: Icon(
                    Icons.edit,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'Hi,',
          style: TextStyle(
            fontSize: 18,
            color: AppColors.textLight,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Maucoder',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
      ],
    );
  }
}

// --- widgets/action_buttons.dart ---
// Row of main action buttons (Add, Withdraw, Transfer).
class _ActionButtons extends StatelessWidget {
  const _ActionButtons();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _ActionButton(icon: Icons.add, label: 'Add money'),
        _ActionButton(icon: Icons.arrow_downward, label: 'Withdraw'),
        _ActionButton(icon: Icons.swap_horiz, label: 'Transfer'),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ActionButton({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: Colors.white,
          child: Icon(icon, color: AppColors.primary, size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}