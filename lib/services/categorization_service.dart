import '../models/expense_category.dart';
import '../models/category.dart';
import '../rules/categorization_rules.dart';

class CategorizationService {
  /// Runtime-override keywords (added via [addKeyword]).
  /// Falls back to [categoryKeywords] for anything not overridden.
  static Map<ExpenseCategory, List<String>>? _keywordOverrides;

  /// Runtime-override regex (added via [addPattern]).
  static Map<ExpenseCategory, List<RegExp>>? _regexOverrides;

  static Map<ExpenseCategory, List<String>> get _keywords =>
      _keywordOverrides ?? categoryKeywords;

  static Map<ExpenseCategory, List<RegExp>> get _regex =>
      _regexOverrides ?? categoryRegex;

  static Map<ExpenseCategory, List<RegExp>> get _exclusions =>
      categoryExclusions;

  /// Reload rules from [categorization_rules.dart].
  /// Call this on hot reload so the new data takes effect.
  static void reload() {
    _keywordOverrides = null;
    _regexOverrides = null;
  }

  /// Add a custom keyword for a category at runtime.
  static void addKeyword(ExpenseCategory category, String keyword) {
    _keywordOverrides ??= {};
    _keywordOverrides!.putIfAbsent(category, () => []);
    _keywordOverrides![category]!.add(keyword.toLowerCase());
  }

  /// Add a custom regex pattern for a category at runtime.
  static void addPattern(ExpenseCategory category, String pattern) {
    _regexOverrides ??= {};
    _regexOverrides!.putIfAbsent(category, () => []);
    _regexOverrides![category]!.add(RegExp(pattern, caseSensitive: false));
  }

  /// Remove all custom patterns for a category (resets to rules file).
  static void clearPatterns(ExpenseCategory category) {
    if (_regexOverrides != null) {
      _regexOverrides!.remove(category);
    }
  }

  /// Guess the single best category from text.
  static ExpenseCategory guessCategory(String text) {
    return guessCategories(text).first;
  }

  /// Guess ranked category suggestions from text.
  static List<ExpenseCategory> guessCategories(String text) {
    final lowerText = text.toLowerCase();
    final scored = <ExpenseCategory, int>{};

    // Build set of excluded categories
    final excluded = <ExpenseCategory>{};
    for (final entry in _exclusions.entries) {
      for (final regex in entry.value) {
        if (regex.hasMatch(text) || regex.hasMatch(lowerText)) {
          excluded.add(entry.key);
        }
      }
    }

    // 1. Regex matches — score 2
    for (final entry in _regex.entries) {
      if (excluded.contains(entry.key)) continue;
      for (final regex in entry.value) {
        if (regex.hasMatch(text) || regex.hasMatch(lowerText)) {
          scored[entry.key] = (scored[entry.key] ?? 0) + 2;
        }
      }
    }

    // 2. Keyword matches — score 1
    for (final entry in _keywords.entries) {
      if (excluded.contains(entry.key)) continue;
      for (final keyword in entry.value) {
        if (lowerText.contains(keyword)) {
          scored[entry.key] = (scored[entry.key] ?? 0) + 1;
        }
      }
    }

    // 3. Sort by score descending, then by enum order for stability
    final sorted = scored.entries.toList()
      ..sort((a, b) {
        final scoreDiff = b.value.compareTo(a.value);
        if (scoreDiff != 0) return scoreDiff;
        return a.key.index.compareTo(b.key.index);
      });

    final result = sorted.map((e) => e.key).toList();

    // 4. Always include 'other' as last resort
    if (!result.contains(ExpenseCategory.other)) {
      result.add(ExpenseCategory.other);
    }

    return result;
  }

  /// Match text against custom category keywords.
  /// Returns matching [Category] names, ranked by score.
  static List<String> guessCustomCategories(String text, List<Category> customCats) {
    final lowerText = text.toLowerCase();
    final scored = <String, int>{};
    for (final cat in customCats) {
      for (final keyword in cat.keywords) {
        if (lowerText.contains(keyword.toLowerCase())) {
          scored[cat.name] = (scored[cat.name] ?? 0) + 1;
        }
      }
    }
    final sorted = scored.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sorted.map((e) => e.key).toList();
  }
}
