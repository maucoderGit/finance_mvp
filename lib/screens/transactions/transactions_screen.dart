import 'package:finance_mvp/constants/app_colors.dart';
import 'package:finance_mvp/database/app_database.dart' as db;
import 'package:finance_mvp/repositories/finance_repository.dart';
import 'package:finance_mvp/screens/transactions/transaction_list_view.dart';
import 'package:finance_mvp/services/finance/currency_converter.dart';
import 'package:finance_mvp/widgets/transaction_card.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// Bucket the transaction list is sliced by, anchored on a date the arrows
/// walk through. [range] is start-inclusive/end-exclusive; null means "all".
enum Period { week, month, quarter, year, all }

extension PeriodLabel on Period {
  String get label => switch (this) {
        Period.week => 'Week',
        Period.month => 'Month',
        Period.quarter => 'Quarter',
        Period.year => 'Year',
        Period.all => 'All',
      };

  /// Start-inclusive, end-exclusive bounds of the period holding [anchor];
  /// null means "every transaction".
  ({DateTime start, DateTime end})? range(DateTime anchor) {
    final a = DateTime(anchor.year, anchor.month, anchor.day);
    return switch (this) {
      Period.week => (
          start: a.subtract(Duration(days: a.weekday - 1)),
          end: a.subtract(Duration(days: a.weekday - 1)).add(const Duration(days: 7))
        ),
      Period.month =>
        (start: DateTime(a.year, a.month), end: DateTime(a.year, a.month + 1)),
      Period.quarter => (
          start: DateTime(a.year, ((a.month - 1) ~/ 3) * 3 + 1),
          end: DateTime(a.year, ((a.month - 1) ~/ 3) * 3 + 4)
        ),
      Period.year => (start: DateTime(a.year), end: DateTime(a.year + 1)),
      Period.all => null,
    };
  }

  /// Human label of the period containing [anchor], e.g. "This month",
  /// "Q3 2026", "Sep 21 – 27".
  String title(DateTime anchor) {
    final start = range(anchor)?.start;
    final isCurrent = start != null && start == range(DateTime.now())?.start;
    final f = DateFormat('MMM d');
    return switch (this) {
      Period.week => isCurrent
          ? 'This week'
          : '${f.format(start!)} – ${f.format(start.add(const Duration(days: 6)))}',
      Period.month =>
        isCurrent ? 'This month' : DateFormat('MMMM yyyy').format(anchor),
      Period.quarter => isCurrent
          ? 'This quarter'
          : 'Q${((anchor.month - 1) ~/ 3) + 1} ${anchor.year}',
      Period.year => isCurrent ? 'This year' : '${anchor.year}',
      Period.all => 'All time',
    };
  }
}

class TransactionPage extends StatefulWidget {
  const TransactionPage({super.key}); // Changed to StatefulWidget

  @override
  State<TransactionPage> createState() => _TransactionPageState();
}

class _TransactionPageState extends State<TransactionPage> {
  String _selectedToggle = 'All'; // State variable for selected toggle
  Period _period = Period.month;
  DateTime _anchor = DateTime.now();

  /// Search mode swaps the title row for a query field; the query narrows the
  /// list (and the summary) on top of the period and In/Out filters.
  final TextEditingController _searchController = TextEditingController();
  bool _searching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String get _query => _searchController.text.trim().toLowerCase();

  /// Net total of the given transactions converted to the base currency.
  Future<({double total, String baseSymbol})> _netTotalInBase(
      FinanceRepository repo, List<db.Transaction> transactions) async {
    final baseCode = await repo.getBaseCurrencyCode();
    double sum = 0;
    for (final t in transactions) {
      sum += await repo.toBaseAmount(t);
    }
    final currencies = await repo.getAllCurrencies();
    final baseSymbol = currencies.isNotEmpty
        ? currencies
            .firstWhere((c) => c.code == baseCode,
                orElse: () => currencies.first)
            .symbol
        : baseCode;
    return (total: sum, baseSymbol: baseSymbol);
  }

  void _shiftPeriod(int dir) {
    setState(() {
      _anchor = switch (_period) {
        Period.week => _anchor.add(Duration(days: 7 * dir)),
        Period.month => DateTime(_anchor.year, _anchor.month + dir, 1),
        Period.quarter => DateTime(_anchor.year, _anchor.month + 3 * dir, 1),
        Period.year => DateTime(_anchor.year + dir, 1, 1),
        Period.all => _anchor,
      };
    });
  }

