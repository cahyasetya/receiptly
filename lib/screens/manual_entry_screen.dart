import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/index.dart';
import '../services/index.dart';
import 'categorize_screen.dart';

class ManualEntryScreen extends StatefulWidget {
  final ExpenseRepository repository;

  const ManualEntryScreen({
    super.key,
    required this.repository,
  });

  @override
  State<ManualEntryScreen> createState() => _ManualEntryScreenState();
}

class _ManualEntryScreenState extends State<ManualEntryScreen> {
  final List<_ManualItem> _items = [];
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final FocusNode _nameFocus = FocusNode();
  final FocusNode _priceFocus = FocusNode();

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _nameFocus.dispose();
    _priceFocus.dispose();
    super.dispose();
  }

  void _addItem() {
    final name = _nameController.text.trim();
    final priceText = _priceController.text.trim().replaceAll('.', '').replaceAll(',', '.');

    if (name.isEmpty) {
      _showError('Nama item tidak boleh kosong');
      return;
    }

    final price = double.tryParse(priceText);
    if (price == null || price <= 0) {
      _showError('Harga tidak valid');
      return;
    }

    setState(() {
      _items.add(_ManualItem(name: name, price: price));
      _nameController.clear();
      _priceController.clear();
    });

    _nameFocus.requestFocus();
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _proceedToCategorize() async {
    if (_items.isEmpty) {
      _showError('Tambahkan minimal 1 item');
      return;
    }

    final ocrItems = _items
        .map((item) => OCRItem(
              name: item.name,
              price: item.price,
              source: InputMode.manual,
            ))
        .toList();

    if (!mounted) return;

    final result = await Navigator.push<Expense>(
      context,
      MaterialPageRoute(
        builder: (context) => CategorizeScreen(
          items: ocrItems,
          ocrText: 'Input Manual',
          repository: widget.repository,
          source: InputMode.manual,
        ),
      ),
    );

    if (result != null && mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Input Manual'),
        actions: [
          if (_items.isNotEmpty)
            TextButton(
              onPressed: _proceedToCategorize,
              child: const Text('Lanjut'),
            ),
        ],
      ),
      body: Column(
        children: [
          // Input form
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[900] : Colors.grey[100],
              border: Border(
                bottom: BorderSide(
                  color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _nameController,
                  focusNode: _nameFocus,
                  decoration: const InputDecoration(
                    labelText: 'Nama Item',
                    hintText: 'Contoh: Nasi Goreng',
                    border: OutlineInputBorder(),
                  ),
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) => _priceFocus.requestFocus(),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _priceController,
                        focusNode: _priceFocus,
                        decoration: const InputDecoration(
                          labelText: 'Harga',
                          hintText: 'Contoh: 15000',
                          border: OutlineInputBorder(),
                          prefixText: 'Rp ',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                        ],
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _addItem(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _addItem,
                      child: const Icon(Icons.add),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Item list
          Expanded(
            child: _items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long,
                          size: 64,
                          color: isDark ? Colors.grey[700] : Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Belum ada item',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: isDark ? Colors.grey[500] : Colors.grey[600],
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tambahkan item di atas',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: isDark ? Colors.grey[600] : Colors.grey[500],
                              ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(item.name),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Rp${item.price.toStringAsFixed(0)}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: () => _removeItem(index),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Total and continue button
          if (_items.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[900] : Colors.white,
                border: Border(
                  top: BorderSide(
                    color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Total (${_items.length} item)',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          'Rp${_items.fold<double>(0, (sum, item) => sum + item.price).toStringAsFixed(0)}',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _proceedToCategorize,
                    child: const Text('Lanjut ke Kategori'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ManualItem {
  final String name;
  final double price;

  _ManualItem({required this.name, required this.price});
}
