import 'package:finance_mvp/widget/numpad.dart';
import 'package:finance_mvp/widget/search_screen/search_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class transactionscreen extends StatefulWidget {
  const transactionscreen({super.key});

  @override
  State<transactionscreen> createState() => _transactionscreenState();
}

class _transactionscreenState extends State<transactionscreen> {

  String _amount = '0.00';

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
                          icon: Icon(Icons.add, color: Color(0xFF1A3A1B)),
                          onPressed: null, // No action
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFF1A3A1B),
                          shape: BoxShape.circle,
                        ),
                        child: const IconButton(
                          icon: Icon(Icons.search, color: Colors.white),
                          onPressed: null, // No action
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // Client Section
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
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SearchScreen()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
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
                      const Text(
                        'Banco mercantil Panama',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'USD',
                          style: TextStyle(
                            color: Color(0xFF4CAF50),
                            fontWeight: FontWeight.w500,
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
                    const Padding(
                      padding: EdgeInsets.only(top: 12.0, left: 4.0),
                      child: Text(
                        'USD',
                        style: TextStyle(
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

              // Numpad Widget
              Numpad(
                onNumberTap: _onNumberTap,
                onBackspaceTap: _onBackspaceTap,
              ),
              const Spacer(),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A3A1B),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'Create invoice',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}