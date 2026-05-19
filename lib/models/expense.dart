import 'dart:convert';
import 'package:intl/intl.dart';
import 'expense_category.dart';

class ExpenseItem {
  final String name;
  final double price;
  final ExpenseCategory category;
  final String? customCategoryName;

  ExpenseItem({
    required this.name,
    required this.price,
    required this.category,
    this.customCategoryName,
  });

  /// Resolved display name: custom category name if set, else built-in display name.
  String get displayCategoryName => customCategoryName ?? category.displayName;

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'category': category.name,
      if (customCategoryName != null) 'customCategory': customCategoryName,
    };
  }

  factory ExpenseItem.fromMap(Map<String, dynamic> map) {
    return ExpenseItem(
      name: map['name'] as String,
      price: (map['price'] as num).toDouble(),
      category: ExpenseCategory.fromString(map['category'] as String),
      customCategoryName: map['customCategory'] as String?,
    );
  }
}

class Expense {
  final String? id;
  final String imagePath;
  final double amount;
  final ExpenseCategory category;
  final String? customCategoryName;
  final DateTime date;
  final String ocrText;
  final String? notes;
  final DateTime createdAt;
  final List<ExpenseItem> items;

  Expense({
    this.id,
    required this.imagePath,
    required this.amount,
    required this.category,
    this.customCategoryName,
    required this.date,
    required this.ocrText,
    this.items = const [],
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  String get displayCategoryName => customCategoryName ?? category.displayName;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'imagePath': imagePath,
      'merchantName': '',
      'amount': amount,
      'category': category.name,
      'customCategoryName': customCategoryName,
      'date': date.toIso8601String(),
      'ocrText': ocrText,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'itemsJson': jsonEncode(items.map((e) => e.toMap()).toList()),
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    final itemsJson = map['itemsJson'] as String?;
    List<ExpenseItem> items = [];
    if (itemsJson != null) {
      final List<dynamic> decoded = jsonDecode(itemsJson);
      items = decoded.map((e) => ExpenseItem.fromMap(e as Map<String, dynamic>)).toList();
    }

    return Expense(
      id: map['id'] as String?,
      imagePath: map['imagePath'] as String,
      amount: (map['amount'] as num).toDouble(),
      category: ExpenseCategory.fromString(map['category'] as String),
      customCategoryName: map['customCategoryName'] as String?,
      date: DateTime.parse(map['date'] as String),
      ocrText: map['ocrText'] as String,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      items: items,
    );
  }

  String get formattedDate => DateFormat('dd MMM yyyy', 'id').format(date);
  String get formattedAmount => NumberFormat.currency(
    locale: 'id',
    symbol: 'Rp',
    decimalDigits: 0,
  ).format(amount);

  String get title {
    if (items.isEmpty) return 'Nota';
    final names = items.map((i) => i.name).take(2).join(', ');
    final suffix = items.length > 2 ? ', ...' : '';
    return '$names$suffix';
  }

  Expense copyWith({
    String? id,
    String? imagePath,
    double? amount,
    ExpenseCategory? category,
    String? customCategoryName,
    DateTime? date,
    String? ocrText,
    String? notes,
    List<ExpenseItem>? items,
  }) {
    return Expense(
      id: id ?? this.id,
      imagePath: imagePath ?? this.imagePath,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      customCategoryName: customCategoryName ?? this.customCategoryName,
      date: date ?? this.date,
      ocrText: ocrText ?? this.ocrText,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      items: items ?? this.items,
    );
  }
}
