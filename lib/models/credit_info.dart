/// Information about the current API key's credits and usage from OpenRouter.
class CreditInfo {
  final String label;
  final bool isFree;
  final double limit;
  final double limitRemaining;
  final double usageTotal;
  final double usageDaily;
  final double usageMonthly;

  const CreditInfo({
    required this.label,
    required this.isFree,
    required this.limit,
    required this.limitRemaining,
    required this.usageTotal,
    required this.usageDaily,
    required this.usageMonthly,
  });

  double get usagePercentage =>
      limit > 0 ? ((usageTotal / limit) * 100).clamp(0, 100) : 0;

  double get remainingPercentage =>
      limit > 0 ? ((limitRemaining / limit) * 100).clamp(0, 100) : 0;

  String get formattedLimit => _formatCredits(limit);
  String get formattedRemaining => _formatCredits(limitRemaining);
  String get formattedUsed => _formatCredits(usageTotal);
  String get formattedDaily => _formatCredits(usageDaily);
  String get formattedMonthly => _formatCredits(usageMonthly);

  static String _formatCredits(double value) {
    if (value >= 1) {
      return '\$${value.toStringAsFixed(2)}';
    }
    return '\$${(value * 100).toStringAsFixed(1)}¢';
  }

  String get planLabel =>
      isFree ? 'Free (50 req/hari)' : 'Pay-as-you-go';

  bool get hasCredits => limit > 0;

  /// Whether remaining credit info is available.
  bool get hasRemaining => limitRemaining > 0 || limit > 0;
}