  void _closeSearch() {
    _searchController.clear();
    setState(() => _searching = false);
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<FinanceRepository>();
    final range = _period.range(_anchor);

    // Contact and category names, so search can match them. Same lookup-map
    // approach the list view uses to render its rows.
    return Scaffold(
      body: FutureBuilder<
          ({Map<int, String> contacts, Map<int, String> categories})>(
        future: () async {
          final contacts = await repo.getAllContacts();
          final categories = await repo.getAllCategories();
          return (
            contacts: {for (final c in contacts) c.id: c.name},
            categories: {for (final c in categories) c.id: c.name},
          );
        }(),
        builder: (context, lookups) => StreamBuilder<List<db.Transaction>>(
          stream: repo.watchTransactions(),
          builder: (context, snapshot) {
            final inPeriod = (snapshot.data ?? []).where((t) {
              if (range == null) return true;
              return !t.date.isBefore(range.start) &&
                  t.date.isBefore(range.end);
            }).toList();
            final shown = inPeriod.where((t) {
              if (_selectedToggle == 'In' && t.amount <= 0) return false;
              if (_selectedToggle == 'Out' && t.amount >= 0) return false;
              if (_query.isNotEmpty) {
                final haystack = [
                  t.reference ?? '',
                  t.contactId == null ? '' : lookups.data?.contacts[t.contactId],
                  t.categoryId == null
                      ? ''
                      : lookups.data?.categories[t.categoryId],
                  t.currencyCode,
                  t.amount.abs(),
                ].join(' ');
                if (!haystack.toLowerCase().contains(_query)) return false;
              }
              return true;
            }).toList()
              ..sort((a, b) => b.date.compareTo(a.date));

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Body has no AppBar, so pad past the status bar like home does.
                  SizedBox(height: MediaQuery.paddingOf(context).top + 12),
                  _buildHeader(context),
                  const SizedBox(height: 16),
                  FutureBuilder<({double total, String baseSymbol})>(
                    future: _netTotalInBase(repo, shown),
                    builder: (context, snapshot) {
                      final total = snapshot.data?.total ?? 0.0;
                      final baseSymbol = snapshot.data?.baseSymbol ?? r'$';
                      return TransactionCard(
                        title: '${switch (_selectedToggle) {
                          'In' => 'Money in',
                          'Out' => 'Money out',
                          _ => 'Net movement',
                        }} · ${shown.length}',
                        displayAmount:
                            formatMoney(total, symbol: baseSymbol),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildPeriodControls(),
                  const SizedBox(height: 12),
                  Expanded(
                    child: TransactionListView(
                      transactions: shown,
                      emptyMessage: _query.isNotEmpty
                          ? 'No matches for "${_searchController.text.trim()}"'
                          : 'No transactions in ${_period.title(_anchor).toLowerCase()}',
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildToggleSection(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// The title row slides out and the query field slides in, so the header
  /// keeps its height and the + / search buttons leave with it.
  Widget _buildHeader(BuildContext context) {
    return SizedBox(
      height: 48,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween(
              begin: const Offset(0.25, 0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        ),
        child: _searching
            ? _buildSearchBar(context)
            : _buildTitleRow(context),
      ),
    );
  }

  Widget _buildTitleRow(BuildContext context) {
    final brand = context.colors.primary;
    return Row(
      key: const ValueKey('title'),
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back, color: brand),
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(width: 15),
            Text(
              'Transactions',
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: brand),
            ),
          ],
        ),
        Row(
          children: [
            _buildCircleIconButton(Icons.add,
                () => Navigator.pushNamed(context, '/v1/transactions/create')),
            const SizedBox(width: 5),
            _buildCircleIconButton(Icons.search,
                () => setState(() => _searching = true),
                isSearch: true),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Row(
      key: const ValueKey('search'),
      children: [
        IconButton(
          icon: Icon(Icons.arrow_back, color: context.colors.primary),
          onPressed: _closeSearch,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: _searchController,
            autofocus: true,
            textInputAction: TextInputAction.search,
            onChanged: (_) => setState(() {}),
            style: TextStyle(color: context.colors.textDark),
            decoration: InputDecoration(
              hintText: 'Search reference or amount',
              hintStyle: TextStyle(color: context.colors.textLight, fontSize: 14),
              isDense: true,
              filled: true,
              fillColor: context.colors.cardBackground,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(999),
                borderSide: BorderSide.none,
              ),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      icon: Icon(Icons.close,
                          size: 18, color: context.colors.textLight),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCircleIconButton(IconData icon, VoidCallback? onTap,
      {bool isSearch = false}) {
    return Container(
      decoration: BoxDecoration(
        color: isSearch
            ? context.colors.primary
            : context.colors.primaryLight.withValues(alpha: 0.3),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon:
            Icon(icon, color: isSearch ? Colors.white : context.colors.primary),
        onPressed: onTap,
      ),
    );
  }

  /// Period chips plus arrows that walk the anchor date; tapping the label
  /// jumps back to the current period.
  Widget _buildPeriodControls() {
    final canStep = _period != Period.all;
    return Column(
      children: [
        Row(
          children: [
            if (canStep)
              IconButton(
                icon: Icon(Icons.chevron_left, color: context.colors.textLight),
                onPressed: () => _shiftPeriod(-1),
              ),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _anchor = DateTime.now()),
                child: Text(
                  _period.title(_anchor),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: context.colors.textDark),
                ),
              ),
            ),
            if (canStep)
              IconButton(
                icon:
                    Icon(Icons.chevron_right, color: context.colors.textLight),
                onPressed: () => _shiftPeriod(1),
              ),
          ],
        ),
        SizedBox(
          height: 34,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final p in Period.values)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildPeriodChip(p),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodChip(Period period) {
    final selected = period == _period;
    return GestureDetector(
      onTap: () => setState(() {
        _period = period;
        _anchor = DateTime.now();
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? context.colors.primary
              : context.colors.cardBackground,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
              color: selected
                  ? context.colors.primary
                  : context.colors.cardBorder),
        ),
        child: Text(
          period.label,
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color:
                  selected ? Colors.white : context.colors.textLight),
        ),
      ),
    );
  }

  Widget _buildToggleSection() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: context.colors.cardBackground,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
                color: context.colors.primaryLight.withValues(alpha: 0.15),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, 3))
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: ['All', 'In', 'Out']
              .map((text) => _buildToggleButton(text))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildToggleButton(String text) {
    bool isSelected = (_selectedToggle == text);
    return GestureDetector(
      onTap: () => setState(() => _selectedToggle = text),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? context.colors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Text(
          text,
          style: TextStyle(
              color: isSelected ? Colors.white : context.colors.textLight,
              fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
