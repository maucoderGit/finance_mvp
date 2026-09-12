import 'package:finance_mvp/constants/account_icons.dart';
import 'package:finance_mvp/constants/app_colors.dart';
import 'package:finance_mvp/database/app_database.dart';
import 'package:finance_mvp/providers/currency_provider.dart';
import 'package:finance_mvp/repositories/finance_repository.dart';
import 'package:finance_mvp/services/currency_converter.dart';
import 'package:finance_mvp/widgets/account_icon_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class _CurrencyOption {
  final String code;
  final String name;
  final String symbol;
  const _CurrencyOption(this.code, this.name, this.symbol);
}

const List<_CurrencyOption> _currencyOptions = [
  _CurrencyOption('USD', 'US Dollar', r'$'),
  _CurrencyOption('VES', 'Venezuelan Bolivar', 'Bs.'),
  _CurrencyOption('EUR', 'Euro', '\u20ac'),
  _CurrencyOption('GBP', 'British Pound', '\u00a3'),
  _CurrencyOption('CAD', 'Canadian Dollar', 'C\$'),
  _CurrencyOption('MXN', 'Mexican Peso', r'$'),
  _CurrencyOption('COP', 'Colombian Peso', r'$'),
  _CurrencyOption('ARS', 'Argentine Peso', r'$'),
  _CurrencyOption('BRL', 'Brazilian Real', 'R\$'),
  _CurrencyOption('CLP', 'Chilean Peso', r'$'),
  _CurrencyOption('PEN', 'Peruvian Sol', 'S/'),
  _CurrencyOption('UYU', 'Uruguayan Peso', r'$'),
  _CurrencyOption('BOB', 'Boliviano', 'Bs'),
  _CurrencyOption('PYG', 'Paraguayan Guarani', '\u20b2'),
];

class _AccountTemplate {
  final String label;
  final String icon;
  final int color;
  const _AccountTemplate(this.label, this.icon, this.color);
}

