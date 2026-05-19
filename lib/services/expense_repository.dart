import '../models/index.dart';
import 'database_service.dart';

class ExpenseRepository {
  final DatabaseService _databaseService = DatabaseService();

  Future<String> addExpense(Expense expense) async {
    return _databaseService.insertExpense(expense);
  }

  Future<Expense?> getExpense(String id) async {
    return _databaseService.getExpense(id);
  }

  Future<List<Expense>> getAllExpenses() async {
    return _databaseService.getAllExpenses();
  }

  Future<List<Expense>> getExpensesByCategory(ExpenseCategory category) async {
    return _databaseService.getExpensesByCategory(category);
  }

  Future<List<Expense>> getExpensesByDateRange(DateTime start, DateTime end) async {
    return _databaseService.getExpensesByDateRange(start, end);
  }

  Future<void> updateExpense(Expense expense) async {
    await _databaseService.updateExpense(expense);
  }

  Future<void> deleteExpense(String id) async {
    await _databaseService.deleteExpense(id);
  }

  Future<double> getTotalExpenses() async {
    return _databaseService.getTotalExpenses();
  }

  Future<Map<String, double>> getCategoryTotals() async {
    return _databaseService.getCategoryTotals();
  }

  Future<void> close() async {
    await _databaseService.close();
  }
}
