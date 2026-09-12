import 'dart:io';

import 'package:finance_mvp/constants/app_colors.dart';
import 'package:finance_mvp/database/app_database.dart' as db;
import 'package:finance_mvp/repositories/finance_repository.dart';
import 'package:finance_mvp/screens/transaction_screen.dart';
import 'package:finance_mvp/services/currency_converter.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

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
      return Center(
          child: Text('No transactions yet',
              style: TextStyle(color: context.colors.textLight)));
    }

    final symbolsFuture = context.read<FinanceRepository>().getAllCurrencies();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title (h2)
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Text(
            'Recent Transactions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: context.colors.textDark,
            ),
          ),
        ),
        // The list of transactions (space-y-3)
        FutureBuilder<List<db.Currency>>(
          future: symbolsFuture,
          builder: (context, snapshot) {
            final symbols = {
              for (final c in snapshot.data ?? const <db.Currency>[])
                c.code: c.symbol,
            };
            return SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.45,
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: widget.transactions.length,
                    itemBuilder: (context, index) {
                      final t = widget.transactions[index];
                      return TransactionItem(
                        transaction: t,
                        symbol: symbols[t.currencyCode] ?? t.currencyCode,
                      );
                    },
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12), // Mimics space-y-3
                  )),
            );
          },
        )
      ],
    );
  }
}

class TransactionItem extends StatelessWidget {
  final db.Transaction transaction;
  final String symbol;

  const TransactionItem(
      {super.key, required this.transaction, required this.symbol});

  @override
  Widget build(BuildContext context) {
    bool isExpense = transaction.amount < 0;
    String amountText = isExpense
        ? '-${formatMoney((-transaction.amount), symbol: symbol)}'
        : '+${formatMoney(transaction.amount, symbol: symbol)}';

    Color amountColor =
        isExpense ? const Color(0xFFC62828) : context.colors.textDark;

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
                        : Icon(
                            Icons.receipt_long,
                            color: context.colors.textDark,
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
                        color: Theme.of(context).textTheme.bodySmall?.color,
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
