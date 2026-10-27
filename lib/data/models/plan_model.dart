class PlanModel {
  final int? id;
  final String name;
  final int durationMonths;
  final int? durationDays;
  final double price;
  final bool isActive;
  final int? totalSessions;

  PlanModel({
    this.id,
    required this.name,
    required this.durationMonths,
    this.durationDays,
    required this.price,
    this.isActive = true,
    this.totalSessions,
  });

  bool get isSessionBased => totalSessions != null && totalSessions! > 0;

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'name': name,
      'duration_months': durationMonths,
      'duration_days': durationDays,
      'price': price,
      'is_active': isActive ? 1 : 0,
      'total_sessions': totalSessions,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  factory PlanModel.fromMap(Map<String, dynamic> map) {
    return PlanModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      durationMonths: map['duration_months'] as int,
      durationDays: map['duration_days'] as int?,
      price: (map['price'] as num).toDouble(),
      isActive: (map['is_active'] as int) == 1,
      totalSessions: (map['total_sessions'] as num?)?.toInt(),
    );
  }

  PlanModel copyWith({
    int? id,
    String? name,
    int? durationMonths,
    int? durationDays,
    double? price,
    bool? isActive,
    int? totalSessions,
  }) {
    return PlanModel(
      id: id ?? this.id,
      name: name ?? this.name,
      durationMonths: durationMonths ?? this.durationMonths,
      durationDays: durationDays ?? this.durationDays,
      price: price ?? this.price,
      isActive: isActive ?? this.isActive,
      totalSessions: totalSessions ?? this.totalSessions,
    );
  }
}
