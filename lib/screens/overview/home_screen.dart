import 'package:finance_mvp/constants/app_colors.dart';
import 'package:finance_mvp/database/app_database.dart';
import 'package:finance_mvp/l10n/l10n.dart';
import 'package:finance_mvp/providers/currency_provider.dart';
import 'package:finance_mvp/providers/revaluation_provider.dart';
import 'package:finance_mvp/repositories/finance_repository.dart';
import 'package:finance_mvp/services/finance/currency_converter.dart';
import 'package:finance_mvp/services/finance/net_worth_tracker.dart';
import 'package:finance_mvp/services/profile_picture_service.dart';
import 'package:finance_mvp/widgets/custom_toast.dart';
import 'package:finance_mvp/services/finance/revaluation_service.dart';
import 'package:finance_mvp/widgets/month_filter_widget.dart';
import 'package:finance_mvp/widgets/appbar.dart';
import 'package:finance_mvp/widgets/info_section_title.dart';
import 'package:finance_mvp/widgets/profile_avatar.dart';
import 'package:finance_mvp/widgets/stat_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime _selectedDate = DateTime.now();
  bool _autoSyncTriggered = false;
  String _baseSymbol = r'$';

  void _onDateChanged(DateTime newDate) {
    setState(() {
      _selectedDate = newDate;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runStartupTasks();
    });
  }

  /// Trigger background tasks on first launch: auto-fetch rates (if enabled)
  /// and ensure today's net worth snapshot exists.
  Future<void> _runStartupTasks() async {
    if (_autoSyncTriggered || !mounted) return;
    _autoSyncTriggered = true;

    final currencyProvider = context.read<CurrencyProvider>();
    final revaluationService = context.read<RevaluationService>();
    final revaluationProvider = context.read<RevaluationProvider>();
    final repo = context.read<FinanceRepository>();
    final tracker =
        NetWorthTracker(context.read<FinanceRepository>(), revaluationService);

    final baseSymbol = await repo.getBaseCurrencySymbol();
    if (mounted && baseSymbol != _baseSymbol) {
      setState(() => _baseSymbol = baseSymbol);
    }

    // Auto-sync rates when settings allow it.
    final settings = await currencyProvider.watchUserSettings().first;
    if (settings?.currencySelectionMode == 'auto') {
      await currencyProvider.syncRates();
    }

    // Ensure a net worth snapshot exists for today (in both currencies).
    final nationalCode = await currencyProvider.getNationalCurrencyCode();
    await tracker.ensureTodaySnapshot(nationalCurrencyCode: nationalCode);

    // Add any recurring transaction that has come due since the last open.
    // Idempotent, so running before or after the rate sync doesn't matter.
    final generated = await repo.materializeDueRecurrences();
    if (generated > 0 && mounted) {
      showToast(
        context,
        message: context.l10n.homeRecurringTransactionsAdded(generated),
      );
    }

    // Refresh revaluation analytics.
    await revaluationProvider.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<FinanceRepository>();

    return Scaffold(
      appBar: HomeAppBar(
        title: MonthFilterWidget(onDateSelected: _onDateChanged),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              SizedBox(height: MediaQuery.of(context).size.height * 0.02),
              const _UserGreeting(),
              SizedBox(height: MediaQuery.of(context).size.height * 0.02),
              StreamBuilder<MonthlySummary>(
                  stream: repo.watchMonthlySummary(_selectedDate),
                  builder: (context, snapshot) {
                    final summary = snapshot.data;
                    final income = summary?.income ?? 0.0;
                    final expenses = summary?.expenses ?? 0.0;
                    final fxImpact = summary?.fxImpact ?? 0.0;

                    const currencyFormat = formatMoney;

                    return _MonthlySummary(
                      income: '+${currencyFormat(income, symbol: _baseSymbol)}',
                      expenses:
                          '-${currencyFormat(expenses, symbol: _baseSymbol)}',
                      fxImpactText:
                          currencyFormat(fxImpact, symbol: _baseSymbol),
                      fxImpactPositive: fxImpact >= 0,
                    );
                  }),
              SizedBox(height: MediaQuery.of(context).size.height * 0.02),
              InfoSectionTitle(
                icon: Icons.receipt_long_outlined,
                title: context.l10n.homeMoves,
                index: 0,
                actionText: context.l10n.homeViewAll,
                onTap: () {
                  Navigator.pushNamed(context, '/v1/transactions');
                },
              ),
              InfoSectionTitle(
                icon: Icons.account_balance_wallet_outlined,
                title: context.l10n.homeMyBalance,
                index: 1,
                actionText: context.l10n.homeReview,
                onTap: () => Navigator.pushNamed(context, '/v1/accounts'),
              ),
              InfoSectionTitle(
                icon: Icons.add_card_outlined,
                title: context.l10n.homeRegisterAccounts,
                index: 2,
                actionText: context.l10n.homeAdd,
                onTap: () => Navigator.pushNamed(context, '/v1/accounts'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserGreeting extends StatefulWidget {
  const _UserGreeting();

  @override
  State<_UserGreeting> createState() => _UserGreetingState();
}

class _UserGreetingState extends State<_UserGreeting> {
  Future<void> _pickProfilePicture() async {
    final path = await pickImageFromGallery();
    if (path == null || !mounted) return;
    await context.read<FinanceRepository>().saveProfilePicturePath(path);
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<FinanceRepository>();
    return StreamBuilder<UserSetting?>(
      stream: repo.watchUserSettings(),
      builder: (context, snapshot) {
        final username = snapshot.data?.username;
        return Column(
          children: [
            ProfileAvatar(
              size: 125,
              shape: ProfileAvatarShape.roundedRect,
              showEditBadge: true,
              onEdit: _pickProfilePicture,
            ),
            const SizedBox(height: 16),
            Text(
              context.l10n.homeHi,
              style: TextStyle(
                fontSize: 18,
                color: context.colors.textLight,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              username?.trim().isNotEmpty == true ? username! : 'Maucoder',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: context.colors.textDark,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MonthlySummary extends StatelessWidget {
  final String income;
  final String expenses;
  final String fxImpactText;
  final bool fxImpactPositive;

  const _MonthlySummary({
    required this.income,
    required this.expenses,
    required this.fxImpactText,
    required this.fxImpactPositive,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: StatCard(
                  label: context.l10n.homeIncome,
                  amount: income,
                  amountColor: context.colors.textDark,
                  onTap: () => Navigator.pushNamed(context, '/v1/transactions',
                      arguments: 'In'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: StatCard(
                  label: context.l10n.homeExpenses,
                  amount: expenses,
                  amountColor: context.colors.textDark,
                  onTap: () => Navigator.pushNamed(context, '/v1/transactions',
                      arguments: 'Out'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _FxCard(
            netImpact: fxImpactText,
            netPositive: fxImpactPositive,
          ),
        ],
      ),
    );
  }
}

/// Single card grouping both FX metrics: the tappable total unrealized
/// gain/loss (top) and the month's Net FX Impact (bottom, sum of fxDelta).
/// Green for gains/savings, red for losses.
class _FxCard extends StatelessWidget {
  final String netImpact;
  final bool netPositive;

  const _FxCard({required this.netImpact, required this.netPositive});

  @override
  Widget build(BuildContext context) {
    final summary = context.watch<RevaluationProvider>().summary;
    final gain = summary?.totalUnrealizedGainLoss ?? 0.0;
    final unrealizedColor = gain >= 0 ? _green : _red;
    final netColor = netPositive ? _green : _red;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: context.colors.stackCardBackground[0],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: InkWell(
              onTap: () => Navigator.pushNamed(context, '/v1/revaluation'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                          gain >= 0
                              ? Icons.trending_up
                              : Icons.trending_down,
                          color: unrealizedColor,
                          size: 16),
                      const SizedBox(width: 4),
                      Text(context.l10n.homeUnrealizedFx,
                          style: TextStyle(
                              fontSize: 11,
                              color: context.colors.textLight,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5)),
                      Icon(Icons.chevron_right,
                          color: context.colors.textLight, size: 14),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    summary == null
                        ? '—'
                        : '${gain >= 0 ? '+' : ''}${formatMoney(gain)} USD',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: unrealizedColor,
                    ),
                  ),
                  if (summary?.purchasingPowerChangePercent != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      context.l10n.homePercentOver12Months(
                          summary!.nationalCurrencyCode,
                          summary.purchasingPowerChangePercent!
                              .toStringAsFixed(1)),
                      style: TextStyle(
                          color: context.colors.textLight, fontSize: 11),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Container(
            width: 1,
            height: 44,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            color: context.colors.cardBorder,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.l10n.homeNetFxImpact,
                    style: TextStyle(
                        fontSize: 11,
                        color: context.colors.textLight,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5)),
                const SizedBox(height: 2),
                Text(netImpact,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: netColor)),
                const SizedBox(height: 2),
                Text(
                  netPositive
                      ? context.l10n.homeGapSavings
                      : context.l10n.homeReplacementLoss,
                  style: TextStyle(
                      color: context.colors.textLight, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

const _green = Color(0xFF2E7D32);
const _red = Color(0xFFC62828);
