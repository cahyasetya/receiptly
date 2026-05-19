import '../../models/ocr_data.dart';
import '../../models/receipt_type.dart';

/// Strategy for extracting [OCRItem]s and total from an AI JSON response.
abstract class ReceiptParser {
  ReceiptType get type;
  List<OCRItem> parseItems(Map<String, dynamic> json);
  double? parseTotal(Map<String, dynamic> json);
}
