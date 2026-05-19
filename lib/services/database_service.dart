import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/index.dart';

class DatabaseService {
  static const String _dbName = 'receiptly.db';
  static const String _expenseTableName = 'expenses';
  static const int _dbVersion = 1;

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
      version: _dbVersion,
      onCreate: _createTables,
    );
  }

  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_expenseTableName (
        id TEXT PRIMARY KEY,
        imagePath TEXT NOT NULL,
        merchantName TEXT NOT NULL,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        date TEXT NOT NULL,
        ocrText TEXT NOT NULL,
        itemsJson TEXT,
        notes TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    // Create index on date for faster queries
    await db.execute('''
      CREATE INDEX idx_date ON $_expenseTableName(date DESC)
    ''');

    // Create index on category for filtering
    await db.execute('''
      CREATE INDEX idx_category ON $_expenseTableName(category)
    ''');
  }

  // CRUD Operations
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

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
