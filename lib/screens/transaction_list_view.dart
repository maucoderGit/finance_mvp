import 'dart:io';

import 'package:finance_mvp/database/app_database.dart' as db;
import 'package:finance_mvp/screens/transaction_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TransactionListView extends StatefulWidget {
  final List<db.Transaction> transactions;
  const TransactionListView({super.key, required this.transactions});

  @override
  State<TransactionListView> createState() => _TransactionListViewState();
}

class _TransactionListViewState extends State<TransactionListView> {
  @override
  Widget build(BuildContext context) {
    if (widget.transactions.isEmpty) {
      return const Center(child: Text('No transactions yet', style: TextStyle(color: Colors.grey)));
    }

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
  final db.Transaction transaction;

  const TransactionItem({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    bool isExpense = transaction.amount < 0;
    String amountText = isExpense
        ? '-\$${(-transaction.amount).toStringAsFixed(2)}'
        : '+\$${transaction.amount.toStringAsFixed(2)}';

    Color amountColor = isExpense ? Colors.red.shade600 : const Color(0xFF0B2013);

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                TransactionScreen(existingTransaction: transaction),
          ),
        );
      },
      child: Container(
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
                ClipOval(
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey[200],
                    ),
                    child: transaction.imagePath != null &&
                            File(transaction.imagePath!).existsSync()
                        ? Image.file(
                            File(transaction.imagePath!),
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                          )
                        : const Icon(
                            Icons.receipt_long,
                            color: Colors.black,
                            size: 20,
                          ),
                  ),
                ),
                const SizedBox(width: 12), // mr-3 equivalent
                // Title and Category Text
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.reference ?? 'Transaction',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      DateFormat('MMM dd, yyyy').format(transaction.date),
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.color,
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
      ),
    );
  }
}
