import 'package:drift/drift.dart' as drift;
import 'package:finance_mvp/constants/app_colors.dart';
import 'package:finance_mvp/database/app_database.dart' as db;
import 'package:finance_mvp/repositories/finance_repository.dart';
import 'package:finance_mvp/widgets/goal_progress_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Full-screen form to create or edit a savings goal. Pops with `true` when
/// something was persisted.
///
/// A new goal always comes with somewhere to keep its money: the form opens a
/// savings account for it unless the user picks an existing one. That's what
/// makes progress real rather than a number typed into a box.
class GoalFormScreen extends StatefulWidget {
  final db.Goal? existingGoal;

  /// Pre-selected backing account when creating (e.g. from an account row).
  final int? accountId;

  const GoalFormScreen({super.key, this.existingGoal, this.accountId});

  @override
  State<GoalFormScreen> createState() => _GoalFormScreenState();
}

class _GoalFormScreenState extends State<GoalFormScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _targetController = TextEditingController();

  db.Currency? _currency;
  List<db.Currency> _currencies = const [];
  List<db.Account> _accounts = const [];
  bool _loaded = false;

  /// Null = "open a new savings account for this goal", which is also the
  /// default: a new goal has no account to point at yet.
  int? _accountId;
  String _icon = 'flag';
  int _iconColor = 0xFF1E8E3E;
  DateTime? _deadline;

    @override
  void initState() {
    super.initState();
    final existing = widget.existingGoal;
    if (existing != null) {
      _nameController.text = existing.name;
      _targetController.text = existing.targetAmount.toStringAsFixed(2);
      _accountId = existing.accountId;
      _icon = existing.icon;
      _iconColor = existing.iconColor;
      _deadline = existing.deadline;
    } else {
      _accountId = widget.accountId;
    }
    _loadContext();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  Future<void> _loadContext() async {
    final repo = context.read<FinanceRepository>();
    final currencies = await repo.getAllCurrencies();
    final accounts = await repo.getAllAccounts();
    if (!mounted) return;
    setState(() {
      _currencies = currencies;
      _accounts = accounts;
      _loaded = true;
      // Default to the goal's own currency when editing, else the base one, so
      // the target is denominated in the money the user actually holds.
      _currency ??= currencies.firstWhere(
        (c) => c.code == widget.existingGoal?.currencyCode,
        orElse: () => currencies.firstWhere(
          (c) => c.code == _accounts
              .where((a) => a.id == _accountId)
              .firstOrNull
              ?.currencyCode,
          orElse: () => currencies.first,
        ),
      );
    });
  }

  Future<void> _pickCurrency() async {
    final selected = await showModalBottomSheet<db.Currency>(
      context: context,
      backgroundColor: context.colors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final c in _currencies)
              ListTile(
                title: Text('${c.code} — ${c.name}'),
                onTap: () => Navigator.pop(sheetContext, c),
              ),
          ],
        ),
      ),
    );
    if (selected != null && mounted) {
      setState(() => _currency = selected);
    }
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? now.add(const Duration(days: 90)),
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 30),
    );
    if (picked != null && mounted) {
      setState(() => _deadline = picked);
    }
  }

  Future<void> _save() async {
    final repo = context.read<FinanceRepository>();
    final name = _nameController.text.trim();
    final target = double.tryParse(_targetController.text);
    if (name.isEmpty || target == null || target <= 0 || _currency == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Give the goal a name and a target above 0')),
      );
      return;
    }

    final existing = widget.existingGoal;
    if (existing != null) {
      await repo.updateGoal(existing.copyWith(
        name: name,
        targetAmount: target,
        currencyCode: _currency!.code,
        icon: _icon,
        iconColor: _iconColor,
        deadline: drift.Value(_deadline),
        updatedAt: DateTime.now(),
      ));
    } else {
      await repo.createGoalWithAccount(
        name: name,
        targetAmount: target,
        currencyCode: _currency!.code,
        accountName: name,
        icon: _icon,
        iconColor: _iconColor,
        deadline: _deadline,
        accountId: _accountId,
      );
    }
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingGoal != null;
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Goal' : 'New Goal'),
        centerTitle: true,
        backgroundColor: context.colors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.colors.textDark),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Goal name', style: TextStyle(color: context.colors.textLight)),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: 'Emergency fund',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Target amount',
              style: TextStyle(color: context.colors.textLight)),
          const SizedBox(height: 8),
          TextField(
            controller: _targetController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              hintText: '0.00',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Its own row: the amount has to be typeable, so the currency can't
          // ride along as a tap target on the field.
          OutlinedButton.icon(
            onPressed: _pickCurrency,
            icon: const Icon(Icons.payments_outlined),
            label: Text(
              _currency == null
                  ? 'Currency'
                  : '${_currency!.code} — ${_currency!.name}',
            ),
          ),
          const SizedBox(height: 20),
          Text('Icon', style: TextStyle(color: context.colors.textLight)),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final option in goalIconOptions) ...[
                GestureDetector(
                  onTap: () => setState(() {
                    _icon = option.icon;
                    _iconColor = option.color;
                  }),
                  child: Container(
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(option.color).withValues(
                        alpha: _icon == option.icon ? 1.0 : 0.15,
                      ),
                    ),
                    child: Icon(
                      goalIconDataFor(option.icon),
                      size: 20,
                      color: _icon == option.icon
                          ? Colors.white
                          : Color(option.color),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 20),
          Text('Target date (optional)',
              style: TextStyle(color: context.colors.textLight)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickDeadline,
                  icon: const Icon(Icons.event),
                  label: Text(
                    _deadline == null
                        ? 'Pick a date'
                        : '${_deadline!.year}-${_deadline!.month.toString().padLeft(2, '0')}-${_deadline!.day.toString().padLeft(2, '0')}',
                  ),
                ),
              ),
              if (_deadline != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => setState(() => _deadline = null),
                ),
              ],
            ],
          ),
          const SizedBox(height: 20),
          Text('Keep the money in',
              style: TextStyle(color: context.colors.textLight)),
          const SizedBox(height: 8),
// Rendered only once accounts are in: a DropdownButton asserts that its value
          // matches exactly one item, and an editing goal's account isn't in the
          // list until the query resolves.
          // A placeholder, not a spinner: an indeterminate animation here would keep
          // `pumpAndSettle` spinning forever in tests, and it lands for a
          // millisecond in the app.
          if (!_loaded) const SizedBox(height: 48)
          else
            DropdownButtonFormField<int?>(
              initialValue: _accountId ?? 0,
              isExpanded: true,
              items: [
                for (final a in _accounts)
                  DropdownMenuItem(value: a.id, child: Text(a.name)),
                // 0 rather than null so the choice can be displayed as well as
                // picked; null means "make one".
                const DropdownMenuItem(
                    value: 0, child: Text('New savings account')),
              ],
              onChanged: (value) =>
                  setState(() => _accountId = value == 0 ? null : value),
            ),
          const SizedBox(height: 8),
          Text(
            _accountId == null
                ? 'An empty savings account will be opened for this goal.'
                : 'Transfer money into this account to fund the goal.',
            style: TextStyle(color: context.colors.textLight, fontSize: 12),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _save,
            child: const Text('Save goal'),
          ),
        ],
      ),
    );
  }
}