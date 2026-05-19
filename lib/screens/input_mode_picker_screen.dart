import 'package:flutter/material.dart';
import '../models/index.dart';
import '../services/index.dart';
import 'camera_screen.dart';
import 'manual_entry_screen.dart';

class InputModePickerScreen extends StatelessWidget {
  final ExpenseRepository repository;

  const InputModePickerScreen({
    super.key,
    required this.repository,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih Mode Input'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: InputMode.values.map((mode) {
            return _ModeCard(
              mode: mode,
              onTap: () => _handleModeSelected(context, mode),
            );
          }).toList(),
        ),
      ),
    );
  }

  Future<void> _handleModeSelected(BuildContext context, InputMode mode) async {
    bool? result;
    switch (mode) {
      case InputMode.ai:
        result = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (context) => CameraScreen(
              repository: repository,
            ),
          ),
        );
      case InputMode.manual:
        result = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (context) => ManualEntryScreen(
              repository: repository,
            ),
          ),
        );
    }
    if (result == true && context.mounted) {
      Navigator.pop(context, true);
    }
  }
}

class _ModeCard extends StatelessWidget {
  final InputMode mode;
  final VoidCallback onTap;

  const _ModeCard({
    required this.mode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(
                mode.icon,
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mode.label,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      mode.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
