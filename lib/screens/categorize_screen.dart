import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/index.dart';
import '../services/index.dart';
import '../widgets/index.dart';

class CategorizeScreen extends StatefulWidget {
  final String? imagePath;
  final String ocrText;
  final List<OCRItem> items;
  final double totalAmount;
  final ExpenseRepository repository;
  final InputMode source;

  const CategorizeScreen({
    super.key,
    this.imagePath,
    this.ocrText = '',
    this.items = const [],
    this.totalAmount = 0,
    required this.repository,
    this.source = InputMode.ai,
  });

  @override
  State<CategorizeScreen> createState() => _CategorizeScreenState();
}

class _CategorizeScreenState extends State<CategorizeScreen> {
  List<ExpenseItem> _expenseItems = [];
  List<List<ExpenseCategory>> _itemSuggestions = [];
  List<Category> _categories = [];
  List<String?> _customCategoryIds = [];
  final TextEditingController _notesController = TextEditingController();
  bool _isSaving = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final cats = await widget.repository.getCategories();
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _categories = cats;
      _expenseItems = [];
      _itemSuggestions = [];
      _customCategoryIds = [];
      for (final item in widget.items) {
        final aiCategory = item.category != null
            ? ExpenseCategory.fromString(item.category!)
            : null;
        _expenseItems.add(ExpenseItem(
          name: item.name,
          price: item.price,
          category: aiCategory ?? CategorizationService.guessCategory(item.name),
        ));
        _itemSuggestions.add(CategorizationService.guessCategories(item.name));
        _customCategoryIds.add(null);
      }
    });
  }

  ExpenseCategory _primaryCategory() {
    if (_expenseItems.isEmpty) return ExpenseCategory.other;
    // Prefer a non-other, non-custom category
    for (final item in _expenseItems) {
      if (item.category != ExpenseCategory.other) return item.category;
    }
    // All are 'other' or custom — pick the first custom name or other
    final custom = _expenseItems.firstWhere(
      (i) => i.customCategoryName != null,
      orElse: () => _expenseItems.first,
    );
    return custom.category;
  }

  String? _primaryCustomCategoryName() {
    for (final item in _expenseItems) {
      if (item.customCategoryName != null) return item.customCategoryName;
    }
    return null;
  }

  Future<void> _saveExpense() async {
    setState(() => _isSaving = true);
    try {
    final total = widget.totalAmount > 0 ? widget.totalAmount : _expenseItems.fold<double>(0, (s, i) => s + i.price);
      final expense = Expense(
        imagePath: widget.imagePath ?? '',
        amount: total,
        category: _primaryCategory(),
        customCategoryName: _primaryCustomCategoryName(),
        date: DateTime.now(),
        ocrText: widget.ocrText,
        notes: _notesController.text,
        items: _expenseItems,
      );

      await widget.repository.addExpense(expense);

      if (mounted) {
        Navigator.pop(context, expense);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Kategorikan Item')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final total = _expenseItems.fold<double>(0, (s, i) => s + i.price);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kategorikan Item'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Total badge
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Total ${_expenseItems.length} item',
                        style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        NumberFormat.currency(
                          locale: 'id',
                          symbol: 'Rp',
                          decimalDigits: 0,
                        ).format(total),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Itemized section
              if (_expenseItems.isNotEmpty) ...[
                const Text(
                  'Item',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _expenseItems.length,
                  itemBuilder: (context, index) {
                    final item = _expenseItems[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    item.name,
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                ),
                                if (item.price > 0)
                                  Text(
                                    NumberFormat.currency(
                                      locale: 'id',
                                      symbol: 'Rp',
                                      decimalDigits: 0,
                                    ).format(item.price),
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  )
                                else
                                  SizedBox(
                                    width: 120,
                                    child: TextField(
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.end,
                                      decoration: const InputDecoration(
                                        prefixText: 'Rp ',
                                        isDense: true,
                                        hintText: '0',
                                        border: OutlineInputBorder(),
                                      ),
                                      onSubmitted: (value) {
                                        final price = double.tryParse(value.replaceAll('.', '').replaceAll(',', '.'));
                                        if (price != null && price > 0) {
                                          setState(() {
                                            _expenseItems[index] = ExpenseItem(
                                              name: item.name,
                                              price: price,
                                              category: item.category,
                                            );
                                          });
                                        }
                                      },
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            CategorySelector(
                              selectedCategory: item.category,
                              suggestions: _itemSuggestions[index],
                              categories: _categories,
                              selectedCategoryId: _customCategoryIds[index],
                              onCategorySelected: (category) {
                                setState(() {
                                  _expenseItems[index] = ExpenseItem(
                                    name: item.name,
                                    price: item.price,
                                    category: category,
                                  );
                                  _customCategoryIds[index] = null;
                                });
                              },
                              onCategoryChosen: (cat) {
                                setState(() {
                                  _expenseItems[index] = ExpenseItem(
                                    name: item.name,
                                    price: item.price,
                                    category: ExpenseCategory.other,
                                    customCategoryName: cat.name,
                                  );
                                  _customCategoryIds[index] = cat.id;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
              ],

              // Notes field
              const Text(
                'Catatan (Opsional)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Tambahkan catatan...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Save button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveExpense,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Simpan Pengeluaran',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }
}
