import 'package:drift/drift.dart' as drift;
import 'package:finance_mvp/constants/app_colors.dart';
import 'package:finance_mvp/database/app_database.dart' as db;
import 'package:finance_mvp/repositories/finance_repository.dart';
import 'package:finance_mvp/screens/contacts/contact_picker_screen.dart';
import 'package:finance_mvp/screens/contacts/contact_widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

const debtDirectionDebtor = 'debtor';
const debtDirectionCreditor = 'creditor';

/// Full-screen form to register or edit a debt/loan. Saves via the repository
/// and pops with `true` when something was persisted.
class DebtFormScreen extends StatefulWidget {
  final bool isCreditor;
  final db.Debt? existingDebt;
  const DebtFormScreen({super.key, this.isCreditor = false, this.existingDebt});

  @override
  State<DebtFormScreen> createState() => _DebtFormScreenState();
}

class _DebtFormScreenState extends State<DebtFormScreen> {
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  late String _direction =
      widget.existingDebt?.direction ?? (widget.isCreditor ? debtDirectionCreditor : debtDirectionDebtor);
  late bool _isSettled = widget.existingDebt?.isSettled ?? false;
  DateTime? _dueDate;
  db.Contact? _contact;
  db.Currency? _currency;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingDebt;
    _descriptionController.text = existing?.description ?? '';
    if (existing != null) {
      _amountController.text = existing.amount.toStringAsFixed(2);
      _dueDate = existing.dueDate;
    }
    _loadContext();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadContext() async {
    final repo = context.read<FinanceRepository>();
    final currencies = await repo.getAllCurrencies();
    if (!mounted) return;

    var currency = currencies.firstOrNull;
    final existing = widget.existingDebt;
    if (existing != null) {
      final existingCurrency = currencies
          .where((c) => c.code == existing.currencyCode)
          .firstOrNull;
      if (existingCurrency != null) currency = existingCurrency;
    } else {
      final base = await repo.getBaseCurrencyCode();
      final baseCurrency =
          currencies.where((c) => c.code == base).firstOrNull;
      if (baseCurrency != null) currency = baseCurrency;
    }

    db.Contact? contact;
    if (existing?.contactId != null) {
      contact = await repo.getContactById(existing!.contactId!);
    }
    if (!mounted) return;
    setState(() {
      _currency = currency;
      _contact = contact;
    });
  }

  Future<void> _pickContact() async {
    final picked = await Navigator.of(context).push<db.Contact>(
      MaterialPageRoute(builder: (_) => const ContactPickerScreen()),
    );
    if (picked != null && mounted) {
      setState(() => _contact = picked);
    }
  }

