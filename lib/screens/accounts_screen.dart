import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:finance_mvp/constants/app_colors.dart';
import 'package:finance_mvp/database/app_database.dart' as db;
import 'package:finance_mvp/repositories/finance_repository.dart';
import 'package:finance_mvp/screens/add_account_sheet.dart';

class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = context.watch<FinanceRepository>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Atelier Finance',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: false,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => DraggableScrollableSheet(
              initialChildSize: 0.8,
              maxChildSize: 0.9,
              minChildSize: 0.5,
              builder: (_, controller) => Container(decoration: const BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16))), child: const AddAccountSheet()),
            ),
          );
        },
        backgroundColor: AppColors.primary,
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
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'BALANCE',
                    style: TextStyle(
                      color: AppColors.textLight,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  FutureBuilder<String>(
                    future: repository.getBaseCurrencyCode(),
                    builder: (context, balanceSnapshot) {
                      final baseCurrencyCode = balanceSnapshot.data ?? 'USD';
                      return FutureBuilder<double>(
                        future: repository.calculateTotalBalance(baseCurrencyCode),
                        builder: (context, totalSnapshot) {
                          final total = totalSnapshot.data ?? 0.0;
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                NumberFormat.currency(symbol: '\$').format(total), // Assuming base is USD-like for symbol
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                  letterSpacing: -1,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8.0, left: 8.0),
                                child: Text(
                                  baseCurrencyCode,
                                  style: const TextStyle(
                                    color: AppColors.textLight,
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
                      const Text(
                        'My Accounts',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${accounts.length} ACTIVE',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ...accounts.map((account) => FutureBuilder<Map<String, dynamic>>(
                        future: () async {
                          final allTransactions = await repository.db.select(repository.db.transactions).get();
                          final accountBalance = allTransactions
                              .where((t) => t.accountId == account.id)
                              .fold<double>(0.0, (sum, t) => sum + t.amount);

                          final baseCurrencyCode = await repository.getBaseCurrencyCode();
                          final converted = await repository.convertAmount(
                            amount: accountBalance,
                            fromCode: account.currencyCode,
                            toCode: baseCurrencyCode,
                          );
                          return {'balance': accountBalance, 'converted': converted, 'baseCode': baseCurrencyCode};
                        }(),
                        builder: (context, balanceSnapshot) {
                          final balance = balanceSnapshot.data?['balance'] ?? 0.0;
                          final converted = balanceSnapshot.data?['converted'];
                          final baseCode = balanceSnapshot.data?['baseCode'] ?? 'USD';
                          return _AccountCard(
                            name: account.name,
                            subtitle: account.subtitle ?? '',
                            amount: balance,
                            currencyCode: account.currencyCode,
                            convertedAmount: converted,
                            baseCurrencyCode: baseCode,
                            // ignore: non_const_argument_for_const_parameter
                            icon: IconData(int.parse(account.icon), fontFamily: 'MaterialIcons'),
                            iconBgColor: Color(account.iconColor),
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
  final Color iconBgColor;

  const _AccountCard({
    required this.name,
    required this.subtitle,
    required this.amount,
    required this.currencyCode,
    this.convertedAmount,
    required this.baseCurrencyCode,
    required this.icon,
    required this.iconBgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: BoxBorder.all(color: AppColors.cardBorder, width: 0.35)
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                Text(subtitle, style: const TextStyle(color: AppColors.textLight, fontSize: 13)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$currencyCode ${amount.toStringAsFixed(currencyCode == 'BTC' ? 3 : 2)}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              if (convertedAmount != null && currencyCode != baseCurrencyCode)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '≈ \$${convertedAmount!.toStringAsFixed(2)}', // Assuming base currency uses '$'
                    style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}