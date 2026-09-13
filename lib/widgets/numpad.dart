import 'package:finance_mvp/constants/app_colors.dart';
import 'package:flutter/material.dart';

class Numpad extends StatelessWidget {
  final Function(String) onNumberTap;
  final VoidCallback onBackspaceTap;

  const Numpad({
    super.key,
    required this.onNumberTap,
    required this.onBackspaceTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _buildRow(context, ['1', '2', '3']),
          _buildRow(context, ['4', '5', '6']),
          _buildRow(context, ['7', '8', '9']),
          // Last row with decimal, 0 and backspace
          Row(
            children: [
              Expanded(child: _buildNumberButton(context, '.')),
              Expanded(child: _buildNumberButton(context, '0')),
              Expanded(child: _buildBackspaceButton(context)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRow(BuildContext context, List<String> numbers) {
    return Row(
      children: numbers
          .map((n) => Expanded(child: _buildNumberButton(context, n)))
          .toList(),
    );
  }

  Widget _buildNumberButton(BuildContext context, String number) {
    return TextButton(
      onPressed: () => onNumberTap(number),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.all(10),
        shape: const CircleBorder(),
      ),
      child: Text(
        number,
        style: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w400,
          color: context.colors.textDark,
        ),
      ),
    );
  }

  Widget _buildBackspaceButton(BuildContext context) {
    return TextButton(
      onPressed: onBackspaceTap,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.all(10),
        shape: const CircleBorder(),
      ),
      child: Icon(
        Icons.backspace_outlined,
        color: context.colors.textDark,
        size: 30,
      ),
    );
  }
}
