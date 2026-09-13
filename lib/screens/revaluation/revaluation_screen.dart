import 'package:finance_mvp/constants/app_colors.dart';
import 'package:finance_mvp/providers/currency_provider.dart';
import 'package:finance_mvp/providers/revaluation_provider.dart';
import 'package:finance_mvp/widgets/gain_loss_card.dart';
import 'package:finance_mvp/widgets/net_worth_line_chart.dart';
import 'package:finance_mvp/widgets/purchasing_power_chart.dart';
import 'package:finance_mvp/widgets/revaluation_summary_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RevaluationScreen extends StatefulWidget {
  const RevaluationScreen({super.key});

  @override
  State<RevaluationScreen> createState() => _RevaluationScreenState();
}

class _RevaluationScreenState extends State<RevaluationScreen> {
  String _baseCurrencyCode = 'USD';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
    _loadBaseCurrency();
  }

  Future<void> _loadBaseCurrency() async {
    final code = await context.read<CurrencyProvider>().getBaseCurrencyCode();
    if (mounted) setState(() => _baseCurrencyCode = code);
  }

  Future<void> _refresh() async {
    await context.read<RevaluationProvider>().refresh();
  }

  Future<void> _syncNow() async {
    final currencyProvider = context.read<CurrencyProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final count = await currencyProvider.syncRates(force: true);
    messenger.showSnackBar(
      SnackBar(
        content: Text(count > 0
            ? 'Synced $count rate(s) from the API.'
            : 'Nothing to sync. Add rates manually if needed.'),
        duration: const Duration(seconds: 2),
      ),
    );
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RevaluationProvider>();
    final currencyProvider = context.watch<CurrencyProvider>();

    final summary = provider.summary;
    final baseCode = summary?.nationalCurrencyCode ?? 'VES';

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
          'Revaluation',
          style: TextStyle(
            color: context.colors.textDark,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.cloud_sync, color: context.colors.primary),
            tooltip: 'Sync rates from API',
            onPressed: currencyProvider.isSyncing ? null : _syncNow,
          ),
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: provider.loading ? Colors.grey : context.colors.primary,
            ),
            tooltip: 'Refresh',
            onPressed: provider.loading ? null : _refresh,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: provider.loading && summary == null
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (summary != null)
                      RevaluationSummaryCard(
                        totalValueInBase: summary.totalValueInBase,
                        totalCostBasisInBase: summary.totalCostBasisInBase,
                        totalUnrealizedGainLoss: summary.totalUnrealizedGainLoss,
                        baseCurrencyCode: _baseCurrencyCode,
                        inflationPercent: summary.purchasingPowerChangePercent,
                        nationalCurrencyCode: summary.nationalCurrencyCode,
                      )
                    else
                      const SizedBox(height: 200),

                    const SizedBox(height: 28),

                    Text(
                      'GAIN / LOSS BY CURRENCY',
                      style: TextStyle(
                        color: context.colors.textLight,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (provider.gainLossByCurrency.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          'No holdings yet. Create accounts and transactions to see FX gain/loss.',
                          style: TextStyle(color: Colors.grey.shade600),
                          textAlign: TextAlign.center,
                        ),
                      )
                    else
                      ...provider.gainLossByCurrency.map(
                        (g) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GainLossCard.fromCurrency(g),
                        ),
                      ),

                    const SizedBox(height: 28),

                    Text(
                      'PURCHASING POWER',
                      style: TextStyle(
                        color: context.colors.textLight,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    PurchasingPowerChart(
                      data: provider.purchasingPowerHistory,
                      nationalCurrencyCode: baseCode,
                    ),

                    const SizedBox(height: 28),

                    Text(
                      'NET WORTH',
                      style: TextStyle(
                        color: context.colors.textLight,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    NetWorthLineChart(
                      data: provider.netWorthHistory,
                      baseCurrencyCode: _baseCurrencyCode,
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
      ),
    );
  }
}