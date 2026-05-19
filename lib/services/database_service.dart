import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/index.dart';
import 'migrations.dart';

class DatabaseService {
  static const String _dbName = 'receiptly.db';
  static const String _expenseTableName = 'expenses';

  static final DatabaseService _instance = DatabaseService._internal();

  factory DatabaseService() => _instance;

  DatabaseService._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _dbName);

    return openDatabase(
      path,
      version: schemaVersion,
      onCreate: (db, version) => createTables(db),
      onUpgrade: (db, oldVersion, newVersion) async {
        for (var i = oldVersion; i < newVersion; i++) {
          await allMigrations[i - 1](db);
        }
      },
    );
  }

  // ------------------------------------------------------------------
  // CRUD Operations
  // ------------------------------------------------------------------

  Future<String> insertExpense(Expense expense) async {
    final db = await database;
    final id = DateTime.now().millisecondsSinceEpoch.toString();

    await db.insert(
      _expenseTableName,
      {...expense.toMap(), 'id': id},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    return id;
  }

  /// Insert expense with a specific ID. Skips if ID already exists.
  Future<void> insertExpenseWithId(Expense expense) async {
    final db = await database;
    try {
      await db.insert(
        _expenseTableName,
        expense.toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    } catch (_) {}
  }

  Future<Expense?> getExpense(String id) async {
    final db = await database;
    final result = await db.query(
      _expenseTableName,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (result.isEmpty) return null;
    return Expense.fromMap(result.first);
  }

  Future<List<Expense>> getAllExpenses() async {
    final db = await database;
    final result = await db.query(
      _expenseTableName,
      orderBy: 'date DESC',
    );

    return result.map((map) => Expense.fromMap(map)).toList();
  }

  Future<List<Expense>> getExpensesByCategory(ExpenseCategory category) async {
    final db = await database;
    final result = await db.query(
      _expenseTableName,
      where: 'category = ?',
      whereArgs: [category.name],
      orderBy: 'date DESC',
    );

    return result.map((map) => Expense.fromMap(map)).toList();
  }

  Future<List<Expense>> getExpensesByDateRange(DateTime start, DateTime end) async {
    final db = await database;
    final result = await db.query(
      _expenseTableName,
      where: 'date BETWEEN ? AND ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'date DESC',
    );

    return result.map((map) => Expense.fromMap(map)).toList();
  }

  Future<int> updateExpense(Expense expense) async {
    final db = await database;
    return db.update(
      _expenseTableName,
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  Future<int> deleteExpense(String id) async {
    final db = await database;
    return db.delete(
      _expenseTableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<double> getTotalExpenses() async {
    final db = await database;
    final result = await db.rawQuery('SELECT SUM(amount) as total FROM $_expenseTableName');
    final total = (result.first['total'] as num?)?.toDouble() ?? 0.0;
    return total;
  }

  Future<double> getTotalExpensesByDateRange(DateTime start, DateTime end) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM $_expenseTableName WHERE date BETWEEN ? AND ?',
      [start.toIso8601String(), end.toIso8601String()],
    );
    final total = (result.first['total'] as num?)?.toDouble() ?? 0.0;
    return total;
  }

  Future<Map<String, double>> getCategoryTotals() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT category, SUM(amount) as total FROM $_expenseTableName
      GROUP BY category
    ''');

    final Map<String, double> totals = {};
    for (var row in result) {
      totals[row['category'] as String] = (row['total'] as num).toDouble();
    }
    return totals;
  }

  Future<Map<String, double>> getCategoryTotalsByDateRange(DateTime start, DateTime end) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT category, SUM(amount) as total FROM $_expenseTableName
      WHERE date BETWEEN ? AND ?
      GROUP BY category
    ''', [start.toIso8601String(), end.toIso8601String()]);

    final Map<String, double> totals = {};
    for (var row in result) {
      totals[row['category'] as String] = (row['total'] as num).toDouble();
    }
    return totals;
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }

  // ------------------------------------------------------------------
  //  Settings (key-value store)
  // ------------------------------------------------------------------

  Future<String?> getSetting(String key) async {
    final db = await database;
    final result = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: [key],
    );
    if (result.isEmpty) return null;
    return result.first['value'] as String?;
  }

  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ------------------------------------------------------------------
  //  Categories (built-in + user-defined)
  // ------------------------------------------------------------------

  Future<List<Category>> getCategories() async {
    final db = await database;
    final result = await db.query('categories', orderBy: 'sort_order ASC');
    return result.map((map) => Category.fromMap(map)).toList();
  }

  Future<void> insertCategory(Category cat) async {
    final db = await database;
    await db.insert('categories', cat.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateCategory(Category cat) async {
    final db = await database;
    await db.update('categories', cat.toMap(), where: 'id = ?', whereArgs: [cat.id]);
  }

  Future<void> deleteCategory(String id) async {
    final db = await database;
    await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }
}
