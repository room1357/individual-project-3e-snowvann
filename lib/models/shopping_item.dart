// models/shopping_item.dart
class ShoppingItem {
  final String id;
  final String name;
  final int quantity;
  final String category;
  final double price;
  bool isCompleted;
  DateTime? completedAt;

  ShoppingItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.category,
    required this.price,
    this.isCompleted = false,
    this.completedAt,
  });

  double get totalPrice => price * quantity;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'category': category,
      'price': price,
      'isCompleted': isCompleted,
      'completedAt': completedAt?.millisecondsSinceEpoch,
    };
  }

  factory ShoppingItem.fromMap(Map<String, dynamic> map) {
    return ShoppingItem(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      quantity: map['quantity'] ?? 1,
      category: map['category'] ?? 'Lainnya',
      price: (map['price'] ?? 0.0).toDouble(),
      isCompleted: map['isCompleted'] ?? false,
      completedAt: map['completedAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['completedAt'])
          : null,
    );
  }
}