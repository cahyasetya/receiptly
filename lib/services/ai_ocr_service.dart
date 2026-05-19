import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/index.dart';
import '../utils/logger.dart';
import 'expense_repository.dart';
import 'parsers/index.dart';

/// Service for AI-powered OCR using OpenRouter API.
///
/// Configuration:
/// - Create a `.env` file in the project root with:
///   OPENROUTER_API_KEY=sk-or-v1-xxx
///   OPENROUTER_MODEL=nvidia/nemotron-nano-12b-v2-vl:free
///
/// - The model can also be changed at runtime via [updateModel].
class AIOCRService {
  static final AIOCRService _instance = AIOCRService._internal();
  static const _log = Logger('AIOCRService');

  factory AIOCRService() => _instance;

  AIOCRService._internal();

  static const _baseUrl = 'https://openrouter.ai/api/v1';
  static const _defaultModel = 'nvidia/nemotron-nano-12b-v2-vl:free';

  String _model = '';
  List<String> _customCategoryNames = [];

  /// API key for OpenRouter authentication.
  String get _apiKey => dotenv.env['OPENROUTER_API_KEY'] ?? '';

  /// Current model identifier.
  String get model => _model.isNotEmpty ? _model : _modelFromEnv;

  String get _modelFromEnv =>
      dotenv.env['OPENROUTER_MODEL'] ?? _defaultModel;

  /// Load model from DB settings, falling back to .env.
  Future<void> init({ExpenseRepository? repository}) async {
    if (repository != null) {
      final saved = await repository.getSetting('ai_model');
      if (saved != null && saved.isNotEmpty) {
        _model = saved;
        _log.info('Model dimuat dari pengaturan: $_model');
      } else {
        _model = _modelFromEnv;
        _log.info('Model dari .env: $_model');
      }
      // Load custom category names for AI prompt
      final cats = await repository.getCategories();
      _customCategoryNames = cats.map((c) => c.name).toList();
      if (_customCategoryNames.isNotEmpty) {
        _log.info('Custom categories untuk prompt: $_customCategoryNames');
      }
    } else {
      _model = _modelFromEnv;
      _customCategoryNames = [];
    }
  }

  /// Override model at runtime (called from SettingsScreen).
  void updateModel(String model) {
    _model = model;
    _log.info('Model diubah: $model');
  }

  Future<OCRResult> recognizeTextFromImage(String imagePath) async {
    try {
      final file = File(imagePath);
      if (!await file.exists()) {
        throw Exception('Image file does not exist: $imagePath');
      }

      if (_apiKey.isEmpty) {
        throw Exception(
          'OPENROUTER_API_KEY tidak diatur di file .env.\n'
          'Dapatkan API key gratis di https://openrouter.ai/keys\n'
          'Lalu tambahkan ke file .env di root project.',
        );
      }

      _log.info('Memproses gambar dengan AI OCR (OpenRouter)...');
      _log.debug('Model: $_model');

      // Convert image to base64
      final bytes = await file.readAsBytes();
      final base64Image = base64Encode(bytes);

      // Detect MIME type
      final mimeType = _getMimeType(imagePath);

      // Build prompt with categories for AI categorization
      final categories = [
        'IPL', 'Listrik', 'Air', 'WIFI', 'Groceries', 'Buah-buahan',
        'Bahan Makanan', 'Laundry', 'Makanan', 'Transportasi',
        'Rekreasi', 'Tak Terduga', 'Tabungan Apart', 'Skincare & Make Up', 'Pakaian',
        ..._customCategoryNames,
      ];

      final prompt = '''
You are an expert receipt OCR system. Analyze the attached image of a receipt.

First, determine the receipt **type**:
- "itemized": each item has its own price → include "price" per item
- "summary": only a total is visible without individual prices → set each item price to 0

Return ONLY valid JSON matching this structure:

For itemized:
{
  "type": "itemized",
  "items": [
    {"name": "Item Name", "price": 15000, "category": "Makanan"},
    {"name": "Another Item", "price": 37000, "category": "Groceries"}
  ],
  "total": 52000
}

For summary:
{
  "type": "summary",
  "items": [
    {"name": "Item Name 1", "price": 0, "category": "Makanan"},
    {"name": "Item Name 2", "price": 0, "category": "Makanan"}
  ],
  "total": 57400
}

Available categories (pick the closest match for each item):
${categories.map((c) => '- $c').join('\n')}

Rules:
1. Extract EVERY product item name listed on the receipt.
2. "type" must be "itemized" or "summary".
3. "price" must be a number (integer or float). Convert Indonesian format (e.g., "15.000" -> 15000).
4. For "summary" type, set each item's price to 0 and use "total" for the grand total.
5. "category" must be one of the available categories listed above.
6. CRITICAL: "total" is the GRAND TOTAL printed on the receipt — the final amount paid. This is NOT the sum of "items". "total" is its own field and already includes taxes, service fees, shipping, discounts, etc. Always read "total" from the receipt's final amount line, never calculate it from items. The sum of items may differ from total due to fees/discounts.
7. Ignore headers, footers, dates, and "Thank You" messages.
8. If the receipt is in Indonesian, keep the item names in Indonesian.
9. Do NOT return markdown code blocks (like ```json). Return raw JSON only.
10. If no items are found, return {"type": "summary", "items": [], "total": 0}.
11. IMPORTANT — Exclude these from "items" (they are NOT products):
    - Pajak / Tax / PPN / PPnBM
    - Ongkos kirim / Shipping fee / Delivery fee
    - Biaya layanan / Service charge / Service fee
    - Biaya platform / Platform fee / Admin fee
    - Diskon / Discount / Potongan harga
    - Kembalian / Change due
    - Any other fee or charge that is not a physical product or service
    These are NOT products — they are already accounted for in "total".
12. "items" should ONLY contain actual products/goods purchased. The "total" field is independent and covers everything (fees, taxes, discounts). Do NOT create an item called "Total" or anything similar.
''';

      // Build request body
      final body = {
        'model': _model,
        'messages': [
          {
            'role': 'user',
            'content': [
              {
                'type': 'text',
                'text': prompt,
              },
              {
                'type': 'image_url',
                'image_url': {
                  'url': 'data:$mimeType;base64,$base64Image',
                },
              },
            ],
          },
        ],
        'response_format': {
          'type': 'json_object',
        },
        'max_tokens': 1000,
        'temperature': 0.1,
      };

      // Send request
      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
          'HTTP-Referer': 'https://receiptly.app',
          'X-Title': 'Receiptly',
        },
        body: jsonEncode(body),
      );

