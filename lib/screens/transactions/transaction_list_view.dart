import 'dart:io';

import 'package:finance_mvp/constants/app_colors.dart';
import 'package:finance_mvp/database/app_database.dart' as db;
import 'package:finance_mvp/repositories/finance_repository.dart';
import 'package:finance_mvp/screens/transactions/transaction_screen.dart';
import 'package:finance_mvp/services/finance/currency_converter.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// Flat list of the given transactions (newest first) split under a header per
/// day, so a period of hundreds of moves stays scannable.
class TransactionListView extends StatefulWidget {
  final List<db.Transaction> transactions;
  final String emptyMessage;

  const TransactionListView({
    super.key,
    required this.transactions,
    this.emptyMessage = 'No transactions yet',
  });

  @override
  State<TransactionListView> createState() => _TransactionListViewState();
}

class _TransactionListViewState extends State<TransactionListView> {
  @override
  Widget build(BuildContext context) {
    if (widget.transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 32, color: context.colors.textLight),
            const SizedBox(height: 8),
            Text(widget.emptyMessage,
                style: TextStyle(color: context.colors.textLight)),
          ],
        ),
      );
    }

    final repo = context.read<FinanceRepository>();

    return FutureBuilder<
        ({List<db.Currency> currencies, List<db.Contact> contacts})>(
      future: () async {
        final currencies = await repo.getAllCurrencies();
        final contacts = await repo.getAllContacts();
        return (currencies: currencies, contacts: contacts);
      }(),
      builder: (context, snapshot) {
        final symbols = {
          for (final c in snapshot.data?.currencies ?? const <db.Currency>[])
            c.code: c.symbol,
        };
        final contactNames = {
          for (final c in snapshot.data?.contacts ?? const <db.Contact>[])
            c.id: c.name,
        };

        // Flat [DateTime?] = day header, [db.Transaction?] = row. Only these
        // cheap records are built up front; widgets are built per visible
        // item, so an "All time" list of thousands still scrolls flat.
        final entries = <({DateTime? day, db.Transaction? tx})>[];
        DateTime? lastDay;
        for (final t in widget.transactions) {
          final day = DateTime(t.date.year, t.date.month, t.date.day);
          if (day != lastDay) {
            lastDay = day;
            entries.add((day: day, tx: null));
          }
          entries.add((day: null, tx: t));
        }

        return ListView.builder(
          padding: const EdgeInsets.only(top: 4),
          itemCount: entries.length,
          itemBuilder: (context, index) {
            final e = entries[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: e.day != null
                  ? _DayHeader(day: e.day!)
                  : TransactionItem(
                      transaction: e.tx!,
                      symbol: symbols[e.tx!.currencyCode] ?? e.tx!.currencyCode,
                      contactName: e.tx!.contactId == null
                          ? null
                          : contactNames[e.tx!.contactId],
                      showDate: false,
                    ),
            );
          },
        );
      },
    );
  }
}

class _DayHeader extends StatelessWidget {
  final DateTime day;

  const _DayHeader({required this.day});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final label = day == today
        ? 'Today'
        : day == today.subtract(const Duration(days: 1))
            ? 'Yesterday'
            : DateFormat('EEEE, MMM d').format(day);

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: context.colors.textLight,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(height: 1, color: context.colors.cardBorder),
          ),
        ],
      ),
    );
  }
}

class TransactionItem extends StatelessWidget {
  final db.Transaction transaction;
  final String symbol;
  final String? contactName;

  /// Show the date under the title. Off when the list already groups rows
  /// under a day header.
  final bool showDate;

  const TransactionItem(
      {super.key,
      required this.transaction,
      required this.symbol,
      this.contactName,
      this.showDate = true});

  @override
  Widget build(BuildContext context) {
    bool isExpense = transaction.amount < 0;
    String amountText = isExpense
        ? '-${formatMoney((-transaction.amount), symbol: symbol)}'
        : '+${formatMoney(transaction.amount, symbol: symbol)}';

    Color amountColor =
        isExpense ? const Color(0xFFC62828) : context.colors.textDark;

    final subtitle = [
      if (showDate) DateFormat('MMM dd, yyyy').format(transaction.date),
      if (contactName?.trim().isNotEmpty == true) contactName!.trim(),
    ].join(' · ');

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
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: context.colors.cardBackground,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: context.colors.cardBorder),
        ),
        child: Row(
          children: [
            // Icon Container (w-10 h-10 rounded-full)
            ClipOval(
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.colors.primaryLight.withValues(alpha: 0.15),
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
                        color: context.colors.textLight,
                        size: 20,
                      ),
              ),
            ),
            const SizedBox(width: 12), // mr-3 equivalent
            // Title and subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.reference?.trim().isNotEmpty == true
                        ? transaction.reference!.trim()
                        : 'Transaction',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: context.colors.textDark,
                    ),
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: context.colors.textLight,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Amount
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
