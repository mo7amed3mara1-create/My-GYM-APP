import 'subscription_model.dart';

class MemberModel {
  final int id;
  final String name;
  final String phone;
  final String? notes;
  final DateTime createdAt;

  // Joined/computed data
  final SubscriptionModel? currentSubscription;
  final DateTime? lastVisit;
  final int totalVisits;
  final int subVisits;

  MemberModel({
    required this.id,
    required this.name,
    required this.phone,
    this.notes,
    required this.createdAt,
    this.currentSubscription,
    this.lastVisit,
    this.totalVisits = 0,
    this.subVisits = 0,
  });

  double get consistencyRate => currentSubscription?.consistencyRate ?? 0.0;
  String get consistencyBadge => currentSubscription?.consistencyBadge ?? '';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory MemberModel.fromMap(Map<String, dynamic> map, {SubscriptionModel? subscription, DateTime? lastVisit, int? totalVisits, int? subVisits}) {
    return MemberModel(
      id: map['id'] as int,
      name: map['name'] as String,
      phone: map['phone'] as String,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      currentSubscription: subscription,
      lastVisit: lastVisit,
      totalVisits: totalVisits ?? (map['total_visits'] as num?)?.toInt() ?? 0,
      subVisits: subVisits ?? (map['sub_visits'] as num?)?.toInt() ?? 0,
    );
  }

  MemberModel copyWith({
    int? id,
    String? name,
    String? phone,
    String? notes,
    DateTime? createdAt,
    SubscriptionModel? currentSubscription,
    DateTime? lastVisit,
    int? totalVisits,
    int? subVisits,
  }) {
    return MemberModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      currentSubscription: currentSubscription ?? this.currentSubscription,
      lastVisit: lastVisit ?? this.lastVisit,
      totalVisits: totalVisits ?? this.totalVisits,
      subVisits: subVisits ?? this.subVisits,
    );
  }
}
