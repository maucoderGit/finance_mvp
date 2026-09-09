import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MonthFilterWidget extends StatefulWidget {
  final Function(DateTime) onDateSelected;

  const MonthFilterWidget({super.key, required this.onDateSelected});

  @override
  State<MonthFilterWidget> createState() => _MonthFilterWidgetState();
}

class _MonthFilterWidgetState extends State<MonthFilterWidget> {
  DateTime _selectedDate = DateTime.now();

  Future<void> _selectDate(BuildContext context) async {
    // For simplicity, using a standard date picker.
    // This can be replaced with a custom month/year picker if needed.
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      widget.onDateSelected(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _selectDate(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFE8E8E4), // surface-container-high
          borderRadius: BorderRadius.circular(9999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(DateFormat('MMMM yyyy').format(_selectedDate), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(width: 4),
            const Icon(Icons.expand_more, size: 20),
          ],
        ),
      ),
    );
  }
}