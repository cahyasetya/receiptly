import 'package:flutter/material.dart';

enum ExpenseCategory {
  ipl('IPL', Colors.purple),
  listrik('Listrik', Colors.amber),
  air('Air', Colors.blue),
  wifi('WIFI', Colors.indigo),
  groceries('Groceries', Colors.green),
  buah('Buah-buahan', Colors.orange),
  bahanMakanan('Bahan Makanan', Colors.teal),
  laundry('Laundry', Colors.cyan),
  makanan('Makanan', Colors.red),
  transportasi('Transportasi', Colors.blueGrey),
  rekreasi('Rekreasi', Colors.pink),
  takTerduga('Tak Terduga', Colors.grey),
  tabunganApart('Tabungan Apart', Colors.brown),
  skincare('Skincare & Make Up', Colors.deepPurple),
  pakaian('Pakaian', Colors.lime),
  other('Lainnya', Colors.grey);

  final String displayName;
  final Color color;

  const ExpenseCategory(this.displayName, this.color);

  String get icon {
    switch (this) {
      case ExpenseCategory.ipl:
        return '🏢';
      case ExpenseCategory.listrik:
        return '⚡';
      case ExpenseCategory.air:
        return '🚿';
      case ExpenseCategory.wifi:
        return '📶';
      case ExpenseCategory.groceries:
        return '🧴';
      case ExpenseCategory.buah:
        return '🍎';
      case ExpenseCategory.bahanMakanan:
        return '🥘';
      case ExpenseCategory.laundry:
        return '👕';
      case ExpenseCategory.makanan:
        return '🍽️';
      case ExpenseCategory.transportasi:
        return '🚗';
      case ExpenseCategory.rekreasi:
        return '🎬';
      case ExpenseCategory.takTerduga:
        return '📌';
      case ExpenseCategory.tabunganApart:
        return '🏦';
      case ExpenseCategory.skincare:
        return '💄';
      case ExpenseCategory.pakaian:
        return '👗';
      case ExpenseCategory.other:
        return '📦';
    }
  }

  static ExpenseCategory fromString(String value) {
    try {
      return ExpenseCategory.values.firstWhere(
        (e) =>
            e.name.toLowerCase() == value.toLowerCase() ||
            e.displayName.toLowerCase() == value.toLowerCase(),
      );
    } catch (e) {
      return ExpenseCategory.other;
    }
  }
}