final List<_AccountTemplate> _accountTemplates = [
  for (final label in accountTypeLabels)
    _AccountTemplate(label, accountIconSlug(label),
        accountTypeColors[accountIconSlug(label)]!),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _accountController = TextEditingController();
  final TextEditingController _balanceController = TextEditingController();

  final List<_AccountDraft> _accounts = [];
  String _accountCurrency = 'VES';
  String _accountType = 'cash';
  int _accountColor = 0xFF4CAF50;

  int _currentStep = 0;
  bool _saving = false;

  String _baseCode = 'USD';
  String _baseName = 'US Dollar';
  String _baseSymbol = r'$';
  String _nationalCode = 'VES';
  String _nationalName = 'Venezuelan Bolivar';
  String _nationalSymbol = 'Bs.';
  String _syncMode = 'auto';

  static const int _totalSteps = 7;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _accountController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _currentStep = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _finish() async {
    if (_saving) return;
    setState(() => _saving = true);

    final username = _nameController.text.trim().isEmpty
        ? 'User'
        : _nameController.text.trim();

    final currencyProvider = context.read<CurrencyProvider>();
    await currencyProvider.completeOnboarding(
      username: username,
      baseCode: _baseCode,
      baseName: _baseName,
      baseSymbol: _baseSymbol,
      nationalCode: _nationalCode,
      nationalName: _nationalName,
      nationalSymbol: _nationalSymbol,
      syncMode: _syncMode,
    );

    if (!mounted) return;
    final repo = context.read<FinanceRepository>();
    for (final account in _accounts) {
      await repo.createAccountWithInitialTransaction(
        AccountsCompanion.insert(
          name: account.name,
          currencyCode: account.code,
          icon: account.icon,
          iconColor: account.iconColor,
        ),
        account.balance,
      );
    }

    // RootScreen watches user settings and swaps to home automatically.
  }

  void _addAccount({
    String? name,
    String? icon,
    int? iconColor,
  }) {
    final accountName = (name ?? _accountController.text).trim();
    if (accountName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Give the account a name.')),
      );
      return;
    }

    var balance = 0.0;
    final balanceText = _balanceController.text.trim();
    if (balanceText.isNotEmpty) {
      final parsed = double.tryParse(balanceText);
      if (parsed == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter a valid initial balance.')),
        );
        return;
      }
      balance = parsed;
    }

    setState(() {
      _accounts.add(_AccountDraft(
        name: accountName,
        code: _accountCurrency,
        balance: balance,
        icon: icon ?? _accountType,
        iconColor: iconColor ?? _accountColor,
      ));
      _accountController.clear();
      _balanceController.clear();
    });
  }

  void _addAccountTemplate(_AccountTemplate template) {
    _addAccount(
        name: template.label, icon: template.icon, iconColor: template.color);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _WelcomeStep(onGetStarted: () => _goToStep(1)),
                  _NameStep(controller: _nameController),
                  _CurrencyStep(
                    title: 'Reference currency',
                    subtitle: 'The currency you use to measure your savings '
                        '(net worth is shown in it).',
                    options: _currencyOptions,
                    selectedCode: _baseCode,
                    onSelected: (option) {
                      setState(() {
                        _baseCode = option.code;
                        _baseName = option.name;
                        _baseSymbol = option.symbol;
                      });
                    },
                  ),
                  _CurrencyStep(
                    title: 'Local currency',
                    subtitle: 'The currency you earn and spend daily. '
                        'Your purchasing power is tracked against it.',
                    options: _currencyOptions,
                    selectedCode: _nationalCode,
                    onSelected: (option) {
                      setState(() {
                        _nationalCode = option.code;
                        _nationalName = option.name;
                        _nationalSymbol = option.symbol;
                      });
                    },
                  ),
                  _SyncModeStep(
                    selected: _syncMode,
                    onSelected: (mode) => setState(() => _syncMode = mode),
                  ),
                  _AccountStep(
                    controller: _accountController,
                    balanceController: _balanceController,
                    accounts: _accounts,
                    options: _currencyOptions,
                    templates: _accountTemplates,
                    accountCurrency: _accountCurrency,
                    selectedType: _accountType,
                    selectedColor: _accountColor,
                    onCurrencyChanged: (code) =>
                        setState(() => _accountCurrency = code),
                    onTypeChanged: (slug) => setState(() {
                      _accountType = slug;
                      _accountColor = accountTypeColors[slug] ?? _accountColor;
                    }),
                    onColorChanged: (color) =>
                        setState(() => _accountColor = color),
                    onAdd: _addAccount,
                    onAddTemplate: _addAccountTemplate,
                    onRemove: (index) =>
                        setState(() => _accounts.removeAt(index)),
                  ),
                  DoneStep(
                    saving: _saving,
                    username: _nameController.text.trim().isEmpty
                        ? 'User'
                        : _nameController.text.trim(),
                    baseCode: _baseCode,
                    nationalCode: _nationalCode,
                    syncMode: _syncMode,
                    accountCount: _accounts.length,
                  ),
                ],
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Row(
        children: [
          if (_currentStep > 0)
            TextButton(
              onPressed: () => _goToStep(_currentStep - 1),
              child: Text(
                'Back',
                style: TextStyle(color: context.colors.textLight, fontSize: 16),
              ),
            )
          else
            const SizedBox(width: 64),
          const Spacer(),
          Row(
            children: List.generate(
              _totalSteps,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _currentStep ? 22 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: i == _currentStep
                      ? context.colors.primaryLight
                      : context.colors.cardBorder.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const Spacer(),
          if (_currentStep < _totalSteps - 1)
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: context.colors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 28),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              onPressed: () => _goToStep(_currentStep + 1),
              child: const Text('Next', style: TextStyle(fontSize: 16)),
            )
          else
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: context.colors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 28),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              onPressed: _saving ? null : _finish,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Finish', style: TextStyle(fontSize: 16)),
            ),
          if (_currentStep == _totalSteps - 1) const SizedBox(width: 64),
        ],
      ),
    );
  }
}

// ── Step 0: Welcome ──────────────────────────────────────────────────────────

