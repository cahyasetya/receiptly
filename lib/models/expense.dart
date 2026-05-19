import 'dart:convert';
import 'package:intl/intl.dart';
import 'expense_category.dart';

class ExpenseItem {
  final String name;
  final double price;
  final ExpenseCategory category;

  ExpenseItem({
    required this.name,
    required this.price,
    required this.category,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'category': category.name,
    };
  }

  factory ExpenseItem.fromMap(Map<String, dynamic> map) {
    return ExpenseItem(
      name: map['name'] as String,
      price: (map['price'] as num).toDouble(),
      category: ExpenseCategory.fromString(map['category'] as String),
    );
  }
}

class Expense {
  final String? id;
  final String imagePath;
  final String merchantName;
  final double amount;
  final ExpenseCategory category; // Primary category or summary category
  final DateTime date;
  final String ocrText;
  final String? notes;
  final DateTime createdAt;
  final List<ExpenseItem> items;

  Expense({
    this.id,
    required this.imagePath,
    required this.merchantName,
    required this.amount,
    required this.category,
    required this.date,
    required this.ocrText,
    this.items = const [],
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // Convert Expense to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'imagePath': imagePath,
      'merchantName': merchantName,
      'amount': amount,
      'category': category.name,
      'date': date.toIso8601String(),
      'ocrText': ocrText,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'itemsJson': jsonEncode(items.map((e) => e.toMap()).toList()),
    };
  }

  // Create Expense from database Map
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
      merchantName: map['merchantName'] as String,
      amount: (map['amount'] as num).toDouble(),
      category: ExpenseCategory.fromString(map['category'] as String),
      date: DateTime.parse(map['date'] as String),
      ocrText: map['ocrText'] as String,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      items: items,
    );
  }

  // Helper getters for formatting
  String get formattedDate => DateFormat('MMM dd, yyyy').format(date);
  String get formattedAmount => '\$${amount.toStringAsFixed(2)}';

  // Copy with method for updates
  Expense copyWith({
    String? id,
    String? imagePath,
    String? merchantName,
    double? amount,
    ExpenseCategory? category,
    DateTime? date,
    String? ocrText,
    String? notes,
    List<ExpenseItem>? items,
  }) {
    return Expense(
      id: id ?? this.id,
      imagePath: imagePath ?? this.imagePath,
      merchantName: merchantName ?? this.merchantName,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      ocrText: ocrText ?? this.ocrText,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      items: items ?? this.items,
    );
  }
}
