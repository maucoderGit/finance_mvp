class SearchItem {
  final String name;
  final double price;
  final String? imageUrl; // Nullable to handle missing images
  final String? tag; // Optional tag like "New"
  final String? category;
  final int? categoryId;

  SearchItem({
    required this.name,
    required this.price,
    this.imageUrl,
    this.tag,
    this.category,
    this.categoryId
  });
}