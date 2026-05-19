import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/index.dart';

class BudgetProgress extends StatefulWidget {
  final List<Expense> expenses;
  final List<Category> categories;

  const BudgetProgress({
    super.key,
    required this.expenses,
    required this.categories,
  });

  @override
  State<BudgetProgress> createState() => _BudgetProgressState();
}

class _BudgetProgressState extends State<BudgetProgress> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final spent = _spentByCategory();
    final withBudget = widget.categories.where((c) => c.hasBudget && (spent[c.name] ?? 0) > 0).toList();
    if (withBudget.isEmpty) return const SizedBox.shrink();

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
                  const Text('Progress Budget', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Text('${withBudget.length} kategori', style: const TextStyle(fontSize: 12)),
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
                children: withBudget.map((cat) {
                  final used = spent[cat.name] ?? 0.0;
                  final amt = cat.budgetAmount;
                  final pct = amt > 0 ? (used / amt) : 0.0;
                  final color = pct < 0.8 ? Colors.green : (pct < 1.0 ? Colors.orange : Colors.red);

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(cat.icon, style: const TextStyle(fontSize: 14)),
                            const SizedBox(width: 6),
                            Expanded(child: Text(cat.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
                            Text(
                              '${NumberFormat.currency(locale: 'id', symbol: 'Rp', decimalDigits: 0).format(used)} / ${NumberFormat.currency(locale: 'id', symbol: 'Rp', decimalDigits: 0).format(amt)}',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: pct.clamp(0, 1),
                            minHeight: 8,
                            backgroundColor: Colors.grey[300],
                            valueColor: AlwaysStoppedAnimation<Color>(color[400]!),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, double> _spentByCategory() {
    final spent = <String, double>{};
    for (final e in widget.expenses) {
      final key = e.displayCategoryName;
      spent[key] = (spent[key] ?? 0) + e.amount;
    }
    return spent;
  }
}
