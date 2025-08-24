import 'package:finance_mvp/widget/transaction_card.dart';
import 'package:flutter/material.dart';

class TransactionListView extends StatefulWidget {
  const TransactionListView({super.key});

  @override
  State<TransactionListView> createState() => _TransactionListViewState();
}

class _TransactionListViewState extends State<TransactionListView> {
  final List<Map<String, dynamic>> _allTransactions = [
    {
      'title': 'Banesco Panama',
      'display_amount': '+ \$3,907.01 USD',
      'amount': 3907.01,
      // 'iconPath': 'assets/revolut_logo.png', // Placeholder for Revolut logo
      'iconBackgroundColor': Colors.grey[100],
    },
    {
      'title': 'Cash',
      'display_amount': '+ \$3,402.00 USD',
      'amount': 3402.00,
      // 'iconPath': 'assets/behance_logo.png', // Placeholder for Behance logo
      'iconBackgroundColor': Colors.blue[50],
    },
    {
      'title': 'Binance (USDT)',
      'display_amount': '+ \$1,337.99 USD',
      'amount': 1337.99,
      // 'iconPath': 'assets/okx_logo.png', // Placeholder for OKX logo
      'iconBackgroundColor': Colors.black87,
    },
    {
      'title': 'Binance (BTC)',
      'display_amount': '+ \$150.66 USD',
      'amount': 150.66,
      // 'iconPath': 'assets/okx_logo.png',
      // 'defaultIcon': Icons.account_balance,
      'iconBackgroundColor': Colors.purple[50],
    },
    {
      'title': 'Reserve / Ugly Cash (USD)',
      'display_amount': '+ \$44.48 USD',
      'amount': 44.48,
      // 'iconPath': 'assets/okx_logo.png',
      'defaultIcon': Icons.work,
      'iconBackgroundColor': Colors.orange[50],
    },
  ];

  List<Map<String, dynamic>> _displayedTransactions = [];
  int _itemsPerPage = 3; // Number of items to load initially and per "page"
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadMoreItems(); // Load initial items
  }

  Future<void> _loadMoreItems() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    int startIndex = _displayedTransactions.length;
    int endIndex = startIndex + _itemsPerPage;
    if (endIndex > _allTransactions.length) {
      endIndex = _allTransactions.length;
    }

    setState(() {
      _displayedTransactions.addAll(_allTransactions.sublist(startIndex, endIndex));
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Add the "Total" card if there are transactions
    List<Widget> cards = <Widget>[];
    if (_allTransactions.isNotEmpty) {
      double totalAmount = _allTransactions.map((data) => data["amount"]).reduce((x, y) => x + y);
      cards.add(
        TransactionCard(
          title: 'Total',
          amount: totalAmount,
          displayAmount: '+ \$$totalAmount USD', // This should be calculated dynamically in a real app
          isTotalCard: true,
        ),
      );
    }

    // Add the "Total" card at the end
    cards = _displayedTransactions.map((data) {
      return TransactionCard(
        title: data['title'],
        amount: data["amount"],
        displayAmount: data['display_amount'],
        iconPath: data['iconPath'],
        defaultIcon: data['defaultIcon'],
        iconBackgroundColor: data['iconBackgroundColor'],
      );
    }).toList();

    return ListView.builder(
      itemCount: cards.length + (_isLoading || _displayedTransactions.length < _allTransactions.length ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < cards.length) {
          return cards[index];
        } else {
          // This is the loading indicator or a "Load More" button
          if (_displayedTransactions.length < _allTransactions.length) {
            // Only show load more if there are more items to load
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Center(
                child: _isLoading
                    ? const CircularProgressIndicator(
                        color: Color(0xFF4CAF50),
                      )
                    : ElevatedButton(
                        onPressed: _loadMoreItems,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CAF50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                        ),
                        child: const Text(
                          'Load More',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
              ),
            );
          } else {
            return const SizedBox.shrink(); // No more items to load
          }
        }
      },
    );
  }
}
