import 'package:finance_mvp/constants/app_colors.dart';
import 'package:flutter/material.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final List<Map<String, dynamic>> _categories = [
    {'id': 1, 'name': 'Services', 'icon': Icons.bookmark, 'color': Colors.blue},
    {'id': 2, 'name': 'Food', 'icon': Icons.fastfood, 'color': Colors.orange},
    {'id': 3, 'name': 'Transport', 'icon': Icons.directions_car, 'color': Colors.red},
    {'id': 4, 'name': 'Shopping', 'icon': Icons.shopping_bag, 'color': Colors.purple},
    {'id': 5, 'name': 'Utilities', 'icon': Icons.lightbulb, 'color': Colors.green},
    {'id': 6, 'name': 'Entertainment', 'icon': Icons.movie, 'color': Colors.teal},
    {'id': 7, 'name': 'Health', 'icon': Icons.health_and_safety, 'color': Colors.pink},
    {'id': 8, 'name': 'Education', 'icon': Icons.school, 'color': Colors.indigo},
    {'id': 9, 'name': 'Salary', 'icon': Icons.attach_money, 'color': Colors.greenAccent},
    {'id': 10, 'name': 'Investments', 'icon': Icons.trending_up, 'color': Colors.lightBlue},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Select Category',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: ListView.builder(
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];

          return ListTile(
            leading: Icon(category['icon'], color: category['color']),
            title: Text(category["name"]),
            onTap: () {
              Navigator.pop(context, category);
            }
          );
        },
      ),
    );
  }
}
