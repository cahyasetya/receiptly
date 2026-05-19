import 'package:flutter/material.dart';

class Category {
  final String id;
  final String name;
  final Color color;
  final String icon;
  final List<String> keywords;
  final int sortOrder;
  final bool isBuiltIn;
  final double budgetAmount;

  const Category({
    required this.id,
    required this.name,
    required this.color,
    this.icon = '📁',
    this.keywords = const [],
    this.sortOrder = 0,
    this.isBuiltIn = false,
    this.budgetAmount = 0,
  });

  bool get hasBudget => budgetAmount > 0;

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'color': color.toARGB32(),
        'icon': icon,
        'keywords': keywords.join(','),
        'sort_order': sortOrder,
        'is_built_in': isBuiltIn ? 1 : 0,
        'budget_amount': budgetAmount,
      };

  factory Category.fromMap(Map<String, dynamic> map) => Category(
        id: map['id'] as String,
        name: map['name'] as String,
        color: Color(_toInt(map['color'])),
        icon: (map['icon'] as String?) ?? '📁',
        keywords: _parseKeywords(map['keywords'] as String?),
        sortOrder: (map['sort_order'] as int?) ?? 0,
        isBuiltIn: (map['is_built_in'] == 1),
        budgetAmount: (map['budget_amount'] as num?)?.toDouble() ?? 0,
      );

  static int _toInt(dynamic v) => (v is int) ? v : int.tryParse(v.toString()) ?? 0;

  static List<String> _parseKeywords(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    return raw.split(',').map((k) => k.trim()).where((k) => k.isNotEmpty).toList();
  }

  /// Seed data: default categories pre-populated on fresh install.
  static const List<Category> seedCategories = [
    Category(id: 'cat_ipl', name: 'IPL', color: Color(0xFF9C27B0), icon: '🏢', sortOrder: 0, isBuiltIn: true),
    Category(id: 'cat_listrik', name: 'Listrik', color: Color(0xFFFFC107), icon: '⚡', sortOrder: 1, isBuiltIn: true),
    Category(id: 'cat_air', name: 'Air', color: Color(0xFF2196F3), icon: '🚿', sortOrder: 2, isBuiltIn: true),
    Category(id: 'cat_wifi', name: 'WIFI', color: Color(0xFF3F51B5), icon: '📶', sortOrder: 3, isBuiltIn: true),
    Category(id: 'cat_groceries', name: 'Groceries', color: Color(0xFF4CAF50), icon: '🧴', sortOrder: 4, isBuiltIn: true),
    Category(id: 'cat_buah', name: 'Buah-buahan', color: Color(0xFFFF9800), icon: '🍎', sortOrder: 5, isBuiltIn: true),
    Category(id: 'cat_bahan', name: 'Bahan Makanan', color: Color(0xFF009688), icon: '🥘', sortOrder: 6, isBuiltIn: true),
    Category(id: 'cat_laundry', name: 'Laundry', color: Color(0xFF00BCD4), icon: '👕', sortOrder: 7, isBuiltIn: true),
    Category(id: 'cat_makanan', name: 'Makanan', color: Color(0xFFF44336), icon: '🍽️', sortOrder: 8, isBuiltIn: true),
    Category(id: 'cat_transportasi', name: 'Transportasi', color: Color(0xFF607D8B), icon: '🚗', sortOrder: 9, isBuiltIn: true),
    Category(id: 'cat_rekreasi', name: 'Rekreasi', color: Color(0xFFE91E63), icon: '🎬', sortOrder: 10, isBuiltIn: true),
    Category(id: 'cat_takterduga', name: 'Tak Terduga', color: Color(0xFF9E9E9E), icon: '📌', sortOrder: 11, isBuiltIn: true),
    Category(id: 'cat_tabungan', name: 'Tabungan Apart', color: Color(0xFF795548), icon: '🏦', sortOrder: 12, isBuiltIn: true),
    Category(id: 'cat_skincare', name: 'Skincare & Make Up', color: Color(0xFF673AB7), icon: '💄', sortOrder: 13, isBuiltIn: true),
    Category(id: 'cat_pakaian', name: 'Pakaian', color: Color(0xFFCDDC39), icon: '👗', sortOrder: 14, isBuiltIn: true),
    Category(id: 'cat_lainnya', name: 'Lainnya', color: Color(0xFF9E9E9E), icon: '📦', sortOrder: 15, isBuiltIn: true),
  ];
}
