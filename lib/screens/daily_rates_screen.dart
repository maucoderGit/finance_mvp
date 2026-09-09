import 'package:drift/drift.dart' as drift;
import 'package:finance_mvp/screens/database.dart';
import 'package:finance_mvp/screens/finance_repository.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class DailyRatesScreen extends StatefulWidget {
  final Currency currency;
  const DailyRatesScreen({super.key, required this.currency});

  @override
  State<DailyRatesScreen> createState() => _DailyRatesScreenState();
}

class _DailyRatesScreenState extends State<DailyRatesScreen> {
  late Future<List<ExchangeRate>> _ratesFuture;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadRates();
  }

  void _loadRates() {
    final repo = context.read<FinanceRepository>();
    setState(() {
      _ratesFuture = repo.getRatesForCurrency(widget.currency.code);
    });
  }

  Future<void> _addRate() async {
    final repo = context.read<FinanceRepository>();
    DateTime? selectedDate = DateTime.now();
    final rateController = TextEditingController();

    final bool? shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Rate for ${widget.currency.code}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: rateController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Rate (1 USD = ?)',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final pickedDate = await showDatePicker(
                  context: context,
                  initialDate: selectedDate!,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                );
                if (pickedDate != null) {
                  selectedDate = pickedDate;
                }
              },
              child: const Text('Select Date'),
            )
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Save')),
        ],
      ),
    );

    if (shouldSave == true) {
      final rate = double.tryParse(rateController.text);
      if (rate != null && selectedDate != null) {
        final newRate = CurrencyRatesCompanion(
          currencyCode: drift.Value(widget.currency.code),
          rate: drift.Value(rate),
          date: drift.Value(selectedDate!),
        );
        await repo.addExchangeRate(newRate);
        _loadRates(); // Refresh the list
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Rates for ${widget.currency.code}'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addRate,
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<ExchangeRate>>(
        future: _ratesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No rates found for this currency.'));
          }

          final rates = snapshot.data!;
          final currentRate = rates[_currentIndex];

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '1 USD = ${currentRate.rate.toStringAsFixed(4)} ${widget.currency.code}',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          onPressed: _currentIndex < rates.length - 1
                              ? () => setState(() => _currentIndex++)
                              : null,
                        ),
                        Column(
                          children: [
                            Text(
                              DateFormat('MMMM dd, yyyy').format(currentRate.date),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          onPressed: _currentIndex > 0
                              ? () => setState(() => _currentIndex--)
                              : null,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  itemCount: rates.length,
                  itemBuilder: (context, index) {
                    final rate = rates[index];
                    return ListTile(
                      title: Text(DateFormat('MMMM dd, yyyy').format(rate.date)),
                      trailing: Text(
                        rate.rate.toString(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
