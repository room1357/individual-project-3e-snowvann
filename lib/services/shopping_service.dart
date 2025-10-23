import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/shopping_item.dart';

class ShoppingService {
  static const String _shoppingListKeyPrefix = 'shopping_list_';
  static const String _statisticsKeyPrefix = 'statistics_';
  
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

  // Key untuk statistics
  String _getStatisticsKey(String username) {
    return '${_statisticsKeyPrefix}${username.toLowerCase()}';
  }

  // Save shopping list to SharedPreferences for specific user
  Future<void> saveShoppingList(List<ShoppingItem> items, String username) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> itemsJson = items.map((item) {
        return jsonEncode(item.toMap());
      }).toList();
      await prefs.setStringList(_getUserKey(username), itemsJson);
      
      // Update statistics setiap kali save shopping list
      await _updateStatistics(items, username);
    } catch (e) {
      throw Exception('Gagal menyimpan daftar belanja: $e');
    }
  }

  // Update statistics berdasarkan shopping list
  Future<void> _updateStatistics(List<ShoppingItem> items, String username) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Hitung statistik
      final completedItems = items.where((item) => item.isCompleted).toList();
      final totalTransactions = completedItems.length;
      final totalSpending = completedItems.fold(0.0, (sum, item) => sum + item.totalPrice);
      
      // Simpan statistik
      final statistics = {
        'totalTransactions': totalTransactions,
        'totalSpending': totalSpending,
        'lastUpdated': DateTime.now().millisecondsSinceEpoch,
        'totalItems': items.length,
        'completedItems': completedItems.length,
      };
      
      await prefs.setString(_getStatisticsKey(username), jsonEncode(statistics));
    } catch (e) {
      throw Exception('Gagal update statistik: $e');
    }
  }

  // Load statistics for user
  Future<Map<String, dynamic>> loadStatistics(String username) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final statisticsJson = prefs.getString(_getStatisticsKey(username));
      
      if (statisticsJson == null) {
        return {
          'totalTransactions': 0,
          'totalSpending': 0.0,
          'lastUpdated': DateTime.now().millisecondsSinceEpoch,
          'totalItems': 0,
          'completedItems': 0,
        };
      }

      final statistics = jsonDecode(statisticsJson);
      return {
        'totalTransactions': statistics['totalTransactions'] ?? 0,
        'totalSpending': statistics['totalSpending'] ?? 0.0,
        'lastUpdated': statistics['lastUpdated'] ?? DateTime.now().millisecondsSinceEpoch,
        'totalItems': statistics['totalItems'] ?? 0,
        'completedItems': statistics['completedItems'] ?? 0,
      };
    } catch (e) {
      return {
        'totalTransactions': 0,
        'totalSpending': 0.0,
        'lastUpdated': DateTime.now().millisecondsSinceEpoch,
        'totalItems': 0,
        'completedItems': 0,
      };
    }
  }

  // Load shopping list from SharedPreferences for specific user
  Future<List<ShoppingItem>> loadShoppingList(String username) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String>? itemsJson = prefs.getStringList(_getUserKey(username));
      
      if (itemsJson == null) {
        return [];
      }

      final items = itemsJson.map((json) {
        try {
          final Map<String, dynamic> map = jsonDecode(json);
          return ShoppingItem.fromMap(map);
        } catch (e) {
          // Return default item untuk data yang corrupt
          return ShoppingItem(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            name: 'Item Tidak Valid',
            quantity: 1,
            category: 'Lainnya',
            price: 0.0,
          );
        }
      }).toList();

      // Filter out null values dan return list yang valid
      return items.where((item) => item.name.isNotEmpty).toList();
    } catch (e) {
      throw Exception('Gagal memuat daftar belanja: $e');
    }
  }

  // Clear shopping data for specific user
  Future<void> clearShoppingList(String username) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_getUserKey(username));
      await prefs.remove(_getStatisticsKey(username));
    } catch (e) {
      throw Exception('Gagal menghapus daftar belanja: $e');
    }
  }

  // Clear only statistics for user
  Future<void> clearStatistics(String username) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_getStatisticsKey(username));
    } catch (e) {
      throw Exception('Gagal menghapus statistik: $e');
    }
  }

  // Reset statistics to zero but keep shopping list
  Future<void> resetStatistics(String username) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final statistics = {
        'totalTransactions': 0,
        'totalSpending': 0.0,
        'lastUpdated': DateTime.now().millisecondsSinceEpoch,
        'totalItems': 0,
        'completedItems': 0,
      };
      await prefs.setString(_getStatisticsKey(username), jsonEncode(statistics));
    } catch (e) {
      throw Exception('Gagal reset statistik: $e');
    }
  }

  // Get shopping list summary (quick stats without loading all items)
  Future<Map<String, dynamic>> getShoppingSummary(String username) async {
    try {
      final items = await loadShoppingList(username);
      final totalItems = items.length;
      final completedItems = items.where((item) => item.isCompleted).length;
      final totalSpending = items
          .where((item) => item.isCompleted)
          .fold(0.0, (sum, item) => sum + item.totalPrice);
      final pendingItems = totalItems - completedItems;

      return {
        'totalItems': totalItems,
        'completedItems': completedItems,
        'pendingItems': pendingItems,
        'totalSpending': totalSpending,
        'completionRate': totalItems > 0 ? (completedItems / totalItems) * 100 : 0,
      };
    } catch (e) {
      return {
        'totalItems': 0,
        'completedItems': 0,
        'pendingItems': 0,
        'totalSpending': 0.0,
        'completionRate': 0,
      };
    }
  }

  // Get recent completed items (last 7 days)
  Future<List<ShoppingItem>> getRecentCompletedItems(String username, {int days = 7}) async {
    try {
      final items = await loadShoppingList(username);
      final cutoffDate = DateTime.now().subtract(Duration(days: days));
      
      return items.where((item) {
        return item.isCompleted && 
               item.completedAt != null && 
               item.completedAt!.isAfter(cutoffDate);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // Get spending by category
  Future<Map<String, double>> getSpendingByCategory(String username) async {
    try {
      final items = await loadShoppingList(username);
      final completedItems = items.where((item) => item.isCompleted);
      
      final spendingByCategory = <String, double>{};
      
      for (final item in completedItems) {
        final category = item.category;
        final totalPrice = item.totalPrice;
        
        spendingByCategory[category] = (spendingByCategory[category] ?? 0) + totalPrice;
      }
      
      return spendingByCategory;
    } catch (e) {
      return {};
    }
  }

  // Get monthly statistics
  Future<Map<String, dynamic>> getMonthlyStatistics(String username, int year, int month) async {
    try {
      final items = await loadShoppingList(username);
      final monthlyItems = items.where((item) {
        if (!item.isCompleted || item.completedAt == null) return false;
        
        final completedDate = item.completedAt!;
        return completedDate.year == year && completedDate.month == month;
      }).toList();
      
      final totalSpending = monthlyItems.fold(0.0, (sum, item) => sum + item.totalPrice);
      final transactions = monthlyItems.length;
      
      return {
        'transactions': transactions,
        'totalSpending': totalSpending,
        'averageSpending': transactions > 0 ? totalSpending / transactions : 0,
        'items': monthlyItems,
      };
    } catch (e) {
      return {
        'transactions': 0,
        'totalSpending': 0.0,
        'averageSpending': 0,
        'items': [],
      };
    }
  }

  // Export shopping list as JSON string
  Future<String> exportShoppingList(String username) async {
    try {
      final items = await loadShoppingList(username);
      final exportData = {
        'exportedAt': DateTime.now().toIso8601String(),
        'username': username,
        'totalItems': items.length,
        'items': items.map((item) => item.toMap()).toList(),
      };
      return jsonEncode(exportData);
    } catch (e) {
      throw Exception('Gagal export daftar belanja: $e');
    }
  }

  // Import shopping list from JSON string
  Future<void> importShoppingList(String username, String jsonData) async {
    try {
      final importData = jsonDecode(jsonData);
      final itemsData = importData['items'] as List<dynamic>;
      
      final items = itemsData.map((itemData) {
        return ShoppingItem.fromMap(Map<String, dynamic>.from(itemData));
      }).toList();
      
      await saveShoppingList(items, username);
    } catch (e) {
      throw Exception('Gagal import daftar belanja: $e');
    }
  }

  // Get all users that have shopping lists (for admin purposes)
  Future<List<String>> getAllUsersWithData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      return keys
          .where((key) => key.startsWith(_shoppingListKeyPrefix))
          .map((key) => key.replaceFirst(_shoppingListKeyPrefix, ''))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Backup all data for user
  Future<Map<String, dynamic>> backupUserData(String username) async {
    try {
      final items = await loadShoppingList(username);
      final statistics = await loadStatistics(username);
      
      return {
        'username': username,
        'backupAt': DateTime.now().toIso8601String(),
        'shoppingList': items.map((item) => item.toMap()).toList(),
        'statistics': statistics,
      };
    } catch (e) {
      throw Exception('Gagal backup data: $e');
    }
  }

  // Restore user data from backup
  Future<void> restoreUserData(String username, Map<String, dynamic> backupData) async {
    try {
      final itemsData = backupData['shoppingList'] as List<dynamic>;
      final items = itemsData.map((itemData) {
        return ShoppingItem.fromMap(Map<String, dynamic>.from(itemData));
      }).toList();
      
      await saveShoppingList(items, username);
    } catch (e) {
      throw Exception('Gagal restore data: $e');
    }
  }
}