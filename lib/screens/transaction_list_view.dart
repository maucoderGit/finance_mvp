import 'package:finance_mvp/models/transactions.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TransactionListView extends StatefulWidget {
  final List<Transaction> transactions;
  const TransactionListView({super.key, required this.transactions});

  @override
  State<TransactionListView> createState() => _TransactionListViewState();
}

class _TransactionListViewState extends State<TransactionListView> {
  final List<Transaction> _displayedTransactions = [];
  final int _itemsPerPage =
      8; // Number of items to load initially and per "page"
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

    int startIndex = _displayedTransactions.length;
    int endIndex = startIndex + _itemsPerPage;
    if (endIndex > widget.transactions.length) {
      endIndex = widget.transactions.length;
    }

    setState(() {
      _displayedTransactions
          .addAll(widget.transactions.sublist(startIndex, endIndex));
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title (h2)
        const Padding(
          padding: EdgeInsets.only(bottom: 16.0),
          child: Text(
            'Recent Transactions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              // Note: For full dark/light theme support, you'd use Theme.of(context).textTheme...
            ),
          ),
        ),
        // The list of transactions (space-y-3)
        SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.45,
            child: ListView.separated(
            shrinkWrap: true,
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: widget.transactions.length,
            itemBuilder: (context, index) {
              return TransactionItem(transaction: widget.transactions[index]);
            },
            separatorBuilder: (context, index) =>
                const SizedBox(height: 12), // Mimics space-y-3
          )),
        )
      ],
    );
  }
}

class TransactionItem extends StatelessWidget {
  final Transaction transaction;

  const TransactionItem({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    // Determine text color based on amount sign
    bool isExpense = transaction.amount < 0;
    String amountText = isExpense
        ? '-\$${(-transaction.amount).toStringAsFixed(2)}'
        : '+\$${transaction.amount.toStringAsFixed(2)}';

    Color amountColor = isExpense ? Colors.red.shade600 : Colors.green.shade600;

    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .cardColor, // A good substitute for surface-light/dark
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: const [
          BoxShadow(
            color: Colors.grey,
            spreadRadius: 0.01,
            blurRadius: 0.3,
            offset: Offset(0, 0.01), // subtle shadow
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left side: Icon, Title, and Category
          Row(
            children: [
              // Icon Container (w-10 h-10 rounded-full)
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: transaction.iconBackgroundColor,
                ),
                child: Icon(
                  transaction.icon,
                  color: transaction.iconColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12), // mr-3 equivalent
              // Title and Category Text
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      // text-text-light dark:text-text-dark
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    transaction.category,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey, // text-sm text-text-secondary...
                    ),
                  ),
                  Text(
                    transaction.date != null
                        ? DateFormat('MMM dd, yyyy').format(transaction.date!)
                        : '',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.color, // text-sm text-text-secondary...
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Right side: Amount
          Text(
            amountText,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: amountColor,
            ),
          ),
        ],
      ),
    );
  }
}