  Future<void> _pickCurrency() async {
    final repo = context.read<FinanceRepository>();
    final currencies = await repo.getAllCurrencies();
    if (!mounted) return;
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
            for (final c in currencies)
              ListTile(
                title: Text('${c.code} — ${c.name}'),
                onTap: () => Navigator.of(sheetContext).pop(c),
              ),
          ],
        ),
      ),
    );
    if (selected != null && mounted) {
      setState(() => _currency = selected);
    }
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
      initialDate: _dueDate ?? now,
    );
    if (picked != null && mounted) {
      setState(() => _dueDate = picked);
    }
  }

  Future<void> _save() async {
    final repo = context.read<FinanceRepository>();
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0 || _currency == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid amount')),
      );
      return;
    }

    final existing = widget.existingDebt;
    final contactId = _contact?.id;
    final description = _descriptionController.text.trim().isEmpty
        ? null
        : _descriptionController.text.trim();
    if (existing != null) {
      await repo.updateDebt(existing.copyWith(
        description: drift.Value(description),
        direction: _direction,
        contactId: drift.Value(contactId),
        amount: amount,
        currencyCode: _currency!.code,
        dueDate: drift.Value(_dueDate),
        isSettled: _isSettled,
      ));
    } else {
      await repo.addDebt(db.DebtsCompanion.insert(
        contactId: drift.Value(contactId),
        direction: drift.Value(_direction),
        description: drift.Value(description),
        amount: amount,
        currencyCode: _currency!.code,
        date: DateTime.now(),
        dueDate: drift.Value(_dueDate),
      ));
    }
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: Text(widget.existingDebt == null ? 'New Debt' : 'Edit Debt'),
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
          Text('Direction', style: TextStyle(color: context.colors.textLight)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _DirectionButton(
                  label: 'They owe me',
                  selected: _direction == debtDirectionDebtor,
                  onTap: () =>
                      setState(() => _direction = debtDirectionDebtor),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DirectionButton(
                  label: 'I owe',
                  selected: _direction == debtDirectionCreditor,
                  onTap: () =>
                      setState(() => _direction = debtDirectionCreditor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text('Contact (optional)',
              style: TextStyle(color: context.colors.textLight)),
          const SizedBox(height: 8),
          _buildContactField(),
          const SizedBox(height: 20),
          Text('Amount', style: TextStyle(color: context.colors.textLight)),
          const SizedBox(height: 8),
          TextField(
            controller: _amountController,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              hintText: '0.00',
              suffixIcon: _currency == null
                  ? null
                  : Padding(
                      padding: const EdgeInsets.all(14),
                      child: Text(_currency!.code,
                          style: TextStyle(
                              color: context.colors.textLight,
                              fontWeight: FontWeight.w600)),
                    ),
              filled: true,
              fillColor: context.colors.fieldsBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Currency',
                  style: TextStyle(color: context.colors.textLight)),
              TextButton(
                onPressed: _pickCurrency,
                child: Text(
                  _currency == null
                      ? 'Select'
                      : '${_currency!.code} — ${_currency!.symbol}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('Description (optional)',
              style: TextStyle(color: context.colors.textLight)),
          const SizedBox(height: 8),
          TextField(
            controller: _descriptionController,
            decoration: InputDecoration(
              hintText: 'e.g. Loan for the market',
              filled: true,
              fillColor: context.colors.fieldsBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (widget.existingDebt != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Settled',
                    style: TextStyle(color: context.colors.textDark)),
                Switch(
                  value: _isSettled,
                  onChanged: (v) => setState(() => _isSettled = v),
                ),
              ],
            ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Due date (optional)',
                  style: TextStyle(color: context.colors.textLight)),
              TextButton(
                onPressed: _pickDueDate,
                child: Text(
                  _dueDate == null
                      ? '+ Set date'
                      : '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              if (_dueDate != null)
                IconButton(
                  tooltip: 'Clear due date',
                  icon: Icon(Icons.close,
                      size: 18, color: context.colors.textLight),
                  onPressed: () => setState(() => _dueDate = null),
                ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                backgroundColor: Theme.of(context).primaryColor,
              ),
              child: const Text('Save Debt', style: TextStyle(color: Colors.white)),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildContactField() {
    final contact = _contact;
    return GestureDetector(
      onTap: _pickContact,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: context.colors.fieldsBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            if (contact != null) ...[
              ContactAvatar(name: contact.name, size: 32),
              const SizedBox(width: 12),
            ] else ...[
              Icon(Icons.person_outline, color: context.colors.textLight),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                contact?.name ?? 'Select contact',
                style: TextStyle(
                  fontSize: 16,
                  color: contact == null
                      ? context.colors.textLight
                      : context.colors.textDark,
                ),
              ),
            ),
            if (contact != null)
              IconButton(
                tooltip: 'Remove contact',
                icon: Icon(Icons.close,
                    size: 18, color: context.colors.textLight),
                onPressed: () => setState(() => _contact = null),
              )
            else
              Icon(Icons.chevron_right, color: context.colors.textLight),
          ],
        ),
      ),
    );
  }
}

class _DirectionButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _DirectionButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? context.colors.primary
              : context.colors.fieldsBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: selected
                ? Colors.white
                : context.colors.textLight,
          ),
        ),
      ),
    );
  }
}