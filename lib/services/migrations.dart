import 'package:sqflite/sqflite.dart';
import '../models/category.dart';

const _tableName = 'expenses';
const _catTable = 'categories';

/// v1  (initial)  — expenses table
/// v2             — added itemsJson, notes
/// v3             — added settings table
/// v4             — added custom_categories table
/// v5             — added budgets table
/// v6             — added customCategoryName column to expenses
/// v7             — custom_categories → categories, added is_built_in, seed
/// v8             — added budget_amount column to categories
const schemaVersion = 8;

final List<Future<void> Function(Database db)> allMigrations = [
  _migrationV1, // v1→v2
  _migrationV2, // v2→v3
  _migrationV3, // v3→v4
  _migrationV4, // v4→v5
  _migrationV5, // v5→v6
  _migrationV6, // v6→v7
  _migrationV7, // v7→v8: budget_amount
];

Future<void> createTables(Database db) async {
  await db.execute('''
    CREATE TABLE $_tableName (
      id TEXT PRIMARY KEY,
      imagePath TEXT NOT NULL,
      merchantName TEXT NOT NULL,
      amount REAL NOT NULL,
      category TEXT NOT NULL,
      date TEXT NOT NULL,
      ocrText TEXT NOT NULL,
      itemsJson TEXT,
      notes TEXT,
      customCategoryName TEXT,
      createdAt TEXT NOT NULL
    )
  ''');
  await db.execute('CREATE INDEX idx_date ON $_tableName(date DESC)');
  await db.execute('CREATE INDEX idx_category ON $_tableName(category)');
  await db.execute('''
    CREATE TABLE IF NOT EXISTS settings (
      key TEXT PRIMARY KEY,
      value TEXT NOT NULL
    )
  ''');
  await db.execute('''
    CREATE TABLE $_catTable (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      color INTEGER NOT NULL,
      icon TEXT NOT NULL DEFAULT '📁',
      keywords TEXT,
      sort_order INTEGER NOT NULL DEFAULT 0,
      is_built_in INTEGER NOT NULL DEFAULT 0,
      budget_amount REAL NOT NULL DEFAULT 0
    )
  ''');
  await db.execute('''
    CREATE TABLE IF NOT EXISTS budgets (
      id TEXT PRIMARY KEY,
      category_name TEXT NOT NULL,
      amount REAL NOT NULL
    )
  ''');
  await _seedCategories(db);
}

Future<void> _seedCategories(Database db) async {
  final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM $_catTable')) ?? 0;
  if (count > 0) return;
  final batch = db.batch();
  for (final cat in Category.seedCategories) {
    batch.insert(_catTable, cat.toMap());
  }
  await batch.commit(noResult: true);
}

Future<void> _migrationV1(Database db) async {
  for (final col in ['itemsJson', 'notes']) {
    try { await db.execute('ALTER TABLE $_tableName ADD COLUMN $col TEXT'); } catch (_) {}
  }
}

Future<void> _migrationV2(Database db) async {
  await db.execute('CREATE TABLE IF NOT EXISTS settings (key TEXT PRIMARY KEY, value TEXT NOT NULL)');
}

Future<void> _migrationV3(Database db) async {
  await db.execute('CREATE TABLE IF NOT EXISTS custom_categories (id TEXT PRIMARY KEY, name TEXT NOT NULL, color INTEGER NOT NULL, icon TEXT NOT NULL DEFAULT \'📁\', keywords TEXT, sort_order INTEGER NOT NULL DEFAULT 0)');
}

Future<void> _migrationV4(Database db) async {
  await db.execute('CREATE TABLE IF NOT EXISTS budgets (id TEXT PRIMARY KEY, category_name TEXT NOT NULL, amount REAL NOT NULL)');
}

Future<void> _migrationV5(Database db) async {
  try { await db.execute('ALTER TABLE $_tableName ADD COLUMN customCategoryName TEXT'); } catch (_) {}
}

Future<void> _migrationV6(Database db) async {
  // Rename custom_categories → categories, add is_built_in, seed
  try { await db.execute('ALTER TABLE custom_categories RENAME TO $_catTable'); } catch (_) {
    // Table may not exist or already renamed — create it
    try { await db.execute('CREATE TABLE IF NOT EXISTS $_catTable (id TEXT PRIMARY KEY, name TEXT NOT NULL, color INTEGER NOT NULL, icon TEXT NOT NULL DEFAULT \'📁\', keywords TEXT, sort_order INTEGER NOT NULL DEFAULT 0, is_built_in INTEGER NOT NULL DEFAULT 0)'); } catch (_) {}
  }
  // Add is_built_in column if missing
  try { await db.execute('ALTER TABLE $_catTable ADD COLUMN is_built_in INTEGER NOT NULL DEFAULT 0'); } catch (_) {}
  // Seed default categories
  await _seedCategories(db);
}

Future<void> _migrationV7(Database db) async {
  try { await db.execute('ALTER TABLE $_catTable ADD COLUMN budget_amount REAL NOT NULL DEFAULT 0'); } catch (_) {}
  // Migrate existing budgets to categories.budget_amount
  try {
    final budgets = await db.query('budgets');
    for (final b in budgets) {
      final catName = b['category_name'] as String?;
      final amount = (b['amount'] as num?)?.toDouble() ?? 0;
      if (catName != null && amount > 0) {
        await db.update(_catTable, {'budget_amount': amount}, where: 'name = ?', whereArgs: [catName]);
      }
    }
  } catch (_) {}
}
