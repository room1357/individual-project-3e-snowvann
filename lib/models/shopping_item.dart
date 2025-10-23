class ShoppingItem {
  final String id;
  String name;
  int quantity;
  String category;
  bool isCompleted;

  ShoppingItem({
    required this.id,
    required this.name,
    this.quantity = 1,
    this.category = 'Lainnya',
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'category': category,
      'isCompleted': isCompleted,
    };
  }

  factory ShoppingItem.fromMap(Map<String, dynamic> map) {
    return ShoppingItem(
      id: map['id'],
      name: map['name'],
      quantity: map['quantity'] ?? 1,
      category: map['category'] ?? 'Lainnya',
      isCompleted: map['isCompleted'] ?? false,
    );
  }
}