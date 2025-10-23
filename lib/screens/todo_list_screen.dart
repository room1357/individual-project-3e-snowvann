import 'package:flutter/material.dart';
import 'dart:convert';
import '../models/shopping_item.dart';
import '../services/shopping_service.dart';

class TodoListScreen extends StatefulWidget {
  final String username;
  
  const TodoListScreen({super.key, required this.username});

  @override
  State<TodoListScreen> createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  final ShoppingService _shoppingService = ShoppingService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  
  List<ShoppingItem> _shoppingList = [];
  String _selectedCategory = 'Lainnya';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadShoppingList();
  }

  Future<void> _loadShoppingList() async {
    setState(() {
      _isLoading = true;
    });
    
    final items = await _shoppingService.loadShoppingList(widget.username);
    setState(() {
      _shoppingList = items;
      _isLoading = false;
    });
  }

  Future<void> _saveShoppingList() async {
    await _shoppingService.saveShoppingList(_shoppingList, widget.username);
  }

  void _addItem(String name, int quantity, String category) {
    final newItem = ShoppingItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      quantity: quantity,
      category: category,
    );
    
    setState(() {
      _shoppingList.add(newItem);
    });
    _saveShoppingList();
    _clearForm();
  }

  void _updateItem(String id, String name, int quantity, String category, bool isCompleted) {
    setState(() {
      final index = _shoppingList.indexWhere((item) => item.id == id);
      if (index != -1) {
        _shoppingList[index] = ShoppingItem(
          id: id,
          name: name,
          quantity: quantity,
          category: category,
          isCompleted: isCompleted,
        );
      }
    });
    _saveShoppingList();
  }

  void _deleteItem(String id) {
    setState(() {
      _shoppingList.removeWhere((item) => item.id == id);
    });
    _saveShoppingList();
  }

  void _toggleItemCompletion(String id) {
    setState(() {
      final index = _shoppingList.indexWhere((item) => item.id == id);
      if (index != -1) {
        _shoppingList[index].isCompleted = !_shoppingList[index].isCompleted;
      }
    });
    _saveShoppingList();
  }

  void _clearForm() {
    _nameController.clear();
    _quantityController.text = '1';
    _selectedCategory = 'Lainnya';
  }

  void _showAddItemDialog({ShoppingItem? existingItem}) {
    final isEditing = existingItem != null;
    
    if (isEditing) {
      _nameController.text = existingItem.name;
      _quantityController.text = existingItem.quantity.toString();
      _selectedCategory = existingItem.category;
    } else {
      _clearForm();
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isEditing ? 'Edit Item' : 'Tambah Item Baru'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Item',
                        border: OutlineInputBorder(),
                      ),
                      autofocus: true,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _quantityController,
                      decoration: const InputDecoration(
                        labelText: 'Jumlah',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Kategori',
                        border: OutlineInputBorder(),
                      ),
                      items: _shoppingService.getCategories().map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          _selectedCategory = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _clearForm();
                  },
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final name = _nameController.text.trim();
                    final quantity = int.tryParse(_quantityController.text) ?? 1;
                    
                    if (name.isNotEmpty) {
                      if (isEditing) {
                        _updateItem(
                          existingItem!.id,
                          name,
                          quantity,
                          _selectedCategory,
                          existingItem.isCompleted,
                        );
                      } else {
                        _addItem(name, quantity, _selectedCategory);
                      }
                      Navigator.pop(context);
                    }
                  },
                  child: Text(isEditing ? 'Simpan' : 'Tambah'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteConfirmation(String id, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Item'),
        content: Text('Apakah Anda yakin ingin menghapus "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              _deleteItem(id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _clearCompletedItems() {
    setState(() {
      _shoppingList.removeWhere((item) => item.isCompleted);
    });
    _saveShoppingList();
  }

  void _clearAllItems() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Semua'),
        content: const Text('Apakah Anda yakin ingin menghapus semua item?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _shoppingList.clear();
              });
              _saveShoppingList();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Hapus Semua'),
          ),
        ],
      ),
    );
  }

  Map<String, List<ShoppingItem>> _groupByCategory() {
    final Map<String, List<ShoppingItem>> grouped = {};
    
    for (final item in _shoppingList) {
      if (!grouped.containsKey(item.category)) {
        grouped[item.category] = [];
      }
      grouped[item.category]!.add(item);
    }
    
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final groupedItems = _groupByCategory();
    final totalItems = _shoppingList.length;
    final completedItems = _shoppingList.where((item) => item.isCompleted).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Daftar Belanja',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.blue,
        actions: [
          if (_shoppingList.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: _clearCompletedItems,
              tooltip: 'Hapus yang selesai',
            ),
            IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: _clearAllItems,
              tooltip: 'Hapus semua',
            ),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // User Info Card
                Card(
                  margin: const EdgeInsets.all(16),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.blue.shade100,
                          child: Text(
                            widget.username[0].toUpperCase(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Daftar Belanja ${widget.username}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${_shoppingList.length} item',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Summary Card
                if (_shoppingList.isNotEmpty)
                  Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildSummaryItem('Total', totalItems.toString(), Colors.blue),
                          _buildSummaryItem('Selesai', completedItems.toString(), Colors.green),
                          _buildSummaryItem('Belum', (totalItems - completedItems).toString(), Colors.orange),
                        ],
                      ),
                    ),
                  ),
                
                // Shopping List
                Expanded(
                  child: _shoppingList.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.shopping_cart,
                                size: 80,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Belum ada item belanja!',
                                style: TextStyle(fontSize: 16, color: Colors.grey),
                              ),
                              Text(
                                'Tambahkan item untuk ${widget.username}',
                                style: const TextStyle(fontSize: 14, color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : ListView(
                          children: [
                            ...groupedItems.entries.map((entry) {
                              return _buildCategorySection(entry.key, entry.value);
                            }).toList(),
                          ],
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddItemDialog(),
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, MaterialColor color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildCategorySection(String category, List<ShoppingItem> items) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              category,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ),
          ...items.map((item) => _buildShoppingItem(item)),
        ],
      ),
    );
  }

  Widget _buildShoppingItem(ShoppingItem item) {
    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) => _deleteItem(item.id),
      child: ListTile(
        leading: Checkbox(
          value: item.isCompleted,
          onChanged: (value) => _toggleItemCompletion(item.id),
        ),
        title: Text(
          item.name,
          style: TextStyle(
            fontSize: 16,
            decoration: item.isCompleted ? TextDecoration.lineThrough : null,
            color: item.isCompleted ? Colors.grey : Colors.black,
          ),
        ),
        subtitle: Text(
          'Jumlah: ${item.quantity}',
          style: TextStyle(
            color: item.isCompleted ? Colors.grey : null,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              color: Colors.blue,
              onPressed: () => _showAddItemDialog(existingItem: item),
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 20),
              color: Colors.red,
              onPressed: () => _showDeleteConfirmation(item.id, item.name),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }
}