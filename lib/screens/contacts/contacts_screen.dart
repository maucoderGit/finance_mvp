import 'package:drift/drift.dart' as drift;
import 'package:finance_mvp/constants/app_colors.dart';
import 'package:finance_mvp/database/app_database.dart' as db;
import 'package:finance_mvp/repositories/finance_repository.dart';
import 'package:finance_mvp/screens/contacts/contact_widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Settings view of all contacts: search, add, edit (tap), delete (trash).
class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
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

  Future<void> _addContact() async {
    final repo = context.read<FinanceRepository>();
    final result = await showContactFormSheet(context);
    if (result == null) return;
    await repo.findOrCreateContact(result.name, phone: result.phone);
    await _load();
  }

  Future<void> _editContact(db.Contact contact) async {
    final repo = context.read<FinanceRepository>();
    final result = await showContactFormSheet(context, contact: contact);
    if (result == null) return;
    await repo.updateContact(contact.copyWith(
      name: result.name,
      phone: drift.Value(result.phone.isEmpty ? null : result.phone),
    ));
    await _load();
  }

  Future<void> _deleteContact(db.Contact contact) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete contact?'),
        content: Text(
          'This removes "${contact.name}" from your contacts. Linked '
          'transactions keep their history but lose the name.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!mounted) return;
    final repo = context.read<FinanceRepository>();
    await repo.deleteContact(contact.id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: const Text('Contacts'),
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
            onPressed: _addContact,
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
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final contact = filtered[index];
                      return ContactTile(
                        contact: contact,
                        onTap: () => _editContact(contact),
                        trailing: IconButton(
                          tooltip: 'Delete',
                          icon: Icon(Icons.delete_outline,
                              color: context.colors.textLight),
                          onPressed: () => _deleteContact(contact),
                        ),
                      );
                    },
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                  ),
          ),
        ],
      ),
    );
  }
}