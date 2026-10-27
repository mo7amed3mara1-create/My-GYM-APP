import '../../core/constants/app_strings.dart';

class AppSettingsModel {
  final int warningDays;
  final int absenceThresholdDays;
  final String templateExpiry;
  final String templateOverdue;
  final String templateAbsent;
  final String templatePayment;
  final bool biometricsEnabled;
  final bool dailyReminderEnabled;
  final DateTime? lastBackupDate;

  AppSettingsModel({
    this.warningDays = 3,
    this.absenceThresholdDays = 7,
    this.templateExpiry = AppStrings.defaultExpiryTemplate,
    this.templateOverdue = AppStrings.defaultOverdueTemplate,
    this.templateAbsent = AppStrings.defaultAbsentTemplate,
    this.templatePayment = AppStrings.defaultPaymentReminderTemplate,
    this.biometricsEnabled = false,
    this.dailyReminderEnabled = true,
    this.lastBackupDate,
  });

  AppSettingsModel copyWith({
    int? warningDays,
    int? absenceThresholdDays,
    String? templateExpiry,
    String? templateOverdue,
    String? templateAbsent,
    String? templatePayment,
    bool? biometricsEnabled,
    bool? dailyReminderEnabled,
    DateTime? lastBackupDate,
  }) {
    return AppSettingsModel(
      warningDays: warningDays ?? this.warningDays,
      absenceThresholdDays: absenceThresholdDays ?? this.absenceThresholdDays,
      templateExpiry: templateExpiry ?? this.templateExpiry,
      templateOverdue: templateOverdue ?? this.templateOverdue,
      templateAbsent: templateAbsent ?? this.templateAbsent,
      templatePayment: templatePayment ?? this.templatePayment,
      biometricsEnabled: biometricsEnabled ?? this.biometricsEnabled,
      dailyReminderEnabled: dailyReminderEnabled ?? this.dailyReminderEnabled,
      lastBackupDate: lastBackupDate ?? this.lastBackupDate,
    );
  }

  Map<String, String> toKeyValues() {
    return {
      'warning_days': warningDays.toString(),
      'absence_threshold_days': absenceThresholdDays.toString(),
      'template_expiry': templateExpiry,
      'template_overdue': templateOverdue,
      'template_absent': templateAbsent,
      'template_payment': templatePayment,
      'biometrics_enabled': biometricsEnabled ? '1' : '0',
      'daily_reminder_enabled': dailyReminderEnabled ? '1' : '0',
      'last_backup_date': lastBackupDate?.toIso8601String() ?? '',
    };
  }

  factory AppSettingsModel.fromKeyValues(Map<String, String> map) {
    return AppSettingsModel(
      warningDays: int.tryParse(map['warning_days'] ?? '') ?? 3,
      absenceThresholdDays: int.tryParse(map['absence_threshold_days'] ?? '') ?? 7,
      templateExpiry: map['template_expiry'] ?? AppStrings.defaultExpiryTemplate,
      templateOverdue: map['template_overdue'] ?? AppStrings.defaultOverdueTemplate,
      templateAbsent: map['template_absent'] ?? AppStrings.defaultAbsentTemplate,
      templatePayment: map['template_payment'] ?? AppStrings.defaultPaymentReminderTemplate,
      biometricsEnabled: map['biometrics_enabled'] == '1',
      dailyReminderEnabled: map['daily_reminder_enabled'] != '0',
      lastBackupDate: map['last_backup_date'] != null && map['last_backup_date']!.isNotEmpty
          ? DateTime.tryParse(map['last_backup_date']!)
          : null,
    );
  }
}
