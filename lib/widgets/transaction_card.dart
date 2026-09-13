import 'package:flutter/material.dart';

class TransactionCard extends StatelessWidget {
  final String title;
  final double amount;
  final String displayAmount;
  final String? description;
  final String? iconPath; // For custom icons like Revolut, BeHance, OKX
  final IconData? defaultIcon; // For a default icon if path is not provided
  final Color? iconBackgroundColor; // Background color for the icon container
  final bool isTotalCard; // To differentiate the "Total" card style

  const TransactionCard({
    super.key,
    required this.title,
    required this.amount,
    required this.displayAmount,
    this.iconPath,
    this.description,
    this.defaultIcon,
    this.iconBackgroundColor,
    this.isTotalCard = false,
  });

  @override
  Widget build(BuildContext context) {
    Color amountColor = amount > 0 ? Colors.green : Colors.red;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18), // Rounded corners
      ),
      elevation: 0, // Slightly higher elevation for total card
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
        child: Row(
          children: [
            // Icon/Logo Section
            if (!isTotalCard) // Don't show icon for "Total" card
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconBackgroundColor ?? Colors.grey[200], // Default grey
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: iconPath != null
                      ? Image.asset(
                          iconPath!,
                          width: 30, // Adjust size as needed for logos
                          height: 30,
                        )
                      : (defaultIcon != null
                          ? Icon(defaultIcon, color: Colors.grey[700])
                          : null),
                ),
              ),
            if (!isTotalCard) const SizedBox(width: 16),
            // Title Section
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(right: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: isTotalCard ? 20 : 18,
                        fontWeight: isTotalCard ? FontWeight.bold : FontWeight.w600,
                        color: isTotalCard ? Colors.black : Colors.black87,
                      ),
                    ),
                    // Subtitles
                    if (!isTotalCard)
                      Row(children: [
                        Text(description ?? "TEsT", style: const TextStyle(color: Colors.grey)),
                        const SizedBox(width: 5),
                        if (description == null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Category', // Replace with actual category data
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ]
                      )
                  ]
                )
              ),
            ),
            // Amount Section
            Text(
              displayAmount,
              style: TextStyle(
                fontSize: isTotalCard ? 18 : 16,
                fontWeight: isTotalCard ? FontWeight.bold : FontWeight.w600,
                color: isTotalCard ? Colors.black : amountColor, // Green for amounts
              ),
            ),
          ],
        ),
      ),
    );
  }
}
