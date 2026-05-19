import '../../models/ocr_data.dart';
import '../../models/receipt_type.dart';
import 'receipt_parser.dart';

/// AI response has items without prices and a total.
/// Result: a single combined [OCRItem] with all names and the total price.
class SummaryReceiptParser implements ReceiptParser {
  @override
  ReceiptType get type => ReceiptType.summary;

  @override
  List<OCRItem> parseItems(Map<String, dynamic> json) {
    final raw = json['items'] as List?;
    if (raw == null || raw.isEmpty) return [];

    final names = <String>[];
    String? firstCategory;

    for (final entry in raw) {
      final item = entry as Map<String, dynamic>;
      final name = (item['name'] as String?)?.trim() ?? '';
      if (name.isNotEmpty) {
        names.add(name);
        firstCategory ??= item['category'] as String?;
      }
    }

    if (names.isEmpty) return [];

    final combinedName = names.join(', ');
    final total = (json['total'] as num?)?.toDouble() ?? 0;

    return [
      OCRItem(
        name: combinedName,
        price: total,
        source: InputMode.ai,
        category: firstCategory,
      ),
    ];
  }

  @override
  double? parseTotal(Map<String, dynamic> json) {
    return (json['total'] as num?)?.toDouble();
  }
}
