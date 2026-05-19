import '../../models/ocr_data.dart';
import '../../models/receipt_type.dart';
import 'receipt_parser.dart';

/// Each item from AI has its own price.
class ItemizedReceiptParser implements ReceiptParser {
  @override
  ReceiptType get type => ReceiptType.itemized;

  @override
  List<OCRItem> parseItems(Map<String, dynamic> json) {
    final items = <OCRItem>[];
    final raw = json['items'] as List?;
    if (raw == null) return items;

    for (final entry in raw) {
      final item = entry as Map<String, dynamic>;
      final name = (item['name'] as String?)?.trim() ?? '';
      final price = (item['price'] as num?)?.toDouble() ?? 0;
      final category = item['category'] as String?;
      if (name.isNotEmpty) {
        items.add(OCRItem(
          name: name,
          price: price,
          source: InputMode.ai,
          category: category,
        ));
      }
    }
    return items;
  }

  @override
  double? parseTotal(Map<String, dynamic> json) {
    return (json['total'] as num?)?.toDouble();
  }
}
