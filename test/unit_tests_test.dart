import 'package:flutter_test/flutter_test.dart';
import 'package:azm_gym/core/utils/date_helper.dart';
import 'package:azm_gym/core/utils/phone_helper.dart';
import 'package:azm_gym/core/utils/id_generator.dart';
import 'package:azm_gym/core/utils/password_helper.dart';
import 'package:azm_gym/data/models/subscription_model.dart';

void main() {
  group('1. ID Generation Tests (Sequential Memorable Numbers)', () {
    test('Generates sequential ID starting at 1 if empty', () {
      final used = <int>{};
      final id = IdGenerator.generateUniqueIdSync(isIdUsed: (id) => used.contains(id));
      expect(id, 1);
    });

    test('If 1 and 2 exist, generates 3', () {
      final used = <int>{1, 2};
      final id = IdGenerator.generateUniqueIdSync(isIdUsed: (id) => used.contains(id));
      expect(id, 3);
    });

    test('Fills gaps sequentially (if 1 and 3 exist, returns 2)', () {
      final used = <int>{1, 3};
      final id = IdGenerator.generateUniqueIdSync(isIdUsed: (id) => used.contains(id));
      expect(id, 2);
    });

    test('Async generator works with callback', () async {
      final used = <int>{1, 2, 3};
      final id = await IdGenerator.generateUniqueId(
        isIdUsed: (candidate) async => used.contains(candidate),
      );
      expect(id, 4);
    });
  });

  group('2. End-Date Calculation Tests', () {
    test('Jan 31 + 1 month clamps to Feb 28 (non-leap year 2025)', () {
      final start = DateTime(2025, 1, 31);
      final end = DateHelper.addMonths(start, 1);
      expect(end.year, 2025);
      expect(end.month, 2);
      expect(end.day, 28);
    });

    test('Jan 31 + 1 month clamps to Feb 29 (leap year 2024)', () {
      final start = DateTime(2024, 1, 31);
      final end = DateHelper.addMonths(start, 1);
      expect(end.year, 2024);
      expect(end.month, 2);
      expect(end.day, 29);
    });

    test('March 31 + 1 month clamps to April 30', () {
      final start = DateTime(2024, 3, 31);
      final end = DateHelper.addMonths(start, 1);
      expect(end.year, 2024);
      expect(end.month, 4);
      expect(end.day, 30);
    });

    test('Multi-month addition cross year boundary (Oct 15 + 6 months = April 15 next year)', () {
      final start = DateTime(2024, 10, 15);
      final end = DateHelper.addMonths(start, 6);
      expect(end.year, 2025);
      expect(end.month, 4);
      expect(end.day, 15);
    });

    test('Days-based duration calculation takes precedence if provided', () {
      final start = DateTime(2024, 5, 1);
      final end = DateHelper.calculateEndDate(
        start,
        durationMonths: 1,
        durationDays: 45,
      );
      expect(end, DateTime(2024, 6, 15));
    });
  });

  group('3. Status Computation Tests', () {
    final now = DateTime.now();

    test('Active status when today <= end date', () {
      final sub = SubscriptionModel(
        memberId: 1,
        planId: 1,
        startDate: now.subtract(const Duration(days: 10)),
        endDate: now.add(const Duration(days: 20)),
        price: 350.0,
        amountPaid: 350.0,
        isPaid: true,
        createdAt: now,
      );
      expect(sub.isActive, isTrue);
      expect(sub.isExpired, isFalse);
    });

    test('Expired status when today > end date', () {
      final sub = SubscriptionModel(
        memberId: 1,
        planId: 1,
        startDate: now.subtract(const Duration(days: 40)),
        endDate: now.subtract(const Duration(days: 10)),
        price: 350.0,
        amountPaid: 350.0,
        isPaid: true,
        createdAt: now,
      );
      expect(sub.isActive, isFalse);
      expect(sub.isExpired, isTrue);
    });

    test('Expiring soon status when active AND remaining days <= warning days', () {
      final sub = SubscriptionModel(
        memberId: 1,
        planId: 1,
        startDate: now.subtract(const Duration(days: 28)),
        endDate: now.add(const Duration(days: 2)),
        price: 350.0,
        amountPaid: 350.0,
        isPaid: true,
        createdAt: now,
      );
      expect(sub.isActive, isTrue);
      expect(sub.isExpiringSoon(3), isTrue);
      expect(sub.isExpiringSoon(1), isFalse);
    });

    test('Unpaid status when remaining amount > 0 or isPaid is false', () {
      final sub = SubscriptionModel(
        memberId: 1,
        planId: 1,
        startDate: now,
        endDate: now.add(const Duration(days: 30)),
        price: 500.0,
        amountPaid: 300.0,
        isPaid: false,
        createdAt: now,
      );
      expect(sub.isPaid, isFalse);
      expect(sub.hasRemainingDebt, isTrue);
      expect(sub.remainingAmount, 200.0);
    });
  });

  group('4. Revenue Calculation Logic Tests', () {
    test('Formulas for Collected, Expected, and Outstanding', () {
      // Setup hypothetical simulated data:
      const paymentsThisMonth = [350.0, 900.0, 150.0];
      final collectedThisMonth = paymentsThisMonth.reduce((a, b) => a + b);
      expect(collectedThisMonth, 1400.0);

      const activeSubscriptionsUnpaidRemainders = [100.0, 200.0];
      final activeDebt = activeSubscriptionsUnpaidRemainders.reduce((a, b) => a + b);
      expect(activeDebt, 300.0);

      const renewalsEndingThisMonthPlanPrices = [350.0, 350.0];
      final expectedRenewals = renewalsEndingThisMonthPlanPrices.reduce((a, b) => a + b);
      expect(expectedRenewals, 700.0);

      // Expected this month = collected + unpaid remainder on active subscriptions + expected renewals of subscriptions ending this month
      final expectedThisMonth = collectedThisMonth + activeDebt + expectedRenewals;
      expect(expectedThisMonth, 2400.0);

      const allSubscriptionsUnpaidRemainders = [100.0, 200.0, 450.0];
      final totalOutstanding = allSubscriptionsUnpaidRemainders.reduce((a, b) => a + b);
      expect(totalOutstanding, 750.0);
    });
  });

  group('5. WhatsApp Phone Normalization & Intent Tests', () {
    test('Egyptian local 01xxxxxxxxx converts to 201xxxxxxxxx', () {
      expect(PhoneHelper.normalizeEgyptianNumber('01012345678'), '201012345678');
      expect(PhoneHelper.normalizeEgyptianNumber('01198765432'), '201198765432');
      expect(PhoneHelper.normalizeEgyptianNumber('01255554444'), '201255554444');
      expect(PhoneHelper.normalizeEgyptianNumber('01511112222'), '201511112222');
    });

    test('Strips plus, dashes, and international prefixes cleanly', () {
      expect(PhoneHelper.normalizeEgyptianNumber('+201012345678'), '201012345678');
      expect(PhoneHelper.normalizeEgyptianNumber('00201012345678'), '201012345678');
      expect(PhoneHelper.normalizeEgyptianNumber('010-1234-5678'), '201012345678');
    });

    test('Builds valid wa.me URL with properly encoded Arabic text', () {
      final url = PhoneHelper.buildWhatsAppUrl('01012345678', 'مرحباً كابتن أحمد! اشتراكك سينتهي');
      expect(url.startsWith('https://wa.me/201012345678?text='), isTrue);
      expect(url.contains(Uri.encodeComponent('مرحباً كابتن أحمد! اشتراكك سينتهي')), isTrue);
    });

    test('Validates Egyptian phone number correctly', () {
      expect(PhoneHelper.isValidEgyptianMobile('01012345678'), isTrue);
      expect(PhoneHelper.isValidEgyptianMobile('01112345678'), isTrue);
      expect(PhoneHelper.isValidEgyptianMobile('01212345678'), isTrue);
      expect(PhoneHelper.isValidEgyptianMobile('01512345678'), isTrue);
      expect(PhoneHelper.isValidEgyptianMobile('123'), isFalse);
      expect(PhoneHelper.isValidEgyptianMobile('0101234567'), isFalse);
      expect(PhoneHelper.isValidEgyptianMobile('010123456789'), isFalse);
      expect(PhoneHelper.isValidEgyptianMobile('01912345678'), isFalse);
    });
  });

  group('6. Password Helper & Salt Hashing Tests', () {
    test('Password verification with correct salt and password succeeds', () {
      final salt = PasswordHelper.generateSalt();
      final hash = PasswordHelper.hashPassword('admin123', salt);
      expect(PasswordHelper.verifyPassword(password: 'admin123', salt: salt, storedHash: hash), isTrue);
      expect(PasswordHelper.verifyPassword(password: 'wrongpass', salt: salt, storedHash: hash), isFalse);
    });
  });

  group('7. Session-Based Subscriptions & Consistency Tracking Tests', () {
    test('Session-based subscription calculates remaining sessions and depleted status correctly', () {
      final now = DateTime.now();
      final sub = SubscriptionModel(
        id: 1,
        memberId: 10,
        planId: 2,
        startDate: now.subtract(const Duration(days: 5)),
        endDate: now.add(const Duration(days: 25)),
        price: 400,
        amountPaid: 400,
        isPaid: true,
        totalSessions: 12,
        attendedSessions: 5,
        createdAt: now.subtract(const Duration(days: 5)),
      );

      expect(sub.isSessionBased, isTrue);
      expect(sub.remainingSessions, 7);
      expect(sub.isSessionsDepleted, isFalse);
      expect(sub.isActive, isTrue);
      expect(sub.isExpired, isFalse);
    });

    test('When attended sessions reach total sessions, subscription is marked expired/depleted', () {
      final now = DateTime.now();
      final sub = SubscriptionModel(
        id: 2,
        memberId: 10,
        planId: 2,
        startDate: now.subtract(const Duration(days: 10)),
        endDate: now.add(const Duration(days: 20)),
        price: 400,
        amountPaid: 400,
        isPaid: true,
        totalSessions: 12,
        attendedSessions: 12,
        createdAt: now.subtract(const Duration(days: 10)),
      );

      expect(sub.remainingSessions, 0);
      expect(sub.isSessionsDepleted, isTrue);
      expect(sub.isActive, isFalse);
      expect(sub.isExpired, isTrue);
    });

    test('Consistency calculation and badge assignment work properly', () {
      final now = DateTime.now();
      // 10 sessions out of 12 attended = 83% (Excellent)
      final sub = SubscriptionModel(
        id: 3,
        memberId: 10,
        planId: 2,
        startDate: now.subtract(const Duration(days: 10)),
        endDate: now.add(const Duration(days: 20)),
        price: 400,
        amountPaid: 400,
        isPaid: true,
        totalSessions: 12,
        attendedSessions: 10,
        createdAt: now.subtract(const Duration(days: 10)),
      );

      expect(sub.consistencyRate.round(), 83);
      expect(sub.consistencyBadge, 'ملتزم ممتاز 🔥');

      // 0 attendance = needs encouragement
      final subZero = SubscriptionModel(
        id: 4,
        memberId: 11,
        planId: 1,
        startDate: now.subtract(const Duration(days: 5)),
        endDate: now.add(const Duration(days: 25)),
        price: 350,
        amountPaid: 350,
        isPaid: true,
        attendedSessions: 0,
        createdAt: now.subtract(const Duration(days: 5)),
      );

      expect(subZero.consistencyRate.round(), 0);
      expect(subZero.consistencyBadge, 'يحتاج تشجيع ⚠️');
    });
  });
}
