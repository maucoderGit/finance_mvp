import 'package:finance_mvp/constants/app_colors.dart';
import 'package:finance_mvp/providers/currency_provider.dart';
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

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final TextEditingController _nameController = TextEditingController();

  int _currentStep = 0;
  bool _saving = false;

  String _baseCode = 'USD';
  String _baseName = 'US Dollar';
  String _baseSymbol = r'$';
  String _nationalCode = 'VES';
  String _nationalName = 'Venezuelan Bolivar';
  String _nationalSymbol = 'Bs.';
  String _syncMode = 'auto';

  static const int _totalSteps = 6;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
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

    final username =
        _nameController.text.trim().isEmpty ? 'User' : _nameController.text.trim();

    await context.read<CurrencyProvider>().completeOnboarding(
          username: username,
          baseCode: _baseCode,
          baseName: _baseName,
          baseSymbol: _baseSymbol,
          nationalCode: _nationalCode,
          nationalName: _nationalName,
          nationalSymbol: _nationalSymbol,
          syncMode: _syncMode,
        );

    // RootScreen watches user settings and swaps to home automatically.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
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
                    subtitle:
                        'The currency you use to measure your savings '
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
                    subtitle:
                        'The currency you earn and spend daily. '
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
                  DoneStep(
                    saving: _saving,
                    username:
                        _nameController.text.trim().isEmpty
                            ? 'User'
                            : _nameController.text.trim(),
                    baseCode: _baseCode,
                    nationalCode: _nationalCode,
                    syncMode: _syncMode,
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
              child: const Text(
                'Back',
                style: TextStyle(color: AppColors.textLight, fontSize: 16),
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
                      ? AppColors.primaryLight
                      : AppColors.cardBorder.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const Spacer(),
          if (_currentStep < _totalSteps - 1)
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
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
                backgroundColor: AppColors.primary,
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
          const Icon(Icons.account_balance_wallet,
              size: 96, color: AppColors.primary),
          const SizedBox(height: 40),
          const Text(
            'Welcome to\nAtelier Finance',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Track your savings across currencies and protect your '
            'purchasing power against exchange-rate changes.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textLight,
              fontSize: 15,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 48),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
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
          const Icon(Icons.person_outline, size: 72, color: AppColors.primary),
          const SizedBox(height: 32),
          const Text(
            'How should we call you?',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textDark,
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
              fillColor: AppColors.cardBackground,
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
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: const TextStyle(
                    color: AppColors.textLight, fontSize: 14, height: 1.4),
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
      color: isSelected ? AppColors.fieldsBackground : AppColors.cardBackground,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.cardBorder.withValues(alpha: 0.3),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor:
                    isSelected ? AppColors.primary : AppColors.segmentedControlBackground,
                child: Text(
                  option.code.substring(0, 1),
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textDark,
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
                      style: const TextStyle(
                        color: AppColors.textDark,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${option.name} (${option.symbol})',
                      style: const TextStyle(
                          color: AppColors.textLight, fontSize: 13),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(Icons.check_circle,
                    color: AppColors.primary, size: 22),
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
          const Text(
            'Exchange rates',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'How do you want currency rates to be kept up to date?',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textLight, fontSize: 14, height: 1.4),
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
      color: isSelected ? AppColors.fieldsBackground : AppColors.cardBackground,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.cardBorder.withValues(alpha: 0.3),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(icon,
                  size: 34,
                  color: isSelected ? AppColors.primary : AppColors.textLight),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textDark,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                          color: AppColors.textLight, fontSize: 13, height: 1.4),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(Icons.check_circle,
                    color: AppColors.primary, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Step 5: Summary ──────────────────────────────────────────────────────────

class DoneStep extends StatelessWidget {
  final bool saving;
  final String username;
  final String baseCode;
  final String nationalCode;
  final String syncMode;

  const DoneStep({
    super.key,
    required this.saving,
    required this.username,
    required this.baseCode,
    required this.nationalCode,
    required this.syncMode,
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
          const Icon(Icons.celebration_outlined,
              size: 80, color: AppColors.primary),
          const SizedBox(height: 24),
          const Text(
            "You're all set!",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          _SummaryRow(label: 'Name', value: username),
          _SummaryRow(label: 'Reference currency', value: baseCode),
          _SummaryRow(label: 'Local currency', value: nationalCode),
          _SummaryRow(
              label: 'Rates', value: isAuto ? 'Automatic sync' : 'Manual entry'),
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
            style: const TextStyle(color: AppColors.textLight, fontSize: 15),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
                color: AppColors.textDark,
                fontSize: 15,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}