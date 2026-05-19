import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SummaryCard extends StatelessWidget {
  final double totalExpenses;
  final int transactionCount;
  final bool isAllTime;

  const SummaryCard({
    super.key,
    required this.totalExpenses,
    required this.transactionCount,
    this.isAllTime = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                isAllTime ? 'Total Pengeluaran' : 'Pengeluaran Periode Ini',
                style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              Text(
                NumberFormat.currency(locale: 'id', symbol: 'Rp', decimalDigits: 0).format(totalExpenses),
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface),
              ),
              const SizedBox(height: 4),
              Text(
                '$transactionCount transaksi',
                style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
