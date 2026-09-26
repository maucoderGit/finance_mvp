import 'package:finance_mvp/constants/app_colors.dart';
import 'package:finance_mvp/database/app_database.dart' as db;
import 'package:finance_mvp/repositories/finance_repository.dart';
import 'package:finance_mvp/screens/contacts/contact_widgets.dart';
import 'package:finance_mvp/screens/debts/debt_form_screen.dart';
import 'package:finance_mvp/screens/transactions/transaction_list_view.dart';
import 'package:finance_mvp/services/finance/currency_converter.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// All debts and loans: open lenders (debtors) on top, with base-currency
/// totals and quick settle/delete.
class DebtsScreen extends StatefulWidget {
  const DebtsScreen({super.key});

  @override
  State<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends State<DebtsScreen> {
  List<db.Debt> _debts = const [];
  Map<int, String> _contactNames = const {};
  Map<int, double> _remaining = const {};
  Map<int, List<db.DebtInstallment>> _installments = const {};
  Map<String, db.Currency> _currencies = const {};
  ({double owedToMe, double owedByMe})? _totals;
  String _baseSymbol = r'$';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = context.read<FinanceRepository>();
    final debts = await repo.getAllDebts();
    final contacts = await repo.getAllContacts();
    final currencies = await repo.getAllCurrencies();
    final totals = await repo.getOpenDebtTotalsInBase();

    // Balance each debt against its linked payments; auto-settle the fully
    // paid ones so the list reflects reality without manual bookkeeping.
    final remaining = <int, double>{};
    final installments = <int, List<db.DebtInstallment>>{};
    for (final debt in debts) {
      final r = await repo.getDebtRemaining(debt);
      remaining[debt.id] = r;
      if (!debt.isSettled && r <= 0) {
        await repo.updateDebt(debt.copyWith(isSettled: true));
      }
      final schedule = await repo.getDebtInstallments(debt.id);
      if (schedule.isNotEmpty) installments[debt.id] = schedule;
    }

    if (!mounted) return;
    setState(() {
      _debts = debts;
      _contactNames = {for (final c in contacts) c.id: c.name};
      _remaining = remaining;
      _installments = installments;
      _currencies = {for (final c in currencies) c.code: c};
      _totals = totals;
    });
    final base = await repo.getBaseCurrencyCode();
    final baseCurrency = currencies.where((c) => c.code == base).firstOrNull;
    if (!mounted || baseCurrency == null) return;
    setState(() => _baseSymbol = baseCurrency.symbol);
  }

