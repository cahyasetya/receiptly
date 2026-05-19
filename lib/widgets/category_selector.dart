import 'package:flutter/material.dart';
import '../models/index.dart';

class CategorySelector extends StatelessWidget {
  final ExpenseCategory selectedCategory;
  final Function(ExpenseCategory) onCategorySelected;
  final List<ExpenseCategory>? suggestions;
  final List<Category> categories;
  final String? selectedCategoryId;
  final ValueChanged<Category>? onCategoryChosen;

  const CategorySelector({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
    this.suggestions,
    this.categories = const [],
    this.selectedCategoryId,
    this.onCategoryChosen,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (suggestions != null && suggestions!.isNotEmpty) ...[
          _sectionHeader(context, Icons.lightbulb_outline, 'Saran'),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: suggestions!
                  .where((c) => c != ExpenseCategory.other)
                  .map((category) => Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: _CategoryChip.builtIn(
                      category: category,
                      isSelected: category == selectedCategory && selectedCategoryId == null,
                      onTap: () => onCategorySelected(category),
                    ),
                  ))
                  .toList(),
            ),
          ),
          const Divider(indent: 16, endIndent: 16, height: 16),
        ],
        _sectionHeader(context, Icons.category, 'Semua Kategori'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              ...ExpenseCategory.values.map((category) => _CategoryChip.builtIn(
                    category: category,
                    isSelected: category == selectedCategory && selectedCategoryId == null,
                    onTap: () => onCategorySelected(category),
                  )),
              if (categories.isNotEmpty)
                ...categories.map((cat) => _CategoryChip.custom(
                      category: cat,
                      isSelected: cat.id == selectedCategoryId,
                      onTap: () => onCategoryChosen?.call(cat),
                    )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sectionHeader(BuildContext context, IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.amber[700]),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String? label;
  final String? icon;
  final Color? color;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip._({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  factory _CategoryChip.builtIn({
    required ExpenseCategory category,
    required bool isSelected,
    required VoidCallback onTap,
  }) => _CategoryChip._(
    label: category.displayName,
    icon: category.icon,
    color: category.color,
    isSelected: isSelected,
    onTap: onTap,
  );

  factory _CategoryChip.custom({
    required Category category,
    required bool isSelected,
    required VoidCallback onTap,
  }) => _CategoryChip._(
    label: category.name,
    icon: category.icon,
    color: category.color,
    isSelected: isSelected,
    onTap: onTap,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isSelected) ...[
            Icon(Icons.check, size: 14, color: theme.colorScheme.onPrimary),
            const SizedBox(width: 4),
          ],
          Text(
            '$icon $label',
            style: TextStyle(
              color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
      selected: isSelected,
      onSelected: (_) => onTap(),
      backgroundColor: isSelected ? color : Colors.transparent,
      selectedColor: color,
      side: isSelected
          ? BorderSide(color: color!, width: 2)
          : BorderSide(color: theme.colorScheme.outlineVariant),
      showCheckmark: false,
      visualDensity: VisualDensity.compact,
    );
  }
}
