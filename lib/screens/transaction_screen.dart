import 'dart:io';

import 'package:drift/drift.dart' hide Column;
import 'package:finance_mvp/constants/account_icons.dart';
import 'package:finance_mvp/constants/app_colors.dart';
import 'package:finance_mvp/database/app_database.dart' as db;
import 'package:finance_mvp/repositories/finance_repository.dart';
import 'package:finance_mvp/screens/category_screen.dart';
import 'package:finance_mvp/services/profile_picture_service.dart';
import 'package:finance_mvp/widget/numpad.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

enum TransactionType {
  income,
  expense,
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
  
  bool _isRecurrenceEnabled = true;
  final TextEditingController _referenceController = TextEditingController();
  final TextEditingController _rateController = TextEditingController();
  db.Account? _selectedAccount;
  Map? category;
  String? _imagePath;

  /// Live conversion preview: rate of "1 base = X account currency" and the
  /// base currency the amount is converted into.
  double? _previewRate;
  String? _previewBaseCode;

  /// When the account is in the base currency, the preview converts into the
  /// national (local) currency instead.
  String? _previewNationalCode;
  double? _previewNationalRate;

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

  String _formatCurrency(String amountStr) {
    final number = double.tryParse(amountStr) ?? 0.0;
    final formatter = NumberFormat.currency(
      locale: 'en_US',
      symbol: '\$',
      decimalDigits: 2,
    );
    return formatter.format(number).replaceAll('.', ',');
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
      _transactionType =
          existing.amount >= 0 ? TransactionType.income : TransactionType.expense;
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

    double? nationalRate;
    if (nationalCode != baseCode) {
      nationalRate = await repo.getRateWithFallback(nationalCode, DateTime.now());
    }

    double? rate;
    if (account.currencyCode != baseCode) {
      rate = await repo.getRateWithFallback(account.currencyCode, DateTime.now());
    }

    // Prefill the manual rate override (account currency vs base) so the user
    // sees what will be applied, unless they already typed one.
    if (rate != null && rate > 0 && _rateController.text.trim().isEmpty) {
      _rateController.text = rate.toStringAsFixed(2);
    }

    if (!mounted) return;
    setState(() {
      _previewRate = rate;
      _previewBaseCode = baseCode;
      _previewNationalCode = nationalCode;
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

    var categories = <db.Category>[];
    try {
      categories = await repo.getAllCategories();
    } catch (_) {}
    final categoryId = existing.categoryId;
    for (final candidate in categories) {
      if (candidate.id == categoryId) {
        setState(() {
          category = {
            'id': candidate.id,
            'name': candidate.name,
            'icon': categoryIcons[candidate.icon] ?? Icons.bookmark,
            'color': Color(candidate.color),
          };
        });
        break;
      }
    }

    if (!mounted) return;
    setState(() {
      _selectedAccount = account;
    });
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
          'No exchange rate available for $nationalCode yet',
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        );
        rateLine = null;
      } else {
        final localAmount = amount * nationalRate;
        amountLine = Text(
          '≈ ${_formatCurrency(localAmount.toString())} $nationalCode',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black54,
          ),
        );
        rateLine = Text(
          '1 $baseCode = ${nationalRate.toStringAsFixed(2)} $nationalCode',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        );
      }
    } else if (rate != null) {
      final baseAmount = rate != 0 ? amount / rate : 0.0;
      amountLine = Text(
        '≈ ${_formatCurrency(baseAmount.toString())} $baseCode',
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.black54,
        ),
      );
      rateLine = Text(
        '1 $baseCode = ${rate.toStringAsFixed(2)} $accountCode',
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      );
    } else {
      amountLine = Text(
        'No exchange rate available for $accountCode yet',
        style: const TextStyle(fontSize: 14, color: Colors.grey),
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
    final repo = context.read<FinanceRepository>();

    // If no account selected, pick the first one for the MVP flow
    if (_selectedAccount == null) {
      final accounts = await repo.db.select(repo.db.accounts).get();
      if (accounts.isNotEmpty) _selectedAccount = accounts.first;
    }

    if (_selectedAccount == null) return;

    var amountValue = double.tryParse(_amount) ?? 0.0;
    if (_transactionType == TransactionType.expense) {
      amountValue = -amountValue;
    }

    // Auto-capture the exchange rate ("1 base = X account currency") at the
    // transaction date: the closest stored rate, falling back to the latest.
    double? rateAtCreation;
    final baseCode = await repo.getBaseCurrencyCode();
    if (_selectedAccount!.currencyCode != baseCode) {
      rateAtCreation = await repo.getRateWithFallback(
          _selectedAccount!.currencyCode, DateTime.now());
    }

    // Manual rate override from the Details step. The field is prefilled with
    // the captured rate by _loadConversionPreview, so an empty field just
    // keeps rateAtCreation unless the user typed something.
    final customRate =
        double.tryParse(_rateController.text.trim().replaceAll(',', '.'));
    if (customRate != null && customRate > 0) {
      rateAtCreation = customRate;
    }

    // Compute the transaction value in the base currency at creation time.
    double? baseAmount;
    if (rateAtCreation != null && rateAtCreation != 0) {
      baseAmount = amountValue / rateAtCreation;
    } else if (_selectedAccount!.currencyCode == baseCode) {
      baseAmount = amountValue;
    }

    final existing = widget.existingTransaction;
    final companion = db.TransactionsCompanion(
      id: existing != null ? Value(existing.id) : const Value.absent(),
      amount: Value(amountValue),
      accountId: Value(_selectedAccount!.id),
      categoryId: Value(category?['id']),
      currencyCode: Value(_selectedAccount!.currencyCode),
      reference: Value(_referenceController.text),
      isRecurrenceEnabled: Value(_isRecurrenceEnabled),
      date: Value(DateTime.now()),
      exchangeRateAtCreation: Value(rateAtCreation),
      baseCurrencyAmount: Value(baseAmount),
      imagePath: Value(_imagePath),
    );

    if (existing != null) {
      await repo.updateTransaction(companion);
    } else {
      await repo.createTransaction(companion);
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
        title: const Text('Delete transaction'),
        content: const Text('This will remove the payment permanently.'),
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

    await context.read<FinanceRepository>().deleteTransaction(existing.id);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _pickAccountFromDatabase() async {
    final repo = context.read<FinanceRepository>();
    final accounts = await repo.watchAccounts().first;

    if (accounts.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Create an account first in "Register Accounts".')),
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
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Select Account',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: controller,
                  itemCount: accounts.length,
                  itemBuilder: (context, index) {
                    final account = accounts[index];
                    return ListTile(
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
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (selected != null && mounted) {
      setState(() => _selectedAccount = selected);
      await _loadConversionPreview();
    }
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
                        icon: const Icon(Icons.arrow_back, color: Color(0xFF1A3A1B)),
                        onPressed: () {
                          Navigator.pop(context);
                        }, // No action
                      ),
                      const SizedBox(width: 15),
                      const Text(
                        'Payment',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A3A1B),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      if (widget.existingTransaction != null)
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Color(0xFFB71C1C)),
                          onPressed: _deleteTransaction,
                        ),
                      Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFFD3E6D3),
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
                                icon: const Icon(Icons.image,
                                    color: Color(0xFF1A3A1B)),
                                onPressed: _pickTransactionImage,
                              ),
                      ),
                      // const SizedBox(width: 10),
                      // Container(
                      //   decoration: const BoxDecoration(
                      //     color: Color(0xFF1A3A1B),
                      //     shape: BoxShape.circle,
                      //   ),
                      //   child: const IconButton(
                      //     icon: Icon(Icons.search, color: Colors.white),
                      //     onPressed: null, // No action
                      //   ),
                      // ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Client Section
              Expanded(
                child: Stepper(
                  type: StepperType.horizontal,
                  elevation: 0,
                  onStepTapped: (value) => setState(() {
                    _currentStep = value;
                  }),
                  currentStep: _currentStep,
                  onStepContinue: () {
                    setState(() {
                      if (_currentStep < 1) {
                        _currentStep += 1;
                      } else {
                        _saveTransaction();
                      }
                    });
                  },
                  onStepCancel: _currentStep > 0 ? () {
                    setState(() {
                      if (_currentStep > 0) {
                        _currentStep -= 1;
                      } else {
                        // First step, do something
                      }
                    });
                  } : null,
                  controlsBuilder: (BuildContext context, ControlsDetails controls) {
                    return Container(
                      margin: const EdgeInsets.only(top: 50),
                      child: Row(
                        children: [
                          Expanded(child: ElevatedButton(onPressed: controls.onStepContinue,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1A3A1B),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              _currentStep < 1 ? 'Add details' : "Save",
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )),
                          Visibility(
                            visible: _currentStep > 0,
                            child: const SizedBox(width: 10),
                          ),
                          Visibility(
                            visible: _currentStep > 0,
                            child: Expanded(child: ElevatedButton(
                              onPressed: controls.onStepCancel,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[100]!,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Return',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            )))
                        ],
                      ),
                    );
                  },
                  steps: [
                    Step(
                      title: const Text('Amount'),
                      content: SizedBox(
                        child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Account',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 10),
                          GestureDetector(
                            onTap: () {
                              _pickAccountFromDatabase();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey[100]!,
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
                                    decoration: const BoxDecoration(
                                      color: Colors.black,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Center(
                                      child: Text(
                                        'OKX',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    _selectedAccount?.name ?? 'Select Account',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const Spacer(),
Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE8F5E9),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          _selectedAccount?.currencyCode ?? 'USD',
                                          style: const TextStyle(
                                            color: Color(0xFF4CAF50),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _formatCurrency(_amount),
                                  style: const TextStyle(
                                    fontSize: 50,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 12.0, left: 4.0),
                                  child: Text(
                                    _selectedAccount?.currencyCode ?? 'USD',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildConversionPreview(),
                          const SizedBox(height: 10),
                          Numpad(
                            onNumberTap: _onNumberTap,
                            onBackspaceTap: _onBackspaceTap,
                          ),
                          // SizedBox(height: MediaQuery.of(context).size.height * 0.1,),
                        ],
                      )),
                      isActive: _currentStep >= 0,
                      state: _currentStep >= 0 ? StepState.complete : StepState.disabled,
                    ),
                    Step(
                      title: const Text('Details'),
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () => setState(() {
                              _currentStep -= 1;
                            }),
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: _formatCurrency(_amount),
                                    style: const TextStyle(
                                      fontSize: 48,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  TextSpan(
                                    text: ' ${_selectedAccount?.currencyCode ?? 'USD'}',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.normal,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          ),
                          
                          const SizedBox(height: 18),

                          // Exchange rate (only when the account currency
                          // differs from the base currency)
                          if (_selectedAccount != null &&
                              _previewBaseCode != null &&
                              _selectedAccount!.currencyCode != _previewBaseCode) ...[
                            const Text(
                              'Exchange rate',
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            _buildRateField(),
                            const SizedBox(height: 20),
                          ],

                          // Category
                          const Text('Category', style: TextStyle(color: Colors.grey, fontSize: 16)),
                          const SizedBox(height: 8),
                          _buildCategorySelector(),

                          const SizedBox(height: 20),

                          // Income/Expense Toggle
                          _buildIncomeExpenseToggle(),

                          const SizedBox(height: 16),

                          // Add Reference Field
                          _buildReferenceField(_referenceController),

                          const SizedBox(height: 20),
                          
                          // Contact Field
                          const Text('Contact', style: TextStyle(color: Colors.grey, fontSize: 16)),
                          const SizedBox(height: 8),
                          _buildContactField(),

                          const SizedBox(height: 20),

                          // Recurrence Section
                          const Text(
                            'Recurrance',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildRecurrenceCard(),
                          
                          // Spacer to push everything above the button to the top
                          // const SizedBox(height: 30),
                        ],
                      ),
                      // isActive: _currentStep >= 1,
                      state: _currentStep >= 1 ? StepState.complete : StepState.indexed,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRateField() {
    final accountCode = _selectedAccount?.currencyCode;
    final baseCode = _previewBaseCode;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.fieldsBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.swap_horiz, color: Colors.black54),
          const SizedBox(width: 8),
          Text(
            '1 $baseCode =',
            style: const TextStyle(fontSize: 16, color: Colors.black54),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _rateController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                hintText: 'Rate',
                border: InputBorder.none,
              ),
              style: const TextStyle(fontSize: 16, color: Colors.black),
            ),
          ),
          Text(
            accountCode ?? '',
            style: const TextStyle(fontSize: 16, color: Colors.black),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySelector() {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(context: context, isDismissible: true, builder: (context) => const CategoryScreen()).then((value) {
          if (value == null) return;

          setState(() {
            category = value;
          });
        });
      },
      child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.fieldsBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(category?["icon"] ?? Icons.bookmark), // Dark green icon
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              category?["name"] ?? "Select category",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        ],
      ),
    ));
  }

  Widget _buildIncomeExpenseToggle() {
    BoxDecoration selectedDecoration = BoxDecoration(
      color: const Color(0xFF33583A), // Selected (Income) dark green
      borderRadius: BorderRadius.circular(8),
    );
    
    TextStyle selectedTextStyle = const TextStyle(color: AppColors.fieldsBackground, fontWeight: FontWeight.bold, fontSize: 16);
    TextStyle enabledTextStyle = const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16);

    return Container(
      height: 55,
      decoration: BoxDecoration(
        color: AppColors.fieldsBackground, // Light grey background
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
      ),
      child: Builder(
        builder: (context) {
          return Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _transactionType = TransactionType.income;
                    });
                  },
                  child: Container(
                    decoration: _transactionType == TransactionType.income ? selectedDecoration : BoxDecoration(
                      color: AppColors.fieldsBackground, // Selected (Income) dark green
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Income',
                      style: _transactionType == TransactionType.income ? selectedTextStyle : enabledTextStyle,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _transactionType = TransactionType.expense;
                    });
                  },
                  child: Container(
                    alignment: Alignment.center,
                    decoration: _transactionType == TransactionType.expense ? selectedDecoration : BoxDecoration(
                      color: AppColors.fieldsBackground, // Selected (Income) dark green
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Expense',
                      style: _transactionType == TransactionType.expense ? selectedTextStyle : enabledTextStyle,
                    ),
                  ),
                ),
              ),
            ],
          );
        }
      ),
    );
  }


  Widget _buildReferenceField(TextEditingController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.fieldsBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.description_outlined, color: Colors.black54),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Enter reference',
                border: InputBorder.none,
              ),
              style: const TextStyle(fontSize: 16, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.fieldsBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          Icon(Icons.person_outline, color: Colors.black54),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Add contact (optional)',
              style: TextStyle(fontSize: 18, color: Colors.black54),
            ),
          ),
          Icon(Icons.add_circle_outline, color: Colors.black54),
        ],
      ),
    );
  }

  Widget _buildRecurrenceCard() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9), // Very light background for the card
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Enable Recurrence Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Text(
                    'Enable Recurrence',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.calendar_today, size: 18, color: Colors.black54),
                ],
              ),
              Switch(
                value: _isRecurrenceEnabled,
                onChanged: (bool value) {
                  setState(() {
                    _isRecurrenceEnabled = value;
                  });
                },
                activeThumbColor: const Color(0xFF33583A), // Dark green switch color
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Repeat/Ends Row
          Wrap( // Changed Row to Wrap
            spacing: 12.0, // Horizontal space between chips
            runSpacing: 12.0, // Vertical space between lines of chips
            children: [
              // Repeat Chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _isRecurrenceEnabled ? const Color(0xFFE0E0E0) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min, // Use min to wrap content
                  children: [
                    Text(
                      'Repeat: Monthly',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _isRecurrenceEnabled ? Colors.black : Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.grid_view,
                      size: 16,
                      color: _isRecurrenceEnabled ? Colors.black : Colors.grey,
                    ),
                  ],
                ),
              ),

              // Ends Chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _isRecurrenceEnabled ? const Color(0xFFE0E0E0) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min, // Use min to wrap content
                  children: [
                    Text(
                      'Ends: Until I cancel',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _isRecurrenceEnabled ? Colors.black : Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.close,
                      size: 16,
                      color: _isRecurrenceEnabled ? Colors.black : Colors.grey,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Description Text
          const Text(
            'Applies to subscriptions, budgets, or saving goals',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ],
      ),
    );
  }
}