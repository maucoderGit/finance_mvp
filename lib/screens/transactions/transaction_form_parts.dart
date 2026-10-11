part of 'transaction_screen.dart';

String _recurrenceTypeLabel(AppLocalizations l10n, RecurrenceType type) =>
    switch (type) {
      RecurrenceType.daily => l10n.recurrenceDaily,
      RecurrenceType.weekly => l10n.recurrenceWeekly,
      RecurrenceType.monthly => l10n.recurrenceMonthly,
      RecurrenceType.yearly => l10n.recurrenceYearly,
    };

String _recurrenceEndLabel(AppLocalizations l10n, RecurrenceEnd end) =>
    switch (end) {
      RecurrenceEnd.never => l10n.recurrenceEndNever,
      RecurrenceEnd.onDate => l10n.recurrenceEndOnDate,
      RecurrenceEnd.afterCount => l10n.recurrenceEndAfterCount,
    };

const _frequencies = <String>['weekly', 'biweekly', 'monthly'];

String _frequencyLabel(AppLocalizations l10n, String id) => switch (id) {
      'weekly' => l10n.frequencyWeekly,
      'biweekly' => l10n.frequencyBiweekly,
      _ => l10n.frequencyMonthly,
    };

/// Bottom sheet listing open (unpaid) debts to link a transaction as a
/// payment against one of them.
class _DebtPickerSheet extends StatefulWidget {
  const _DebtPickerSheet({required this.repo});

  final FinanceRepository repo;

  @override
  State<_DebtPickerSheet> createState() => _DebtPickerSheetState();
}

class _DebtPickerSheetState extends State<_DebtPickerSheet> {
  List<db.Debt> _debts = [];
  Map<int, double> _remaining = {};
  Map<String, String> _symbols = {};
  Map<int, String> _contactNames = {};
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = widget.repo;
    final debts = await repo.getAllDebts();
    final contacts = await repo.getAllContacts();
    final currencies = await repo.getAllCurrencies();
    final symbolByCode = {
      for (final c in currencies) c.code: c.symbol,
    };
    final remainingByDebt = <int, double>{};
    for (final debt in debts) {
      final remaining = await repo.getDebtRemaining(debt);
      if (debt.isSettled || remaining <= 0) continue;
      remainingByDebt[debt.id] = remaining;
    }
    if (!mounted) return;
    setState(() {
      _debts = debts.where((d) => remainingByDebt.containsKey(d.id)).toList();
      _remaining = remainingByDebt;
      _symbols = symbolByCode;
      _contactNames = {for (final c in contacts) c.id: c.name};
      _loaded = true;
    });
  }

  String _titleFor(db.Debt debt) {
    if (debt.contactId != null && _contactNames[debt.contactId] != null) {
      return _contactNames[debt.contactId]!;
    }
    return (debt.description ?? '').trim().isEmpty
        ? context.l10n.debtsDebt
        : debt.description!.trim();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colors;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Row(
                children: [
                  Text(
                    context.l10n.txPayTowardDebt,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.textDark,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.close, color: colorScheme.textLight),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            if (!_loaded)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_debts.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Text(
                    context.l10n.txNoOpenDebts,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colorScheme.textLight),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: _debts.length,
                  itemBuilder: (context, index) {
                    final debt = _debts[index];
                    final symbol = _symbols[debt.currencyCode] ?? r'$';
                    return ListTile(
                      leading: Icon(
                        Icons.account_balance_wallet_outlined,
                        color: colorScheme.primary,
                      ),
                      title: Text(_titleFor(debt),
                          style: TextStyle(color: colorScheme.textDark)),
                      subtitle: Text(
                        '${debt.direction == 'creditor' ? context.l10n.debtsIOwe : context.l10n.debtsTheyOweMe}'
                        ' · ${context.l10n.debtsProgressOf(
                          formatMoney(_remaining[debt.id]!, symbol: symbol),
                          formatMoney(debt.amount, symbol: symbol),
                        )}',
                        style: TextStyle(color: colorScheme.textLight),
                      ),
                      onTap: () => Navigator.pop(context, debt),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}

/// A tappable label/value row inside the recurrence card. Deliberately looks
/// like the other pickers in this flow (chevron on the right) so it doesn't
/// read as a dead chip.
class _RecurrenceRow extends StatelessWidget {
  const _RecurrenceRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: Row(
          children: [
            Icon(icon, size: 20, color: context.colors.primary),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(fontSize: 15)),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: context.colors.primary,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, size: 20, color: context.colors.textLight),
          ],
        ),
      ),
    );
  }
}

/// "Next: 28 Feb 2026", or a note that the series has already finished.
class _NextDueHint extends StatelessWidget {
  const _NextDueHint({required this.rule});

