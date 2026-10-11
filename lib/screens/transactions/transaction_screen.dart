import 'dart:io';

import 'package:drift/drift.dart' hide Column;
import 'package:finance_mvp/constants/account_icons.dart';
import 'package:finance_mvp/constants/app_colors.dart';
import 'package:finance_mvp/database/app_database.dart' as db;
import 'package:finance_mvp/l10n/l10n.dart';
import 'package:finance_mvp/repositories/finance_repository.dart';
import 'package:finance_mvp/screens/contacts/contact_picker_screen.dart';
import 'package:finance_mvp/screens/contacts/contact_widgets.dart';
import 'package:finance_mvp/screens/settings/category_screen.dart';
import 'package:finance_mvp/services/finance/currency_converter.dart';
import 'package:finance_mvp/services/finance/recurrence.dart';
import 'package:finance_mvp/services/finance/transaction_planner.dart';
import 'package:finance_mvp/services/profile_picture_service.dart';
import 'package:finance_mvp/widgets/custom_toast.dart';
import 'package:finance_mvp/widgets/numpad.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

part 'transaction_form_parts.dart';

enum TransactionType {
  income,
  expense,
  transfer,
}

/// A category chosen in the form, with its icon and colour already resolved so
/// the row is cheap to build and there are no untyped map lookups.
class SelectedCategory {
  const SelectedCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });

  final int id;
  final String name;
  final IconData icon;
  final Color color;
}

class TransactionScreen extends StatefulWidget {
  const TransactionScreen({super.key, this.existingTransaction});

  /// When set, the screen edits this transaction instead of creating a new one.
  final db.Transaction? existingTransaction;

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  String _amount = '0';
  int _currentStep = 0;
  TransactionType _transactionType = TransactionType.income;

  /// Off by default: a transaction is not a bill until the user says so.
  bool _isRecurrenceEnabled = false;
  RecurrenceType _recurrenceType = RecurrenceType.monthly;
  int _recurrenceInterval = 1;
  RecurrenceEnd _recurrenceEnd = RecurrenceEnd.never;
  DateTime? _recurrenceEndDate;
  int _recurrenceTotalCount = 12;

  /// The day this transaction is booked, and for a recurring one the anchor
  /// every later occurrence is derived from. Movable only while recurrence is
  /// on, so editing an ordinary transaction can't refile it into another month.
  DateTime _date = DateTime.now();
  final TextEditingController _referenceController = TextEditingController();
  final TextEditingController _rateController = TextEditingController();

  /// The contact linked to this transaction; choosing/replacing it happens
  /// from the full-screen [ContactPickerScreen].
  db.Contact? _selectedContact;

  /// The debt this transaction pays toward (reduces its outstanding amount).
  db.Debt? _selectedDebt;
  double? _selectedDebtRemaining;

  /// Display metadata for the linked debt (contact name / description and
  /// the currency symbol), resolved when picking so the row is cheap to build.
  String? _selectedDebtTitle;
  String _selectedDebtSymbol = r'$';
  db.Account? _selectedAccount;
  SelectedCategory? category;
  String? _imagePath;

  /// Destination account of an internal transfer/menudeo.
  db.Account? _transferToAccount;

  /// The id of the sibling leg when editing an existing transfer.
  int? _transferPairId;

  /// Live conversion preview: rate of "1 base = X account currency" and the
  /// base currency the amount is converted into.
  double? _previewRate;
  String? _previewBaseCode;
  String? _previewBaseSymbol;

  /// When the account is in the base currency, the preview converts into the
  /// national (local) currency instead.
  String? _previewNationalCode;
  String? _previewNationalSymbol;
  double? _previewNationalRate;

  /// When true, step 3 (Debt/installments) is unlocked: saving also splits the
  /// transaction into a debt (or one debt per installment) with a due date.
  bool _debtEnabled = false;
  int _installmentCount = 1;
  String _dueFrequency = 'monthly';
  DateTime? _dueDate;

  /// The debt this transaction sourced (debt mode). Non-null while editing a
  /// transaction that already created a debt/installment plan; clearing it on
  /// save deletes that plan.
  db.Debt? _sourceDebt;

