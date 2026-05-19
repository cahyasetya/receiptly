import 'package:flutter/material.dart';
import '../services/index.dart';
import '../services/google_sheets_service.dart';

class SyncScreen extends StatefulWidget {
  final ExpenseRepository repository;

  const SyncScreen({super.key, required this.repository});

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  final GoogleSheetsService _sheetsService = GoogleSheetsService();
  bool _isSyncing = false;
  String _spreadsheetId = '';
  String? _status;
  bool? _lastSuccess;

  @override
  void initState() {
    super.initState();
    _sheetsService.initialize();
    _loadSheetId();
  }

  Future<void> _loadSheetId() async {
    final id = await widget.repository.getSetting('google_sheet_id');
    if (mounted) setState(() => _spreadsheetId = id ?? '');
  }

  Future<void> _saveSheetId(String id) async {
    await widget.repository.setSetting('google_sheet_id', id);
    setState(() => _spreadsheetId = id);
  }

  Future<void> _login() async {
    try {
      final account = await _sheetsService.signIn();
      if (account != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login sebagai ${account.email}')),
        );
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal login: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _sync() async {
    setState(() { _isSyncing = true; _status = 'Menyinkronkan...'; _lastSuccess = null; });

    try {
      final sheetId = await _sheetsService.syncAll(
        widget.repository,
        _spreadsheetId.isNotEmpty ? _spreadsheetId : null,
      );

      await _saveSheetId(sheetId);

      setState(() {
        _isSyncing = false;
        _status = 'Sinkronisasi berhasil!';
        _lastSuccess = true;
      });
    } catch (e) {
      setState(() {
        _isSyncing = false;
        _status = 'Gagal: $e';
        _lastSuccess = false;
      });
    }
  }

  Future<void> _restore() async {
    if (_spreadsheetId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Masukkan ID spreadsheet'), backgroundColor: Colors.red),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore Data'),
        content: const Text('Data dari sheet akan ditambahkan ke database lokal. Data dengan ID yang sama akan dilewati. Lanjutkan?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Restore')),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() { _isSyncing = true; _status = 'Merestore...'; _lastSuccess = null; });
    try {
      await _sheetsService.restoreFromSheet(_spreadsheetId, widget.repository);
      setState(() { _isSyncing = false; _status = 'Restore berhasil!'; _lastSuccess = true; });
    } catch (e) {
      setState(() { _isSyncing = false; _status = 'Gagal restore: $e'; _lastSuccess = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final signedIn = _sheetsService.isSignedIn;

    return Scaffold(
      appBar: AppBar(title: const Text('Sinkronisasi Google Sheets')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Status card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(
                    signedIn ? Icons.cloud_done : Icons.cloud_off,
                    size: 48,
                    color: signedIn ? Colors.green[400] : Colors.grey,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    signedIn ? 'Terhubung sebagai' : 'Belum terhubung',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  if (signedIn) ...[
                    const SizedBox(height: 4),
                    Text(_sheetsService.email ?? '', style: const TextStyle(fontSize: 13)),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Login/out button
          SizedBox(
            width: double.infinity,
            child: signedIn
                ? OutlinedButton.icon(
                    onPressed: () async {
                      await _sheetsService.signOut();
                      setState(() {});
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Logout'),
                  )
                : ElevatedButton.icon(
                    onPressed: _login,
                    icon: const Icon(Icons.login),
                    label: const Text('Login dengan Google'),
                  ),
          ),
          const SizedBox(height: 24),

          // Spreadsheet ID
          const Text('ID Spreadsheet', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Kosongi untuk buat baru',
                    border: OutlineInputBorder(),
                  ),
                  controller: TextEditingController(text: _spreadsheetId),
                  onChanged: _saveSheetId,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Isi ID spreadsheet yang sudah ada, atau kosongi untuk membuat spreadsheet baru.',
            style: TextStyle(fontSize: 12),
          ),
          if (_spreadsheetId.isNotEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Spreadsheet ID: $_spreadsheetId')),
                  );
                },
                icon: const Icon(Icons.open_in_browser),
                label: const Text('Buka di Browser'),
              ),
            ),
          ],
          const SizedBox(height: 24),

          // Sync button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: signedIn && !_isSyncing ? _sync : null,
              icon: _isSyncing
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.sync),
              label: Text(_isSyncing ? 'Menyinkronkan...' : 'Sinkronkan Sekarang'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: signedIn && !_isSyncing ? _restore : null,
              icon: const Icon(Icons.restore),
              label: const Text('Restore dari Sheet'),
            ),
          ),

          // Status
          if (_status != null) ...[
            const SizedBox(height: 16),
            Card(
              color: _lastSuccess == true
                  ? Colors.green[50]
                  : _lastSuccess == false
                      ? Colors.red[50]
                      : null,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(
                      _lastSuccess == true ? Icons.check_circle : Icons.error,
                      color: _lastSuccess == true ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_status!, style: const TextStyle(fontSize: 13))),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),

          // Instructions
          const Text(
            'Cara Setup Google Sheets Sync',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text(
            '1. Buka console.cloud.google.com\n'
            '2. Buat project baru → Enable Google Sheets API\n'
            '3. Buat OAuth Client ID (Web application type)\n'
            '4. Masukkan Client ID ke file .env:\n'
            '   GOOGLE_CLIENT_ID=xxx.apps.googleusercontent.com\n'
            '5. Login dan sinkronisasi di sini',
            style: TextStyle(fontSize: 12, height: 1.6),
          ),
        ],
      ),
    );
  }
}
