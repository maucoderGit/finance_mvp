import 'package:finance_mvp/constants/app_colors.dart';
import 'package:finance_mvp/models/budget.dart';
import 'package:finance_mvp/widget/custom_segmented_control.dart';
import 'package:finance_mvp/widget/filter_chip.dart';
import 'package:finance_mvp/widget/summary_card.dart';
import 'package:finance_mvp/widget/transaction_row.dart';
import 'package:flutter/material.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({Key? key}) : super(key: key);

  @override
  _BudgetScreenState createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final Budget _budget = Budget(
    currentBalance: 1450.75,
    netFlow: 250.25,
    budgetRemaining: 350,
    budgetSpent: 650,
    budgetTotal: 1000,
  );

  final List<Transaction> _transactions = [
    Transaction(
      icon: 'music_note',
      title: 'Spotify Subscription',
      date: 'Oct 28, 2023',
      amount: 10.99,
      isExpense: true,
    ),
    Transaction(
      icon: 'work',
      title: 'Salary',
      date: 'Oct 25, 2023',
      amount: 2500.00,
      isExpense: false,
    ),
    Transaction(
      icon: 'shopping_cart',
      title: 'Groceries',
      date: 'Oct 22, 2023',
      amount: 85.40,
      isExpense: true,
    ),
  ];

  int _selectedFilter = 0;
  int _selectedSegment = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Financial Plan'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.show_chart),
            onPressed: () {
              Navigator.pushNamed(context, '/v1/forecast');
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SummaryCard(budget: _budget),
            ),
            SizedBox(
              height: 35,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                children: [
                  FilterChipWidget(
                    label: 'This Month',
                    isSelected: _selectedFilter == 0,
                    onSelected: () => setState(() => _selectedFilter = 0),
                  ),
                  const SizedBox(width: 8.0),
                  FilterChipWidget(
                    label: 'This Week',
                    isSelected: _selectedFilter == 1,
                    onSelected: () => setState(() => _selectedFilter = 1),
                  ),
                  const SizedBox(width: 8.0),
                  FilterChipWidget(
                    label: 'Last 30 Days',
                    isSelected: _selectedFilter == 2,
                    onSelected: () => setState(() => _selectedFilter = 2),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: CustomSegmentedControl(
                segments: const ['Recent', 'Upcoming'],
                onSegmentChosen: (index) {
                  setState(() {
                    _selectedSegment = index;
                  });
                },
              ),
            ),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _transactions.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8.0),
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: TransactionRow(transaction: _transactions[index]),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add),
                label: const Text('Add Forecast'),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.primary,
                  backgroundColor: AppColors.cardBackground.withValues(alpha: 0.8),
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 16.0),
            Expanded(
              child: TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add),
                label: const Text('Add Record'),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
