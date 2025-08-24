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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: const PreferredSize(
      //   preferredSize: Size.fromHeight(kToolbarHeight),
      //   child: HomeAppBar(),
      // ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                        fontSize: 36,
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
                      child: const IconButton(
                        icon: Icon(Icons.add, color: Color(0xFF1A3A1B)),
                        onPressed: null, // No action
                      ),
                    ),
                    const SizedBox(width: 10),
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
            const TransactionCard(
              title: 'Summary',
              amount: 1000,
              displayAmount: '\$1000.00 USD', // This should be calculated dynamically in a real app
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
            const Expanded(
              child: TransactionListView(),
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
                      color: Colors.grey.withOpacity(0.1),
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
