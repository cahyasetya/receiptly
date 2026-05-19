import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../models/index.dart';

class OCRService {
  static final OCRService _instance = OCRService._internal();

  factory OCRService() => _instance;

  OCRService._internal();

  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  Future<OCRResult> recognizeTextFromImage(String imagePath) async {
    try {
      final file = File(imagePath);
      if (!await file.exists()) {
        throw Exception('Image file does not exist: $imagePath');
      }

      final inputImage = InputImage.fromFile(file);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);

      final fullText = recognizedText.text;

      // --- LOGGING ---
      print('--- START OCR EXTRACTED TEXT ---');
      print(fullText);
      print('--- END OCR EXTRACTED TEXT ---');

      // Extract merchant name and amount from OCR text
      final merchantName = _extractMerchantName(fullText);
      final totalAmount = _extractAmount(fullText);
      final items = _extractItems(fullText);

      print('Detected Merchant: $merchantName');
      print('Detected Total: $totalAmount');
      print('Detected Items: ${items.length}');
      for (var item in items) {
        print('  - $item');
      }

      return OCRResult(
        fullText: fullText,
        merchantName: merchantName,
        amount: totalAmount,
        items: items,
      );
    } catch (e) {
      print('Error recognizing text: $e');
      rethrow;
    }
  }

  List<OCRItem> _extractItems(String text) {
    final List<OCRItem> items = [];
    final lines = text.split('\n');

    // Pattern to find price at the end of a line
    // e.g., "Burger 10.99" or "Coffee .... 4.50"
    final itemRegex = RegExp(r'^(.*?)\s+[\$€£]?\s*(\d+[.,]\d{2})$');

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      final match = itemRegex.firstMatch(trimmed);
      if (match != null) {
        final name = match.group(1)?.trim() ?? '';
        final priceStr = match.group(2)?.replaceAll(',', '.') ?? '0';

        if (name.isNotEmpty && !_isTotalKeyword(name)) {
          try {
            final price = double.parse(priceStr);
            items.add(OCRItem(name: name, price: price));
          } catch (e) {
            // Skip if price parsing fails
          }
        }
      }
    }
    return items;
  }

  bool _isTotalKeyword(String text) {
    final lower = text.toLowerCase();
    return lower.contains('total') ||
           lower.contains('sum') ||
           lower.contains('amount') ||
           lower.contains('balance') ||
           lower.contains('tax') ||
           lower.contains('subtotal');
  }

  String? _extractMerchantName(String text) {
    final lines = text.split('\n');
    if (lines.isEmpty) return null;

    // Usually the first non-empty line is the merchant name
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isNotEmpty && trimmed.length > 2 && trimmed.length < 100) {
        // Filter out amount-like strings and dates
        if (!_isLikelyAmount(trimmed) && !_isLikelyDate(trimmed)) {
          return trimmed;
        }
      }
    }

    return null;
  }

  double? _extractAmount(String text) {
    // Common patterns for prices: $10.99, 10.99, $10,99, etc.
    final patterns = [
      r'\$\s*(\d+[.,]\d{2})', // $10.99 or $10,99
      r'(?:total|amount|price|cost)[\s:]*\$?(\d+[.,]\d{2})',
      r'(\d+[.,]\d{2})\s*(?:USD|EUR|GBP)',
    ];

    for (final pattern in patterns) {
      final regex = RegExp(pattern, caseSensitive: false);
      final match = regex.firstMatch(text);
      if (match != null) {
        final amountStr = match.group(1)?.replaceAll(',', '.');
        try {
          return double.parse(amountStr ?? '0');
        } catch (e) {
          continue;
        }
      }
    }

    // Fallback: look for any number sequence with decimals
    final fallbackRegex = RegExp(r'(\d+[.,]\d{2})');
    final matches = fallbackRegex.allMatches(text);
    if (matches.isNotEmpty) {
      // Return the last amount found (usually total is at bottom)
      try {
        final lastMatch = matches.last.group(1)?.replaceAll(',', '.');
        return double.parse(lastMatch ?? '0');
      } catch (e) {
        return null;
      }
    }

    return null;
  }

  bool _isLikelyAmount(String text) {
    return RegExp(r'^\s*[\$€£]?\d+[.,]\d{2}\s*$').hasMatch(text);
  }

  bool _isLikelyDate(String text) {
    return RegExp(r'\d{1,2}[/-]\d{1,2}[/-]\d{2,4}').hasMatch(text);
  }

  void dispose() {
    _textRecognizer.close();
  }
}
