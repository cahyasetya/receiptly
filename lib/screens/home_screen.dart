import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/index.dart';
import '../services/index.dart';
import '../widgets/index.dart';
import '../widgets/category_chart.dart';
import '../widgets/budget_progress.dart';
import '../widgets/empty_state.dart';
import '../widgets/summary_card.dart';
import 'input_mode_picker_screen.dart';
import 'settings_screen.dart';

enum _Period { thisMonth, lastMonth, last30Days, allTime, custom }

class HomeScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;

  const HomeScreen({super.key, required this.onToggleTheme});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late ExpenseRepository _repository;
  List<Expense> _expenses = [];
  List<Expense> _filteredExpenses = [];
  List<Category> _categories = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  DateTime _startDate = _firstOfMonth(DateTime.now());
  DateTime _endDate = DateTime.now();
  _Period _selectedPeriod = _Period.thisMonth;

  static DateTime _firstOfMonth(DateTime date) =>
      DateTime(date.year, date.month, 1);

  static DateTime _lastOfMonth(DateTime date) =>
      DateTime(date.year, date.month + 1, 0);

  @override
  void initState() {
    super.initState();
    _repository = ExpenseRepository();
    _loadExpenses();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await _repository.getCategories();
      if (mounted) setState(() => _categories = cats);
    } catch (_) {}
  }

  Future<void> _loadExpenses() async {
    setState(() => _isLoading = true);
    try {
      final List<Expense> expenses;
      if (_selectedPeriod == _Period.allTime) {
        expenses = await _repository.getAllExpenses();
      } else {
        expenses = await _repository.getExpensesByDateRange(
          _startDate,
          _endDate.add(const Duration(days: 1)),
        );
      }
      setState(() {
        _expenses = expenses;
        _isLoading = false;
      });
      _filterExpenses();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat pengeluaran: $e')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  void _filterExpenses() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filteredExpenses = List.from(_expenses);
      } else {
        _filteredExpenses = _expenses.where((e) {
          if (e.title.toLowerCase().contains(query)) return true;
          for (final item in e.items) {
            if (item.name.toLowerCase().contains(query)) return true;
          }
          return false;
        }).toList();
      }
    });
  }

  Future<void> _setPeriod(_Period period) async {
    final now = DateTime.now();
    setState(() {
      _selectedPeriod = period;
      switch (period) {
        case _Period.thisMonth:
          _startDate = _firstOfMonth(now);
          _endDate = now;
        case _Period.lastMonth:
          final lastMonth = DateTime(now.year, now.month - 1, 1);
          _startDate = _firstOfMonth(lastMonth);
          _endDate = _lastOfMonth(lastMonth);
        case _Period.last30Days:
          _startDate = now.subtract(const Duration(days: 30));
          _endDate = now;
        case _Period.allTime:
          _startDate = DateTime(2000);
          _endDate = now;
        case _Period.custom:
          return;
      }
    });
    _loadExpenses();
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(
        start: _startDate,
        end: _endDate,
      ),
      firstDate: DateTime(2000),
      lastDate: now,
      locale: const Locale('id'),
      helpText: 'Pilih Rentang Tanggal',
      cancelText: 'Batal',
      confirmText: 'Pilih',
      fieldStartHintText: 'Tanggal Mulai',
      fieldEndHintText: 'Tanggal Akhir',
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _selectedPeriod = _Period.custom;
      });
      _loadExpenses();
    }
  }

  Future<void> _deleteExpense(String id) async {
    try {
      await _repository.deleteExpense(id);
      _loadExpenses();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pengeluaran dihapus')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus: $e')),
        );
      }
    }
  }

  void _navigateToAddExpense() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => InputModePickerScreen(
          repository: _repository,
        ),
      ),
    );
    if (result == true) {
      _loadExpenses();
      _loadCategories();
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalExpenses = _expenses.fold<double>(
      0,
      (sum, expense) => sum + expense.amount,
    );
    final dateFormat = DateFormat('dd MMM yyyy', 'id');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Receiptly'),
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Theme.of(context).brightness == Brightness.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            tooltip: 'Ganti tema',
            onPressed: widget.onToggleTheme,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Pengaturan',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsScreen(
                    repository: _repository,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadExpenses,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    _buildPeriodSelector(),
                    _buildDateRangeBar(dateFormat),
                    if (_expenses.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Cari pengeluaran...',
                            prefixIcon: const Icon(Icons.search, size: 20),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 10),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: () { _searchController.clear(); _filterExpenses(); },
                                  )
                                : null,
                          ),
                          onChanged: (_) => _filterExpenses(),
                        ),
                      ),
                    if (_expenses.isNotEmpty)
                      SummaryCard(
                        totalExpenses: totalExpenses,
                        transactionCount: _expenses.length,
                        isAllTime: _selectedPeriod == _Period.allTime,
                      ),
                    if (_expenses.isNotEmpty)
                      CategoryChart(
                        expenses: _expenses,
                        categories: _categories,
                      ),
                    if (_expenses.isNotEmpty && _categories.any((c) => c.hasBudget))
                      BudgetProgress(
                        expenses: _expenses,
                        categories: _categories,
                      ),
                    if (_filteredExpenses.isEmpty)
                      EmptyState(
                        icon: _searchController.text.isNotEmpty ? Icons.search_off : Icons.receipt_long,
                        title: _searchController.text.isNotEmpty ? 'Pencarian tidak ditemukan' : 'Belum ada pengeluaran',
                        subtitle: _searchController.text.isNotEmpty ? 'Coba kata kunci lain' : 'Tekan tombol di bawah untuk menambahkan nota pertama',
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: 100),
                        itemCount: _filteredExpenses.length,
                        itemBuilder: (context, index) {
                          final expense = _filteredExpenses[index];
                          return ExpenseCard(
                            expense: expense,
                            onDelete: () => _deleteExpense(expense.id!),
                          );
                        },
                      ),
                    if (_expenses.isNotEmpty)
                      CategoryChart(
                        expenses: _expenses,
                        categories: _categories,
                      ),
                    if (_expenses.isNotEmpty && _categories.any((c) => c.hasBudget))
                      BudgetProgress(
                        expenses: _expenses,
                        categories: _categories,
                      ),
                    if (_expenses.isEmpty)
                      EmptyState(
                        icon: _selectedPeriod == _Period.allTime ? Icons.receipt_long : Icons.search_off,
                        title: _selectedPeriod == _Period.allTime ? 'Belum ada pengeluaran' : 'Tidak ada pengeluaran',
                        subtitle: _selectedPeriod == _Period.allTime
                            ? 'Tekan tombol di bawah untuk menambahkan nota pertama'
                            : 'Tidak ada pengeluaran di periode ini',
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: 100),
                        itemCount: _expenses.length,
                        itemBuilder: (context, index) {
                          final expense = _expenses[index];
                          return ExpenseCard(
                            expense: expense,
                            onDelete: () => _deleteExpense(expense.id!),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAddExpense,
        label: const Text('Tambah Nota'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    const periods = [
      (_Period.thisMonth, 'Bulan Ini'),
      (_Period.lastMonth, 'Bulan Lalu'),
      (_Period.last30Days, '30 Hari'),
      (_Period.allTime, 'Semua'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: periods.map((period) {
          final isSelected = _selectedPeriod == period.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(period.$2),
              selected: isSelected,
              onSelected: (_) => _setPeriod(period.$1),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDateRangeBar(DateFormat dateFormat) {
    if (_selectedPeriod == _Period.allTime) return const SizedBox.shrink();

    final label = '${dateFormat.format(_startDate)} - ${dateFormat.format(_endDate)}';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: _pickDateRange,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.calendar_today, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface),
                ),
              ),
              Icon(Icons.edit_calendar, size: 16, color: Theme.of(context).colorScheme.primary),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

}
