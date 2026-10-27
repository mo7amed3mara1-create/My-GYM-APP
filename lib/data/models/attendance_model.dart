class AttendanceModel {
  final int? id;
  final int memberId;
  final String date; // YYYY-MM-DD
  final String time; // HH:mm:ss

  // Joined fields for check-in queue list
  final String? memberName;
  final String? phone;
  final String? planName;
  final int? daysLeft;
  final bool? isPaid;

  AttendanceModel({
    this.id,
    required this.memberId,
    required this.date,
    required this.time,
    this.memberName,
    this.phone,
    this.planName,
    this.daysLeft,
    this.isPaid,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'member_id': memberId,
      'date': date,
      'time': time,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  factory AttendanceModel.fromMap(Map<String, dynamic> map) {
    return AttendanceModel(
      id: (map['id'] as num?)?.toInt(),
      memberId: (map['member_id'] as num?)?.toInt() ?? 0,
      date: map['date'] as String? ?? '',
      time: map['time'] as String? ?? '',
      memberName: map['member_name'] as String?,
      phone: map['phone'] as String?,
      planName: map['plan_name'] as String?,
      daysLeft: (map['days_left'] as num?)?.toInt(),
      isPaid: map['is_paid'] != null ? ((map['is_paid'] as num?)?.toInt() == 1) : null,
    );
  }
}
