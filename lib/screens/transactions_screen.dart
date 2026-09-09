import 'package:finance_mvp/database/app_database.dart' as db;
import 'package:finance_mvp/repositories/finance_repository.dart';
import 'package:finance_mvp/screens/transaction_list_view.dart';
import 'package:finance_mvp/widget/transaction_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TransactionPage extends StatefulWidget {
  const TransactionPage({super.key}); // Changed to StatefulWidget

  @override
  State<TransactionPage> createState() => _TransactionPageState();
}

class _TransactionPageState extends State<TransactionPage> {
  String _selectedToggle = 'All'; // State variable for selected toggle

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<FinanceRepository>();

    return Scaffold(
      body: StreamBuilder<List<db.Transaction>>(
        stream: repo.watchTransactions(),
        builder: (context, snapshot) {
          final allTransactions = snapshot.data ?? [];
          final filteredTransactions = allTransactions.where((t) {
            if (_selectedToggle == 'In') return t.amount > 0;
            if (_selectedToggle == 'Out') return t.amount < 0;
            return true;
          }).toList();

          final total = allTransactions.fold(0.0, (sum, t) => sum + t.amount);

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.05),
                _buildHeader(context),
                const SizedBox(height: 20),
                TransactionCard(
                  title: 'Summary',
                  amount: total,
                  displayAmount: '\$${total.toStringAsFixed(2)}',
                  isTotalCard: true,
                ),
                const SizedBox(height: 40),
                _buildMonthSelector(),
                const SizedBox(height: 16),
                Expanded(
                  child: TransactionListView(transactions: filteredTransactions),
                ),
                const SizedBox(height: 20),
                _buildToggleSection(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF1A3A1B)),
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(width: 15),
            const Text(
              'Transactions',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1A3A1B)),
            ),
          ],
        ),
        Row(
          children: [
            _buildCircleIconButton(Icons.add, () => Navigator.pushNamed(context, '/v1/transactions/create')),
            const SizedBox(width: 5),
            _buildCircleIconButton(Icons.search, null, isSearch: true),
          ],
        ),
      ],
    );
  }

  Widget _buildCircleIconButton(IconData icon, VoidCallback? onTap, {bool isSearch = false}) {
    return Container(
      decoration: BoxDecoration(
        color: isSearch ? const Color(0xFF1A3A1B) : const Color(0xFFD3E6D3),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: isSearch ? Colors.white : const Color(0xFF1A3A1B)),
        onPressed: onTap,
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'This month',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey),
        ),
        Icon(Icons.keyboard_arrow_down, color: Colors.grey[600]),
      ],
    );
  }

  Widget _buildToggleSection() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [BoxShadow(color: Colors.grey[100]!, spreadRadius: 1, blurRadius: 5, offset: const Offset(0, 3))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: ['All', 'In', 'Out'].map((text) => _buildToggleButton(text)).toList(),
        ),
      ),
    );
  }

  Widget _buildToggleButton(String text) {
    bool isSelected = (_selectedToggle == text);
    return GestureDetector(
      onTap: () => setState(() => _selectedToggle = text),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4CAF50) : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Text(
          text,
          style: TextStyle(color: isSelected ? Colors.white : Colors.grey[600], fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
