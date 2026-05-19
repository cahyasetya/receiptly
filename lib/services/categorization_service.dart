import '../models/expense_category.dart';

class CategorizationService {
  static final Map<ExpenseCategory, List<String>> _categoryKeywords = {
    ExpenseCategory.food: [
      'mcdonald', 'burger', 'starbucks', 'coffee', 'cafe', 'restaurant', 'pizza', 'kfc', 'subway', 'bakery', 'donut'
    ],
    ExpenseCategory.transport: [
      'uber', 'grab', 'lyft', 'taxi', 'shell', 'petrol', 'gas', 'station', 'parking', 'bus', 'train', 'airline', 'flight'
    ],
    ExpenseCategory.utilities: [
      'electric', 'water', 'gas', 'internet', 'broadband', 'mobile', 'phone', 'telecom', 'netflix', 'spotify'
    ],
    ExpenseCategory.groceries: [
      'walmart', 'target', 'supermarket', 'grocery', 'tesco', 'costco', 'market', '7-eleven', 'convenience'
    ],
    ExpenseCategory.dining: [
      'steakhouse', 'grill', 'bistro', 'diner', 'pub', 'bar', 'sushi', 'ramen'
    ],
    ExpenseCategory.entertainment: [
      'cinema', 'movie', 'theater', 'concert', 'museum', 'zoo', 'park', 'game', 'steam', 'playstation'
    ],
    ExpenseCategory.shopping: [
      'amazon', 'ebay', 'zara', 'h&m', 'nike', 'adidas', 'apple', 'fashion', 'clothing', 'electronics'
    ],
    ExpenseCategory.healthcare: [
      'pharmacy', 'hospital', 'clinic', 'doctor', 'dentist', 'medical', 'cvs', 'walgreens'
    ],
  };

  static ExpenseCategory guessCategory(String text) {
    final lowerText = text.toLowerCase();

    for (var entry in _categoryKeywords.entries) {
      for (var keyword in entry.value) {
        if (lowerText.contains(keyword)) {
          return entry.key;
        }
      }
    }

    return ExpenseCategory.other;
  }

  static ExpenseCategory guessPrimaryCategory(String merchantName, String ocrText) {
    // Try merchant name first
    final merchantGuess = guessCategory(merchantName);
    if (merchantGuess != ExpenseCategory.other) return merchantGuess;

    // Try full OCR text
    return guessCategory(ocrText);
  }
}
