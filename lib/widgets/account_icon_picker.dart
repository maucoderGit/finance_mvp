import 'package:finance_mvp/constants/account_icons.dart';
import 'package:finance_mvp/constants/app_colors.dart';
import 'package:flutter/material.dart';

const List<int> accountColorPalette = [
  0xFF4CAF50, 0xFF2196F3, 0xFFFF9800, 0xFF9C27B0, 0xFFE91E63,
  0xFF00BCD4, 0xFFF44336, 0xFF3F51B5, 0xFF607D8B, 0xFF795548,
];

/// Compact icon + accent color picker, shared by the onboarding account step
/// and the Add/Edit Account sheet. Icons render as small dots so they don't
/// dominate the form.
class AccountIconPicker extends StatelessWidget {
  final String selectedType;
  final int selectedColor;
  final ValueChanged<String> onTypeChanged;
  final ValueChanged<int> onColorChanged;

  const AccountIconPicker({
    super.key,
    required this.selectedType,
    required this.selectedColor,
    required this.onTypeChanged,
    required this.onColorChanged,
  });

  String get _selectedTypeLabel {
    for (final label in accountTypeLabels) {
      if (accountIconSlug(label) == selectedType) return label;
    }
    return selectedType;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _PickerLabel('ICON'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final label in accountTypeLabels)
              _buildIconDot(context, label),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          _selectedTypeLabel,
          style: TextStyle(color: context.colors.textLight, fontSize: 12),
        ),
        const SizedBox(height: 20),
        const _PickerLabel('COLOR'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final color in accountColorPalette)
              _ColorDot(
                color: color,
                selected: selectedColor == color,
                onTap: () => onColorChanged(color),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildIconDot(BuildContext context, String label) {
    final slug = accountIconSlug(label);
    final isSelected = selectedType == slug;
    final color = Color(accountTypeColors[slug] ?? 0xFF4CAF50);
    return GestureDetector(
      onTap: () => onTypeChanged(slug),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.22)
              : context.colors.cardBackground,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected
                ? color
                : context.colors.cardBorder.withValues(alpha: 0.4),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Icon(accountIconFor(slug),
            size: 18,
            color: isSelected ? color : context.colors.textLight),
      ),
    );
  }
}

class _PickerLabel extends StatelessWidget {
  final String text;
  const _PickerLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: context.colors.textLight,
        fontWeight: FontWeight.w600,
        fontSize: 12,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  final int color;
  final bool selected;
  final VoidCallback onTap;

  const _ColorDot({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: Color(color),
          shape: BoxShape.circle,
          border: selected
              ? Border.all(color: context.colors.textDark, width: 3)
              : null,
        ),
        child: selected
            ? const Icon(Icons.check, color: Colors.white, size: 18)
            : null,
      ),
    );
  }
}