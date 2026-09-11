import 'package:drift/drift.dart' as drift;
import 'package:finance_mvp/constants/account_icons.dart';
import 'package:finance_mvp/constants/app_colors.dart';
import 'package:finance_mvp/database/app_database.dart';
import 'package:finance_mvp/repositories/finance_repository.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AddAccountSheet extends StatefulWidget {
  const AddAccountSheet({super.key});

  @override
  State<AddAccountSheet> createState() => _AddAccountSheetState();
}

class _AddAccountSheetState extends State<AddAccountSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _initialBalanceController = TextEditingController();

  String _selectedAccountType = 'Bank';
  String? _selectedCurrencyCode;
  bool _includeInTotal = true;

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
    final name = _nameController.text;
    final initialBalance = double.tryParse(_initialBalanceController.text) ?? 0.0;

    if (_selectedCurrencyCode == null) {
      // Show an error or handle case where no currency is selected
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a currency.')),
      );
      return;
    }

    final accountData = AccountsCompanion(
      name: drift.Value(name),
      subtitle: drift.Value(_selectedAccountType),
      currencyCode: drift.Value(_selectedCurrencyCode!),
      icon: drift.Value(accountIconSlug(_selectedAccountType)),
      iconColor: drift.Value(AppColors.primary.value), // Example color
    );

    await repository.createAccountWithInitialTransaction(accountData, initialBalance);

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
              const Text(
                'Create Account',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Organize your assets with precision.',
                style: TextStyle(color: AppColors.textLight, fontSize: 14),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Account Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an account name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedAccountType,
                      decoration: const InputDecoration(labelText: 'Type'),
                      items: accountTypeLabels.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          _selectedAccountType = newValue!;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FutureBuilder<List<Currency>>(
                      future: repository.db.select(repository.db.currencies).get(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        final currencies = snapshot.data!;
                        if (_selectedCurrencyCode == null && currencies.isNotEmpty) {
                          _selectedCurrencyCode = currencies.first.code;
                        }
                        return DropdownButtonFormField<String>(
                          value: _selectedCurrencyCode,
                          decoration: const InputDecoration(labelText: 'Currency'),
                          items: currencies.map((currency) {
                            return DropdownMenuItem<String>(
                              value: currency.code,
                              child: Text(currency.code),
                            );
                          }).toList(),
                          onChanged: (newValue) {
                            setState(() {
                              _selectedCurrencyCode = newValue;
                            });
                          },
                          validator: (value) => value == null ? 'Select currency' : null,
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _initialBalanceController,
                decoration: const InputDecoration(
                  labelText: 'Initial Balance',
                  prefixText: '\$ ',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value != null && value.isNotEmpty && double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SwitchListTile(
                title: const Text('Include in total balance'),
                subtitle: const Text('Contribute to net worth'),
                value: _includeInTotal,
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
                    backgroundColor: AppColors.primary,
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
}