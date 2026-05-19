/// How a receipt's items are structured.
enum ReceiptType {
  /// Each item has its own price.
  itemized,

  /// Only total is known; items have no individual prices.
  summary,
}
