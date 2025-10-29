
import 'package:finance_mvp/constants/app_colors.dart';
import 'package:finance_mvp/screens/currency_form.dart';
import 'package:flutter/material.dart';
import '../models/currency.dart';
import 'daily_rates_screen.dart';

class CurrencyScreen extends StatefulWidget {
  const CurrencyScreen({super.key});

  @override
  State<CurrencyScreen> createState() => _CurrencyScreenState();
}

class _CurrencyScreenState extends State<CurrencyScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Currency> _currencies = [];
  List<Currency> _filteredCurrencies = [];
  Currency? _selectedCurrency;

  @override
  void initState() {
    super.initState();
    _currencies = [
      Currency(name: 'United States Dollar', code: 'USD', symbol: '\$', separator: ',', decimalDigits: 2),
      Currency(name: 'Euro', code: 'EUR', symbol: '€', separator: '.', decimalDigits: 2),
      Currency(name: 'British Pound', code: 'GBP', symbol: '£', separator: ',', decimalDigits: 2),
      Currency(name: 'Japanese Yen', code: 'JPY', symbol: '¥', separator: ',', decimalDigits: 0),
      Currency(name: 'Australian Dollar', code: 'AUD', symbol: '\$', separator: ',', decimalDigits: 2),
      Currency(name: 'Canadian Dollar', code: 'CAD', symbol: '\$', separator: ',', decimalDigits: 2),
      Currency(name: 'Swiss Franc', code: 'CHF', symbol: 'CHF', separator: '\'', decimalDigits: 2),
    ];
    _filteredCurrencies = _currencies;
    _selectedCurrency = _currencies.first;
    _searchController.addListener(_filterCurrencies);
  }

  void _filterCurrencies() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredCurrencies = _currencies.where((currency) {
        return currency.name.toLowerCase().contains(query) || currency.code.toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Currency'),
        actionsPadding: const EdgeInsets.only(right: 10),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          CircleAvatar(
            backgroundColor: AppColors.primary,
            child: IconButton(icon: const Icon(Icons.add, color: AppColors.background), onPressed: () async {
              final newCurrency = await showModalBottomSheet<Currency>(
                context: context,
                isScrollControlled: true,
                builder: (context) => const CurrencyForm(),
              );
              if (newCurrency != null) {
                setState(() {
                  _currencies.add(newCurrency);
                  _filterCurrencies();
                });
              }
            },
          ))
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search by name or code',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12.0)),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredCurrencies.length,
              itemBuilder: (context, index) {
                final currency = _filteredCurrencies[index];
                final isSelected = currency.code == _selectedCurrency?.code;
                return _CurrencyListItem(
                  currency: currency,
                  isSelected: isSelected,
                  onTap: () {
                    setState(() {
                      _selectedCurrency = currency;
                    });
                  },
                  onLongPress: () {
                    showModalBottomSheet(context: context, builder: (context) {
                      return Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
                        ),
                        child: const DailyRatesScreen(),
                      );
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrencyListItem extends StatelessWidget {
  const _CurrencyListItem({
    required this.currency,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
  });

  final Currency currency;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        decoration: isSelected
            ? BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                border: Border(left: BorderSide(color: Theme.of(context).colorScheme.primary, width: 4)),
              )
            : null,
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
              child: Text(
                currency.symbol,
                style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 18),
              ),
            ),
            const SizedBox(width: 16.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currency.code,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    currency.name,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }
}
