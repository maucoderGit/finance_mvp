import 'package:finance_mvp/constants/app_colors.dart';
import 'package:flutter/material.dart';

class _StepGroup {
  final String title;
  final String subtitle;
  final int firstStep;
  final int lastStep;
  const _StepGroup(this.title, this.subtitle, this.firstStep, this.lastStep);
}

/// Groups the 7 onboarding pages into the 5 milestones shown on the rail.
const List<_StepGroup> _stepGroups = [
  _StepGroup('Welcome & Profile', 'Get to know you', 0, 1),
  _StepGroup('Currencies & Valuation', 'VES, USD & multi-currency', 2, 3),
  _StepGroup('Exchange rates', 'Auto or manual sync', 4, 4),
  _StepGroup('Your first account', 'Customize your vault', 5, 5),
  _StepGroup('Ready to launch', 'Portfolio analytics active', 6, 6),
];

/// Branding + journey progress rail for the wide-screen onboarding layout.
/// Lives in `widgets/` because it's expected to become the app shell sidebar
/// after onboarding — only onboarding puts it on screen today.
class OnboardingSidebar extends StatelessWidget {
  final int currentStep;
  const OnboardingSidebar({super.key, required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      color: context.colors.cardBackground,
      padding: const EdgeInsets.fromLTRB(28, 28, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: context.colors.fieldsBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        context.colors.primaryLight.withValues(alpha: 0.6),
                  ),
                ),
                child: Icon(Icons.account_balance_wallet,
                    color: context.colors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Finance',
                    style: TextStyle(
                      color: context.colors.textDark,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                  Text(
                    'WEALTH PORTFOLIO',
                    style: TextStyle(
                      color: context.colors.textLight,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.6,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 36),
          Text(
            'ONBOARDING PATHWAY',
            style: TextStyle(
              color: context.colors.textLight,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          for (final entry in _stepGroups.indexed)
            _StepRow(
              number: entry.$1 + 1,
              group: entry.$2,
              state: _stateFor(entry.$1),
            ),
        ],
      ),
    );
  }

  _StepState _stateFor(int index) {
    final group = _stepGroups[index];
    if (currentStep > group.lastStep) return _StepState.done;
    if (currentStep >= group.firstStep) return _StepState.active;
    return _StepState.upcoming;
  }
}

enum _StepState { done, active, upcoming }

class _StepRow extends StatelessWidget {
  final int number;
  final _StepGroup group;
  final _StepState state;
  const _StepRow({
    required this.number,
    required this.group,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final titleColor = state == _StepState.upcoming
        ? context.colors.textLight
        : context.colors.textDark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Indicator(number: number, state: state),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.title,
                    style: TextStyle(
                      color: titleColor,
                      fontSize: 13,
                      fontWeight: state == _StepState.active
                          ? FontWeight.w700
                          : FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    group.subtitle,
                    style: TextStyle(
                      color: context.colors.textLight,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Indicator extends StatelessWidget {
  final int number;
  final _StepState state;
  const _Indicator({required this.number, required this.state});

  @override
  Widget build(BuildContext context) {
    final primary = context.colors.primary;
    if (state == _StepState.done) {
      return Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: primary.withValues(alpha: 0.10),
          shape: BoxShape.circle,
          border: Border.all(color: primary.withValues(alpha: 0.35)),
        ),
        child: Icon(Icons.check, size: 16, color: primary),
      );
    }
    if (state == _StepState.active) {
      return Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: primary.withValues(alpha: 0.35), blurRadius: 10),
          ],
        ),
        child: Text(
          number.toString().padLeft(2, '0'),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: context.colors.segmentedControlBackground,
        shape: BoxShape.circle,
        border: Border.all(
          color: context.colors.cardBorder.withValues(alpha: 0.4),
        ),
      ),
      child: Text(
        number.toString().padLeft(2, '0'),
        style: TextStyle(
          color: context.colors.textLight,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}