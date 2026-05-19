import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/sheets/v4.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import '../models/index.dart';
import '../utils/logger.dart';
import 'expense_repository.dart';

class GoogleSheetsService {
  static const _log = Logger('GoogleSheetsService');
  static const _scopes = ['https://www.googleapis.com/auth/drive.file'];
  static const _folderName = 'Receiptly Backups';

  GoogleSignInAccount? _account;

  bool get isSignedIn => _account != null;
  String? get email => _account?.email;

  Future<void> initialize() async {
    final webClientId = dotenv.env['GOOGLE_CLIENT_ID'] ?? '';
    if (webClientId.isEmpty) {
      _log.warn('GOOGLE_CLIENT_ID tidak diatur di .env');
    }
    await GoogleSignIn.instance.initialize(
      serverClientId: webClientId.isNotEmpty ? webClientId : null,
    );
  }

  Future<GoogleSignInAccount?> signIn() async {
    try {
      _account = await GoogleSignIn.instance.authenticate(scopeHint: _scopes);
      _log.info('Login: ${_account?.email}');
      return _account;
    } catch (e) {
      _log.error('Login gagal: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    await GoogleSignIn.instance.signOut();
    _account = null;
  }

  Future<http.Client> _authHttpClient() async {
    final authz = await _account!.authorizationClient.authorizeScopes(_scopes);
    return _GoogleAuthClient(authz.accessToken);
  }

  Future<SheetsApi> _sheetsApi() async {
    final client = await _authHttpClient();
    return SheetsApi(client);
  }

  Future<drive.DriveApi> _driveApi() async {
    final client = await _authHttpClient();
    return drive.DriveApi(client);
  }

  /// Find or create the dedicated backups folder.
  Future<String> _getOrCreateFolder(drive.DriveApi api) async {
    // Search for existing folder
    final list = await api.files.list(
      q: "name = '$_folderName' and mimeType = 'application/vnd.google-apps.folder' and trashed = false",
      spaces: 'drive',
    );
    if (list.files != null && list.files!.isNotEmpty) {
      _log.info('Folder ditemukan: ${list.files!.first.id}');
      return list.files!.first.id!;
    }

    // Create new folder
    final folder = await api.files.create(
      drive.File(
        name: _folderName,
        mimeType: 'application/vnd.google-apps.folder',
      ),
    );
    _log.info('Folder baru dibuat: ${folder.id}');
    return folder.id!;
  }

  /// Get or create the spreadsheet inside the backups folder.
  Future<String> _getOrCreateSpreadsheet(SheetsApi sheets, drive.DriveApi driveApi) async {
    final folderId = await _getOrCreateFolder(driveApi);

    // Search for existing spreadsheet
    final list = await driveApi.files.list(
      q: "name = 'Receiptly Data' and '$folderId' in parents and trashed = false",
      spaces: 'drive',
    );
    if (list.files != null && list.files!.isNotEmpty) {
      final id = list.files!.first.id!;
      _log.info('Spreadsheet ditemukan: $id');
      return id;
    }

    // Create spreadsheet inside folder
    final spreadsheet = await sheets.spreadsheets.create(
      Spreadsheet(properties: SpreadsheetProperties(title: 'Receiptly Data')),
    );
    final id = spreadsheet.spreadsheetId!;

    // Move to folder
    final emptyFile = drive.File();
    await driveApi.files.update(emptyFile, id, addParents: folderId);
    _log.info('Spreadsheet baru di folder: $id');
    await _initSheets(sheets, id);
    return id;
  }

  Future<void> _initSheets(SheetsApi api, String spreadsheetId) async {
    final requests = <Request>[];
    requests.add(Request(updateSheetProperties: UpdateSheetPropertiesRequest(
      properties: SheetProperties(sheetId: 0, title: 'Expenses'),
      fields: 'title',
    )));
    requests.add(Request(addSheet: AddSheetRequest(properties: SheetProperties(title: 'Categories'))));
    try {
      await api.spreadsheets.batchUpdate(BatchUpdateSpreadsheetRequest(requests: requests), spreadsheetId);
    } catch (e) {
      _log.warn('Init sheets: $e');
    }

    final headerData = [
      ('Expenses!A1:G1', ['id', 'date', 'amount', 'category', 'notes', 'itemsJson', 'createdAt']),
      ('Categories!A1:G1', ['id', 'name', 'color', 'icon', 'keywords', 'sort_order', 'budget_amount']),
    ];
    for (final entry in headerData) {
      try {
        await api.spreadsheets.values.update(
          ValueRange(values: [entry.$2]),
          spreadsheetId, entry.$1,
          valueInputOption: 'USER_ENTERED',
        );
      } catch (e) {
        _log.warn('Header ${entry.$1}: $e');
      }
    }
  }

  Future<void> _pushData(SheetsApi api, String sheetId, String range, List<List<String>> rows) async {
    if (rows.isEmpty) return;
    try {
      final response = await api.spreadsheets.values.update(
        ValueRange(values: rows),
        sheetId, range,
        valueInputOption: 'USER_ENTERED',
      );
      _log.info('Push $range: ${response.updatedCells} cells');
    } catch (e) {
      _log.error('Gagal push $range: $e');
      rethrow;
    }
  }

  /// Push all local data to sheet. Returns spreadsheet ID.
  Future<String> syncAll(ExpenseRepository repository, String? spreadsheetId) async {
    if (_account == null) throw Exception('Belum login');

    final sheets = await _sheetsApi();
    final driveApi = await _driveApi();

    // Always ensure the backups folder exists
    final folderId = await _getOrCreateFolder(driveApi);

    // Get or create spreadsheet inside the folder
    String sid;
    if (spreadsheetId != null && spreadsheetId.isNotEmpty) {
      sid = spreadsheetId;
      // Ensure spreadsheet is inside the backups folder
      try {
        await driveApi.files.update(drive.File(), sid, addParents: folderId);
        _log.info('Spreadsheet $sid dipastikan di folder');
      } catch (e) {
        _log.warn('Gagal update parents spreadsheet: $e');
      }
    } else {
      sid = await _getOrCreateSpreadsheet(sheets, driveApi);
    }

    // Always ensure headers are up to date
    await _initSheets(sheets, sid);

    final expenses = await repository.getAllExpenses();
    final categories = await repository.getCategories();

    // Expenses
    final expenseRows = <List<String>>[];
    for (final e in expenses) {
      expenseRows.add([
        e.id ?? '', e.date.toIso8601String(), e.amount.toString(),
        e.displayCategoryName, e.notes ?? '',
        jsonEncode(e.items.map((i) => i.toMap()).toList()),
        e.createdAt.toIso8601String(),
      ]);
    }
    await _pushData(sheets, sid, 'Expenses!A2:G${expenseRows.length + 1}', expenseRows);

    // Categories
    final catRows = <List<String>>[];
    for (final c in categories) {
      catRows.add([c.id, c.name, c.color.toARGB32().toString(), c.icon, c.keywords.join(','), c.sortOrder.toString(), c.budgetAmount.toString()]);
    }
    await _pushData(sheets, sid, 'Categories!A2:G${catRows.length + 1}', catRows);

    _log.info('Sync selesai! Sheet ID: $sid');
    return sid;
  }

  /// Restore data from sheet into local DB. Skips existing IDs.
  Future<void> restoreFromSheet(String spreadsheetId, ExpenseRepository repository) async {
    if (_account == null) throw Exception('Belum login');
    final sheets = await _sheetsApi();
    _log.info('Mulai restore dari $spreadsheetId...');

    // Restore categories first (expenses depend on category names)
    final catResp = await sheets.spreadsheets.values.get(spreadsheetId, 'Categories!A:G');
    if (catResp.values != null && catResp.values!.length > 1) {
      int restored = 0;
      for (var i = 1; i < catResp.values!.length; i++) {
        final row = catResp.values![i];
        if (row.length < 2) continue;
        final cat = Category(
          id: row[0] as String? ?? '',
          name: row[1] as String? ?? '',
          color: ui.Color(int.tryParse(row[2] as String? ?? '0') ?? 0),
          icon: (row[3] as String?) ?? '📁',
          keywords: (row[4] as String?)?.split(',').map((k) => k.trim()).where((k) => k.isNotEmpty).toList() ?? [],
          sortOrder: int.tryParse(row[5] as String? ?? '0') ?? 0,
          budgetAmount: double.tryParse(row[6] as String? ?? '0') ?? 0,
        );
        if (cat.name.isEmpty) continue;
        try { await repository.addCategory(cat); restored++; } catch (_) {}
      }
      _log.info('Restore $restored kategori');
    }

    // Restore expenses
    final expResp = await sheets.spreadsheets.values.get(spreadsheetId, 'Expenses!A:G');
    if (expResp.values != null && expResp.values!.length > 1) {
      int restored = 0;
      for (var i = 1; i < expResp.values!.length; i++) {
        final row = expResp.values![i];
        if (row.length < 3) continue;
        final id = row[0] as String? ?? '';
        if (id.isEmpty) continue;

        List<ExpenseItem> items = [];
        try {
          final itemsJson = row[5] as String?;
          if (itemsJson != null && itemsJson.isNotEmpty) {
            final decoded = jsonDecode(itemsJson) as List;
            items = decoded.map((e) => ExpenseItem.fromMap(e as Map<String, dynamic>)).toList();
          }
        } catch (_) {}

        final expense = Expense(
          id: id,
          imagePath: '',
          amount: double.tryParse(row[2] as String? ?? '0') ?? 0,
          category: ExpenseCategory.fromString(row[3] as String? ?? 'other'),
          customCategoryName: null,
          date: DateTime.tryParse(row[1] as String? ?? '') ?? DateTime.now(),
          ocrText: row[4] as String? ?? '',
          notes: '',
          items: items,
        );
        try { await repository.addExpense(expense); restored++; } catch (_) {}
      }
      _log.info('Restore $restored expenses');
    }

    _log.info('Restore selesai!');
  }
}

class _GoogleAuthClient extends http.BaseClient {
  final String _token;
  final http.Client _inner = http.Client();
  _GoogleAuthClient(this._token);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['Authorization'] = 'Bearer $_token';
    return _inner.send(request);
  }

  @override
  void close() => _inner.close();
}
