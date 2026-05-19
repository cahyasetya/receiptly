import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/index.dart';

class ExpenseCard extends StatelessWidget {
  final Expense expense;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const ExpenseCard({
    super.key,
    required this.expense,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ExpansionTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: expense.category.color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              expense.category.icon,
              style: const TextStyle(fontSize: 24),
            ),
          ),
        ),
        title: Text(
          expense.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: expense.category.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                expense.displayCategoryName,
                style: TextStyle(
                  fontSize: 12,
                  color: expense.category.color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              expense.formattedDate,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              expense.formattedAmount,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (onDelete != null)
              GestureDetector(
                onTap: onDelete,
                child: Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: Colors.red[400],
                ),
              ),
          ],
        ),
        children: [
          if (expense.items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  const Divider(),
                  ...expense.items.map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Text(item.category.icon),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.name,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        Text(
                          NumberFormat.currency(
                            locale: 'id',
                            symbol: 'Rp',
                            decimalDigits: 0,
                          ).format(item.price),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  )),
                  if (expense.notes != null && expense.notes!.isNotEmpty) ...[
                    const Divider(),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Catatan: ${expense.notes}',
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}
