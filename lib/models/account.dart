class Account {
  final String name;
  final double balance;
  final String currency;
  final String? imageUrl;
  final String? tag;

  Account({
    required this.name,
    required this.balance,
    required this.currency,
    this.imageUrl,
    this.tag,
  });
}
