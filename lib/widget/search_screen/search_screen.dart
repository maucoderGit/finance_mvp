import 'package:finance_mvp/widget/search_screen/search_element_card.dart';
import 'package:flutter/material.dart';
import 'search_element.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  // Mock data - replace this with your actual data from an API
  final List<SearchItem> searchItems = [
    SearchItem(
      name: 'Mercantil Bank',
      price: 300,
      imageUrl: null,
      tag: 'BS',
    ),
    SearchItem(
      name: 'Banesco',
      price: 150,
      imageUrl: null,
    ),
    SearchItem(
      name: 'BBVA',
      price: 125,
      imageUrl: null, // This item will display the gray placeholder
      tag: 'USD',
    ),
    SearchItem(
      name: 'Paypal',
      price: 490,
      imageUrl: null,
    ),
  ];

  List<SearchItem> _filteredItems = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredItems = searchItems;
    _searchController.addListener(_filterSearchResults);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterSearchResults() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      _filteredItems = searchItems
          .where((item) => item.name.toLowerCase().contains(query))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search products...',
            prefixIcon: const Icon(Icons.search, color: Colors.black54),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.grey[200],
            contentPadding:
                const EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
          ),
          style: const TextStyle(color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        // Remove the default back button if it appears
        automaticallyImplyLeading: true,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // 2 items per row
          crossAxisSpacing: 12, // Horizontal space between cards
          mainAxisSpacing: 12, // Vertical space between cards
          childAspectRatio:
          4, // Adjust to change the card's height-to-width ratio
        ),
        itemCount: _filteredItems.length,
        itemBuilder: (context, index) {
          return SearchElementCard(product: _filteredItems[index]);
        },
      ),
    );
  }
}