  final Recurrence rule;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final next = rule.nextOccurrenceOnOrAfter(today);
    return Text(
      next == null
          ? context.l10n.txSeriesFinished
          : context.l10n.txNext(DateFormat.yMMMd().format(next)),
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: next == null ? context.colors.textLight : context.colors.primary,
      ),
    );
  }
}

/// Stepper shared by the two sheets: `- value +` clamped to [min]..[max].
class _CountStepper extends StatelessWidget {
  const _CountStepper({
    required this.label,
    required this.value,
    required this.onChanged,
    this.max = 365,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  final int max;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 15)),
        Row(
          children: [
            _StepButton(
              icon: Icons.remove,
              enabled: value > 1,
              onTap: () => onChanged(value - 1),
            ),
            SizedBox(
              width: 56,
              child: Text(
                '$value',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ),
            _StepButton(
              icon: Icons.add,
              enabled: value < max,
              onTap: () => onChanged(value + 1),
            ),
          ],
        ),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: enabled
              ? context.colors.primaryLight.withValues(alpha: 0.25)
              : context.colors.fieldsBackground,
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? context.colors.primary : context.colors.textLight,
        ),
      ),
    );
  }
}

/// Picks how often the transaction repeats.
class _RepeatsSheet extends StatefulWidget {
  const _RepeatsSheet({required this.type, required this.interval});

  final RecurrenceType type;
  final int interval;

  @override
  State<_RepeatsSheet> createState() => _RepeatsSheetState();
}

class _RepeatsSheetState extends State<_RepeatsSheet> {
  late RecurrenceType _type = widget.type;
  late int _interval = widget.interval;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.l10n.txRepeat,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final t in RecurrenceType.values)
                  ChoiceChip(
                    label: Text(_recurrenceTypeLabel(context.l10n, t)),
                    selected: _type == t,
                    onSelected: (_) => setState(() => _type = t),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            _CountStepper(
              label: context.l10n.txEvery,
              value: _interval,
              max: _type == RecurrenceType.daily ? 365 : 60,
              onChanged: (v) => setState(() => _interval = v),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, (type: _type, interval: _interval)),
                child: Text(context.l10n.txDone),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// What the `_pickEnds` sheet hands back.
class _RecurrenceEndChoice {
  const _RecurrenceEndChoice({required this.end, this.endDate, this.totalCount});

  final RecurrenceEnd end;
  final DateTime? endDate;
  final int? totalCount;
}

/// Picks when the series stops.
class _EndsSheet extends StatefulWidget {
  const _EndsSheet({
    required this.end,
    required this.endDate,
    required this.totalCount,
  });

  final RecurrenceEnd end;
  final DateTime? endDate;
  final int totalCount;

  @override
  State<_EndsSheet> createState() => _EndsSheetState();
}

class _EndsSheetState extends State<_EndsSheet> {
  late RecurrenceEnd _end = widget.end;
  late DateTime? _endDate = widget.endDate;
  late int _count = widget.totalCount;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.l10n.txEnds,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            RadioGroup<RecurrenceEnd>(
              groupValue: _end,
              onChanged: (v) => setState(() => _end = v!),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final e in RecurrenceEnd.values)
                    RadioListTile<RecurrenceEnd>(
                      value: e,
                      activeColor: context.colors.primary,
                      contentPadding: EdgeInsets.zero,
                      title: Text(_recurrenceEndLabel(context.l10n, e),
                          style: TextStyle(color: context.colors.textDark)),
                      subtitle: Text(
                        switch (e) {
                          RecurrenceEnd.never => context.l10n.txEndNever,
                          RecurrenceEnd.onDate => context.l10n.txEndOnDate,
                          RecurrenceEnd.afterCount => context.l10n.txEndAfterCount,
                        },
                        style: TextStyle(color: context.colors.textLight),
                      ),
                    ),
                ],
              ),
            ),
            if (_end == RecurrenceEnd.onDate)
              TextButton.icon(
                icon: const Icon(Icons.calendar_today, size: 18),
                label: Text(
                  _endDate == null
                      ? context.l10n.txPickEndDate
                      : DateFormat.yMMMd().format(_endDate!),
                ),
                onPressed: _pickDate,
              ),
            if (_end == RecurrenceEnd.afterCount) ...[
              const SizedBox(height: 8),
              _CountStepper(
                label: context.l10n.txOccurrences,
                value: _count,
                onChanged: (v) => setState(() => _count = v),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(
                  context,
                  _RecurrenceEndChoice(
                    end: _end,
                    // Default to a year out rather than leaving it unset, which
                    // would read as "never" while the radio says "on a date".
                    endDate: _end == RecurrenceEnd.onDate
                        ? (_endDate ??
                            DateTime.now().add(const Duration(days: 365)))
                        : null,
                    totalCount: _end == RecurrenceEnd.afterCount ? _count : null,
                  ),
                ),
                child: Text(context.l10n.txDone),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _endDate = picked);
  }
}
