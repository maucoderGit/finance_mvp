import 'package:drift/drift.dart' as drift;
import 'package:finance_mvp/constants/account_icons.dart';
import 'package:finance_mvp/constants/app_colors.dart';
import 'package:finance_mvp/database/app_database.dart';
import 'package:finance_mvp/repositories/finance_repository.dart';
import 'package:finance_mvp/widgets/account_icon_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AddAccountSheet extends StatefulWidget {
  final Account? existing;

  const AddAccountSheet({super.key, this.existing});

  bool get isEdit => existing != null;

  @override
  State<AddAccountSheet> createState() => _AddAccountSheetState();
}

class _AddAccountSheetState extends State<AddAccountSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _initialBalanceController = TextEditingController();

  String _selectedType = 'Bank';
  int _selectedColor = accountTypeColors['bank']!;
  String? _selectedCurrencyCode;
  bool _includeInTotal = true;

  @override
  void initState() {
    super.initState();
    final account = widget.existing;
    if (account != null) {
      _nameController.text = account.name;
      _selectedType =
          (account.subtitle?.isNotEmpty ?? false) ? account.subtitle! : 'Cash';
      _selectedColor = account.iconColor;
      _selectedCurrencyCode = account.currencyCode;
      _includeInTotal = account.includeInRevaluation;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _initialBalanceController.dispose();
    super.dispose();
  }

  Future<void> _saveAccount() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final repository = context.read<FinanceRepository>();
    final name = _nameController.text.trim();
    final initialBalance =
        double.tryParse(_initialBalanceController.text) ?? 0.0;

    if (_selectedCurrencyCode == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a currency.')),
      );
      return;
    }

    final accountData = AccountsCompanion(
      name: drift.Value(name),
      subtitle: drift.Value(_selectedType),
      currencyCode: drift.Value(_selectedCurrencyCode!),
      icon: drift.Value(accountIconSlug(_selectedType)),
      iconColor: drift.Value(_selectedColor),
      includeInRevaluation: drift.Value(_includeInTotal),
    );

    if (widget.isEdit) {
      await repository.updateAccount(accountData.copyWith(
        id: drift.Value(widget.existing!.id),
      ));
    } else {
      await repository.createAccountWithInitialTransaction(
          accountData, initialBalance);
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final repository = context.read<FinanceRepository>();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.isEdit ? 'Edit Account' : 'Create Account',
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close,
                        color: context.colors.textLight, size: 24),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Close',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                widget.isEdit
                    ? 'Update the details of this account.'
                    : 'Organize your assets with precision.',
                style: TextStyle(color: context.colors.textLight, fontSize: 14),
              ),
              const SizedBox(height: 20),

              // ── Live preview card ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.colors.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: context.colors.cardBorder.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Color(_selectedColor).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                          accountIconFor(accountIconSlug(_selectedType)),
                          color: Color(_selectedColor),
                          size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _nameController.text.trim().isEmpty
                                ? 'Account name'
                                : _nameController.text.trim(),
                            style: TextStyle(
                              color: context.colors.textDark,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _selectedType,
                            style: TextStyle(
                                color: context.colors.textLight, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Icon + color picker ──
              AccountIconPicker(
                selectedType: accountIconSlug(_selectedType),
                selectedColor: _selectedColor,
                onTypeChanged: (slug) => setState(() {
                  _selectedType = _labelForSlug(slug);
                  _selectedColor = accountTypeColors[slug] ?? _selectedColor;
                }),
                onColorChanged: (color) =>
                    setState(() => _selectedColor = color),
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Account Name'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter an account name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              FutureBuilder<List<Currency>>(
                future: repository.db.select(repository.db.currencies).get(),
                builder: (context, snapshot) {
                  final currencies = snapshot.data ?? const <Currency>[];
                  if (_selectedCurrencyCode == null && currencies.isNotEmpty) {
                    _selectedCurrencyCode = currencies.first.code;
                  }
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final symbol = currencies
                      .firstWhere(
                        (c) => c.code == _selectedCurrencyCode,
                        orElse: () => currencies.first,
                      )
                      .symbol;
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedCurrencyCode,
                          decoration:
                              const InputDecoration(labelText: 'Currency'),
                          items: currencies.map((currency) {
                            return DropdownMenuItem<String>(
                              value: currency.code,
                              child:
                                  Text('${currency.code} — ${currency.name}'),
                            );
                          }).toList(),
                          onChanged: (newValue) {
                            setState(() {
                              _selectedCurrencyCode = newValue;
                            });
                          },
                          validator: (value) =>
                              value == null ? 'Select currency' : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      if (!widget.isEdit)
                        Expanded(
                          child: TextFormField(
                            controller: _initialBalanceController,
                            decoration: InputDecoration(
                              labelText: 'Initial Balance',
                              prefixText: '$symbol ',
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            validator: (value) {
                              if (value != null &&
                                  value.isNotEmpty &&
                                  double.tryParse(value) == null) {
                                return 'Enter a valid number';
                              }
                              return null;
                            },
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('Include in net worth'),
                subtitle: const Text('Contribute to revaluation totals'),
                value: _includeInTotal,
                contentPadding: EdgeInsets.zero,
                onChanged: (value) {
                  setState(() {
                    _includeInTotal = value;
                  });
                },
                secondary: const Icon(Icons.analytics),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('Save Account'),
                  onPressed: _saveAccount,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.colors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9999),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  String _labelForSlug(String slug) => accountTypeLabels.firstWhere(
        (label) => accountIconSlug(label) == slug,
        orElse: () => _selectedType,
      );
}