  Future<void> _add() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const DebtFormScreen()),
    );
    if (saved == true) await _load();
  }

  Future<void> _edit(db.Debt debt) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
          builder: (_) => DebtFormScreen(existingDebt: debt)),
    );
    if (saved == true) await _load();
  }

  Future<void> _toggleSettled(db.Debt debt) async {
    final repo = context.read<FinanceRepository>();
    await repo.updateDebt(
        debt.copyWith(isSettled: !debt.isSettled));
    await _load();
  }

  Future<void> _showPayments(db.Debt debt) async {
    final repo = context.read<FinanceRepository>();
    final payments = await repo.getTransactionsForDebt(debt.id);
    final currencies = await repo.getAllCurrencies();
    final contacts = await repo.getAllContacts();
    if (!mounted) return;
    final symbols = {for (final c in currencies) c.code: c.symbol};
    final contactNames = {for (final c in contacts) c.id: c.name};
    final symbol = symbols[debt.currencyCode] ?? r'$';
    final totalPaid = payments.fold<double>(
        0,
        (sum, t) => sum +
            ((t.baseCurrencyAmount ??
                        (t.currencyCode == debt.currencyCode ? t.amount : 0))
                    .abs()));

    await showModalBottomSheet(
      context: context,
      backgroundColor: context.colors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.75,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 8, 8),
                child: Row(
                  children: [
                    Text(
                      'Linked payments',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: context.colors.textDark,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(Icons.close,
                          color: context.colors.textLight),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  '${payments.length} payment(s) · '
                  '${formatMoney(totalPaid, symbol: symbol)} total',
                  style: TextStyle(
                      fontSize: 12, color: context.colors.textLight),
                ),
              ),
              const Divider(height: 24),
              Expanded(
                child: payments.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(32),
                        child: Center(
                          child: Text(
                            'No linked transactions yet.\nRecord an expense and choose '
                            "\u201CPay toward debt\u201D to link one.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: context.colors.textLight),
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        itemCount: payments.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final t = payments[index];
                          final usedRaw = t.baseCurrencyAmount ??
                              (t.currencyCode == debt.currencyCode
                                  ? t.amount
                                  : 0);
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TransactionItem(
                                transaction: t,
                                symbol:
                                    symbols[t.currencyCode] ??
                                        t.currencyCode,
                                contactName: t.contactId == null
                                    ? null
                                    : contactNames[t.contactId],
                              ),
                              Padding(
                                padding: const EdgeInsets.only(
                                    left: 4, top: 2),
                                child: Text(
                                  'Applied: ${formatMoney(usedRaw.abs(), symbol: symbol)}',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: context.colors.textLight),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _delete(db.Debt debt) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete debt?'),
        content: Text(
          'This removes the ${debt.direction == 'creditor' ? 'debt to' : 'loan to'} '
          '${_contactNames[debt.contactId] ?? 'contact'} (${formatMoney(debt.amount, symbol: _currencies[debt.currencyCode]?.symbol ?? debt.currencyCode)}).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!mounted) return;
    final repo = context.read<FinanceRepository>();
    await repo.deleteDebt(debt.id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final totals = _totals;
    final openDebts = [for (final d in _debts) if (!d.isSettled) d];
    final settledDebts = [for (final d in _debts) if (d.isSettled) d];
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: const Text('Debts & Debtors'),
        centerTitle: true,
        backgroundColor: context.colors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.colors.textDark),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            tooltip: 'New debt',
            icon: Icon(Icons.add, color: context.colors.textDark),
            onPressed: _add,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  label: 'They owe me',
                  amount: totals?.owedToMe ?? 0,
                  symbol: _baseSymbol,
                  tone: 'good',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryCard(
                  label: 'I owe',
                  amount: totals?.owedByMe ?? 0,
                  symbol: _baseSymbol,
                  tone: 'bad',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_debts.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 120),
              child: Column(
                children: [
                  Icon(Icons.handshake_outlined,
                      size: 40, color: context.colors.textLight),
                  const SizedBox(height: 8),
                  Text(
                    'No debts yet',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: context.colors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Track loans you gave or received with the + button.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: context.colors.textLight,
                    ),
                  ),
                ],
              ),
            ),
          for (final debt in openDebts) _buildDebtTile(debt),
          if (settledDebts.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.only(top: 20, bottom: 8),
              child: Text('Settled',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey)),
            ),
            for (final debt in settledDebts) _buildDebtTile(debt),
          ],
        ],
      ),
    );
  }

  Widget _buildDebtTile(db.Debt debt) {
    final contactName = _contactNames[debt.contactId];
    final symbol =
        _currencies[debt.currencyCode]?.symbol ?? debt.currencyCode;
    final isCreditor = debt.direction == 'creditor';
    final title = contactName ?? debt.description ?? 'Debt';
    final remaining = _remaining[debt.id] ?? debt.amount;
    final schedule = _installments[debt.id];
    final subtitle = <String>[
      if (isCreditor) 'I owe' else 'They owe me',
      if (contactName != null && debt.description != null)
        debt.description!,
      if (schedule != null && schedule.length > 1)
        '${schedule.length} cuotas',
      if (debt.dueDate != null)
        'Due ${DateFormat('MMM dd, yyyy').format(debt.dueDate!)}',
      if (!debt.isSettled)
        '${formatMoney(remaining, symbol: symbol)} of '
            '${formatMoney(debt.amount, symbol: symbol)}',
      DateFormat('MMM dd, yyyy').format(debt.date),
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: debt.isSettled
            ? context.colors.fieldsBackground
            : context.colors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => _edit(debt),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                ContactAvatar(
                  name: contactName ?? (isCreditor ? 'I' : 'P'),
                  size: 40,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: debt.isSettled
                              ? context.colors.textLight
                              : context.colors.textDark,
                          decoration: debt.isSettled
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: context.colors.textLight,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  formatMoney(debt.isSettled ? debt.amount : remaining,
                      symbol: symbol),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: debt.isSettled
                        ? context.colors.textLight
                        : (isCreditor
                            ? const Color(0xFFC62828)
                            : context.colors.primary),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  tooltip: 'Linked payments',
                  icon: Icon(Icons.receipt_long,
                      color: context.colors.textLight),
                  onPressed: () => _showPayments(debt),
                ),
                IconButton(
                  tooltip: debt.isSettled ? 'Reopen' : 'Settle',
                  icon: Icon(
                    debt.isSettled
                        ? Icons.restore
                        : Icons.check_circle_outline,
                    color: debt.isSettled
                        ? context.colors.primary
                        : context.colors.textLight,
                  ),
                  onPressed: () => _toggleSettled(debt),
                ),
                IconButton(
                  tooltip: 'Delete',
                  icon: Icon(Icons.delete_outline,
                      color: context.colors.textLight),
                  onPressed: () => _delete(debt),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final double amount;
  final String symbol;
  final String tone;
  const _SummaryCard({
    required this.label,
    required this.amount,
    required this.symbol,
    required this.tone,
  });

  @override
  Widget build(BuildContext context) {
    final color = tone == 'good'
        ? context.colors.primary
        : const Color(0xFFC62828);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, color: context.colors.textLight),
          ),
          const SizedBox(height: 4),
          Text(
            formatMoney(amount, symbol: symbol),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}