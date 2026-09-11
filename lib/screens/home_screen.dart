import 'package:finance_mvp/constants/app_colors.dart';
import 'package:finance_mvp/database/app_database.dart';
import 'package:finance_mvp/providers/currency_provider.dart';
import 'package:finance_mvp/providers/revaluation_provider.dart';
import 'package:finance_mvp/repositories/finance_repository.dart';
import 'package:finance_mvp/services/net_worth_tracker.dart';
import 'package:finance_mvp/services/profile_picture_service.dart';
import 'package:finance_mvp/services/revaluation_service.dart';
import 'package:finance_mvp/widget/month_filter_widget.dart';
import 'package:finance_mvp/widget/appbar.dart';
import 'package:finance_mvp/widget/info_section_title.dart';
import 'package:finance_mvp/widget/profile_avatar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime _selectedDate = DateTime.now();
  bool _autoSyncTriggered = false;

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
    final tracker = NetWorthTracker(context.read<FinanceRepository>(), revaluationService);

    // Auto-sync rates when settings allow it.
    final settings = await currencyProvider.watchUserSettings().first;
    if (settings?.currencySelectionMode == 'auto') {
      await currencyProvider.syncRates();
    }

    // Ensure a net worth snapshot exists for today (in both currencies).
    final nationalCode = await currencyProvider.getNationalCurrencyCode();
    await tracker.ensureTodaySnapshot(nationalCurrencyCode: nationalCode);
    tracker.cancel();

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
              const _RevaluationSummaryStrip(),
              SizedBox(height: MediaQuery.of(context).size.height * 0.02),
              StreamBuilder<MonthlySummary>(
                stream: repo.watchMonthlySummary(_selectedDate),
                builder: (context, snapshot) {
                  final summary = snapshot.data;
                  final income = summary?.income ?? 0.0;
                  final expenses = summary?.expenses ?? 0.0;

                  final currencyFormat = NumberFormat.currency(locale: 'en_US', symbol: '\$');

                  return _MonthlySummary(
                    income: '+${currencyFormat.format(income)}',
                    expenses: '-${currencyFormat.format(expenses)}',
                  );
                }
              ),
              const _ActionButtons(),
              SizedBox(height: MediaQuery.of(context).size.height * 0.08),
              InfoSectionTitle(
                icon: Icons.receipt_long_outlined,
                title: 'Moves',
                index: 0,
                actionText: 'View all',
                onTap: () {
                  Navigator.pushNamed(context, '/v1/transactions');
                },
              ),
              InfoSectionTitle(
                icon: Icons.account_balance_wallet_outlined,
                title: 'My balance',
                index: 1,
                actionText: 'Review',
                onTap: () => Navigator.pushNamed(context, '/v1/accounts'),
              ),
              InfoSectionTitle(
                icon: Icons.add_card_outlined,
                title: 'Register Accounts',
                index: 2,
                actionText: 'Add',
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
            const Text(
              'Hi,',
              style: TextStyle(
                fontSize: 18,
                color: AppColors.textLight,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              username?.trim().isNotEmpty == true ? username! : 'Maucoder',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
          ],
        );
      },
    );
  }
}

// --- widgets/action_buttons.dart ---
// Row of main action buttons (Add, Withdraw, Transfer).
class _ActionButtons extends StatelessWidget {
  const _ActionButtons();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _ActionButton(icon: Icons.add, label: 'Register Transaction', onTap: () {
          Navigator.pushNamed(context, '/v1/transactions/create');
        }),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final GestureTapCallback onTap;

  const _ActionButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: Colors.white,
          child: Icon(icon, color: AppColors.primary, size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ));
  }
}

class _MonthlySummary extends StatelessWidget {
  final String income;
  final String expenses;
  const _MonthlySummary({required this.income, required this.expenses});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      child: Row(
        children: [
          Expanded(
            child: _SummaryCard(
              label: 'Income',
              amount: income,
              amountColor: const Color(0xFF0B2013),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _SummaryCard(
              label: 'Expenses',
              amount: expenses,
              amountColor: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String amount;
  final Color amountColor;

  const _SummaryCard({required this.label, required this.amount, required this.amountColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4EF), // surface-container-low
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC3C8C1)), // outline-variant
      ),
      child: Column(
        children: [
          Text(label.toUpperCase(), style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Text(amount, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: amountColor)),
        ],
      ),
    );
  }
}

/// Compact, tappable strip showing total unrealized FX gain/loss.
class _RevaluationSummaryStrip extends StatelessWidget {
  const _RevaluationSummaryStrip();

  @override
  Widget build(BuildContext context) {
    final revaluationProvider = context.watch<RevaluationProvider>();
    final summary = revaluationProvider.summary;

    if (summary == null) {
      return InkWell(
        onTap: () => Navigator.pushNamed(context, '/v1/revaluation'),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, Color(0xFF1E6B34)],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Row(
            children: [
              Icon(Icons.trending_up, color: Colors.white),
              SizedBox(width: 12),
              Text(
                'Revaluation analytics',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600),
              ),
              Spacer(),
              Icon(Icons.chevron_right, color: Colors.white70),
            ],
          ),
        ),
      );
    }

    final isGain = summary.totalUnrealizedGainLoss >= 0;
    final color = isGain ? const Color(0xFFB9F6CA) : const Color(0xFFFFCDD2);
    final icon = isGain ? Icons.trending_up : Icons.trending_down;
    final formatted = NumberFormat.currency(
      locale: 'en_US',
      symbol: '',
      decimalDigits: 2,
    ).format(summary.totalUnrealizedGainLoss);

    return InkWell(
      onTap: () => Navigator.pushNamed(context, '/v1/revaluation'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, Color(0xFF1E6B34)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(width: 8),
                const Text(
                  'UNREALIZED FX',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
                const Spacer(),
                const Text(
                  'Details',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const Icon(Icons.chevron_right,
                    color: Colors.white70, size: 16),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${isGain ? '+' : ''}$formatted USD',
              style: TextStyle(
                color: color,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            if (summary.purchasingPowerChangePercent != null) ...[
              const SizedBox(height: 4),
              Text(
                '${summary.nationalCurrencyCode} devalued '
                '${summary.purchasingPowerChangePercent!.toStringAsFixed(1)}% in 12 months',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }
}