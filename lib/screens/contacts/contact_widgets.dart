import 'package:finance_mvp/constants/app_colors.dart';
import 'package:finance_mvp/database/app_database.dart' as db;
import 'package:flutter/material.dart';

String initialsFor(String name) {
  final letters = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .take(2)
      .map((w) => w[0].toUpperCase())
      .join();
  return letters.isEmpty ? '?' : letters;
}

class ContactAvatar extends StatelessWidget {
  final String name;
  final double size;
  const ContactAvatar({super.key, required this.name, this.size = 44});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: context.colors.fieldsBackground,
      ),
      alignment: Alignment.center,
      child: Text(
        initialsFor(name),
        style: TextStyle(
          fontSize: size * 0.32,
          fontWeight: FontWeight.w600,
          color: context.colors.primary,
        ),
      ),
    );
  }
}

/// Card row used by both the contact picker and the contacts manager.
class ContactTile extends StatelessWidget {
  final db.Contact contact;
  final Widget? trailing;
  final VoidCallback? onTap;
  const ContactTile({
    super.key,
    required this.contact,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colors.cardBackground,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              ContactAvatar(name: contact.name),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contact.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: context.colors.textDark,
                      ),
                    ),
                    if (contact.phone?.trim().isNotEmpty == true)
                      Text(
                        contact.phone!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: context.colors.textLight,
                        ),
                      ),
                  ],
                ),
              ),
              trailing ??
                  Icon(Icons.chevron_right, color: context.colors.textLight),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shared name/phone form for creating or editing a contact. Returns the
/// entered values (name trimmed, non-empty) or null when dismissed.
Future<({String name, String phone})?> showContactFormSheet(
  BuildContext context, {
  db.Contact? contact,
}) {
  return showModalBottomSheet<({String name, String phone})>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.colors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      final nameController =
          TextEditingController(text: contact?.name ?? '');
      final phoneController =
          TextEditingController(text: contact?.phone ?? '');
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              contact == null ? 'New contact' : 'Edit contact',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: context.colors.textDark,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 48,
              child: TextField(
                controller: nameController,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Name',
                  hintText: 'e.g. La Casa Bakery',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 48,
              child: TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone (optional)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  final name = nameController.text.trim();
                  if (name.isEmpty) return;
                  Navigator.of(sheetContext).pop((
                    name: name,
                    phone: phoneController.text.trim(),
                  ));
                },
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  backgroundColor: Theme.of(context).primaryColor,
                ),
                child: Text(
                  contact == null ? 'Add contact' : 'Save changes',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      );
    },
  );
}