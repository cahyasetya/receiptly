import 'package:flutter/material.dart';
import '../models/index.dart';
import '../services/index.dart';

class CategoryManagerScreen extends StatefulWidget {
  final ExpenseRepository repository;

  const CategoryManagerScreen({super.key, required this.repository});

  @override
  State<CategoryManagerScreen> createState() => _CategoryManagerScreenState();
}

class _CategoryManagerScreenState extends State<CategoryManagerScreen> {
  List<Category> _categories = [];
  bool _isLoading = true;

  static const _iconOptions = ['📁', '🍕', '🚗', '💡', '🛒', '👕', '🎬', '🏥', '📚', '🎵', '🏠', '💻', '📱', '🎮', '✈️', '🐾', '🎁', '🔧', '📦'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final cats = await widget.repository.getCategories();
    if (mounted) setState(() { _categories = cats; _isLoading = false; });
  }

  Future<void> _add() async {
    final result = await _showEditor(null);
    if (result != null) {
      await widget.repository.addCategory(result);
      _load();
    }
  }

  Future<void> _edit(Category cat) async {
    final result = await _showEditor(cat);
    if (result != null) {
      await widget.repository.updateCategory(result);
      _load();
    }
  }

  Future<void> _delete(Category cat) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Kategori'),
        content: Text('Hapus "${cat.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus')),
        ],
      ),
    );
    if (ok == true) {
      await widget.repository.deleteCategory(cat.id);
      _load();
    }
  }

  Future<Category?> _showEditor(Category? existing) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final keywordCtrl = TextEditingController(text: existing?.keywords.join(', ') ?? '');
    final currentBudget = existing?.budgetAmount ?? 0;
    final budgetCtrl = TextEditingController(text: currentBudget > 0 ? currentBudget.toStringAsFixed(0) : '');
    Color selectedColor = existing?.color ?? Colors.blue;
    String selectedIcon = existing?.icon ?? '📁';
    int sortOrder = existing?.sortOrder ?? _categories.length;

    final colors = [
      Colors.red, Colors.pink, Colors.purple, Colors.deepPurple,
      Colors.indigo, Colors.blue, Colors.lightBlue, Colors.cyan,
      Colors.teal, Colors.green, Colors.lightGreen, Colors.lime,
      Colors.yellow, Colors.amber, Colors.orange, Colors.deepOrange,
      Colors.brown, Colors.grey, Colors.blueGrey,
    ];

    final result = await showDialog<Category>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(existing == null ? 'Tambah Kategori' : 'Edit Kategori'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nama Kategori', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),

                // Icon picker
                const Text('Ikon', style: TextStyle(fontSize: 12)),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: _iconOptions.map((icon) => GestureDetector(
                    onTap: () => setDialogState(() => selectedIcon = icon),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: selectedIcon == icon ? selectedColor.withValues(alpha: 0.2) : null,
                        borderRadius: BorderRadius.circular(8),
                        border: selectedIcon == icon ? Border.all(color: selectedColor) : null,
                      ),
                      child: Text(icon, style: const TextStyle(fontSize: 22)),
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 12),

                // Color picker
                const Text('Warna', style: TextStyle(fontSize: 12)),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: colors.map((c) => GestureDetector(
                    onTap: () => setDialogState(() => selectedColor = c),
                    child: Container(
                      width: 30, height: 30,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: selectedColor == c ? Border.all(color: Colors.white, width: 3) : null,
                        boxShadow: selectedColor == c ? [BoxShadow(color: c.withValues(alpha: 0.5), blurRadius: 6)] : null,
                      ),
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: keywordCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Kata Kunci (pisahkan dengan koma)',
                    border: OutlineInputBorder(),
                    hintText: 'contoh: sepatu, baju, tas',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: budgetCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Budget per Bulan (Rp)',
                    border: OutlineInputBorder(),
                    hintText: 'Kosongi jika tidak ada budget',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                final keywords = keywordCtrl.text.split(',').map((k) => k.trim()).where((k) => k.isNotEmpty).toList();
                Navigator.pop(ctx, Category(
                  id: existing?.id ?? 'custom_${DateTime.now().millisecondsSinceEpoch}',
                  name: name,
                  color: selectedColor,
                  icon: selectedIcon,
                  keywords: keywords,
                  sortOrder: sortOrder,
                  budgetAmount: double.tryParse(budgetCtrl.text) ?? 0,
                ));
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );

    nameCtrl.dispose();
    keywordCtrl.dispose();
    budgetCtrl.dispose();
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Kategori'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _categories.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.category, size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
                      const SizedBox(height: 16),
                      Text('Belum ada kategori kustom', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(onPressed: _add, icon: const Icon(Icons.add), label: const Text('Tambah Kategori')),
                    ],
                  ),
                )
              : ReorderableListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _categories.length + 1,
                  onReorderItem: (oldIndex, newIndex) async {
                    if (newIndex > oldIndex) newIndex--;
                    final updated = List<Category>.from(_categories);
                    final item = updated.removeAt(oldIndex);
                    updated.insert(newIndex, item);
                    for (var i = 0; i < updated.length; i++) {
                      final c = updated[i];
                      await widget.repository.updateCategory(Category(
                        id: c.id, name: c.name, color: c.color, icon: c.icon, keywords: c.keywords, sortOrder: i,
                      ));
                    }
                    _load();
                  },
                  proxyDecorator: (child, index, animation) => Material(elevation: 2, borderRadius: BorderRadius.circular(12), child: child),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Padding(
                        key: const ValueKey('header'),
                        padding: const EdgeInsets.only(bottom: 12),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _add,
                            icon: const Icon(Icons.add),
                            label: const Text('Tambah Kategori Baru'),
                          ),
                        ),
                      );
                    }
                    final cat = _categories[index - 1];
                    return Card(
                      key: ValueKey(cat.id),
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(backgroundColor: cat.color, child: Text(cat.icon, style: const TextStyle(fontSize: 18))),
                        title: Text(cat.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (cat.keywords.isNotEmpty)
                              Text(cat.keywords.join(', '), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11)),
                            if (cat.hasBudget)
                              Text('Budget: Rp${cat.budgetAmount.toStringAsFixed(0)}', style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.primary)),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(icon: const Icon(Icons.edit, size: 20), onPressed: () => _edit(cat)),
                            IconButton(icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red), onPressed: () => _delete(cat)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
