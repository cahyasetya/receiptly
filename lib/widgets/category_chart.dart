import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/index.dart';

class CategoryChart extends StatefulWidget {
  final List<Expense> expenses;
  final List<Category> categories;

  const CategoryChart({
    super.key,
    required this.expenses,
    this.categories = const [],
  });

  @override
  State<CategoryChart> createState() => _CategoryChartState();
}

class _CategoryChartState extends State<CategoryChart> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final totals = _categoryTotals();
    if (totals.isEmpty) return const SizedBox.shrink();

    final totalAmount = totals.values.fold<double>(0, (s, v) => s + v);
    final sections = totals.entries.map((e) {
      final pct = totalAmount > 0 ? (e.value / totalAmount * 100) : 0.0;
      return PieChartSectionData(
        value: e.value,
        color: _colorFor(e.key),
        title: '${pct.toStringAsFixed(0)}%',
        titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
        radius: pct > 20 ? 55 : 45,
      );
    }).toList();

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  const Text('Grafik Pengeluaran', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Text('${totals.length} kategori', style: const TextStyle(fontSize: 12)),
                  const SizedBox(width: 8),
                  Icon(_expanded ? Icons.expand_less : Icons.expand_more),
                ],
              ),
            ),
          ),
          Offstage(
            offstage: !_expanded,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  SizedBox(height: 200, child: PieChart(PieChartData(sections: sections, centerSpaceRadius: 40, sectionsSpace: 2))),
                  const SizedBox(height: 12),
                  ...totals.entries.map(_legendRow),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, double> _categoryTotals() {
    final totals = <String, double>{};
    for (final expense in widget.expenses) {
      final key = expense.displayCategoryName;
      totals[key] = (totals[key] ?? 0) + expense.amount;
    }
    final sorted = totals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return {for (final e in sorted) e.key: e.value};
  }

  Widget _legendRow(MapEntry<String, double> entry) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(color: _colorFor(entry.key), borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: 8),
          Expanded(child: Text(entry.key, style: const TextStyle(fontSize: 13))),
          Text(NumberFormat.currency(locale: 'id', symbol: 'Rp', decimalDigits: 0).format(entry.value),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Color _colorFor(String name) {
    final builtIn = {for (final c in ExpenseCategory.values) c.displayName: c.color};
    if (builtIn.containsKey(name)) return builtIn[name]!;
    final custom = widget.categories.where((c) => c.name == name).firstOrNull;
    if (custom != null) return custom.color;
    final hue = name.hashCode.abs() % 360;
    return HSLColor.fromAHSL(1, hue.toDouble(), 0.6, 0.5).toColor();
  }
}
