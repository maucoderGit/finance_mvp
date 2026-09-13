import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:finance_mvp/constants/account_icons.dart';
import 'package:finance_mvp/constants/app_colors.dart';
import 'package:finance_mvp/database/app_database.dart' as db;
import 'package:finance_mvp/repositories/finance_repository.dart';
import 'package:finance_mvp/screens/accounts/add_account_sheet.dart';
import 'package:finance_mvp/services/finance/currency_converter.dart';

class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  void _showAccountSheet(BuildContext context, {db.Account? account}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (_, controller) => Container(
            decoration: BoxDecoration(
                color: context.colors.background,
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16))),
            child: AddAccountSheet(existing: account)),
      ),
    );
  }

  Future<void> _adjustBalance(
      BuildContext context, db.Account account, double currentBalance) async {
    final repository = context.read<FinanceRepository>();
    final controller =
        TextEditingController(text: currentBalance.toStringAsFixed(2));

    final bool? shouldSave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Adjust ${account.name} balance'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'New balance'),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Sets the balance to this value. A "Balance adjustment" '
                'transaction is recorded for the difference.',
                style: TextStyle(
                    color: context.colors.textLight, fontSize: 12, height: 1.4),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Save')),
        ],
      ),
    );

    if (shouldSave == true) {
      final value = double.tryParse(controller.text);
      if (value == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Enter a valid balance.')),
          );
        }
        return;
      }
      await repository.adjustAccountBalance(
        accountId: account.id,
        currencyCode: account.currencyCode,
        newBalance: value,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final repository = context.watch<FinanceRepository>();

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: context.colors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.colors.textDark),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Finance',
          style: TextStyle(
            color: context.colors.textDark,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: false,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAccountSheet(context),
        backgroundColor: context.colors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<List<db.Account>>(
        stream: repository.watchAccounts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final accounts = snapshot.data ?? [];

          return SingleChildScrollView(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'BALANCE',
                    style: TextStyle(
                      color: context.colors.textLight,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  FutureBuilder<({String code, String symbol})>(
                    future: () async {
                      final code = await repository.getBaseCurrencyCode();
                      return (
                        code: code,
                        symbol: await repository.getBaseCurrencySymbol(),
                      );
                    }(),
                    builder: (context, balanceSnapshot) {
                      final baseCurrencyCode =
                          balanceSnapshot.data?.code ?? 'USD';
                      final baseSymbol = balanceSnapshot.data?.symbol ?? r'$';
                      return FutureBuilder<double>(
                        future:
                            repository.calculateTotalBalance(baseCurrencyCode),
                        builder: (context, totalSnapshot) {
                          final total = totalSnapshot.data ?? 0.0;
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                formatMoney(total, symbol: baseSymbol),
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w700,
                                  color: context.colors.primary,
                                  letterSpacing: -1,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(
                                    bottom: 8.0, left: 8.0),
                                child: Text(
                                  baseCurrencyCode,
                                  style: TextStyle(
                                    color: context.colors.textLight,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'My Accounts',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: context.colors.textDark,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: context.colors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${accounts.length} ACTIVE',
                          style: TextStyle(
                            color: context.colors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ...accounts.map((account) =>
                      FutureBuilder<Map<String, dynamic>>(
                        future: () async {
                          final allTransactions = await repository.db
                              .select(repository.db.transactions)
                              .get();
                          final accountBalance = allTransactions
                              .where((t) => t.accountId == account.id)
                              .fold<double>(0.0, (sum, t) => sum + t.amount);

                          final baseCurrencyCode =
                              await repository.getBaseCurrencyCode();
                          final converted = await repository.convertAmount(
                            amount: accountBalance,
                            fromCode: account.currencyCode,
                            toCode: baseCurrencyCode,
                          );
                          return {
                            'balance': accountBalance,
                            'converted': converted,
                            'baseCode': baseCurrencyCode
                          };
                        }(),
                        builder: (context, balanceSnapshot) {
                          final balance =
                              balanceSnapshot.data?['balance'] ?? 0.0;
                          final converted = balanceSnapshot.data?['converted'];
                          final baseCode =
                              balanceSnapshot.data?['baseCode'] ?? 'USD';
                          return _AccountCard(
                            name: account.name,
                            subtitle: account.subtitle ?? '',
                            amount: balance,
                            currencyCode: account.currencyCode,
                            convertedAmount: converted,
                            baseCurrencyCode: baseCode,
                            icon: accountIconFor(account.icon),
                            iconColor: account.iconColor,
                            onAdjustBalance: () =>
                                _adjustBalance(context, account, balance),
                            onTap: () =>
                                _showAccountSheet(context, account: account),
                          );
                        },
                      )),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  final String name;
  final String subtitle;
  final double amount;
  final String currencyCode;
  final double? convertedAmount;
  final String baseCurrencyCode;
  final IconData icon;
  final int iconColor;
  final VoidCallback onAdjustBalance;
  final VoidCallback onTap;

  const _AccountCard({
    required this.name,
    required this.subtitle,
    required this.amount,
    required this.currencyCode,
    this.convertedAmount,
    required this.baseCurrencyCode,
    required this.icon,
    required this.iconColor,
    required this.onAdjustBalance,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: context.colors.background,
            borderRadius: BorderRadius.circular(16),
            border:
                BoxBorder.all(color: context.colors.cardBorder, width: 0.35)),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Color(iconColor).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Color(iconColor), size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 17)),
                  Text(subtitle,
                      style: TextStyle(
                          color: context.colors.textLight, fontSize: 13)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      formatMoney(
                        amount,
                        decimalDigits: currencyCode == 'BTC' ? 3 : 2,
                      ),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      currencyCode,
                      style: TextStyle(
                          color: context.colors.textLight, fontSize: 11),
                    ),
                  ],
                ),
                if (convertedAmount != null &&
                    currencyCode != baseCurrencyCode) ...[
                  const SizedBox(height: 4),
                  Text(
                    '≈ ${formatMoney(convertedAmount!)}',
                    style: TextStyle(
                        color: context.colors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ],
            ),
            IconButton(
              onPressed: onAdjustBalance,
              tooltip: 'Adjust balance',
              icon: Icon(Icons.tune, color: context.colors.textLight, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}
