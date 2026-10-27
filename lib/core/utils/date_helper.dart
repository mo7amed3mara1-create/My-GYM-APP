import 'package:intl/intl.dart';

/// Helper for date arithmetic, month-end calculations, and formatting.
class DateHelper {
  /// Strip time component so comparison is purely by calendar date.
  static DateTime dateOnly(DateTime dt) {
    return DateTime(dt.year, dt.month, dt.day);
  }

  /// Calculates end date using real calendar months and proper month-end clamping.
  /// Example: Jan 31 + 1 month = Feb 28 (or 29 in leap year).
  static DateTime addMonths(DateTime startDate, int months) {
    if (months <= 0) return startDate;

    final targetMonthTotal = (startDate.month - 1) + months;
    final newYear = startDate.year + (targetMonthTotal ~/ 12);
    final newMonth = (targetMonthTotal % 12) + 1;

    // Get number of days in the new month
    // Day 0 of the next month is the last day of the target month
    final daysInTargetMonth = DateTime(newYear, newMonth + 1, 0).day;
    final clampedDay = startDate.day > daysInTargetMonth ? daysInTargetMonth : startDate.day;

    return DateTime(newYear, newMonth, clampedDay);
  }

  /// Calculates end date for subscription given duration in months or days.
  /// Uses calendar-based day addition to remain immune to daylight saving time shifts.
  static DateTime calculateEndDate(DateTime startDate, {int durationMonths = 1, int? durationDays}) {
    if (durationDays != null && durationDays > 0) {
      return DateTime(startDate.year, startDate.month, startDate.day + durationDays);
    }
    return addMonths(startDate, durationMonths);
  }

  /// Difference in calendar days between two dates (target - reference).
  /// Positive if target is in future, negative if in past.
  static int daysRemaining(DateTime endDate, [DateTime? fromDate]) {
    final ref = dateOnly(fromDate ?? DateTime.now());
    final end = dateOnly(endDate);
    return end.difference(ref).inDays;
  }

  /// Check if subscription is active (today <= endDate).
  static bool isActive(DateTime endDate, [DateTime? fromDate]) {
    final ref = dateOnly(fromDate ?? DateTime.now());
    final end = dateOnly(endDate);
    return !end.isBefore(ref);
  }

  /// Check if subscription is expiring soon (active AND daysRemaining <= warningDays).
  static bool isExpiringSoon(DateTime endDate, int warningDays, [DateTime? fromDate]) {
    final remaining = daysRemaining(endDate, fromDate);
    return remaining >= 0 && remaining <= warningDays;
  }

  /// Check if subscription is expired (today > endDate).
  static bool isExpired(DateTime endDate, [DateTime? fromDate]) {
    final ref = dateOnly(fromDate ?? DateTime.now());
    final end = dateOnly(endDate);
    return end.isBefore(ref);
  }

  /// Formats date into readable Arabic or standard format (e.g., 2026/10/24).
  static String formatDate(DateTime dt) {
    return DateFormat('yyyy/MM/dd').format(dt);
  }

  /// Formats time in 12h format (e.g., 04:30 PM).
  static String formatTime(DateTime dt) {
    return DateFormat('hh:mm a').format(dt);
  }

  /// Formats full date and time.
  static String formatDateTime(DateTime dt) {
    return DateFormat('yyyy/MM/dd hh:mm a').format(dt);
  }

  /// Formats month for reports (e.g. 2026-10).
  static String formatYearMonth(DateTime dt) {
    return DateFormat('yyyy-MM').format(dt);
  }

  /// Parses date from yyyy-MM-dd or returns null.
  static DateTime? parseIsoDate(String? str) {
    if (str == null || str.trim().isEmpty) return null;
    return DateTime.tryParse(str);
  }

  /// Returns start of month.
  static DateTime startOfMonth(DateTime dt) {
    return DateTime(dt.year, dt.month, 1);
  }

  /// Returns end of month.
  static DateTime endOfMonth(DateTime dt) {
    return DateTime(dt.year, dt.month + 1, 0, 23, 59, 59);
  }
}
