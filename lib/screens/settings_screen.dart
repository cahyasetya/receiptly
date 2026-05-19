import 'package:flutter/material.dart';
import '../services/index.dart';
import 'ai_settings_screen.dart';
import 'category_manager_screen.dart';
import 'sync_screen.dart';

class SettingsScreen extends StatelessWidget {
  final ExpenseRepository repository;

  const SettingsScreen({super.key, required this.repository});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _MenuCard(
            icon: Icons.auto_awesome,
            title: 'Pengaturan AI',
            subtitle: 'Model, kredit API, dan lainnya',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AISettingsScreen(repository: repository)),
            ),
          ),
          const SizedBox(height: 12),
          _MenuCard(
            icon: Icons.category,
            title: 'Kelola Kategori',
            subtitle: 'Tambah, edit, atau hapus kategori kustom',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => CategoryManagerScreen(repository: repository)),
            ),
          ),
          const SizedBox(height: 12),
          _MenuCard(
            icon: Icons.cloud_sync,
            title: 'Sinkronisasi Google Sheets',
            subtitle: 'Backup data ke Google Sheets',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => SyncScreen(repository: repository)),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Icon(icon)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
