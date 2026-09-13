
import 'package:finance_mvp/constants/app_colors.dart';
import 'package:finance_mvp/database/app_database.dart' as db;
import 'package:finance_mvp/screens/settings/currency_form.dart';
import 'package:finance_mvp/repositories/finance_repository.dart';
import 'package:flutter/material.dart';
import 'daily_rates_screen.dart';
import 'package:provider/provider.dart';

class CurrencyScreen extends StatefulWidget {
  const CurrencyScreen({super.key});

  @override
  State<CurrencyScreen> createState() => _CurrencyScreenState();
}

class _CurrencyScreenState extends State<CurrencyScreen> {
  final TextEditingController _searchController = TextEditingController();
  late Future<List<db.Currency>> _currenciesFuture;
  late Future<String> _baseCurrencyCodeFuture;
  List<db.Currency> _filteredCurrencies = [];

  @override
  void initState() {
    super.initState();
    _loadCurrencies();
    _searchController.addListener(_filterCurrencies);
  }

  void _loadCurrencies() {
    final repo = context.read<FinanceRepository>();
    _currenciesFuture = repo.db.select(repo.db.currencies).get();
    _baseCurrencyCodeFuture = repo.getBaseCurrencyCode();
  }

  void _filterCurrencies() {
    // This will be handled within the FutureBuilder now
    setState(() {});
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _setBaseCurrency(String code) async {
    final repo = context.read<FinanceRepository>();
    await repo.setBaseCurrency(code);
    _loadCurrencies(); // Reload to reflect changes
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
            backgroundColor: context.colors.primary,
            child: IconButton(icon: Icon(Icons.add, color: context.colors.background), onPressed: () {
              showModalBottomSheet<db.Currency>(
                context: context,
                isScrollControlled: true,
                builder: (context) => const CurrencyForm(),
              ).then((newCurrency) {
                if (newCurrency != null) {
                setState(() {
                    _loadCurrencies();
                });
              }});
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
            child: FutureBuilder(
              future: Future.wait([_currenciesFuture, _baseCurrencyCodeFuture]),
              builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting || !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final allCurrencies = snapshot.data![0] as List<db.Currency>;
                final baseCurrencyCode = snapshot.data![1] as String;

                if (allCurrencies.isEmpty) {
                  return const Center(child: Text('No currencies found.'));
                }

                final query = _searchController.text.toLowerCase();
                _filteredCurrencies = allCurrencies.where((currency) {
                  return currency.name.toLowerCase().contains(query) || currency.code.toLowerCase().contains(query);
                }).toList();

                return ListView.builder(
                  itemCount: _filteredCurrencies.length,
                  itemBuilder: (context, index) {
                    final currency = _filteredCurrencies[index];
                    final isBase = currency.code == baseCurrencyCode;
                    return _CurrencyListItem(
                      currency: currency,
                      isBase: isBase,
                      onTap: () {
                        _setBaseCurrency(currency.code);
                      },
                      onViewRates: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => DailyRatesScreen(currency: currency)));
                      },
                    );
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
    required this.isBase,
    required this.onTap,
    required this.onViewRates,
  });

  final db.Currency currency;
  final bool isBase;
  final VoidCallback onTap;
  final VoidCallback onViewRates;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        decoration: isBase
            ? BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                border: Border(left: BorderSide(color: Theme.of(context).colorScheme.primary, width: 4)),
              )
            : null,
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
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
            if (isBase)
              Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.primary,
              ),
            if (!isBase)
              IconButton(
                icon: const Icon(Icons.timeline),
                onPressed: onViewRates,
                tooltip: 'View historical rates',
              ),
          ],
        ),
      ),
    );
  }
}
