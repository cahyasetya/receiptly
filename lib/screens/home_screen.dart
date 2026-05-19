import 'package:flutter/material.dart';
import '../models/index.dart';
import '../services/index.dart';
import '../widgets/index.dart';
import 'camera_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late ExpenseRepository _repository;
  List<Expense> _expenses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _repository = ExpenseRepository();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    setState(() => _isLoading = true);
    try {
      final expenses = await _repository.getAllExpenses();
      setState(() {
        _expenses = expenses;
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading expenses: $e')),
      );
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteExpense(String id) async {
    try {
      await _repository.deleteExpense(id);
      _loadExpenses();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expense deleted')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting expense: $e')),
      );
    }
  }

  void _navigateToCamera() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => CameraScreen(repository: _repository),
      ),
    );

    if (result == true) {
      _loadExpenses();
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalExpenses = _expenses.fold<double>(
      0,
      (sum, expense) => sum + expense.amount,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Receiptly'),
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _expenses.isEmpty
              ? _buildEmptyState()
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      // Summary card
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                const Text(
                                  'Total Expenses',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '\$${totalExpenses.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${_expenses.length} ${_expenses.length == 1 ? 'expense' : 'expenses'}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Expense list
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _expenses.length,
                        itemBuilder: (context, index) {
                          final expense = _expenses[index];
                          return ExpenseCard(
                            expense: expense,
                            onDelete: () => _deleteExpense(expense.id!),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToCamera,
        label: const Text('Add Receipt'),
        icon: const Icon(Icons.camera_alt),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 24),
          Text(
            'No expenses yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the button below to add your first receipt',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}
