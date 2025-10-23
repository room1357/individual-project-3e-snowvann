import 'package:flutter/material.dart';
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
  final TextEditingController _priceController = TextEditingController();
  
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
    
    try {
      final items = await _shoppingService.loadShoppingList(widget.username);
      setState(() {
        _shoppingList = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Gagal memuat daftar belanja');
    }
  }

  Future<void> _saveShoppingList() async {
    try {
      await _shoppingService.saveShoppingList(_shoppingList, widget.username);
    } catch (e) {
      _showErrorSnackBar('Gagal menyimpan daftar belanja');
    }
  }

  void _addItem(String name, int quantity, String category, double price) {
    final newItem = ShoppingItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      quantity: quantity,
      category: category,
      price: price,
    );
    
    setState(() {
      _shoppingList.add(newItem);
    });
    _saveShoppingList();
    _clearForm();
    _showSuccessSnackBar('Item berhasil ditambahkan');
  }

  void _updateItem(String id, String name, int quantity, String category, bool isCompleted, double price) {
    setState(() {
      final index = _shoppingList.indexWhere((item) => item.id == id);
      if (index != -1) {
        _shoppingList[index] = ShoppingItem(
          id: id,
          name: name,
          quantity: quantity,
          category: category,
          isCompleted: isCompleted,
          price: price,
          completedAt: _shoppingList[index].completedAt,
        );
      }
    });
    _saveShoppingList();
    _showSuccessSnackBar('Item berhasil diupdate');
  }

  void _deleteItem(String id) {
    final item = _shoppingList.firstWhere((item) => item.id == id);
    setState(() {
      _shoppingList.removeWhere((item) => item.id == id);
    });
    _saveShoppingList();
    _showUndoSnackBar('Item "${item.name}" dihapus', () {
      setState(() {
        _shoppingList.add(item);
      });
      _saveShoppingList();
    });
  }

  void _toggleItemCompletion(String id) {
    setState(() {
      final index = _shoppingList.indexWhere((item) => item.id == id);
      if (index != -1) {
        _shoppingList[index].isCompleted = !_shoppingList[index].isCompleted;
        if (_shoppingList[index].isCompleted) {
          _shoppingList[index].completedAt = DateTime.now();
        } else {
          _shoppingList[index].completedAt = null;
        }
      }
    });
    _saveShoppingList();
  }

  void _clearForm() {
    _nameController.clear();
    _quantityController.text = '1';
    _priceController.text = '';
    _selectedCategory = 'Lainnya';
  }

  void _showAddItemDialog({ShoppingItem? existingItem}) {
    final isEditing = existingItem != null;
    
    if (isEditing) {
      _nameController.text = existingItem.name;
      _quantityController.text = existingItem.quantity.toString();
      _priceController.text = existingItem.price > 0 ? existingItem.price.toStringAsFixed(0) : '';
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
                        labelText: 'Nama Item *',
                        border: OutlineInputBorder(),
                        hintText: 'Masukkan nama item',
                      ),
                      autofocus: true,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _quantityController,
                            decoration: const InputDecoration(
                              labelText: 'Jumlah *',
                              border: OutlineInputBorder(),
                              hintText: '1',
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: _priceController,
                            decoration: const InputDecoration(
                              labelText: 'Harga (Rp)',
                              border: OutlineInputBorder(),
                              prefixText: 'Rp ',
                              hintText: '0',
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Kategori *',
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
                    const SizedBox(height: 8),
                    Text(
                      '* Wajib diisi',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
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
                    final price = double.tryParse(_priceController.text) ?? 0.0;
                    
                    if (name.isNotEmpty && quantity > 0) {
                      if (isEditing) {
                        _updateItem(
                          existingItem!.id,
                          name,
                          quantity,
                          _selectedCategory,
                          existingItem.isCompleted,
                          price,
                        );
                      } else {
                        _addItem(name, quantity, _selectedCategory, price);
                      }
                      Navigator.pop(context);
                    } else {
                      _showErrorSnackBar('Nama item dan jumlah harus diisi');
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
    final completedCount = _shoppingList.where((item) => item.isCompleted).length;
    
    if (completedCount == 0) {
      _showInfoSnackBar('Tidak ada item yang selesai');
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Item Selesai'),
        content: Text('Hapus $completedCount item yang sudah selesai?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _shoppingList.removeWhere((item) => item.isCompleted);
              });
              _saveShoppingList();
              Navigator.pop(context);
              _showSuccessSnackBar('$completedCount item selesai dihapus');
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

  void _clearAllItems() {
    if (_shoppingList.isEmpty) {
      _showInfoSnackBar('Daftar belanja kosong');
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Semua Item'),
        content: const Text('Apakah Anda yakin ingin menghapus semua item? Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              final itemsCount = _shoppingList.length;
              setState(() {
                _shoppingList.clear();
              });
              _saveShoppingList();
              Navigator.pop(context);
              _showSuccessSnackBar('Semua $itemsCount item dihapus');
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

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Data'),
        content: const Text('Export daftar belanja ke file JSON?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                // Hapus variabel yang tidak digunakan
                await _shoppingService.exportShoppingList(widget.username);
                // TODO: Implement file download/save functionality
                if (mounted) {
                  Navigator.pop(context);
                  _showSuccessSnackBar('Data berhasil diexport');
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  _showErrorSnackBar('Gagal export data');
                }
              }
            },
            child: const Text('Export'),
          ),
        ],
      ),
    );
  }

  // SnackBar helpers
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showUndoSnackBar(String message, VoidCallback onUndo) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Batal',
          textColor: Colors.white,
          onPressed: onUndo,
        ),
      ),
    );
  }

  // Statistics calculations
  double get _totalSpending {
    return _shoppingList
        .where((item) => item.isCompleted)
        .fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  int get _completedTransactions {
    return _shoppingList.where((item) => item.isCompleted).length;
  }

  double get _completionRate {
    return _shoppingList.isNotEmpty ? (_completedTransactions / _shoppingList.length) * 100 : 0;
  }

  Map<String, List<ShoppingItem>> _groupByCategory() {
    final Map<String, List<ShoppingItem>> grouped = {};
    
    // Sort items: completed items first, then by name
    final sortedItems = List<ShoppingItem>.from(_shoppingList)
      ..sort((a, b) {
        if (a.isCompleted != b.isCompleted) {
          return a.isCompleted ? 1 : -1; // Uncompleted first
        }
        return a.name.compareTo(b.name);
      });
    
    for (final item in sortedItems) {
      if (!grouped.containsKey(item.category)) {
        grouped[item.category] = [];
      }
      grouped[item.category]!.add(item);
    }
    
    return grouped;
  }

  String _formatCurrency(double amount) {
    if (amount == 0) return '0';
    return amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final groupedItems = _groupByCategory();
    final totalItems = _shoppingList.length;
    final completedItems = _completedTransactions;
    final totalSpending = _totalSpending;
    final completionRate = _completionRate;

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
            IconButton(
              icon: const Icon(Icons.import_export),
              onPressed: _showExportDialog,
              tooltip: 'Export data',
            ),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Memuat daftar belanja...'),
                ],
              ),
            )
          : Column(
              children: [
                // User Info Card
                Card(
                  margin: const EdgeInsets.all(16),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.blue.shade100,
                          child: Text(
                            widget.username[0].toUpperCase(),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
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
                              const SizedBox(height: 4),
                              Text(
                                '${_shoppingList.length} item • ${completionRate.toStringAsFixed(1)}% selesai',
                                style: TextStyle(
                                  fontSize: 14,
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
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildSummaryItem('Total', totalItems.toString(), Colors.blue),
                              _buildSummaryItem('Selesai', '$completedItems', Colors.green),
                              _buildSummaryItem('Progress', '${completionRate.toStringAsFixed(0)}%', Colors.amber),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total Pengeluaran:',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.green.shade800,
                                  ),
                                ),
                                Text(
                                  'Rp ${_formatCurrency(totalSpending)}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ),
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
                                Icons.shopping_cart_outlined,
                                size: 80,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Belum ada item belanja!',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tambahkan item untuk ${widget.username}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: () => _showAddItemDialog(),
                                icon: const Icon(Icons.add),
                                label: const Text('Tambah Item Pertama'),
                              ),
                            ],
                          ),
                        )
                      : ListView(
                          children: [
                            ...groupedItems.entries.map((entry) {
                              return _buildCategorySection(entry.key, entry.value);
                            }),
                          ],
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddItemDialog(),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
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
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySection(String category, List<ShoppingItem> items) {
    final categorySpending = items
        .where((item) => item.isCompleted)
        .fold(0.0, (sum, item) => sum + item.totalPrice);
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  category,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                if (categorySpending > 0)
                  Text(
                    'Rp ${_formatCurrency(categorySpending)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.green.shade700,
                    ),
                  ),
              ],
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
        child: const Icon(Icons.delete, color: Colors.white, size: 24),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Hapus Item'),
            content: Text('Hapus "${item.name}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: const Text('Hapus'),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) => _deleteItem(item.id),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Colors.grey.shade200,
              width: 1,
            ),
          ),
        ),
        child: ListTile(
          leading: Checkbox(
            value: item.isCompleted,
            onChanged: (value) => _toggleItemCompletion(item.id),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          title: Text(
            item.name,
            style: TextStyle(
              fontSize: 16,
              decoration: item.isCompleted ? TextDecoration.lineThrough : null,
              color: item.isCompleted ? Colors.grey : Colors.black87,
              fontWeight: item.isCompleted ? FontWeight.normal : FontWeight.w500,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                'Jumlah: ${item.quantity}',
                style: TextStyle(
                  fontSize: 14,
                  color: item.isCompleted ? Colors.grey : Colors.grey[700],
                ),
              ),
              if (item.price > 0) ...[
                const SizedBox(height: 2),
                Text(
                  'Harga: Rp ${_formatCurrency(item.totalPrice)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: item.isCompleted ? Colors.grey : Colors.green.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              if (item.completedAt != null) ...[
                const SizedBox(height: 2),
                Text(
                  'Selesai: ${_formatDate(item.completedAt)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, size: 20),
                color: Colors.blue,
                onPressed: () => _showAddItemDialog(existingItem: item),
                tooltip: 'Edit item',
              ),
              IconButton(
                icon: const Icon(Icons.delete, size: 20),
                color: Colors.red.shade400,
                onPressed: () => _showDeleteConfirmation(item.id, item.name),
                tooltip: 'Hapus item',
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }
}