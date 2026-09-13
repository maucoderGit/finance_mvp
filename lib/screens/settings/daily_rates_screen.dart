import 'package:drift/drift.dart' as drift;
import 'package:finance_mvp/database/app_database.dart';
import 'package:finance_mvp/providers/currency_provider.dart';
import 'package:finance_mvp/repositories/finance_repository.dart';
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
  bool _syncing = false;

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

  Future<void> _syncFromApi() async {
    final provider = context.read<CurrencyProvider>();
    setState(() => _syncing = true);

    try {
      final count = await provider.syncHistoricalRates(
        widget.currency.code,
        daysBack: 90,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            count > 0
                ? 'Synced $count rate(s) from the API.'
                : 'No rates available from the API. Add them manually.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sync failed: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _syncing = false);
        _loadRates();
      }
    }
  }

  Future<void> _showRateDialog({ExchangeRate? existing}) async {
    final repo = context.read<FinanceRepository>();
    final rateController =
        TextEditingController(text: existing != null ? existing.rate.toString() : '');
    var selectedDate = existing?.date ?? DateTime.now();
    final isEdit = existing != null;

    final bool? shouldSave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
              '${isEdit ? 'Edit' : 'Add'} Rate for ${widget.currency.code}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: rateController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Rate (1 USD = ?)',
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (pickedDate != null) {
                    setDialogState(() => selectedDate = pickedDate);
                  }
                },
                child: Text(
                    'Date: ${DateFormat('MMMM dd, yyyy').format(selectedDate)}'),
              )
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                if (double.tryParse(rateController.text) == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Enter a valid rate.')),
                  );
                  return;
                }
                Navigator.of(context).pop(true);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (shouldSave == true) {
      final rate = double.tryParse(rateController.text);
      if (rate != null) {
        var companion = CurrencyRatesCompanion(
          currencyCode: drift.Value(widget.currency.code),
          rate: drift.Value(rate),
          date: drift.Value(selectedDate),
        );
        if (existing != null) {
          companion = companion.copyWith(id: drift.Value(existing.id));
        }
        await repo.addExchangeRate(companion);
        _loadRates();
      }
    }
  }

  Future<void> _confirmDelete(ExchangeRate rate) async {
    final repo = context.read<FinanceRepository>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete rate?'),
        content: Text(
            'Remove the rate for ${DateFormat('MMMM dd, yyyy').format(rate.date)}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete')),
        ],
      ),
    );

    if (confirmed == true) {
      await repo.deleteExchangeRate(rate.id);
      if (mounted) _loadRates();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Rates for ${widget.currency.code}'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: _syncing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync),
            tooltip: 'Sync from API',
            onPressed: _syncing ? null : _syncFromApi,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showRateDialog(),
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<ExchangeRate>>(
        future: _ratesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.trending_down, size: 48, color: Colors.grey),
                    const SizedBox(height: 12),
                    const Text(
                      'No rates found for this currency.',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Use the sync button to fetch from the API, or add rates manually.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _syncing ? null : _syncFromApi,
                      icon: const Icon(Icons.cloud_download),
                      label: const Text('Fetch from API'),
                    ),
                  ],
                ),
              ),
            );
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
                    final isLatest = index == 0;
                    return ListTile(
                      title: Text(DateFormat('MMMM dd, yyyy').format(rate.date)),
                      subtitle: isLatest
                          ? const Text('Latest', style: TextStyle(color: Colors.green))
                          : null,
                      onTap: () => _showRateDialog(existing: rate),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            rate.rate.toStringAsFixed(4),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            tooltip: 'Edit rate',
                            visualDensity: VisualDensity.compact,
                            onPressed: () => _showRateDialog(existing: rate),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            tooltip: 'Delete rate',
                            visualDensity: VisualDensity.compact,
                            onPressed: () => _confirmDelete(rate),
                          ),
                        ],
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