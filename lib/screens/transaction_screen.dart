import 'package:drift/drift.dart' hide Column;
import 'package:finance_mvp/constants/app_colors.dart';
import 'package:finance_mvp/database/app_database.dart' as db;
import 'package:finance_mvp/repositories/finance_repository.dart';
import 'package:finance_mvp/screens/currency_screen.dart';
import 'package:finance_mvp/screens/category_screen.dart';
import 'package:finance_mvp/widget/numpad.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

enum TransactionType {
  income,
  expense,
}



class TransactionScreen extends StatefulWidget {
  const TransactionScreen({super.key});

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {

  String _amount = '0.00';
  int _currentStep = 0;
  TransactionType _transactionType = TransactionType.income;
  
  bool _isRecurrenceEnabled = true;
  final TextEditingController _referenceController = TextEditingController();
  db.Account? _selectedAccount;
  Map? category;

  void _onNumberTap(String number) {
    setState(() {
      if (_amount == '0.00' && number != '.') {
        _amount = number == '0' ? '0.00' : number;
      } else {
        _amount = (_amount + number);
      }
    });
  }

  void _onBackspaceTap() {
    setState(() {
      if (_amount.length > 1) {
        if (_amount.length == 2 && _amount.contains('.')) {
          _amount = '0.00';
        } else if (_amount.length == 4 && _amount.contains('.')) {
          _amount = '${_amount.substring(0, _amount.length - 1)}0';
        } else {
          _amount = _amount.substring(0, _amount.length - 1);
        }
      } else {
        _amount = '0.00';
        // If the amount is '0.00' and backspace is pressed, keep it '0.00'
        if (_amount == '0.00') _amount = '0.00';
      }
    });
  }

  String _formatCurrency(String amountStr) {
    if (amountStr.isEmpty) return "\$0,00";
    // Assuming the input string is in cents
    double number;
    if (amountStr.contains('.')) {
      number = double.parse(amountStr);
    } else {
      number = double.parse(amountStr) / 100;
    }
    final formatter = NumberFormat.currency(
      locale: 'en_US',
      symbol: '\$',
      decimalDigits: 2,
    );
    return formatter.format(number).replaceAll('.', ',');
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

    // Auto-capture the exchange rate at the transaction date (manual rate
    // overrides are not yet implemented in the form UI, so we use the
    // closest stored rate or the API-latest rate).
    double? rateAtCreation;
    final baseCode = await repo.getBaseCurrencyCode();
    if (_selectedAccount!.currencyCode != baseCode) {
      final stored = await repo.getRateAtDate(
          _selectedAccount!.currencyCode, DateTime.now());
      if (stored != null) {
        rateAtCreation = stored.rate;
      }
      if (rateAtCreation == null) {
        // Fall back to the latest stored rate if none exists for today.
        final latest = await repo.getLatestRate(_selectedAccount!.currencyCode);
        rateAtCreation = latest?.rate;
      }
    }

    // Compute the transaction value in the base currency at creation time.
    double? baseAmount;
    if (rateAtCreation != null && rateAtCreation != 0) {
      baseAmount = amountValue / rateAtCreation;
    } else if (_selectedAccount!.currencyCode == baseCode) {
      baseAmount = amountValue;
    }

    await repo.createTransaction(db.TransactionsCompanion(
      amount: Value(amountValue),
      accountId: Value(_selectedAccount!.id),
      categoryId: Value(category?['id']),
      currencyCode: Value(_selectedAccount!.currencyCode),
      reference: Value(_referenceController.text),
      isRecurrenceEnabled: Value(_isRecurrenceEnabled),
      date: Value(DateTime.now()),
      exchangeRateAtCreation: Value(rateAtCreation),
      baseCurrencyAmount: Value(baseAmount),
    ));

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
                          _iconDataFrom(account.icon),
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
                      Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFFD3E6D3),
                          shape: BoxShape.circle,
                        ),
                        child: const IconButton(
                          icon: Icon(Icons.image, color: Color(0xFF1A3A1B)),
                          onPressed: null, // No action
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
GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (context) => const CurrencyScreen()),
                                        );
                                      },
                                      child: Container(
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

IconData _iconDataFrom(String codePoint) {
  final parsed = int.tryParse(codePoint);
  if (parsed == null) return Icons.account_balance;
  // ignore: non_const_argument_for_const_parameter
  return IconData(parsed);
}