class _WelcomeStep extends StatelessWidget {
  final VoidCallback onGetStarted;
  const _WelcomeStep({required this.onGetStarted});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.account_balance_wallet,
              size: 96, color: context.colors.primary),
          const SizedBox(height: 40),
          Text(
            'Welcome to\nFinance',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.colors.textDark,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Track your savings across currencies and protect your '
            'purchasing power against exchange-rate changes.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.colors.textLight,
              fontSize: 15,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 48),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: context.colors.primary,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            onPressed: onGetStarted,
            child: const Text('Get started',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ── Step 1: Name ─────────────────────────────────────────────────────────────

class _NameStep extends StatelessWidget {
  final TextEditingController controller;
  const _NameStep({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.person_outline, size: 72, color: context.colors.primary),
          const SizedBox(height: 32),
          Text(
            'How should we call you?',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.colors.textDark,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 40),
          TextField(
            controller: controller,
            autofocus: true,
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: 'Your name',
              filled: true,
              fillColor: context.colors.cardBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Steps 2 & 3: Currency selection ──────────────────────────────────────────

class _CurrencyStep extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<_CurrencyOption> options;
  final String selectedCode;
  final ValueChanged<_CurrencyOption> onSelected;

  const _CurrencyStep({
    required this.title,
    required this.subtitle,
    required this.options,
    required this.selectedCode,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 40, 32, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: context.colors.textDark,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: TextStyle(
                    color: context.colors.textLight, fontSize: 14, height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: options.length,
            itemBuilder: (context, index) {
              final option = options[index];
              final isSelected = option.code == selectedCode;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _CurrencyTile(
                  option: option,
                  isSelected: isSelected,
                  onTap: () => onSelected(option),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CurrencyTile extends StatelessWidget {
  final _CurrencyOption option;
  final bool isSelected;
  final VoidCallback onTap;

  const _CurrencyTile({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected
          ? context.colors.fieldsBackground
          : context.colors.cardBackground,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? context.colors.primary
                  : context.colors.cardBorder.withValues(alpha: 0.3),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: isSelected
                    ? context.colors.primary
                    : context.colors.segmentedControlBackground,
                child: Text(
                  option.code.substring(0, 1),
                  style: TextStyle(
                    color: isSelected ? Colors.white : context.colors.textDark,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.code,
                      style: TextStyle(
                        color: context.colors.textDark,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${option.name} (${option.symbol})',
                      style: TextStyle(
                          color: context.colors.textLight, fontSize: 13),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle,
                    color: context.colors.primary, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Step 4: Sync mode ────────────────────────────────────────────────────────

class _SyncModeStep extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelected;

  const _SyncModeStep({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Exchange rates',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.colors.textDark,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'How do you want currency rates to be kept up to date?',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: context.colors.textLight, fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 32),
          _SyncModeCard(
            icon: Icons.cloud_done_outlined,
            title: 'Automatic',
            description: 'Fetch the latest rates from the exchange API '
                'whenever you open the app.',
            isSelected: selected == 'auto',
            onTap: () => onSelected('auto'),
          ),
          const SizedBox(height: 16),
          _SyncModeCard(
            icon: Icons.edit_outlined,
            title: 'Manual',
            description: 'You\'ll enter rates yourself. Best when the API '
                'can\'t track your currency.',
            isSelected: selected == 'manual',
            onTap: () => onSelected('manual'),
          ),
        ],
      ),
    );
  }
}

class _SyncModeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  const _SyncModeCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected
          ? context.colors.fieldsBackground
          : context.colors.cardBackground,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? context.colors.primary
                  : context.colors.cardBorder.withValues(alpha: 0.3),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(icon,
                  size: 34,
                  color: isSelected
                      ? context.colors.primary
                      : context.colors.textLight),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: context.colors.textDark,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                          color: context.colors.textLight,
                          fontSize: 13,
                          height: 1.4),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle,
                    color: context.colors.primary, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Step 5: First account ────────────────────────────────────────────────────

class _AccountDraft {
  final String name;
  final String code;
  final double balance;
  final String icon;
  final int iconColor;
  const _AccountDraft({
    required this.name,
    required this.code,
    this.balance = 0,
    this.icon = 'cash',
    this.iconColor = 0xFF4CAF50,
  });
}

class _AccountStep extends StatelessWidget {
  final TextEditingController controller;
  final TextEditingController balanceController;
  final List<_AccountDraft> accounts;
  final List<_CurrencyOption> options;
  final List<_AccountTemplate> templates;
  final String accountCurrency;
  final String selectedType;
  final int selectedColor;
  final ValueChanged<String> onCurrencyChanged;
  final ValueChanged<String> onTypeChanged;
  final ValueChanged<int> onColorChanged;
  final VoidCallback onAdd;
  final ValueChanged<_AccountTemplate> onAddTemplate;
  final ValueChanged<int> onRemove;

  const _AccountStep({
    required this.controller,
    required this.balanceController,
    required this.accounts,
    required this.options,
    required this.templates,
    required this.accountCurrency,
    required this.selectedType,
    required this.selectedColor,
    required this.onCurrencyChanged,
    required this.onTypeChanged,
    required this.onColorChanged,
    required this.onAdd,
    required this.onAddTemplate,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(32, 40, 32, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your first account',
                        style: TextStyle(
                          color: context.colors.textDark,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Accounts are optional. Tap a template for a quick start, '
                        'or pick an icon and add your own below.',
                        style: TextStyle(
                            color: context.colors.textLight,
                            fontSize: 14,
                            height: 1.4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final template in templates)
                        ActionChip(
                          avatar: Icon(accountIconFor(template.icon),
                              size: 16, color: Color(template.color)),
                          label: Text(template.label),
                          backgroundColor: context.colors.cardBackground,
                          onPressed: () => onAddTemplate(template),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: AccountIconPicker(
                    selectedType: selectedType,
                    selectedColor: selectedColor,
                    onTypeChanged: onTypeChanged,
                    onColorChanged: onColorChanged,
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      TextField(
                        key: const Key('onboarding-account-name'),
                        controller: controller,
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          hintText: 'Account name',
                          filled: true,
                          fillColor: context.colors.cardBackground,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: balanceController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          hintText: 'Initial balance (optional)',
                          filled: true,
                          fillColor: context.colors.cardBackground,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: accountCurrency,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: context.colors.cardBackground,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              isExpanded: true,
                              items: [
                                for (final option in options)
                                  DropdownMenuItem(
                                    value: option.code,
                                    child:
                                        Text('${option.code} — ${option.name}'),
                                  ),
                              ],
                              onChanged: (code) {
                                if (code != null) onCurrencyChanged(code);
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: context.colors.primary,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: onAdd,
                            child: const Text('Add'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (accounts.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
            child: Text(
              'No accounts yet — this step is optional.',
              textAlign: TextAlign.center,
              style: TextStyle(color: context.colors.textLight),
            ),
          )
        else
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 180),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: accounts.length,
              itemBuilder: (context, index) {
                final account = accounts[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: context.colors.cardBackground,
                    borderRadius: BorderRadius.circular(14),
                    child: ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color:
                              context.colors.cardBorder.withValues(alpha: 0.3),
                        ),
                      ),
                      leading: CircleAvatar(
                        backgroundColor:
                            Color(account.iconColor).withValues(alpha: 0.15),
                        child: Icon(accountIconFor(account.icon),
                            color: Color(account.iconColor), size: 16),
                      ),
                      title: Text(account.name,
                          style: TextStyle(
                              color: context.colors.textDark,
                              fontWeight: FontWeight.w600)),
                      subtitle: Text(
                        account.balance == 0
                            ? account.code
                            : '${account.code} · ${formatMoney(account.balance)}',
                        style: TextStyle(
                            color: context.colors.textLight, fontSize: 13),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        tooltip: 'Remove account',
                        onPressed: () => onRemove(index),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

// ── Step 6: Summary ──────────────────────────────────────────────────────────

class DoneStep extends StatelessWidget {
  final bool saving;
  final String username;
  final String baseCode;
  final String nationalCode;
  final String syncMode;
  final int accountCount;

  const DoneStep({
    super.key,
    required this.saving,
    required this.username,
    required this.baseCode,
    required this.nationalCode,
    required this.syncMode,
    required this.accountCount,
  });

  @override
  Widget build(BuildContext context) {
    final isAuto = syncMode == 'auto';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.celebration_outlined,
              size: 80, color: context.colors.primary),
          const SizedBox(height: 24),
          Text(
            "You're all set!",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.colors.textDark,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          _SummaryRow(label: 'Name', value: username),
          _SummaryRow(label: 'Reference currency', value: baseCode),
          _SummaryRow(label: 'Local currency', value: nationalCode),
          _SummaryRow(
              label: 'Accounts',
              value:
                  accountCount == 1 ? '1 account' : '$accountCount accounts'),
          _SummaryRow(
              label: 'Rates',
              value: isAuto ? 'Automatic sync' : 'Manual entry'),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(color: context.colors.textLight, fontSize: 15),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
                color: context.colors.textDark,
                fontSize: 15,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
