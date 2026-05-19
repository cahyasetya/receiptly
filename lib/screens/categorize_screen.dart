import 'package:flutter/material.dart';
import '../models/index.dart';
import '../services/index.dart';
import '../widgets/index.dart';

class CategorizeScreen extends StatefulWidget {
  final String imagePath;
  final String merchantName;
  final double amount;
  final String ocrText;
  final List<OCRItem> items;
  final ExpenseRepository repository;

  const CategorizeScreen({
    Key? key,
    required this.imagePath,
    required this.merchantName,
    required this.amount,
    required this.ocrText,
    this.items = const [],
    required this.repository,
  }) : super(key: key);

  @override
  State<CategorizeScreen> createState() => _CategorizeScreenState();
}

class _CategorizeScreenState extends State<CategorizeScreen> {
  late ExpenseCategory _selectedCategory;
  late List<ExpenseItem> _expenseItems;
  final TextEditingController _notesController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Guess primary category
    _selectedCategory = CategorizationService.guessPrimaryCategory(
      widget.merchantName,
      widget.ocrText,
    );

    // Initialize expense items from OCR items
    _expenseItems = widget.items.map((item) => ExpenseItem(
      name: item.name,
      price: item.price,
      category: CategorizationService.guessCategory(item.name),
    )).toList();
  }

  Future<void> _saveExpense() async {
    setState(() => _isSaving = true);
    try {
      final expense = Expense(
        imagePath: widget.imagePath,
        merchantName: widget.merchantName,
        amount: widget.amount,
        category: _selectedCategory,
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
          SnackBar(content: Text('Error saving expense: $e')),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categorize Expense'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.receipt, size: 40, color: Colors.blue),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.merchantName,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '\$${widget.amount.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.blue,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 32),
                      CategorySelector(
                        selectedCategory: _selectedCategory,
                        onCategorySelected: (category) {
                          setState(() => _selectedCategory = category);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Itemized section
              if (_expenseItems.isNotEmpty) ...[
                const Text(
                  'Individual Items',
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
                                Text(
                                  '\$${item.price.toStringAsFixed(2)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            CategorySelector(
                              selectedCategory: item.category,
                              onCategorySelected: (category) {
                                setState(() {
                                  _expenseItems[index] = ExpenseItem(
                                    name: item.name,
                                    price: item.price,
                                    category: category,
                                  );
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
                'Notes (Optional)',
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
                  hintText: 'Add some notes about this expense...',
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
                          'Save Expense',
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
