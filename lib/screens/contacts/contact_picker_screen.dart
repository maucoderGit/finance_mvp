import 'package:finance_mvp/constants/app_colors.dart';
import 'package:finance_mvp/database/app_database.dart' as db;
import 'package:finance_mvp/repositories/finance_repository.dart';
import 'package:finance_mvp/screens/contacts/contact_widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Full-screen contact selector. Pops with the picked [db.Contact]; a new
/// contact can be registered on the fly from the add button.
class ContactPickerScreen extends StatefulWidget {
  const ContactPickerScreen({super.key});

  @override
  State<ContactPickerScreen> createState() => _ContactPickerScreenState();
}

class _ContactPickerScreenState extends State<ContactPickerScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<db.Contact> _contacts = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final repo = context.read<FinanceRepository>();
    final all = await repo.getAllContacts();
    if (!mounted) return;
    setState(() => _contacts = all);
  }

  List<db.Contact> get _filtered {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return _contacts;
    return _contacts
        .where((c) =>
            c.name.toLowerCase().contains(q) ||
            (c.phone?.toLowerCase().contains(q) ?? false))
        .toList();
  }

  Future<void> _createContact() async {
    final repo = context.read<FinanceRepository>();
    final result = await showContactFormSheet(context);
    if (result == null) return;
    final created =
        await repo.findOrCreateContact(result.name, phone: result.phone);
    if (!mounted) return;
    Navigator.of(context).pop(created);
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: const Text('Select Recipient'),
        centerTitle: true,
        backgroundColor: context.colors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.colors.textDark),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            tooltip: 'New contact',
            icon: Icon(Icons.add, color: context.colors.textDark),
            onPressed: _createContact,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search by name or phone...',
                prefixIcon: Icon(Icons.search, color: context.colors.textLight),
                filled: true,
                fillColor: context.colors.cardBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.person_search,
                            size: 40, color: context.colors.textLight),
                        const SizedBox(height: 8),
                        Text(
                          _contacts.isEmpty
                              ? 'No contacts yet'
                              : 'No matching contacts',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: context.colors.textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            'Add one with the + button to link it to this '
                            'transaction.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: context.colors.textLight,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) => ContactTile(
                      contact: filtered[index],
                      onTap: () => Navigator.of(context).pop(filtered[index]),
                    ),
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                  ),
          ),
        ],
      ),
    );
  }
}