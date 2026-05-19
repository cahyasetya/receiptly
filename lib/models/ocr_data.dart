/// Represents the source of expense data input.
enum InputMode {
  ai('AI Scan', '🤖', 'OCR dengan AI (OpenRouter)'),
  manual('Input Manual', '✍️', 'Input item secara manual');

  final String label;
  final String icon;
  final String description;

  const InputMode(this.label, this.icon, this.description);
}

class OCRItem {
  final String name;
  final double price;
  final InputMode source;
  final String? category;

  OCRItem({
    required this.name,
    required this.price,
    this.source = InputMode.ai,
    this.category,
  });

  @override
  String toString() => '$name: Rp${price.toStringAsFixed(0)}';
}

class OCRResult {
  final String fullText;
  final double? amount;
  final List<OCRItem> items;
  final InputMode source;

  OCRResult({
    required this.fullText,
    this.amount,
    this.items = const [],
    this.source = InputMode.ai,
  });
}
