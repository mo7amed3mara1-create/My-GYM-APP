/// Generates clean, memorable, sequential numeric member IDs (1, 2, 3, 4...).
/// Fills gaps or increments sequentially, making it effortless for members
/// and captains to remember and type in check-in.
class IdGenerator {
  /// Generates the next sequential ID starting from 1 (or custom starting number).
  static Future<int> generateUniqueId({
    required Future<bool> Function(int id) isIdUsed,
    int startFrom = 1,
  }) async {
    int candidate = startFrom;
    while (await isIdUsed(candidate)) {
      candidate++;
    }
    return candidate;
  }

  /// Synchronous version for testing with pre-loaded Set or check function.
  static int generateUniqueIdSync({
    required bool Function(int id) isIdUsed,
    int startFrom = 1,
  }) {
    int candidate = startFrom;
    while (isIdUsed(candidate)) {
      candidate++;
    }
    return candidate;
  }
}
