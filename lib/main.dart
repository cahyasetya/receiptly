import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/home_screen.dart';
import 'screens/ocr_screen.dart';
import 'services/expense_repository.dart';
import 'services/share_handler.dart';
import 'services/google_sheets_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Pending shared image path captured before app is ready.
String? _pendingSharedPath;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  // Setup share handler
  final shareHandler = ShareHandler();
  shareHandler.onImageReceived = (imagePath) {
    _pendingSharedPath = imagePath;
    // Try to navigate immediately if app is already running
    _handlePendingShare();
  };
  await shareHandler.init();

  // Init Google Sign-In (restores session silently if previously signed in)
  await GoogleSheetsService().initialize();

  runApp(const ReceiptlyApp());
}

void _handlePendingShare() {
  final path = _pendingSharedPath;
  if (path == null) return;
  final context = navigatorKey.currentContext;
  if (context == null) return;

  _pendingSharedPath = null;
  final repository = ExpenseRepository();
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => OCRScreen(
        imagePath: path,
        repository: repository,
      ),
    ),
  );
}

class ReceiptlyApp extends StatefulWidget {
  const ReceiptlyApp({super.key});

  @override
  State<ReceiptlyApp> createState() => _ReceiptlyAppState();
}

class _ReceiptlyAppState extends State<ReceiptlyApp> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _handlePendingShare());
  }

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Receiptly',
      debugShowCheckedModeBanner: false,
      locale: const Locale('id', 'ID'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('id', 'ID'),
        Locale('en', 'US'),
      ],
      themeMode: _themeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
      ),
      home: HomeScreen(onToggleTheme: _toggleTheme),
    );
  }
}
