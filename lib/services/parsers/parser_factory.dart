import '../../models/receipt_type.dart';
import 'receipt_parser.dart';
import 'itemized_parser.dart';
import 'summary_parser.dart';

/// Selects the appropriate [ReceiptParser] based on the AI response content.
class ParserFactory {
  const ParserFactory();

  /// Detect type from JSON and return matching parser.
  /// Falls back to [ItemizedReceiptParser] which keeps items as-is.
  ReceiptParser detect(Map<String, dynamic> json) {
    final type = _detectType(json);
    return _parserFor(type);
  }

  ReceiptType _detectType(Map<String, dynamic> json) {
    // 1. Explicit type field from AI
    final explicitType = json['type'] as String?;
    if (explicitType != null) {
      return _parseType(explicitType);
    }

    // 2. Auto-detect from data
    final rawItems = json['items'] as List?;
    if (rawItems == null || rawItems.isEmpty) return ReceiptType.summary;

    final hasAnyPrice = rawItems.any((entry) {
      final item = entry as Map<String, dynamic>;
      return ((item['price'] as num?)?.toDouble() ?? 0) > 0;
    });

    if (hasAnyPrice) return ReceiptType.itemized;

    return ReceiptType.summary;
  }

  ReceiptType _parseType(String s) {
    switch (s.toLowerCase()) {
      case 'itemized':
        return ReceiptType.itemized;
      case 'summary':
        return ReceiptType.summary;
      default:
        return ReceiptType.itemized;
    }
  }

  ReceiptParser _parserFor(ReceiptType type) {
    switch (type) {
      case ReceiptType.summary:
        return SummaryReceiptParser();
      case ReceiptType.itemized:
        return ItemizedReceiptParser();
    }
  }
}
