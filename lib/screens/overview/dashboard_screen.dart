import 'package:finance_mvp/constants/account_icons.dart';
import 'package:finance_mvp/constants/app_colors.dart';
import 'package:finance_mvp/database/app_database.dart' as db;
import 'package:finance_mvp/l10n/l10n.dart';
import 'package:finance_mvp/providers/revaluation_provider.dart';
import 'package:finance_mvp/repositories/finance_repository.dart';
import 'package:finance_mvp/screens/settings/category_screen.dart' show categoryIcons;
import 'package:finance_mvp/services/finance/currency_converter.dart';
import 'package:finance_mvp/widgets/profile_avatar.dart';
import 'package:finance_mvp/widgets/revaluation_summary_card.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// One screen that answers "where do I stand?": the net-worth card first, then
/// the month at a glance, currency health, accounts and where the money went.
/// Every figure is derived from a repository stream or the revaluation
/// provider — the screen computes no totals of its own.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  /// Streams are held rather than rebuilt per `build()`: a fresh stream makes
  /// the `StreamBuilder` unsubscribe and resubscribe on every repaint, and each
  /// cancel schedules cleanup work in drift.
  late final Stream<MonthlySummary> _monthSummary;
  late final Stream<List<db.Account>> _accounts;
  late final Stream<List<CategorySpending>> _categorySpending;

  /// Per-account balance streams, keyed by id, so a rebuild doesn't tear down
  /// and rebuild one subscription per account.
  final Map<int, Stream<double>> _balanceStreams = {};

  /// Every figure here is denominated in the base currency, so it is read once
  /// rather than per widget.
  String _baseCode = 'USD';
  String _symbol = r'$';
  bool _baseLoaded = false;

  /// The month the dashboard reports on, fixed at open so the progress bar and
  /// summaries don't drift if the screen stays open across midnight.
  final DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    final repo = context.read<FinanceRepository>();
    _monthSummary = repo.watchMonthlySummary(_now);
    _accounts = repo.watchAccounts();
    _categorySpending = repo.watchSpendingByCategory(_now);
    _loadBase();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<RevaluationProvider>().refresh();
    });
  }

  Future<void> _loadBase() async {
    final repo = context.read<FinanceRepository>();
    final code = await repo.getBaseCurrencyCode();
    final symbol = await repo.getBaseCurrencySymbol();
    if (!mounted) return;
    setState(() {
      _baseCode = code;
      _symbol = symbol;
      _baseLoaded = true;
    });
  }

  Stream<double> _balanceFor(int accountId) => _balanceStreams.putIfAbsent(
      accountId,
      () => context.read<FinanceRepository>().watchAccountBalance(accountId));

  Future<double> _loadTotalBalance() =>
      context.read<FinanceRepository>().calculateTotalBalance(_baseCode);

  @override
  Widget build(BuildContext context) {
    final reval = context.watch<RevaluationProvider>();

    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  _buildNetWorth(reval),
                  const SizedBox(height: 16),
                  _buildMonthAtAGlance(context),
                  const SizedBox(height: 24),
                  _buildFx(reval),
                  const SizedBox(height: 24),
                  _buildAccounts(context),
                  const SizedBox(height: 24),
                  _buildTopSpending(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ──

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 16, 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const ProfileAvatar(size: 40),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.l10n.dashboardWelcomeBack,
                style: TextStyle(
                  color: context.colors.textLight,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.0,
                ),
              ),
              Text(
                context.l10n.dashboardFinancialOverview,
                style: TextStyle(
                  color: context.colors.textDark,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Net worth ──

  Widget _buildNetWorth(RevaluationProvider reval) {
    final history = reval.netWorthHistory;
    final hasDelta = history.length >= 2;
    final delta =
        hasDelta ? history.last.baseAmount - history.first.baseAmount : 0.0;
    final start = hasDelta ? history.first.baseAmount : 0.0;
    final up = delta >= 0;
    final trendColor = up ? _green : _red;
    final percent = (hasDelta && start != 0) ? (delta / start) * 100 : 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(context, context.l10n.dashboardNetWorth),
          const SizedBox(height: 12),
          FutureBuilder<double>(
            future: _baseLoaded ? _loadTotalBalance() : null,
            builder: (context, snapshot) => Text(
              snapshot.data == null
                  ? ''
                  : formatMoney(snapshot.data!, symbol: _symbol),
              style: TextStyle(
                color: context.colors.textDark,
                fontSize: 34,
                fontWeight: FontWeight.bold,
                letterSpacing: -1,
              ),
            ),
          ),
          if (hasDelta) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(up ? Icons.trending_up : Icons.trending_down,
                    color: trendColor, size: 16),
                const SizedBox(width: 4),
                Text(
                  '${up ? '+' : ''}${formatMoney(delta, symbol: _symbol)}',
                  style: TextStyle(
                      color: trendColor, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 6),
                Text(
                  context.l10n.dashboardSinceDate(
                      DateFormat('MMM d').format(history.first.date)),
                  style: TextStyle(
                      color: context.colors.textLight, fontSize: 12),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: trendColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${up ? '+' : ''}${percent.toStringAsFixed(1)}%',
                    style: TextStyle(
                        color: trendColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ── Currency & purchasing power ──

  Widget _buildFx(RevaluationProvider reval) {
    final summary = reval.summary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header(context, context.l10n.dashboardCurrencyPurchasingPower,
            action: context.l10n.dashboardDetails,
            onAction: () => Navigator.pushNamed(context, '/v1/revaluation')),
        if (summary == null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: _cardDecoration(context),
            child: Text(
              context.l10n.dashboardNoExchangeRateData,
              style: TextStyle(color: context.colors.textLight),
            ),
          )
        else
          RevaluationSummaryCard(
            totalValueInBase: summary.totalValueInBase,
            totalCostBasisInBase: summary.totalCostBasisInBase,
            totalUnrealizedGainLoss: summary.totalUnrealizedGainLoss,
            baseCurrencyCode: _baseCode,
            inflationPercent: summary.purchasingPowerChangePercent,
            nationalCurrencyCode: summary.nationalCurrencyCode,
          ),
      ],
    );
  }

  // ── Month at a glance ──

  Widget _buildMonthAtAGlance(BuildContext context) {
    final daysInMonth = DateTime(_now.year, _now.month + 1, 0).day;
    final day = _now.day;
    final elapsed = day / daysInMonth;
    final daysLeft = daysInMonth - day;

    return StreamBuilder<MonthlySummary>(
      stream: _monthSummary,
      builder: (context, snapshot) {
        final income = snapshot.data?.income ?? 0.0;
        final expenses = snapshot.data?.expenses ?? 0.0;
        final net = income - expenses;
        final rate = income > 0 ? net / income : 0.0;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: _cardDecoration(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(context.l10n.dashboardMonthAtAGlance,
                            style: TextStyle(
                                color: context.colors.textDark,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text(
                          context.l10n.dashboardCurrentCycle(
                              DateFormat('MMMM yyyy').format(_now)),
                          style: TextStyle(
                              color: context.colors.textLight, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: context.colors.segmentedControlBackground,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      context.l10n.dashboardDayOfMonth(day, daysInMonth),
                      style: TextStyle(
                          color: context.colors.textDark,
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(context.l10n.dashboardBillingPeriodProgress,
                      style: TextStyle(
                          color: context.colors.textLight,
                          fontSize: 12,
                          fontWeight: FontWeight.w500)),
                  const Spacer(),
                  Text(
                    context.l10n.dashboardElapsedDaysLeft(
                        (elapsed * 100).toStringAsFixed(1), daysLeft),
                    style: TextStyle(
                        color: context.colors.textDark,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: elapsed.clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: context.colors.segmentedControlBackground,
                  valueColor: AlwaysStoppedAnimation(context.colors.primary),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _metricTile(
                        context,
                        context.l10n.dashboardIncome,
                        income,
                        Icons.arrow_downward,
                        _green,
                        context.l10n.dashboardEarned),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _metricTile(
                        context,
                        context.l10n.dashboardExpenses,
                        expenses,
                        Icons.arrow_upward,
                        _red,
                        context.l10n.dashboardSpent),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _metricTile(
                        context,
                        context.l10n.dashboardNetSaved,
                        net,
                        Icons.savings,
                        _amber,
                        context.l10n
                            .dashboardRate((rate * 100).toStringAsFixed(1))),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _savingsPace(context, rate),
            ],
          ),
        );
      },
    );
  }

  Widget _metricTile(BuildContext context, String label, double amount,
      IconData icon, Color color, String footnote) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: color)),
              ),
              Icon(icon, size: 14, color: color),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              formatMoney(amount, symbol: _symbol),
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: context.colors.textDark),
            ),
          ),
          Text(footnote,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 10, color: color)),
        ],
      ),
    );
  }

  Widget _savingsPace(BuildContext context, double rate) {
    final positive = rate >= 0;
    final color = !positive ? _red : (rate >= 0.5 ? _green : _amber);
    final title = rate >= 0.5
        ? context.l10n.dashboardExceptionalSavingsPace
        : rate >= 0.2
            ? context.l10n.dashboardHealthySavingsPace
            : positive
                ? context.l10n.dashboardPositiveSavingsPace
                : context.l10n.dashboardSpendingExceedsIncome;
    final description = rate >= 0.5
        ? context.l10n
            .dashboardRetainedCashFlow((rate * 100).toStringAsFixed(1))
        : rate >= 0.2
            ? context.l10n
                .dashboardKeepingEarnings((rate * 100).toStringAsFixed(1))
            : positive
                ? context.l10n.dashboardIncomeCoversSpending
                : context.l10n.dashboardExpensesAheadOfIncome;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.colors.segmentedControlBackground.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(positive ? Icons.verified : Icons.error_outline,
                        color: color, size: 14),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: context.colors.textDark)),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(description,
                    style: TextStyle(
                        fontSize: 11, color: context.colors.textLight)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${positive ? '+' : ''}${(rate * 100).toStringAsFixed(1)}%',
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w800, color: color),
          ),
        ],
      ),
    );
  }

  // ── Connected accounts ──

  Widget _buildAccounts(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                context.l10n.dashboardConnectedAccounts,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: context.colors.textLight),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/v1/accounts'),
              child: Text(context.l10n.dashboardManage),
            ),
          ],
        ),
        StreamBuilder<List<db.Account>>(
          stream: _accounts,
          builder: (context, snapshot) {
            final accounts = snapshot.data ?? const <db.Account>[];
            if (accounts.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  context.l10n.dashboardNoAccounts,
                  style: TextStyle(color: context.colors.textLight),
                ),
              );
            }
            return GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.9,
              children: [
                for (final account in accounts) _accountTile(context, account),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _accountTile(BuildContext context, db.Account account) {
    final color = Color(account.iconColor);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child:
                    Icon(accountIconFor(account.icon), color: color, size: 18),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  account.currencyCode,
                  style: TextStyle(
                      fontSize: 9, fontWeight: FontWeight.bold, color: color),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                account.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 11,
                    color: context.colors.textLight,
                    fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 2),
              StreamBuilder<double>(
                stream: _balanceFor(account.id),
                builder: (context, snap) => FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    formatMoney(snap.data ?? 0),
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: context.colors.textDark),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Top spending categories ──

  Widget _buildTopSpending(BuildContext context) {
    return StreamBuilder<List<CategorySpending>>(
      stream: _categorySpending,
      builder: (context, snapshot) {
        final categories = snapshot.data ?? const <CategorySpending>[];
        final total = categories.fold<double>(0, (sum, c) => sum + c.amount);

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: _cardDecoration(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(context.l10n.dashboardTopSpendingCategories,
                            style: TextStyle(
                                color: context.colors.textDark,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text(context.l10n.dashboardDistributionExpenditures,
                            style: TextStyle(
                                color: context.colors.textLight, fontSize: 12)),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: context.colors.segmentedControlBackground,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      context.l10n.dashboardSpendLabel(
                          formatMoney(total, symbol: _symbol)),
                      style: TextStyle(
                          color: context.colors.textDark,
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (categories.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(context.l10n.dashboardNoSpendingThisMonth,
                      style: TextStyle(color: context.colors.textLight)),
                )
              else ...[
                for (final category in categories.take(5))
                  _categoryRow(context, category, total),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pushNamed(context,
                        '/v1/transactions',
                        arguments: 'Out'),
                    child: Text(context.l10n.dashboardViewCompleteBreakdown),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _categoryRow(
      BuildContext context, CategorySpending category, double total) {
    final color = Color(category.color);
    final share = total == 0 ? 0.0 : category.amount / total;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(categoryIcons[category.icon] ?? Icons.bookmark,
                    color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: context.colors.textDark),
                    ),
                    Text(
                      context.l10n.dashboardPercentOfSpending(
                          (share * 100).toStringAsFixed(1)),
                      style: TextStyle(
                          fontSize: 11, color: context.colors.textLight),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatMoney(category.amount, symbol: _symbol),
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: context.colors.textDark),
                  ),
                  Text(
                    '${(share * 100).toStringAsFixed(1)}%',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: color),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: share.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: context.colors.segmentedControlBackground,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }

  // ── Shared bits ──

  Widget _header(BuildContext context, String title,
      {String? action, VoidCallback? onAction}) {
    return Padding(
      padding: const EdgeInsets.only(top: 0, bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              color: context.colors.textDark,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (onAction != null)
            TextButton(
              onPressed: onAction,
              child: Text(action ?? context.l10n.dashboardSeeAll),
            ),
        ],
      ),
    );
  }

  Widget _label(BuildContext context, String text) => Text(
        text,
        style: TextStyle(
          color: context.colors.textLight,
          fontSize: 12,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w600,
        ),
      );

  BoxDecoration _cardDecoration(BuildContext context) => BoxDecoration(
        color: context.colors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.cardBorder),
      );
}

const _green = Color(0xFF2E7D32);
const _red = Color(0xFFC62828);
const _amber = Color(0xFFB45309);