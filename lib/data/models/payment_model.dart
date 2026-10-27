class PaymentModel {
  final int? id;
  final int memberId;
  final int subscriptionId;
  final double amount;
  final DateTime date;

  // Joined fields
  final String? memberName;
  final String? planName;

  PaymentModel({
    this.id,
    required this.memberId,
    required this.subscriptionId,
    required this.amount,
    required this.date,
    this.memberName,
    this.planName,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'member_id': memberId,
      'subscription_id': subscriptionId,
      'amount': amount,
      'date': date.toIso8601String(),
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  factory PaymentModel.fromMap(Map<String, dynamic> map, {String? memberName, String? planName}) {
    return PaymentModel(
      id: map['id'] as int?,
      memberId: map['member_id'] as int,
      subscriptionId: map['subscription_id'] as int,
      amount: (map['amount'] as num).toDouble(),
      date: DateTime.parse(map['date'] as String),
      memberName: memberName ?? (map['member_name'] as String?),
      planName: planName ?? (map['plan_name'] as String?),
    );
  }
}
