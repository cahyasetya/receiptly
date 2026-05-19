import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/sheets/v4.dart';
import 'package:http/http.dart' as http;
import '../utils/logger.dart';
import 'expense_repository.dart';

class GoogleSheetsService {
  static const _log = Logger('GoogleSheetsService');
  static const _scopes = ['https://www.googleapis.com/auth/drive.file'];

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
    _log.info('GoogleSignIn initialized');
  }

  Future<GoogleSignInAccount?> signIn() async {
    try {
      _account = await GoogleSignIn.instance.authenticate(
        scopeHint: _scopes,
      );
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
    _log.info('Logout');
  }

  Future<String> _accessToken() async {
    final authz = await _account!.authorizationClient.authorizeScopes(_scopes);
    return authz.accessToken;
  }

  Future<SheetsApi> _api() async {
    final token = await _accessToken();
    return SheetsApi(_GoogleAuthClient(token));
  }

  Future<String> _getOrCreateSpreadsheet(SheetsApi api) async {
    final spreadsheet = await api.spreadsheets.create(
      Spreadsheet(properties: SpreadsheetProperties(title: 'Receiptly Data')),
    );
    final id = spreadsheet.spreadsheetId!;
    _log.info('Spreadsheet baru: $id');
    await _initSheets(api, id);
    return id;
  }

  Future<void> _initSheets(SheetsApi api, String spreadsheetId) async {
    // Rename default Sheet1 → Expenses, then add Categories
    final requests = <Request>[];
    requests.add(Request(updateSheetProperties: UpdateSheetPropertiesRequest(
      properties: SheetProperties(sheetId: 0, title: 'Expenses'),
      fields: 'title',
    )));
    requests.add(Request(addSheet: AddSheetRequest(properties: SheetProperties(title: 'Categories'))));
    try {
      await api.spreadsheets.batchUpdate(
        BatchUpdateSpreadsheetRequest(requests: requests),
        spreadsheetId,
      );
    } catch (e) {
      _log.warn('Init sheets warning: $e');
    }

    final headerData = [
      ('Expenses!A1:G1', ['id', 'date', 'amount', 'category', 'notes', 'itemsJson', 'createdAt']),
      ('Categories!A1:G1', ['id', 'name', 'color', 'icon', 'keywords', 'sort_order', 'budget_amount']),
    ];
    for (final entry in headerData) {
      try {
        await api.spreadsheets.values.update(
          ValueRange(values: [entry.$2]),
          spreadsheetId,
          entry.$1,
          valueInputOption: 'USER_ENTERED',
        );
      } catch (e) {
        _log.warn('Header write warning (${entry.$1}): $e');
      }
    }
  }

  Future<void> _pushData(SheetsApi api, String sheetId, String range, List<List<String>> rows) async {
    if (rows.isEmpty) {
      _log.info('Skip $range: tidak ada data');
      return;
    }
    try {
      final response = await api.spreadsheets.values.update(
        ValueRange(values: rows),
        sheetId,
        range,
        valueInputOption: 'USER_ENTERED',
      );
      _log.info('Push $range: ${response.updatedCells} cells');
    } catch (e) {
      _log.error('Gagal push $range: $e');
      rethrow;
    }
  }

  /// Sync all data. Returns the spreadsheet ID used/created.
  Future<String> syncAll(ExpenseRepository repository, String? spreadsheetId) async {
    if (_account == null) throw Exception('Belum login');

    final api = await _api();
    final sid = spreadsheetId ?? await _getOrCreateSpreadsheet(api);

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
    await _pushData(api, sid, 'Expenses!A2:G${expenseRows.length + 1}', expenseRows);

    // Categories
    final catRows = <List<String>>[];
    for (final c in categories) {
      catRows.add([c.id, c.name, c.color.toARGB32().toString(), c.icon, c.keywords.join(','), c.sortOrder.toString(), c.budgetAmount.toString()]);
    }
    await _pushData(api, sid, 'Categories!A2:G${catRows.length + 1}', catRows);

    _log.info('Sync selesai! Sheet ID: $sid');
    return sid;
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
