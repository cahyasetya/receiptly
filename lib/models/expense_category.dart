import 'package:flutter/material.dart';

enum ExpenseCategory {
  food('Food', Colors.orange),
  transport('Transport', Colors.blue),
  utilities('Utilities', Colors.purple),
  groceries('Groceries', Colors.green),
  dining('Dining', Colors.red),
  entertainment('Entertainment', Colors.pink),
  shopping('Shopping', Colors.indigo),
  healthcare('Healthcare', Colors.teal),
  other('Other', Colors.grey);

  final String displayName;
  final Color color;

  const ExpenseCategory(this.displayName, this.color);

  String get icon {
    switch (this) {
      case ExpenseCategory.food:
        return '🍔';
      case ExpenseCategory.transport:
        return '🚗';
      case ExpenseCategory.utilities:
        return '💡';
      case ExpenseCategory.groceries:
        return '🛒';
      case ExpenseCategory.dining:
        return '🍽️';
      case ExpenseCategory.entertainment:
        return '🎬';
      case ExpenseCategory.shopping:
        return '👜';
      case ExpenseCategory.healthcare:
        return '⚕️';
      case ExpenseCategory.other:
        return '📌';
    }
  }

  static ExpenseCategory fromString(String value) {
    try {
      return ExpenseCategory.values.firstWhere(
        (e) => e.name.toLowerCase() == value.toLowerCase(),
      );
    } catch (e) {
      return ExpenseCategory.other;
    }
  }
}