  @override
  void dispose() {
    _referenceController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  void _onNumberTap(String value) {
    setState(() {
      if (value == '.') {
        if (!_amount.contains('.')) _amount = '$_amount.';
        return;
      }
      if (_amount == '0') {
        _amount = value;
      } else {
        _amount = '$_amount$value';
      }
    });
  }

  void _onBackspaceTap() {
    setState(() {
      if (_amount.length > 1) {
        _amount = _amount.substring(0, _amount.length - 1);
      } else {
        _amount = '0';
      }
    });
  }

  String _formatCurrency(String amountStr, {String symbol = r'$'}) {
    final number = double.tryParse(amountStr) ?? 0.0;
    return formatMoney(number, symbol: symbol);
  }

  @override
  void initState() {
    super.initState();
    final existing = widget.existingTransaction;
    if (existing != null) {
      _amount = existing.amount.abs().toStringAsFixed(2);
      _referenceController.text = existing.reference ?? '';
      if (existing.exchangeRateAtCreation != null) {
        _rateController.text =
            existing.exchangeRateAtCreation!.toStringAsFixed(2);
      }
      _isRecurrenceEnabled = existing.isRecurrenceEnabled;
      _recurrenceType =
          RecurrenceType.tryParse(existing.recurrenceType) ??
              RecurrenceType.monthly;
      _recurrenceInterval = existing.recurrenceInterval;
      _recurrenceEnd = RecurrenceEnd.tryParse(existing.recurrenceEnds);
      _recurrenceEndDate = existing.recurrenceEndDate;
      _recurrenceTotalCount = existing.recurrenceTotalCount ?? 12;
      _date = existing.date;
      _transactionType = existing.transferGroupId != null
          ? TransactionType.transfer
          : existing.amount >= 0
              ? TransactionType.income
              : TransactionType.expense;
      _imagePath = existing.imagePath;
      _loadContextForEdit(existing);
    } else {
      _loadInitialAccount();
    }
  }

  /// Pre-select the first account so the conversion preview is visible
  /// without opening the picker (mirrors the save-time fallback).
  Future<void> _loadInitialAccount() async {
    final repo = context.read<FinanceRepository>();
    final accounts = await repo.getAllAccounts();
    if (!mounted) return;
    if (_selectedAccount == null && accounts.isNotEmpty) {
      setState(() => _selectedAccount = accounts.first);
    }
    await _loadConversionPreview();
  }

  /// Resolve the rates of the selected account currency and the national
  /// currency against the base currency (stored rate at today, falling back
  /// to the latest available).
  Future<void> _loadConversionPreview() async {
    final repo = context.read<FinanceRepository>();
    final account = _selectedAccount;
    if (account == null) return;

    final baseCode = await repo.getBaseCurrencyCode();
    final nationalCode = await repo.getNationalCurrencyCode();

    final currencies = await repo.getAllCurrencies();
    String symbolOf(String code) {
      for (final c in currencies) {
        if (c.code == code) return c.symbol;
      }
      return '';
    }

    double? nationalRate;
    if (nationalCode != baseCode) {
      nationalRate =
          await repo.getRateWithFallback(nationalCode, DateTime.now());
    }

    // The rate field ("1 base = X") always targets a non-base currency. For a
    // cross-currency transfer the amount sits in the source currency, so when
    // the source IS the base currency the rate must describe the destination.
    final isTransfer = _transactionType == TransactionType.transfer &&
        _transferToAccount != null;
    final targetCode = isTransfer
        ? (account.currencyCode != baseCode
            ? account.currencyCode
            : _transferToAccount!.currencyCode)
        : account.currencyCode;

    // Exchange is an explicit act only for cross-currency transfers: the real
    // (parallel) price is the reference and prefill the editable field. A plain
    // income/expense is bookkeeping — convert it at the stored/official
    // reference rate, identically for a USD or a VES account.
    final double? rate;
    if (isTransfer) {
      rate = await repo.effectiveRate(targetCode);
      if (rate != null && rate > 0 && _rateController.text.trim().isEmpty) {
        _rateController.text = rate.toStringAsFixed(2);
      }
    } else {
      // A plain move has no editable rate: drop any value left over from a
      // transfer so switching back re-prefills the reference cleanly.
      _rateController.clear();
      rate = targetCode != baseCode
          ? await repo.getRateWithFallback(targetCode, DateTime.now())
          : null;
    }

    if (!mounted) return;
    setState(() {
      _previewRate = rate;
      _previewBaseCode = baseCode;
      _previewBaseSymbol = symbolOf(baseCode);
      _previewNationalCode = nationalCode;
      _previewNationalSymbol = symbolOf(nationalCode);
      _previewNationalRate = nationalRate;
    });
  }

  Future<void> _loadContextForEdit(db.Transaction existing) async {
    final repo = context.read<FinanceRepository>();
    final accounts = await repo.getAllAccounts();
    db.Account? account;
    for (final candidate in accounts) {
      if (candidate.id == existing.accountId) {
        account = candidate;
        break;
      }
    }

    db.Account? fromAccount = account;
    db.Transaction pairLeg = existing;
    if (existing.transferGroupId != null) {
      final pair = await repo.getTransactionsByGroup(existing.transferGroupId!);
      for (final t in pair) {
        if (t.id != existing.id) {
          pairLeg = t;
          break;
        }
      }
      // The source leg is always stored negative; whichever leg the user
      // tapped, the form edits the full transfer, so open on the source.
      final isSourceLeg = existing.amount < 0;
      final fromLeg = isSourceLeg ? existing : pairLeg;
      final toLeg = isSourceLeg ? pairLeg : existing;
      _amount = fromLeg.amount.abs().toStringAsFixed(2);
      _transferPairId = pairLeg.id;
      for (final candidate in accounts) {
        if (candidate.id == fromLeg.accountId) fromAccount = candidate;
        if (candidate.id == toLeg.accountId) _transferToAccount = candidate;
      }
    }

    var categories = <db.Category>[];
    try {
      categories = await repo.getAllCategories();
    } catch (_) {}
    final categoryId = existing.categoryId;
    for (final candidate in categories) {
      if (candidate.id == categoryId) {
        setState(() {
          category = SelectedCategory(
            id: candidate.id,
            name: candidate.name,
            icon: categoryIcons[candidate.icon] ?? Icons.bookmark,
            color: Color(candidate.color),
          );
        });
        break;
      }
    }

    if (!mounted) return;
    setState(() {
      _selectedAccount = fromAccount;
    });

    // Resolve the stored contact so the picker opens with it selected.
    if (existing.contactId != null) {
      final contact = await repo.getContactById(existing.contactId!);
      if (contact != null && mounted) {
        setState(() => _selectedContact = contact);
      }
    }

    // Resolve the debt this transaction pays toward.
    if (existing.debtId != null) {
      final debt = await repo.getDebtById(existing.debtId!);
      if (debt != null && mounted) {
        final meta = await _debtMeta(debt);
        if (!mounted) return;
        setState(() {
          _selectedDebt = debt;
          _selectedDebtTitle = meta.title;
          _selectedDebtSymbol = meta.symbol;
        });
      }
    }

    // This transaction created the debt in debt mode: restore the debt plan
    // so the user can see (and edit) the quota schedule in step 3.
    if (existing.sourceDebtId != null) {
      final source = await repo.getDebtById(existing.sourceDebtId!);
      if (source != null && mounted) {
        final schedule = await repo.getDebtInstallments(source.id);
        if (!mounted) return;
        setState(() {
          _sourceDebt = source;
          _debtEnabled = true;
          _installmentCount =
              schedule.isEmpty ? 1 : schedule.length;
          _dueFrequency = source.frequency ?? 'monthly';
          _dueDate = schedule.isNotEmpty
              ? schedule.first.dueDate
              : source.dueDate;
        });
      }
    }

    await _loadConversionPreview();
  }

  Widget _buildConversionPreview() {
    final accountCode = _selectedAccount?.currencyCode;
    final baseCode = _previewBaseCode;
    if (accountCode == null || baseCode == null) {
      return const SizedBox.shrink();
    }

    final amount = double.tryParse(_amount) ?? 0.0;
    final rate = _previewRate;

    final Text amountLine;
    final Text? rateLine;

    if (accountCode == baseCode) {
      // Account in base currency: show the amount in the national currency.
      final nationalCode = _previewNationalCode;
      final nationalRate = _previewNationalRate;
      if (nationalCode == null) return const SizedBox.shrink();

      if (nationalCode == baseCode || nationalRate == null) {
        amountLine = Text(
          context.l10n.txfNoExchangeRate(nationalCode),
          style: TextStyle(fontSize: 14, color: context.colors.textLight),
        );
        rateLine = null;
      } else {
        final localAmount = amount * nationalRate;
        amountLine = Text(
          context.l10n.txfApproxAmount(
              _formatCurrency(localAmount.toString(),
                  symbol: _previewNationalSymbol ?? r'$')),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: context.colors.textLight,
          ),
        );
        rateLine = Text(
          context.l10n.txfRateLine(
              baseCode, nationalRate.toStringAsFixed(2), nationalCode),
          style: TextStyle(fontSize: 12, color: context.colors.textLight),
        );
      }
    } else if (rate != null) {
      final baseAmount = rate != 0 ? amount / rate : 0.0;
      amountLine = Text(
        context.l10n.txfApproxAmount(
            _formatCurrency(baseAmount.toString(),
                symbol: _previewBaseSymbol ?? r'$')),
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: context.colors.textLight,
        ),
      );
      rateLine = Text(
        context.l10n.txfRateLine(
            baseCode, rate.toStringAsFixed(2), accountCode),
        style: TextStyle(fontSize: 12, color: context.colors.textLight),
      );
    } else {
      amountLine = Text(
        context.l10n.txfNoExchangeRate(accountCode),
        style: TextStyle(fontSize: 14, color: context.colors.textLight),
      );
      rateLine = null;
    }

    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          amountLine,
          if (rateLine != null) ...[
            const SizedBox(height: 2),
            rateLine,
          ],
        ],
      ),
    );
  }

  Future<void> _saveTransaction() async {
    if (_transactionType == TransactionType.transfer) {
      await _saveTransfer();
      return;
    }

    final repo = context.read<FinanceRepository>();
    final existing = widget.existingTransaction;

    // When the original save used debt mode, or this fresh one does, save the
    // transaction together with the debt plan.
    if (_debtEnabled) {
      await _saveTransactionWithDebt();
      return;
    }

    final companion = await _buildTransactionCompanion();
    if (companion == null) return;

    if (existing != null) {
      await repo.updateTransaction(companion);
      // The user turned debt mode off while editing a debt-sourced
      // transaction: drop the plan created by the original save too.
      if (existing.sourceDebtId != null) {
        await repo.deleteDebt(existing.sourceDebtId!);
      }
    } else {
      await repo.createTransaction(companion);
    }

    if (mounted) Navigator.pop(context);
  }

  /// Validates the form and builds the transaction to persist, or returns null
  /// (and toasts) when something is missing. Shared by plain and debit save.
  Future<db.TransactionsCompanion?> _buildTransactionCompanion() async {
    final repo = context.read<FinanceRepository>();

    if (_selectedAccount == null) {
      if (mounted) {
        showToast(context,
            message: context.l10n.txfSelectAccountFirst,
            type: ToastType.error);
      }
      return null;
    }

    var amountValue = double.tryParse(_amount) ?? 0.0;
    if (amountValue <= 0) {
      if (mounted) {
        showToast(context,
            message: context.l10n.txfEnterAmount, type: ToastType.error);
      }
      return null;
    }
    if (_transactionType == TransactionType.expense) {
      amountValue = -amountValue;
    }

    // A plain income/expense is bookkeeping, not an exchange: capture the
    // stored/official reference rate for the account currency (1:1 for a base
    // account) with no manual override. The parallel/market price is reserved
    // for explicit cross-currency transfers (see TransactionPlanner), so plain
    // moves carry no FX arbitrage delta either.
    final fx = await repo.captureFxFields(
      accountCurrencyCode: _selectedAccount!.currencyCode,
      signedAmount: amountValue,
    );
    final rateAtCreation = fx.rateAtCreation;
    final baseAmount = fx.baseAmount;

    final existing = widget.existingTransaction;
    return db.TransactionsCompanion(
      id: existing != null ? Value(existing.id) : const Value.absent(),
      amount: Value(amountValue),
      accountId: Value(_selectedAccount!.id),
      categoryId: Value(category?.id),
      currencyCode: Value(_selectedAccount!.currencyCode),
      reference: Value(_referenceController.text),
      contactId: Value(_selectedContact?.id),
      debtId: Value(_selectedDebt?.id),
      sourceDebtId: Value(_sourceDebt?.id),
      isRecurrenceEnabled: Value(_isRecurrenceEnabled),
      recurrenceType:
          Value(_isRecurrenceEnabled ? _recurrenceType.id : null),
      recurrenceInterval: Value(_recurrenceInterval),
      recurrenceEnds: Value(_isRecurrenceEnabled ? _recurrenceEnd.id : null),
      recurrenceEndDate:
          Value(_isRecurrenceEnabled && _recurrenceEnd == RecurrenceEnd.onDate
              ? _recurrenceEndDate
              : null),
      recurrenceTotalCount: Value(
          _isRecurrenceEnabled && _recurrenceEnd == RecurrenceEnd.afterCount
              ? _recurrenceTotalCount
              : null),
      date: Value(_date),
      exchangeRateAtCreation: Value(rateAtCreation),
      baseCurrencyAmount: Value(baseAmount),
      imagePath: Value(_imagePath),
      fxDelta: const Value(null),
    );
  }

  /// The debt plan for the current form state, delegated to
  /// [TransactionPlanner] so the schedule math stays unit-testable.
  Future<DebtPlan> _buildDebtPlan() {
    final ref = _referenceController.text.trim();
    final catName = category?.name.trim();
    final title =
        ref.isNotEmpty ? ref : (catName?.isNotEmpty == true ? catName! : context.l10n.txfDebt);
    return TransactionPlanner(context.read<FinanceRepository>()).buildDebtPlan(
      title: title,
      total: double.tryParse(_amount) ?? 0.0,
      installmentCount: _installmentCount,
      firstDueDate: _dueDate ?? DateTime.now(),
      frequency: _dueFrequency,
      direction:
          _transactionType == TransactionType.expense ? 'creditor' : 'debtor',
      currency: _selectedAccount!.currencyCode,
      contactId: _selectedContact?.id,
    );
  }

  /// Saves the transaction and, because debt mode is on, ensures ONE debt in
  /// the account currency with the full amount exists and its quota schedule
  /// (per-installment amount + due date) matches the form. For a fresh
  /// transaction the debt (and schedule) is created and linked; for an edited
  /// transaction that already sourced a debt, that debt and its schedule are
  /// re-synced with the edits. Views streaming the transaction table get the
  /// change through the database watchers.
  Future<void> _saveTransactionWithDebt() async {
    final repo = context.read<FinanceRepository>();
    final companion = await _buildTransactionCompanion();
    if (companion == null || _selectedAccount == null) return;

    final plan = await _buildDebtPlan();
    final existing = widget.existingTransaction;

    if (existing == null) {
      await repo.createTransactionWithDebt(
          companion, plan.debt, plan.installments);
    } else if (existing.sourceDebtId != null) {
      final source = _sourceDebt;
      if (source != null) {
        await repo.updateTransactionWithDebt(
          companion,
          existing.sourceDebtId!,
          source.copyWith(
            contactId: Value(plan.contactId),
            direction: plan.direction,
            description: Value(plan.title),
            amount: plan.amount,
            currencyCode: plan.currency,
            dueDate: Value(plan.firstDueDate),
            frequency: Value(_dueFrequency),
            updatedAt: DateTime.now(),
          ),
          plan.installments,
        );
      }
    }
    if (mounted) Navigator.pop(context);
  }

  /// Save an internal transfer/menudeo as two linked legs (source negative,
  /// destination positive) sharing one [transferGroupId]. The single rate
  /// field describes the rate-target currency; per-account rates keep both
  /// legs' base values consistent. FX delta is logged on the national-currency
  /// leg (expense-style sign), exactly like a plain VES transaction.
  Future<void> _saveTransfer() async {
    final repo = context.read<FinanceRepository>();
    final from = _selectedAccount;
    final to = _transferToAccount;
    if (from == null || to == null) {
      if (mounted) {
        showToast(context,
            message: context.l10n.txfSelectDestinationFirst,
            type: ToastType.error);
      }
      return;
    }
    if (from.id == to.id) {
      if (mounted) {
        showToast(context,
            message: context.l10n.txfSourceDestinationDifferent,
            type: ToastType.error);
      }
      return;
    }

    final amount = double.tryParse(_amount) ?? 0.0;
    final now = DateTime.now();

    // Source/destination rates, base values and FX delta are computed by the
    // planner so they stay consistent between the two legs.
    final legs = await TransactionPlanner(repo).buildTransferLegs(
      from: from,
      to: to,
      amount: amount,
      reference: _referenceController.text,
      date: now,
      manualRate:
          double.tryParse(_rateController.text.trim().replaceAll(',', '.')),
    );
    final fromCompanion = legs.fromLeg;
    final toCompanion = legs.toLeg;

    final existing = widget.existingTransaction;
    final groupId =
        existing?.transferGroupId ?? now.microsecondsSinceEpoch.toString();

    if (existing?.transferGroupId != null) {
      final isSourceLeg = existing!.amount < 0;
      final fromId = isSourceLeg ? existing.id : _transferPairId!;
      final toId = isSourceLeg ? _transferPairId! : existing.id;
      await repo.updateTransaction(fromCompanion.copyWith(
          id: Value(fromId), transferGroupId: Value(groupId)));
      await repo.updateTransaction(toCompanion.copyWith(
          id: Value(toId), transferGroupId: Value(groupId)));
    } else {
      await repo.createTransfer(
          groupId: groupId, fromLeg: fromCompanion, toLeg: toCompanion);
    }

    if (mounted) Navigator.pop(context);
  }

  Future<void> _pickTransactionImage() async {
    final path = await pickImageFromGallery(maxWidth: 512, maxHeight: 512);
    if (path == null || !mounted) return;
    setState(() => _imagePath = path);
  }

  Future<void> _deleteTransaction() async {
    final existing = widget.existingTransaction;
    if (existing == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.txfDeleteTransaction),
        content: Text(context.l10n.txfDeleteTransactionBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.txfCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.txfDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await context.read<FinanceRepository>().deleteTransaction(existing.id);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _showAccountPicker({
    db.Account? exclude,
    required Future<void> Function(db.Account) onPicked,
  }) async {
    final repo = context.read<FinanceRepository>();
    final accounts = (await repo.getAllAccounts())
        .where((a) => a.id != exclude?.id)
        .toList();

    if (accounts.isEmpty) {
      if (!mounted) return;
      showToast(
        context,
        message: exclude == null
            ? context.l10n.txfCreateAccountFirst
            : context.l10n.txfCreateSecondAccount,
        type: ToastType.error,
      );
      return;
    }

    if (!mounted) return;
    final selected = await showModalBottomSheet<db.Account>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.85,
        minChildSize: 0.4,
        expand: false,
        builder: (context, controller) => Container(
          decoration: BoxDecoration(
            color: context.colors.cardBackground,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  context.l10n.txfSelectAccount,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: controller,
                  itemCount: accounts.length,
                  itemBuilder: (context, index) {
                    final account = accounts[index];
                    return Material(
                      color: Colors.transparent,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Color(account.iconColor),
                          child: Icon(
                            accountIconFor(account.icon),
                            color: Colors.white,
                          ),
                        ),
                        title: Text(account.name),
                        subtitle: Text(account.currencyCode),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.pop(context, account),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (selected != null && mounted) await onPicked(selected);
  }

  Future<void> _pickAccountFromDatabase() {
    return _showAccountPicker(onPicked: (account) async {
      setState(() {
        if (_transactionType == TransactionType.transfer &&
            _transferToAccount?.id == account.id) {
          _transferToAccount = null;
        }
        _selectedAccount = account;
      });
      await _loadConversionPreview();
    });
  }

  Future<void> _pickToAccount() {
    return _showAccountPicker(
        exclude: _selectedAccount,
        onPicked: (account) async {
          setState(() => _transferToAccount = account);
          await _loadConversionPreview();
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back,
                            color: context.colors.primary),
                        onPressed: () {
                          Navigator.pop(context);
                        }, // No action
                      ),
                      const SizedBox(width: 15),
                      Text(
                        context.l10n.txfPayment,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: context.colors.primary,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      if (widget.existingTransaction != null)
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Color(0xFFEF5350)),
                          onPressed: _deleteTransaction,
                        ),
                      Container(
                        decoration: BoxDecoration(
                          color: context.colors.primaryLight
                              .withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: _imagePath != null
                            ? GestureDetector(
                                onTap: _pickTransactionImage,
                                child: Image.file(
                                  File(_imagePath!),
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : IconButton(
                                icon: Icon(Icons.image,
                                    color: context.colors.primary),
                                onPressed: _pickTransactionImage,
                              ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Client Section
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStepIndicator(),
                    const SizedBox(height: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        child: switch (_currentStep) {
                          0 => _buildAmountStep(),
                          1 => _buildDetailsStep(),
                          _ => _buildDebtPlanStep(),
                        },
                      ),
                    ),
                    _buildStepControls(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Step 0: pick the account and punch in the amount.
  Widget _buildAmountStep() {
    return SizedBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.txfAccount,
            style: TextStyle(
              fontSize: 16,
              color: context.colors.textLight,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          _buildAccountCard(),
          const SizedBox(height: 24),
          _buildAmountDisplay(),
          const SizedBox(height: 4),
          _buildConversionPreview(),
          const SizedBox(height: 4),
          Numpad(
            onNumberTap: _onNumberTap,
            onBackspaceTap: _onBackspaceTap,
          ),
        ],
      ),
    );
  }

  /// Step 1: type (income/expense/transfer) and all the optional details.
  Widget _buildDetailsStep() {
    final isTransfer = _transactionType == TransactionType.transfer;
    final isCrossCurrencyTransfer = isTransfer &&
        _selectedAccount != null &&
        _transferToAccount != null &&
        _selectedAccount!.currencyCode != _transferToAccount!.currencyCode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        _buildSummaryHeader(),
        const SizedBox(height: 18),
        _buildIncomeExpenseToggle(),
        if (isTransfer) ...[
          const SizedBox(height: 20),
          _fieldLabel(context.l10n.txfToAccount),
          const SizedBox(height: 8),
          _buildToAccountSelector(),
        ],
        // The rate field only matters for cross-currency transfers; plain
        // transactions apply the silently captured market rate instead.
        if (isCrossCurrencyTransfer) ...[
          const SizedBox(height: 20),
          _fieldLabel(context.l10n.txfExchangeRate),
          const SizedBox(height: 8),
          _buildRateField(),
        ],
        if (!isTransfer) ...[
          const SizedBox(height: 20),
          _fieldLabel(context.l10n.txfCategory),
          const SizedBox(height: 8),
          _buildCategorySelector(),
        ],
        const SizedBox(height: 20),
        _buildReferenceField(_referenceController),
        if (!isTransfer) ...[
          const SizedBox(height: 20),
          _fieldLabel(context.l10n.txfContact),
          const SizedBox(height: 8),
          _buildContactField(),
          const SizedBox(height: 12),
          _buildDebtField(),
          const SizedBox(height: 20),
          Text(
            context.l10n.txfRecurrence,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildRecurrenceCard(),
          // Debt/installments opt-in: unlocks step 3. Shown for a new
          // transaction and when editing one that already sourced a debt (so
          // its quota plan can be re-edited or dropped).
          if (widget.existingTransaction == null || _sourceDebt != null) ...[
            const SizedBox(height: 20),
            _buildDebtOptInCard(),
          ],
        ],
      ],
    );
  }

  /// Small section label used across the details step.
  Widget _fieldLabel(String text) => Text(
        text,
        style: TextStyle(color: context.colors.textLight, fontSize: 16),
      );

  /// The tappable account chip on the amount step. Shows the selected
  /// account's own icon/colour, falling back to an "add" affordance.
  Widget _buildAccountCard() {
    final account = _selectedAccount;
    return GestureDetector(
      onTap: _pickAccountFromDatabase,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: context.colors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: context.colors.cardBackground,
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: account == null
                    ? context.colors.primary
                    : Color(account.iconColor),
                shape: BoxShape.circle,
              ),
              child: Icon(
                account == null ? Icons.add : accountIconFor(account.icon),
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              account?.name ?? context.l10n.txfSelectAccount,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: context.colors.textDark,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: context.colors.primaryLight.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                account?.currencyCode ?? 'USD',
                style: TextStyle(
                  color: context.colors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The big editable amount on the amount step, with its currency suffix.
  Widget _buildAmountDisplay() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                _formatCurrency(_amount, symbol: ''),
                style: TextStyle(
                  fontSize: 50,
                  fontWeight: FontWeight.bold,
                  color: context.colors.textDark,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 12.0, left: 4.0),
            child: Text(
              _selectedAccount?.currencyCode ?? 'USD',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: context.colors.textLight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// The tappable amount + currency line at the top of the details step;
  /// tapping it hops back to the amount step.
  Widget _buildSummaryHeader() {
    return GestureDetector(
      onTap: () => setState(() => _currentStep -= 1),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: _formatCurrency(_amount, symbol: ''),
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: context.colors.textDark,
                ),
              ),
              TextSpan(
                text: ' ${_selectedAccount?.currencyCode ?? 'USD'}',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.normal,
                  color: context.colors.textLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.colors.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildStepSegment(context.l10n.txfAmount, 0),
          _buildStepSegment(context.l10n.txfDetails, 1),
          _buildStepSegment(context.l10n.txfDebt, 2, locked: !_debtEnabled),
        ],
      ),
    );
  }

  Widget _buildStepSegment(String label, int stepIndex, {bool locked = false}) {
    final isActive = _currentStep == stepIndex && !locked;
    final isDone = !locked && _currentStep > stepIndex;

    final Color bg = isActive
        ? context.colors.primary
        : isDone
            ? context.colors.primary.withValues(alpha: 0.12)
            : context.colors.fieldsBackground;
    final Color fg = isActive
        ? Colors.white
        : isDone
            ? context.colors.primary
            : context.colors.textLight;

    return Expanded(
      child: GestureDetector(
        onTap: locked ? null : () => setState(() => _currentStep = stepIndex),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isDone)
                const Icon(Icons.check, size: 14)
              else
                Icon(locked ? Icons.lock_outline : Icons.circle,
                    size: locked || isActive ? 12 : 10),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isActive || isDone
                        ? FontWeight.bold
                        : FontWeight.w600,
                    color: fg,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepControls() {
    final String primaryLabel;
    final VoidCallback onPrimary;

    switch (_currentStep) {
      case 0:
        primaryLabel = context.l10n.txfAddDetails;
        onPrimary = () => setState(() => _currentStep = 1);
        break;
      case 1:
        if (_debtEnabled) {
          primaryLabel = context.l10n.txfContinueToDebtPlan;
          onPrimary = () => setState(() => _currentStep = 2);
        } else {
          primaryLabel = context.l10n.txfSave;
          onPrimary = _saveTransaction;
        }
        break;
      default:
        primaryLabel = context.l10n.txfConfirmSaveWithDebt;
        onPrimary = _saveTransaction;
    }

    return Container(
      margin: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton(
            onPressed: onPrimary,
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colors.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              primaryLabel,
              style: const TextStyle(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (_currentStep > 0) ...[
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => setState(() => _currentStep -= 1),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.colors.cardBackground,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                context.l10n.txfReturn,
                style: TextStyle(
                  fontSize: 18,
                  color: context.colors.textDark,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRateField() {
    final accountCode = _selectedAccount?.currencyCode;
    final baseCode = _previewBaseCode;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: context.colors.fieldsBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.swap_horiz, color: context.colors.textLight),
          const SizedBox(width: 8),
          Text(
            context.l10n.txfRatePrefix(baseCode ?? ''),
            style: TextStyle(fontSize: 16, color: context.colors.textLight),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _rateController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: context.l10n.txfRateHint,
                border: InputBorder.none,
              ),
              style: TextStyle(fontSize: 16, color: context.colors.textDark),
            ),
          ),
          Text(
            accountCode ?? '',
            style: TextStyle(fontSize: 16, color: context.colors.textDark),
          ),
        ],
      ),
    );
  }

  Widget _buildToAccountSelector() {
    final to = _transferToAccount;
    return GestureDetector(
      onTap: _pickToAccount,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: context.colors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: context.colors.cardBackground,
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: context.colors.primaryLight.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.swap_horiz, color: context.colors.primary),
            ),
            const SizedBox(width: 12),
            Text(
              to?.name ?? context.l10n.txfSelectToAccount,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: context.colors.textDark,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: context.colors.primaryLight.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                to?.currencyCode ?? '...',
                style: TextStyle(
                  color: context.colors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    return GestureDetector(
        onTap: () async {
          final picked = await showModalBottomSheet<db.Category>(
              context: context,
              isDismissible: true,
              builder: (context) => const CategoryScreen());
          if (picked == null || !mounted) return;
          setState(() {
            category = SelectedCategory(
              id: picked.id,
              name: picked.name,
              icon: categoryIcons[picked.icon] ?? Icons.bookmark,
              color: Color(picked.color),
            );
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: context.colors.fieldsBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(category?.icon ?? Icons.bookmark),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  category?.name ?? context.l10n.txfSelectCategory,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
              Icon(Icons.arrow_forward_ios,
                  size: 16, color: context.colors.textLight),
            ],
          ),
        ));
  }

  Widget _buildIncomeExpenseToggle() {
    final options = [
      (TransactionType.income, context.l10n.txfIncome),
      (TransactionType.expense, context.l10n.txfExpense),
      (TransactionType.transfer, context.l10n.txfTransfer),
    ];
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: context.colors.fieldsBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.colors.cardBorder, width: 1),
      ),
      child: Row(
        children: [
          for (final (type, label) in options)
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _transactionType = type;
                    if (type == TransactionType.transfer && _debtEnabled) {
                      _debtEnabled = false;
                      if (_currentStep > 1) _currentStep = 1;
                    }
                  });
                  // Type decides transfer-vs-reference pricing, so the preview
                  // (and its rate field) must be rebuilt on every switch.
                  _loadConversionPreview();
                },
                child: Container(
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _transactionType == type
                        ? context.colors.primary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _transactionType == type
                          ? context.colors.fieldsBackground
                          : context.colors.textDark,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReferenceField(TextEditingController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: context.colors.fieldsBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.description_outlined, color: context.colors.textLight),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: context.l10n.txfEnterReference,
                border: InputBorder.none,
              ),
              style: TextStyle(fontSize: 16, color: context.colors.textDark),
            ),
          ),
        ],
      ),
    );
  }

Future<void> _openContactPicker() async {
    final picked = await Navigator.of(context).push<db.Contact>(
      MaterialPageRoute(builder: (_) => const ContactPickerScreen()),
    );
    if (picked != null && mounted) {
      setState(() => _selectedContact = picked);
    }
  }

  Widget _buildContactField() {
    final contact = _selectedContact;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: context.colors.fieldsBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: _openContactPicker,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              if (contact != null) ...[
                ContactAvatar(name: contact.name, size: 36),
                const SizedBox(width: 12),
              ] else ...[
                Icon(Icons.person_outline, color: context.colors.textLight),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: contact == null
                    ? Text(
                        context.l10n.txfSelectContactOptional,
                        style: TextStyle(color: context.colors.textLight),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            contact.name,
                            style: TextStyle(
                              fontSize: 16,
                              color: context.colors.textDark,
                            ),
                          ),
                          if (contact.phone?.trim().isNotEmpty == true)
                            Text(
                              contact.phone!,
                              style: TextStyle(
                                fontSize: 12,
                                color: context.colors.textLight,
                              ),
                            ),
                        ],
                      ),
              ),
              if (contact != null)
                IconButton(
                  tooltip: context.l10n.txfRemoveContact,
                  icon: Icon(Icons.close,
                      size: 18, color: context.colors.textLight),
                  onPressed: () => setState(() => _selectedContact = null),
                )
              else
                Icon(Icons.chevron_right, color: context.colors.textLight),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDebt() async {
    final picked = await showModalBottomSheet<db.Debt>(
      context: context,
      backgroundColor: context.colors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _DebtPickerSheet(repo: context.read<FinanceRepository>()),
    );
    if (picked == null || !mounted) return;
    final repo = context.read<FinanceRepository>();
    final remaining = await repo.getDebtRemaining(picked);
    final meta = await _debtMeta(picked);
    if (!mounted) return;
    setState(() {
      _selectedDebt = picked;
      _selectedDebtRemaining = remaining;
      _selectedDebtTitle = meta.title;
      _selectedDebtSymbol = meta.symbol;
    });
  }

  /// Contact name (or description) and currency symbol for a debt row.
  Future<({String title, String symbol})> _debtMeta(db.Debt debt) async {
    final repo = context.read<FinanceRepository>();
    final debtLabel = context.l10n.txfDebt;
    var title = debt.description;
    if (debt.contactId != null) {
      final contact = await repo.getContactById(debt.contactId!);
      if (contact != null) title = contact.name;
    }
    final currency = await repo.getCurrency(debt.currencyCode);
    return (
      title: title?.trim().isEmpty == false ? title!.trim() : debtLabel,
      symbol: currency?.symbol ?? r'$',
    );
  }

  Widget _buildDebtField() {
    final debt = _selectedDebt;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: context.colors.fieldsBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: _pickDebt,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Icon(debt == null
                  ? Icons.account_balance_wallet_outlined
                  : Icons.account_balance_wallet,
                  color: debt == null
                      ? context.colors.textLight
                      : context.colors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: debt == null
                    ? Text(
                        context.l10n.txfPayTowardDebtOptional,
                        style: TextStyle(color: context.colors.textLight),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedDebtTitle ?? context.l10n.txfDebt,
                            style: TextStyle(
                              fontSize: 16,
                              color: context.colors.textDark,
                            ),
                          ),
                          Text(
                            _debtSubtitle(debt),
                            style: TextStyle(
                              fontSize: 12,
                              color: context.colors.textLight,
                            ),
                          ),
                        ],
                      ),
              ),
              if (debt != null)
                IconButton(
                  tooltip: context.l10n.txfRemoveDebtLink,
                  icon: Icon(Icons.close,
                      size: 18, color: context.colors.textLight),
                  onPressed: () => setState(() {
                    _selectedDebt = null;
                    _selectedDebtRemaining = null;
                  }),
                )
              else
                Icon(Icons.chevron_right, color: context.colors.textLight),
            ],
          ),
        ),
      ),
    );
  }

  String _debtSubtitle(db.Debt debt) {
    final remaining = _selectedDebtRemaining;
    return remaining == null
        ? (debt.direction == 'creditor'
            ? context.l10n.txfIOwe
            : context.l10n.txfTheyOweMe)
        : context.l10n.txfDebtProgress(
            formatMoney(remaining, symbol: _selectedDebtSymbol),
            formatMoney(debt.amount, symbol: _selectedDebtSymbol),
          );
  }

  Widget _buildRecurrenceCard() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: context.colors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.colors.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    context.l10n.txfRecurring,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.autorenew,
                      size: 18, color: context.colors.textLight),
                ],
              ),
              Switch(
                value: _isRecurrenceEnabled,
                onChanged: (bool value) {
                  setState(() => _isRecurrenceEnabled = value);
                },
                activeThumbColor: context.colors.primary,
              ),
            ],
          ),

          // Off means off: no dead chips pretending to be settings.
          if (_isRecurrenceEnabled) ...[
            const SizedBox(height: 4),
            Text(
              context.l10n.txfRecurringDescription,
              style: TextStyle(color: context.colors.textLight, fontSize: 13),
            ),
            const SizedBox(height: 12),
            _RecurrenceRow(
              icon: Icons.event,
              label: context.l10n.txfFirstDue,
              value: DateFormat.yMMMd().format(_date),
              onTap: _pickFirstDue,
            ),
            _RecurrenceRow(
              icon: Icons.repeat,
              label: context.l10n.txfRepeats,
              value: _repeatsLabel,
              onTap: _pickRepeats,
            ),
            _RecurrenceRow(
              icon: Icons.event_busy,
              label: context.l10n.txfEnds,
              value: _endsLabel,
              onTap: _pickEnds,
            ),
            const SizedBox(height: 4),
            _NextDueHint(rule: _currentRule),
          ],
        ],
      ),
    );
  }

  /// The rule as currently configured. Anchored on [_date], the day this
  /// transaction is booked.
  Recurrence get _currentRule => Recurrence(
        type: _recurrenceType,
        anchor: DateTime(_date.year, _date.month, _date.day),
        interval: _recurrenceInterval,
        end: _recurrenceEnd,
        endDate: _recurrenceEndDate,
        totalCount: _recurrenceTotalCount,
      );

  String get _repeatsLabel => switch (_recurrenceType) {
        RecurrenceType.daily => _recurrenceInterval == 1
            ? context.l10n.txfEveryDay
            : context.l10n.txfEveryNDays(_recurrenceInterval),
        RecurrenceType.weekly => _recurrenceInterval == 1
            ? context.l10n.txfEveryWeek
            : context.l10n.txfEveryNWeeks(_recurrenceInterval),
        RecurrenceType.monthly => _recurrenceInterval == 1
            ? context.l10n.txfEveryMonth
            : context.l10n.txfEveryNMonths(_recurrenceInterval),
        RecurrenceType.yearly => _recurrenceInterval == 1
            ? context.l10n.txfEveryYear
            : context.l10n.txfEveryNYears(_recurrenceInterval),
      };

  String get _endsLabel => switch (_recurrenceEnd) {
        RecurrenceEnd.never =>
          _recurrenceEndLabel(context.l10n, RecurrenceEnd.never),
        RecurrenceEnd.onDate => _recurrenceEndDate == null
            ? context.l10n.txfPickADate
            : DateFormat.yMMMd().format(_recurrenceEndDate!),
        RecurrenceEnd.afterCount =>
          context.l10n.txfAfterNTimes(_recurrenceTotalCount),
      };

  Future<void> _pickFirstDue() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() => _date = picked);
  }

  Future<void> _pickRepeats() async {
    final result = await showModalBottomSheet<({RecurrenceType type, int interval})>(
      context: context,
      isDismissible: true,
      builder: (_) => _RepeatsSheet(
        type: _recurrenceType,
        interval: _recurrenceInterval,
      ),
    );
    if (result == null) return;
    setState(() {
      _recurrenceType = result.type;
      _recurrenceInterval = result.interval;
    });
  }

  Future<void> _pickEnds() async {
    final result = await showModalBottomSheet<_RecurrenceEndChoice>(
      context: context,
      isDismissible: true,
      builder: (_) => _EndsSheet(
        end: _recurrenceEnd,
        endDate: _recurrenceEndDate,
        totalCount: _recurrenceTotalCount,
      ),
    );
    if (result == null) return;
    setState(() {
      _recurrenceEnd = result.end;
      if (result.endDate != null) _recurrenceEndDate = result.endDate;
      if (result.totalCount != null) _recurrenceTotalCount = result.totalCount!;
    });
  }
  Widget _buildDebtOptInCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.colors.primaryLight.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _debtEnabled
              ? context.colors.primary
              : context.colors.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Checkbox(
            value: _debtEnabled,
            activeColor: context.colors.primary,
            onChanged: (value) => setState(() {
              _debtEnabled = value ?? false;
              if (!_debtEnabled) {
                // Dropping the plan while editing: the linked debt is cleared
                // here and deleted on save.
                _sourceDebt = null;
                if (_currentStep > 1) _currentStep = 1;
              }
            }),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.txfGenerateDebtInstallments,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: context.colors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  context.l10n.txfSplitPaymentInstallments,
                  style: TextStyle(
                      fontSize: 12, color: context.colors.textLight),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDebtPlanStep() {
    final total = double.tryParse(_amount) ?? 0.0;
    final per = total / _installmentCount;
    final code = _selectedAccount?.currencyCode ?? 'USD';
    final cat = category?.name;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.colors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: context.colors.cardBorder.withValues(alpha: 0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_transactionType == TransactionType.expense ? context.l10n.txfExpense : context.l10n.txfIncome}'
                ' · ${_selectedAccount?.name ?? context.l10n.txfAccount}'
                '${cat != null ? ' · $cat' : ''}',
                style:
                    TextStyle(fontSize: 12, color: context.colors.textLight),
              ),
              const SizedBox(height: 4),
              Text(
                '${formatMoney(total)} $code',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: context.colors.textDark,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(context.l10n.txfFrequency,
            style: TextStyle(
                color: context.colors.textLight, fontSize: 16)),
        const SizedBox(height: 8),
        _buildFrequencySelector(),
        const SizedBox(height: 20),
        Text(context.l10n.txfInstallments,
            style: TextStyle(
                color: context.colors.textLight, fontSize: 16)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: context.colors.cardBackground,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: context.colors.cardBorder.withValues(alpha: 0.5)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildInstallmentButton(Icons.remove, () {
                    if (_installmentCount > 1) {
                      setState(() => _installmentCount--);
                    }
                  }),
                  Column(
                    children: [
                      Text(
                        '$_installmentCount',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: context.colors.textDark,
                        ),
                      ),
                      Text(_periodLabel,
                          style: TextStyle(
                              fontSize: 12,
                              color: context.colors.textLight)),
                    ],
                  ),
                  _buildInstallmentButton(Icons.add, () {
                    if (_installmentCount < 36) {
                      setState(() => _installmentCount++);
                    }
                  }),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  for (final n in const [1, 3, 6, 12, 24])
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: _buildInstallmentChip(n),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.colors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: context.colors.cardBorder.withValues(alpha: 0.5)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(context.l10n.txfPerPeriod(_periodLabel),
                          style: TextStyle(
                              fontSize: 12,
                              color: context.colors.textLight)),
                      const SizedBox(height: 2),
                      Text(
                        '${formatMoney(per)} $code',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: context.colors.textDark,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: context.colors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      context.l10n.txfZeroInterest,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: context.colors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(height: 1),
              ),
              GestureDetector(
                onTap: _pickDueDate,
                child: Row(
                  children: [
                    Icon(Icons.event, size: 18,
                        color: context.colors.primary),
                    const SizedBox(width: 8),
                    Text(
                      context.l10n.txfFirstDueDate,
                      style: TextStyle(
                        fontSize: 13,
                        color: context.colors.textLight,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      DateFormat('MMM dd, yyyy')
                          .format(_dueDate ?? DateTime.now()),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: context.colors.textDark,
                      ),
                    ),
                    Icon(Icons.chevron_right, size: 18,
                        color: context.colors.textLight),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          _installmentCount == 1
              ? context.l10n.txfSavingCreatesOneDebt
              : context.l10n.txfSavingCreatesInstallments(
                  formatMoney(total),
                  code,
                  _installmentCount,
                  formatMoney(per),
                  _periodLabel,
                  DateFormat('MMM dd, yyyy').format(
                    TransactionPlanner.intervalDate(
                        _dueDate, _dueFrequency, _installmentCount - 1),
                  ),
                ),
          style: TextStyle(fontSize: 12, color: context.colors.textLight),
        ),
      ],
    );
  }

  Widget _buildFrequencySelector() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: context.colors.fieldsBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colors.cardBorder, width: 1),
      ),
      child: Row(
        children: [
          for (final id in _frequencies)
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _dueFrequency = id),
                child: Container(
                  alignment: Alignment.center,
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: _dueFrequency == id
                        ? context.colors.primary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _frequencyLabel(context.l10n, id),
                    style: TextStyle(
                      color: _dueFrequency == id
                          ? context.colors.fieldsBackground
                          : context.colors.textDark,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInstallmentButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: context.colors.fieldsBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.colors.cardBorder, width: 1),
        ),
        child: Icon(icon, size: 20, color: context.colors.textDark),
      ),
    );
  }

  Widget _buildInstallmentChip(int n) {
    final selected = _installmentCount == n;
    return GestureDetector(
      onTap: () => setState(() => _installmentCount = n),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? context.colors.primary
              : context.colors.fieldsBackground,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? context.colors.primary
                : context.colors.cardBorder.withValues(alpha: 0.6),
          ),
        ),
        child: Text(
          '${n}x',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color:
                selected ? context.colors.fieldsBackground : context.colors.textDark,
          ),
        ),
      ),
    );
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

  String get _periodLabel => switch (_dueFrequency) {
        'weekly' => context.l10n.txfPeriodWeek,
        'biweekly' => context.l10n.txfPeriodBiweek,
        _ => context.l10n.txfPeriodMonth,
      };
}
