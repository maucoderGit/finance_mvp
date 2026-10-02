import 'package:finance_mvp/constants/app_colors.dart';
import 'package:finance_mvp/repositories/finance_repository.dart';
import 'package:finance_mvp/screens/goals/goals_screen.dart';
import 'package:finance_mvp/services/finance/currency_converter.dart';
import 'package:finance_mvp/widgets/cash_flow_chart.dart';
import 'package:finance_mvp/widgets/goal_progress_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _showIncome = false;
  CashFlowBucket _bucket = CashFlowBucket.month;

  /// Held rather than rebuilt per `build()`: a fresh stream makes the
  /// `StreamBuilder` unsubscribe and resubscribe on every repaint, and each
  /// cancel schedules cleanup work in drift.
  late final Stream<List<GoalProgress>> _goals;

  /// Every figure here is denominated in the base currency, so it is read once
  /// rather than per widget. [FutureBuilder] on the balance still re-queries on
  /// rebuild, which is what keeps it live.
  String _baseCode = 'USD';
  String _symbol = r'$';
  bool _baseLoaded = false;

  /// Cached so toggling Spending/Income — a rebuild that changes no query
  /// parameters — doesn't re-run the aggregation. Dropped when the bucket
  /// changes, which is the only input the query depends on.
  Stream<List<CashFlowPoint>>? _cashFlow;

  @override
  void initState() {
    super.initState();
    _goals = context.read<FinanceRepository>().watchGoalsWithProgress();
    _loadBase();
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

  Stream<List<CashFlowPoint>> _cashFlowFor(CashFlowBucket bucket) =>
      _cashFlow ??= context.read<FinanceRepository>().watchCashFlow(bucket: bucket);

  void _selectBucket(CashFlowBucket bucket) {
    if (bucket == _bucket) return;
    setState(() {
      _bucket = bucket;
      _cashFlow = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDarkMode ? AppColors.darkBackground : context.colors.background;
    final textColor =
        isDarkMode ? AppColors.darkPrimary : context.colors.textDark;
    final cardBackgroundColor = isDarkMode
        ? AppColors.darkCardBackground
        : context.colors.cardBackground;
    final segmentedControlBackgroundColor = isDarkMode
        ? AppColors.darkSegmentedControlBackground
        : context.colors.segmentedControlBackground;
    final segmentedControlActiveColor = isDarkMode
        ? AppColors.darkSegmentedControlActive
        : context.colors.segmentedControlActive;
    final primaryColor = context.colors.primaryLight;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTopAppBar(textColor),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Total Balance',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: FutureBuilder<double>(
                future: _baseLoaded ? _loadTotalBalance() : null,
                builder: (context, snapshot) => Text(
                  snapshot.data == null
                      ? ''
                      : formatMoney(snapshot.data!, symbol: _symbol),
                  style: TextStyle(
                    color: textColor,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  _buildChartSection(
                    context,
                    cardBackgroundColor,
                    segmentedControlBackgroundColor,
                    segmentedControlActiveColor,
                    primaryColor,
                    textColor,
                  ),
                  _buildGoalsSection(context, textColor),
                ],
              ),
            ),
            _buildBottomFilterBar(context, primaryColor),
          ],
        ),
      ),
    );
  }

  Future<double> _loadTotalBalance() =>
      context.read<FinanceRepository>().calculateTotalBalance(_baseCode);

  Widget _buildTopAppBar(Color textColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 4.0, 16.0, 2.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          // No trailing action: the notification bell this held had no
          // destination and no screen behind it.
          const SizedBox(width: 48),
          Expanded(
            child: Text(
              'Dashboard',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartSection(
    BuildContext context,
    Color cardBackgroundColor,
    Color segmentedControlBackgroundColor,
    Color segmentedControlActiveColor,
    Color primaryColor,
    Color textColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: cardBackgroundColor,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[800]!
              : Colors.transparent,
        ),
      ),
      child: Column(
        children: [
          _buildSegmentedControl(segmentedControlBackgroundColor,
              segmentedControlActiveColor, textColor),
          const SizedBox(height: 16),
          StreamBuilder<List<CashFlowPoint>>(
            stream: _cashFlowFor(_bucket),
            builder: (context, snapshot) {
              if (!_baseLoaded) return const SizedBox(height: 220);
              return CashFlowChart(
                data: snapshot.data ?? const <CashFlowPoint>[],
                showIncome: _showIncome,
                bucket: _bucket,
                currencyCode: _baseCode,
              );
            },
          ),
        ],
      ),
    );
  }

  /// The top few goals, progress only. Projections live on the goals screen —
  /// they're per-goal async queries and the dashboard has no rate to hand them,
  /// and a card that guessed "no date" here would be stating something false.
  Widget _buildGoalsSection(BuildContext context, Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Goals',
              style: TextStyle(
                  color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const GoalsScreen(),
              )),
              child: const Text('See all'),
            ),
          ],
        ),
        StreamBuilder<List<GoalProgress>>(
          stream: _goals,
          builder: (context, snapshot) {
            final goals = snapshot.data ?? const <GoalProgress>[];
            if (goals.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'No goals yet. Open Goals to start saving toward something.',
                  style: TextStyle(color: context.colors.textLight),
                ),
              );
            }
            return Column(
              children: [
                for (final goal in goals.take(3))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GoalProgressCard(
                        goal: goal, showProjection: false),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildSegmentedControl(
      Color backgroundColor, Color activeColor, Color textColor) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        children: [
          _buildSegmentedControlItem(0, 'Spending', activeColor, textColor),
          _buildSegmentedControlItem(1, 'Income', activeColor, textColor),
        ],
      ),
    );
  }

  Widget _buildSegmentedControlItem(
    int index,
    String text,
    Color activeColor,
    Color activeTextColor,
  ) {
    final isSelected = _showIncome == (index == 1);
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _showIncome = index == 1),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(6.0),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    )
                  ]
                : [],
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                color: isSelected ? activeTextColor : Colors.grey[500],
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomFilterBar(BuildContext context, Color primaryColor) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final barBackgroundColor =
        isDarkMode ? const Color(0xFF1F2937) : Colors.white;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
          ),
        ),
      ),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: barBackgroundColor,
          borderRadius: BorderRadius.circular(24.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            for (final bucket in CashFlowBucket.values)
              _buildFilterItem(bucket, primaryColor),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterItem(CashFlowBucket bucket, Color primaryColor) {
    final isSelected = _bucket == bucket;
    return GestureDetector(
      onTap: () => _selectBucket(bucket),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(24.0),
        ),
        child: Text(
          bucket.shortLabel,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[600],
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}