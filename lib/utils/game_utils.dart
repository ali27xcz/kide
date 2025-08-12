import 'dart:math' as math;

class GameUtils {
  /// Compute star count based on score percentage, aligned with ProgressTracker logic.
  /// 3 stars: >= 90%, 2 stars: >= 70%, 1 star: >= 50%, else 0.
  static int computeStars({required int score, required int maxScore}) {
    if (maxScore <= 0) return 0;
    final double ratio = score / math.max(maxScore, 1);
    if (ratio >= 0.9) return 3;
    if (ratio >= 0.7) return 2;
    if (ratio >= 0.5) return 1;
    return 0;
  }
}


