import 'package:finance_mvp/constants/app_colors.dart';
import 'package:finance_mvp/database/app_database.dart' as db;
import 'package:finance_mvp/repositories/finance_repository.dart';
import 'package:finance_mvp/screens/transaction_list_view.dart';
import 'package:finance_mvp/services/currency_converter.dart';
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

  /// Net total of all transactions converted to the base currency.
  Future<({double total, String baseCode, String baseSymbol})> _netTotalInBase(
      FinanceRepository repo, List<db.Transaction> transactions) async {
    final baseCode = await repo.getBaseCurrencyCode();
    double sum = 0;
    for (final t in transactions) {
      sum += await repo.toBaseAmount(t);
    }
    final currencies = await repo.getAllCurrencies();
    final baseSymbol = currencies.isNotEmpty
        ? currencies
            .firstWhere((c) => c.code == baseCode,
                orElse: () => currencies.first)
            .symbol
        : baseCode;
    return (total: sum, baseCode: baseCode, baseSymbol: baseSymbol);
  }

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

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.05),
                _buildHeader(context),
                const SizedBox(height: 20),
                FutureBuilder<
                    ({double total, String baseCode, String baseSymbol})>(
                  future: _netTotalInBase(repo, allTransactions),
                  builder: (context, snapshot) {
                    final total = snapshot.data?.total ?? 0.0;
                    final baseSymbol = snapshot.data?.baseSymbol ?? r'$';
                    return TransactionCard(
                      title: 'Summary',
                      amount: total,
                      displayAmount: formatMoney(total, symbol: baseSymbol),
                      isTotalCard: true,
                    );
                  },
                ),
                const SizedBox(height: 40),
                _buildMonthSelector(),
                const SizedBox(height: 16),
                Expanded(
                  child:
                      TransactionListView(transactions: filteredTransactions),
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
    final brand = context.colors.primary;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back, color: brand),
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(width: 15),
            Text(
              'Transactions',
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: brand),
            ),
          ],
        ),
        Row(
          children: [
            _buildCircleIconButton(Icons.add,
                () => Navigator.pushNamed(context, '/v1/transactions/create')),
            const SizedBox(width: 5),
            _buildCircleIconButton(Icons.search, null, isSearch: true),
          ],
        ),
      ],
    );
  }

  Widget _buildCircleIconButton(IconData icon, VoidCallback? onTap,
      {bool isSearch = false}) {
    return Container(
      decoration: BoxDecoration(
        color: isSearch
            ? context.colors.primary
            : context.colors.primaryLight.withValues(alpha: 0.3),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon:
            Icon(icon, color: isSearch ? Colors.white : context.colors.primary),
        onPressed: onTap,
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'This month',
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: context.colors.textLight),
        ),
        Icon(Icons.keyboard_arrow_down, color: context.colors.textLight),
      ],
    );
  }

  Widget _buildToggleSection() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: context.colors.cardBackground,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
                color: context.colors.primaryLight.withValues(alpha: 0.15),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, 3))
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: ['All', 'In', 'Out']
              .map((text) => _buildToggleButton(text))
              .toList(),
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
          color: isSelected ? context.colors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Text(
          text,
          style: TextStyle(
              color: isSelected ? Colors.white : context.colors.textLight,
              fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
