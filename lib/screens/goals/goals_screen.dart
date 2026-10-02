import 'package:finance_mvp/constants/app_colors.dart';
import 'package:finance_mvp/database/app_database.dart' as db;
import 'package:finance_mvp/repositories/finance_repository.dart';
import 'package:finance_mvp/screens/goals/goal_form_screen.dart';
import 'package:finance_mvp/widgets/goal_progress_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Savings goals with live progress, each backed by a real account.
class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  /// The monthly rate is the same for every goal, so it's derived once per
  /// emission and shared, rather than each card re-deriving the series.
  double? _monthlyRate;
  bool _rateLoaded = false;

  /// Held rather than rebuilt per `build()`: a fresh stream makes the
  /// `StreamBuilder` unsubscribe and resubscribe on every repaint, and each
  /// cancel schedules cleanup work in drift.
  late final Stream<List<GoalProgress>> _goals;

  @override
  void initState() {
    super.initState();
    _goals = context.read<FinanceRepository>().watchGoalsWithProgress();
    _loadRate();
  }

  Future<void> _loadRate() async {
    final rate = await context.read<FinanceRepository>().averageMonthlySurplus();
    if (!mounted) return;
    setState(() {
      _monthlyRate = rate;
      _rateLoaded = true;
    });
  }

  Future<void> _openForm({db.Goal? existing}) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => GoalFormScreen(existingGoal: existing),
      ),
    );
    if (changed == true) await _loadRate();
  }

  Future<void> _confirmDelete(GoalProgress goal) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete "${goal.goal.name}"?'),
        content: Text(
          'The goal is removed. The ${goal.account.name} account and its '
          'transactions stay — that money is yours.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await context.read<FinanceRepository>().deleteGoal(goal.goal.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: const Text('Goals'),
        centerTitle: true,
        backgroundColor: context.colors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.colors.textDark),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            tooltip: 'New goal',
            icon: Icon(Icons.add, color: context.colors.textDark),
            onPressed: _openForm,
          ),
        ],
      ),
      body: StreamBuilder<List<GoalProgress>>(
        stream: _goals,
        builder: (context, snapshot) {
          final goals = snapshot.data ?? const <GoalProgress>[];
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (goals.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.flag, size: 40, color: context.colors.textLight),
                    const SizedBox(height: 12),
                    Text(
                      'No goals yet',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: context.colors.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'A goal opens an account to hold the money, so your '
                      'progress is always your real balance.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: context.colors.textLight),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadRate,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: goals.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final goal = goals[index];
                return _GoalTile(
                  goal: goal,
                  // Before the rate resolves, show no date rather than a
                  // placeholder that flashes into a real one.
                  monthlyRate: _rateLoaded ? _monthlyRate : null,
                  onTap: () => _openForm(existing: goal.goal),
                  onDelete: () => _confirmDelete(goal),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _GoalTile extends StatefulWidget {
  final GoalProgress goal;
  final double? monthlyRate;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _GoalTile({
    required this.goal,
    required this.monthlyRate,
    required this.onTap,
    required this.onDelete,
  });

  @override
  State<_GoalTile> createState() => _GoalTileState();
}

class _GoalTileState extends State<_GoalTile> {
  DateTime? _projectedOn;

  @override
  void initState() {
    super.initState();
    _project();
  }

  @override
  void didUpdateWidget(covariant _GoalTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A transfer into the pot changes what's left to save, so the projection
    // has to be re-derived rather than kept from the first build.
    if (oldWidget.goal.current != widget.goal.current) _project();
  }

  Future<void> _project() async {
    final projected = await context
        .read<FinanceRepository>()
        .projectGoalCompletion(widget.goal, monthlyRate: widget.monthlyRate);
    if (!mounted) return;
    setState(() => _projectedOn = projected);
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(widget.goal.goal.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        widget.onDelete();
        return false;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: const Color(0xFFD93025),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(16),
        child: GoalProgressCard(
          goal: widget.goal,
          projectedOn: _projectedOn,
          showAccountName: true,
        ),
      ),
    );
  }
}