      _log.debug('Response status: ${response.statusCode}');

      if (response.statusCode != 200) {
        final errorMsg = response.body.length > 200
            ? response.body.substring(0, 200)
            : response.body;
        throw Exception('OpenRouter API error (${response.statusCode}): $errorMsg');
      }

      // Parse response
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final content = data['choices']?[0]?['message']?['content'] as String?;

      if (content == null || content.isEmpty) {
        throw Exception('AI tidak mengembalikan response');
      }

      _log.debug('AI Response: $content');

      // Parse JSON from response
      String rawContent = content.trim();
      // Remove markdown code blocks if present (common with Qwen)
      if (rawContent.startsWith('```')) {
        rawContent = rawContent.replaceAll(RegExp(r'^```json\s*|```$'), '').trim();
      }

      final parsed = jsonDecode(rawContent) as Map<String, dynamic>;

      final parser = const ParserFactory().detect(parsed);
      final items = parser.parseItems(parsed);
      final totalAmount = parser.parseTotal(parsed);
      final fullText = parsed['fullText'] as String? ?? content;

      _log.info('AI OCR detected type=${parser.type}, ${items.length} items, total: $totalAmount');
      for (var item in items) {
        _log.debug('  - $item');
      }

      return OCRResult(
        fullText: fullText,
        amount: totalAmount,
        items: items,
        source: InputMode.ai,
      );
    } catch (e) {
      _log.error('Error in AI OCR: $e');
      rethrow;
    }
  }

  /// Parse a number field that might also be a Map (token stats).
  /// Returns 0 if not a valid number.
  double _parseDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return 0;
  }

  String _getMimeType(String path) {
    final ext = path.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  /// Fetch credit/limit info for the current API key.
  Future<CreditInfo> fetchCreditInfo() async {
    if (_apiKey.isEmpty) {
      return CreditInfo(
        label: 'Tidak ada API key',
        isFree: true,
        limit: 0,
        limitRemaining: 0,
        usageTotal: 0,
        usageDaily: 0,
        usageMonthly: 0,
      );
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/auth/key'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        _log.warn('Gagal fetch credit info: ${response.statusCode}');
        return CreditInfo(
          label: 'Gagal memuat',
          isFree: true,
          limit: 0,
          limitRemaining: 0,
          usageTotal: 0,
          usageDaily: 0,
          usageMonthly: 0,
        );
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>?;

      if (data == null) {
        return CreditInfo(
          label: 'Response tidak valid',
          isFree: true,
          limit: 0,
          limitRemaining: 0,
          usageTotal: 0,
          usageDaily: 0,
          usageMonthly: 0,
        );
      }

      return CreditInfo(
        label: (data['label'] as String?) ?? '',
        isFree: (data['is_free'] as bool?) ?? true,
        limit: (data['limit'] as num?)?.toDouble() ?? 0,
        limitRemaining: _parseDouble(data['limit_remaining']),
        usageTotal: _parseDouble(data['usage']),
        usageDaily: _parseDouble(data['usage_daily']),
        usageMonthly: _parseDouble(data['usage_monthly']),
      );
    } catch (e) {
      _log.error('Error fetch credit info: $e');
      return CreditInfo(
        label: 'Error: ${e.toString().substring(0, 50)}',
        isFree: true,
        limit: 0,
        limitRemaining: 0,
        usageTotal: 0,
        usageDaily: 0,
        usageMonthly: 0,
      );
    }
  }
}
