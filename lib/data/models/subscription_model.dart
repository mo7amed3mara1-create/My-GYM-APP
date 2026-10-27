import '../../core/utils/date_helper.dart';

class SubscriptionModel {
  final int? id;
  final int memberId;
  final int planId;
  final DateTime startDate;
  final DateTime endDate;
  final double price;
  final double amountPaid;
  final bool isPaid;
  final DateTime? paidAt;
  final DateTime createdAt;
  final int? totalSessions;
  final int attendedSessions;

  // Joined display field
  final String? planName;

  SubscriptionModel({
    this.id,
    required this.memberId,
    required this.planId,
    required this.startDate,
    required this.endDate,
    required this.price,
    required this.amountPaid,
    required this.isPaid,
    this.paidAt,
    required this.createdAt,
    this.totalSessions,
    this.attendedSessions = 0,
    this.planName,
  });

  // Business Logic Computed Properties
  double get remainingAmount => (price - amountPaid) > 0 ? (price - amountPaid) : 0.0;
  int get daysLeft => DateHelper.daysRemaining(endDate);
  
  // Sessions logic
  bool get isSessionBased => totalSessions != null && totalSessions! > 0;
  int get remainingSessions => isSessionBased ? ((totalSessions! - attendedSessions) > 0 ? (totalSessions! - attendedSessions) : 0) : 0;
  bool get isSessionsDepleted => isSessionBased && attendedSessions >= totalSessions!;

  bool get isActive => DateHelper.isActive(endDate) && !isSessionsDepleted;
  bool get isExpired => DateHelper.isExpired(endDate) || isSessionsDepleted;
  bool isExpiringSoon(int warningDays) => DateHelper.isExpiringSoon(endDate, warningDays);
  bool get hasRemainingDebt => remainingAmount > 0;

  // Attendance Consistency Rate (0 to 100%)
  double get consistencyRate {
    if (isSessionBased) {
      if (totalSessions == null || totalSessions! <= 0) return 100.0;
      return ((attendedSessions / totalSessions!) * 100).clamp(0.0, 100.0);
    }
    final daysElapsed = DateTime.now().difference(startDate).inDays + 1;
    if (daysElapsed <= 0) return 100.0;
    // In gyms, attending 4+ days per week (~60% of total calendar days) is excellent commitment!
    final rawRate = (attendedSessions / (daysElapsed * 0.6)) * 100;
    return rawRate.clamp(0.0, 100.0);
  }

  String get consistencyBadge {
    final rate = consistencyRate;
    if (rate >= 75) return 'ملتزم ممتاز 🔥';
    if (rate >= 45) return 'ملتزم جيد 👍';
    return 'يحتاج تشجيع ⚠️';
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'member_id': memberId,
      'plan_id': planId,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'price': price,
      'amount_paid': amountPaid,
      'is_paid': isPaid ? 1 : 0,
      'paid_at': paidAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'total_sessions': totalSessions,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  factory SubscriptionModel.fromMap(Map<String, dynamic> map, {String? planName, int? attendedSessions}) {
    return SubscriptionModel(
      id: map['id'] as int?,
      memberId: map['member_id'] as int,
      planId: map['plan_id'] as int,
      startDate: DateTime.parse(map['start_date'] as String),
      endDate: DateTime.parse(map['end_date'] as String),
      price: (map['price'] as num).toDouble(),
      amountPaid: (map['amount_paid'] as num).toDouble(),
      isPaid: (map['is_paid'] as int) == 1,
      paidAt: map['paid_at'] != null ? DateTime.parse(map['paid_at'] as String) : null,
      createdAt: DateTime.parse(map['created_at'] as String),
      totalSessions: (map['total_sessions'] as num?)?.toInt(),
      attendedSessions: attendedSessions ?? (map['sub_visits'] as num?)?.toInt() ?? 0,
      planName: planName ?? (map['plan_name'] as String?),
    );
  }

  SubscriptionModel copyWith({
    int? id,
    int? memberId,
    int? planId,
    DateTime? startDate,
    DateTime? endDate,
    double? price,
    double? amountPaid,
    bool? isPaid,
    DateTime? paidAt,
    DateTime? createdAt,
    int? totalSessions,
    int? attendedSessions,
    String? planName,
  }) {
    return SubscriptionModel(
      id: id ?? this.id,
      memberId: memberId ?? this.memberId,
      planId: planId ?? this.planId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      price: price ?? this.price,
      amountPaid: amountPaid ?? this.amountPaid,
      isPaid: isPaid ?? this.isPaid,
      paidAt: paidAt ?? this.paidAt,
      createdAt: createdAt ?? this.createdAt,
      totalSessions: totalSessions ?? this.totalSessions,
      attendedSessions: attendedSessions ?? this.attendedSessions,
      planName: planName ?? this.planName,
    );
  }
}
