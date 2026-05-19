import 'package:flutter/material.dart';
import '../models/index.dart';

class CategorySelector extends StatelessWidget {
  final ExpenseCategory selectedCategory;
  final Function(ExpenseCategory) onCategorySelected;

  const CategorySelector({
    Key? key,
    required this.selectedCategory,
    required this.onCategorySelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Category',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: ExpenseCategory.values
                .map((category) => _CategoryChip(
                      category: category,
                      isSelected: category == selectedCategory,
                      onTap: () => onCategorySelected(category),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final ExpenseCategory category;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        label: Text(
          '${category.icon} ${category.displayName}',
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
        selected: isSelected,
        onSelected: (_) => onTap(),
        backgroundColor: Colors.grey[200],
        selectedColor: category.color,
        showCheckmark: false,
      ),
    );
  }
}
