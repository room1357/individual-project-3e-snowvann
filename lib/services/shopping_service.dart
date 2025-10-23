import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/shopping_item.dart';

class ShoppingService {
  static const String _shoppingListKeyPrefix = 'shopping_list_';
  static const List<String> _categories = [
    'Buah & Sayur',
    'Daging & Ikan',
    'Susu & Telur',
    'Roti & Makanan Ringan',
    'Minuman',
    'Bahan Pokok',
    'Kebutuhan Rumah Tangga',
    'Lainnya'
  ];

  // Get all categories
  List<String> getCategories() {
    return _categories;
  }

  // Generate unique key for each user
  String _getUserKey(String username) {
    return '${_shoppingListKeyPrefix}${username.toLowerCase()}';
  }

  // Save shopping list to SharedPreferences for specific user
  Future<void> saveShoppingList(List<ShoppingItem> items, String username) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> itemsJson = items.map((item) {
      return jsonEncode(item.toMap());
    }).toList();
    await prefs.setStringList(_getUserKey(username), itemsJson);
  }

  // Load shopping list from SharedPreferences for specific user
  Future<List<ShoppingItem>> loadShoppingList(String username) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? itemsJson = prefs.getStringList(_getUserKey(username));
    
    if (itemsJson == null) {
      return [];
    }

    return itemsJson.map((json) {
      try {
        final Map<String, dynamic> map = jsonDecode(json);
        return ShoppingItem.fromMap(map);
      } catch (e) {
        // Handle corrupted data
        return ShoppingItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: 'Item Corrupted',
          quantity: 1,
          category: 'Lainnya',
        );
      }
    }).toList();
  }

  // Clear shopping data for specific user
  Future<void> clearShoppingList(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_getUserKey(username));
  }

  // Get all users that have shopping lists (for admin purposes)
  Future<List<String>> getAllUsersWithData() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    return keys
        .where((key) => key.startsWith(_shoppingListKeyPrefix))
        .map((key) => key.replaceFirst(_shoppingListKeyPrefix, ''))
        .toList();
  }
}