

import 'package:flutter/material.dart';

class Transaction {
  final String title;
  final String category;
  final double amount;
  final IconData icon;
  final Color iconColor;
  final Color iconBackgroundColor;
  final DateTime? date;

  Transaction({
    required this.title,
    required this.category,
    required this.amount,
    required this.icon,
    required this.iconColor,
    required this.iconBackgroundColor,
    required this.date,
  });
}