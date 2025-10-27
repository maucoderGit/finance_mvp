import 'package:finance_mvp/models/transactions.dart';
import 'package:finance_mvp/screens/transaction_list_view.dart';
import 'package:finance_mvp/widget/transaction_card.dart';
import 'package:flutter/material.dart';

class TransactionPage extends StatefulWidget {
  const TransactionPage({super.key}); // Changed to StatefulWidget

  @override
  State<TransactionPage> createState() => _TransactionPageState();
}

class _TransactionPageState extends State<TransactionPage> {
  String _selectedToggle = 'All'; // State variable for selected toggle

  final List<Transaction> _allTransactions = [
    Transaction(
      title: 'Coffee Shop',
      category: 'Food',
      amount: -5.20,
      icon: Icons.coffee,
      iconColor: Colors.white,
      iconBackgroundColor: Colors.brown,
      date: DateTime.now()
    ),
    Transaction(
      title: 'Dividend Payout',
      category: 'Investments',
      amount: 120.00,
      icon: Icons.trending_up,
      iconColor: Colors.white,
      iconBackgroundColor: Colors.teal,
      date: DateTime.now()
    ),
    Transaction(
      title: 'New Gadget',
      category: 'Shopping',
      amount: -299.99,
      icon: Icons.devices,
      iconColor: Colors.white,
      iconBackgroundColor: Colors.blueGrey,
      date: DateTime.now()
    ),
    Transaction(
      title: 'Book Purchase',
      category: 'Education',
      amount: -25.00,
      icon: Icons.book,
      iconColor: Colors.white,
      iconBackgroundColor: Colors.indigoAccent,
      date: DateTime.now()
    ),
    Transaction(
      title: 'Electricity Bill',
      category: 'Utilities',
      amount: -85.00,
      icon: Icons.lightbulb_outline,
      iconColor: Colors.white,
      iconBackgroundColor: Colors.amber,
      date: DateTime.now()
    ),
    Transaction(
      title: 'Concert Tickets',
      category: 'Entertainment',
      amount: -150.00,
      icon: Icons.music_note,
      iconColor: Colors.white,
      iconBackgroundColor: Colors.deepPurple,
      date: DateTime.now()
    ),
    Transaction(
      title: 'Refund from Store',
      category: 'Income',
      amount: 45.00,
      icon: Icons.refresh,
      iconColor: Colors.white,
      iconBackgroundColor: Colors.lightGreen,
      date: DateTime.now()
    ),
    Transaction(
      title: 'Taxi Ride',
      category: 'Travel',
      amount: -18.50,
      icon: Icons.local_taxi,
      iconColor: Colors.white,
      iconBackgroundColor: Colors.grey,
      date: DateTime.now()
    ),
  ];

  List<Transaction> _displayedTransactions = [];

  double get transactionsTotalAmount => _allTransactions.fold(0.0, (sum, nextTrx) => sum + nextTrx.amount);

  @override
  void initState() {
    _displayedTransactions = _allTransactions;

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.05),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Color(0xFF1A3A1B)),
                      onPressed: () {
                        Navigator.pop(context);
                      }, // No action
                    ),
                    const SizedBox(width: 15),
                    const Text(
                      'Transactions',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A3A1B),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFFD3E6D3),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.add, color: Color(0xFF1A3A1B)),
                        onPressed: () => Navigator.pushNamed(context, '/v1/transactions/create'),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFF1A3A1B),
                        shape: BoxShape.circle,
                      ),
                      child: const IconButton(
                        icon: Icon(Icons.search, color: Colors.white),
                        onPressed: null, // No action
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            TransactionCard(
              title: 'Summary',
              amount: transactionsTotalAmount,
              displayAmount: '\$${(transactionsTotalAmount).toStringAsFixed(2)}', // This should be calculated dynamically in a real app
              isTotalCard: true,
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'This month',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
                Icon(Icons.keyboard_arrow_down, color: Colors.grey[600]),
              ],
            ),
            const SizedBox(height: 16),
            // Transaction List View
            Expanded(
              child: TransactionListView(transactions: _displayedTransactions),
            ),
            const SizedBox(height: 20),
            // In/Out/All Toggle Buttons
            Center(
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey[100]!,
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: _buildToggleButtons(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildToggleButtons() {
    return ['All', 'In', 'Out'].map((text) {
      bool isSelected = (_selectedToggle == text);

      return _buildToggleButton(text, isSelected);
    }).toList();
  }

  Widget _buildToggleButton(String text, bool isSelected) { // Changed to accept isSelected
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedToggle = text;

          _displayedTransactions = _allTransactions.where((transaction) {
            switch (_selectedToggle) {
              case 'All':
                return true;
              case 'In':
                return transaction.amount > 0;
              case 'Out':
                return transaction.amount < 0;
              default:
                return false;
            }
          }).toList();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4CAF50) : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[600],
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
