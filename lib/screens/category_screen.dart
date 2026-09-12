import 'package:finance_mvp/constants/app_colors.dart';
import 'package:finance_mvp/database/app_database.dart' as db;
import 'package:finance_mvp/repositories/finance_repository.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

const Map<String, IconData> categoryIcons = {
  'home_repair_service': Icons.build,
  'restaurant': Icons.restaurant,
  'directions_car': Icons.directions_car,
  'shopping_bag': Icons.shopping_bag,
  'bolt': Icons.bolt,
  'movie': Icons.movie,
  'local_hospital': Icons.local_hospital,
  'school': Icons.school,
  'payments': Icons.payments,
  'trending_up': Icons.trending_up,
  'bookmark': Icons.bookmark,
  'fastfood': Icons.fastfood,
  'lightbulb': Icons.lightbulb,
  'health_and_safety': Icons.health_and_safety,
  'attach_money': Icons.attach_money,
};

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  late Future<List<db.Category>> _categoriesFuture;

  @override
  void initState() {
    super.initState();
    _categoriesFuture = context.read<FinanceRepository>().getAllCategories();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Select Category',
          style: TextStyle(
            color: context.colors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: context.colors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.colors.textDark),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: FutureBuilder<List<db.Category>>(
        future: _categoriesFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final categories = snapshot.data!;
          if (categories.isEmpty) {
            return const Center(child: Text('No categories found.'));
          }
          return ListView.builder(
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              final icon = categoryIcons[category.icon] ?? Icons.bookmark;
              final color = Color(category.color);

              return ListTile(
                leading: Icon(icon, color: color),
                title: Text(category.name),
                onTap: () {
                  Navigator.pop(context, {
                    'id': category.id,
                    'name': category.name,
                    'icon': icon,
                    'color': color,
                  });
                },
              );
            },
          );
        },
      ),
    );
  }
}