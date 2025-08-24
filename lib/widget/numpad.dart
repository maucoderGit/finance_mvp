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
      padding: const EdgeInsets.only(top: 20),
      // decoration: BoxDecoration(
      //   gradient: LinearGradient(
      //     begin: Alignment.topCenter,
      //     end: Alignment.bottomCenter,
      //     colors: [
      //       Colors.white.withOpacity(0.0),
      //       Colors.grey.withOpacity(0.15),
      //     ],
      //     stops: const [0.0, 1.0],
      //   ),
      // ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _buildRow(['1', '2', '3']),
          _buildRow(['4', '5', '6']),
          _buildRow(['7', '8', '9']),
          // Last row with 0 and backspace
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Empty space to align 0 to the center
              const Expanded(child: SizedBox()),
              Expanded(child: _buildNumberButton('0')),
              Expanded(child: _buildBackspaceButton()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRow(List<String> numbers) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: numbers.map((number) => Expanded(child: _buildNumberButton(number))).toList(),
    );
  }

  Widget _buildNumberButton(String number) {
    return TextButton(
      onPressed: () => onNumberTap(number),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.all(20),
        shape: const CircleBorder(),
      ),
      child: Text(
        number,
        style: const TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w400,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _buildBackspaceButton() {
    return TextButton(
      onPressed: onBackspaceTap,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.all(20),
        shape: const CircleBorder(),
      ),
      child: const Icon(
        Icons.backspace_outlined,
        color: Colors.black,
        size: 30,
      ),
    );
  }
}