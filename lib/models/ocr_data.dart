class OCRItem {
  final String name;
  final double price;

  OCRItem({required this.name, required this.price});

  @override
  String toString() => '$name: \$${price.toStringAsFixed(2)}';
}

class OCRResult {
  final String fullText;
  final String? merchantName;
  final double? amount;
  final List<OCRItem> items;

  OCRResult({
    required this.fullText,
    this.merchantName,
    this.amount,
    this.items = const [],
  });
}
