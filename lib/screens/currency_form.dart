import 'package:drift/drift.dart' as drift;
import 'package:finance_mvp/screens/database.dart';
import 'package:finance_mvp/screens/finance_repository.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CurrencyForm extends StatefulWidget {
  const CurrencyForm({super.key});

  @override
  State<CurrencyForm> createState() => _CurrencyFormState();
}

class _CurrencyFormState extends State<CurrencyForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _symbolController = TextEditingController();
  final _separatorController = TextEditingController();
  final _decimalDigitsController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _symbolController.dispose();
    _separatorController.dispose();
    _decimalDigitsController.dispose();
    super.dispose();
  }

  Future<void> _saveForm() async {
    if (_formKey.currentState!.validate()) {
      final repo = context.read<FinanceRepository>();
      final newCurrencyCompanion = CurrenciesCompanion(
        name: drift.Value(_nameController.text),
        code: drift.Value(_codeController.text.toUpperCase()),
        symbol: drift.Value(_symbolController.text),
        separator: drift.Value(_separatorController.text),
        decimalDigits: drift.Value(int.parse(_decimalDigitsController.text)),
      );

      // Insert and get the created object
      await repo.db.into(repo.db.currencies).insert(newCurrencyCompanion);
      final newCurrency = await (repo.db.select(repo.db.currencies)
            ..where((tbl) => tbl.code.equals(_codeController.text.toUpperCase())))
          .getSingle();

      if (mounted) Navigator.of(context).pop(newCurrency);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final labelStyle = textTheme.labelMedium?.copyWith(
      fontWeight: FontWeight.w500,
      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
    );

    final inputDecoration = InputDecoration(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Theme.of(context).primaryColor),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Add New Currency',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Name', style: labelStyle),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _nameController,
                          decoration: inputDecoration.copyWith(hintText: 'e.g. Euro'),
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Please enter a name';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Code', style: labelStyle),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _codeController,
                          decoration: inputDecoration.copyWith(hintText: 'e.g. EUR'),
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Please enter a code';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Symbol', style: labelStyle),
              const SizedBox(height: 8),
              TextFormField(
                controller: _symbolController,
                decoration: inputDecoration.copyWith(hintText: 'e.g. €'),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter a symbol';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Separator', style: labelStyle),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _separatorController,
                          decoration: inputDecoration.copyWith(hintText: 'e.g. ,'),
                           validator: (value) {
                            if (value == null || value.isEmpty) return 'Please enter a separator';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Decimal Digits', style: labelStyle),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _decimalDigitsController,
                          decoration: inputDecoration.copyWith(hintText: 'e.g. 2'),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Enter number of digits';
                            if (int.tryParse(value) == null) return 'Enter a valid number';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _saveForm,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          backgroundColor: Theme.of(context).primaryColor,
                        ),
                        child: const Text('Save Currency', style: TextStyle(color: Colors.white),),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}