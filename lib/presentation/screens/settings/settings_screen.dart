import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/services/biometric_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/utils/app_notification.dart';
import '../../../core/utils/date_helper.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/module_row.dart';
import '../../../data/models/app_settings_model.dart';
import '../../../data/models/owner_model.dart';
import '../../../data/repositories/backup_repository.dart';
import '../../providers/auth_provider.dart';
import '../../providers/members_provider.dart';
import '../../providers/revenue_provider.dart';
import '../../providers/settings_provider.dart';
import '../auth/login_screen.dart';
import 'plans_screen.dart';

final backupRepoProvider = Provider<BackupRepository>((ref) => BackupRepository());

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _warningDaysController = TextEditingController();
  final _absenceDaysController = TextEditingController();
  final _expiryTemplateController = TextEditingController();
  final _overdueTemplateController = TextEditingController();
  final _absentTemplateController = TextEditingController();

  bool _isInit = true;
  bool _isExporting = false;
  bool _isRestoring = false;
  List<OwnerModel> _admins = [];

  @override
  void initState() {
    super.initState();
    _loadAdmins();
  }

  Future<void> _loadAdmins() async {
    final settingsRepo = ref.read(settingsRepoProvider);
    final admins = await settingsRepo.getAllAdmins();
    if (mounted) {
      setState(() => _admins = admins);
    }
  }

  @override
  void dispose() {
    _warningDaysController.dispose();
    _absenceDaysController.dispose();
    _expiryTemplateController.dispose();
    _overdueTemplateController.dispose();
    _absentTemplateController.dispose();
    super.dispose();
  }

  void _populate(AppSettingsModel s) {
    if (_isInit) {
      _isInit = false;
      _warningDaysController.text = s.warningDays.toString();
      _absenceDaysController.text = s.absenceThresholdDays.toString();
      _expiryTemplateController.text = s.templateExpiry;
      _overdueTemplateController.text = s.templateOverdue;
      _absentTemplateController.text = s.templateAbsent;
    }
  }

  Future<void> _saveGeneralSettings(AppSettingsModel current) async {
    final warningDays = int.tryParse(_warningDaysController.text) ?? 3;
    final absenceDays = int.tryParse(_absenceDaysController.text) ?? 7;

    final updated = current.copyWith(
      warningDays: warningDays,
      absenceThresholdDays: absenceDays,
      templateExpiry: _expiryTemplateController.text.trim(),
      templateOverdue: _overdueTemplateController.text.trim(),
      templateAbsent: _absentTemplateController.text.trim(),
    );

    await ref.read(settingsNotifierProvider.notifier).updateSettings(updated);
    ref.read(membersProvider.notifier).loadMembers();
    ref.invalidate(dashboardStatsProvider);

    if (mounted) {
      AppNotification.showSuccess(context, AppStrings.saveSuccess);
    }
  }

  Future<void> _exportBackupJson() async {
    setState(() => _isExporting = true);
    try {
      final backupRepo = ref.read(backupRepoProvider);
      await backupRepo.exportDatabaseJson();
      ref.invalidate(backupDueProvider);
      if (mounted) {
        AppNotification.showSuccess(context, AppStrings.backupSuccess);
      }
    } catch (e) {
      if (mounted) {
        AppNotification.showError(context, 'خطأ أثناء التصدير: $e');
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _exportMembersCsv() async {
    setState(() => _isExporting = true);
    try {
      final backupRepo = ref.read(backupRepoProvider);
      await backupRepo.exportMembersCsv();
      if (mounted) {
        AppNotification.showSuccess(context, 'تم تصدير ملف الأعضاء CSV بنجاح');
      }
    } catch (e) {
      if (mounted) {
        AppNotification.showError(context, 'خطأ أثناء تصدير CSV: $e');
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _importBackupJson() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(AppStrings.restoreConfirmTitle, style: GoogleFonts.cairo(fontWeight: FontWeight.w800)),
        content: Text(AppStrings.restoreConfirmBody, style: GoogleFonts.cairo(fontSize: 13, height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppStrings.cancel, style: GoogleFonts.cairo(color: AppColors.textSecondary, fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.statusRedFg),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(AppStrings.confirm, style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() => _isRestoring = true);
      try {
        final file = File(result.files.single.path!);
        final content = await file.readAsString();

        final backupRepo = ref.read(backupRepoProvider);
        final success = await backupRepo.restoreDatabaseFromJson(content);

        if (success) {
          ref.read(membersProvider.notifier).loadMembers();
          ref.invalidate(dashboardStatsProvider);
          ref.read(settingsNotifierProvider.notifier).loadSettings();
          await _loadAdmins();

          if (mounted) {
            AppNotification.showSuccess(context, AppStrings.restoreSuccess);
          }
        } else {
          if (mounted) {
            AppNotification.showError(context, AppStrings.restoreInvalidFile);
          }
        }
      } catch (e) {
        if (mounted) {
          AppNotification.showError(context, 'خطأ أثناء الاستعادة: $e');
        }
      } finally {
        if (mounted) setState(() => _isRestoring = false);
      }
    }
  }

  /// Two-step security verification before adding a new admin
  void _startAddAdminFlow() {
    final currentUsernameController = TextEditingController();
    final currentPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (authCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(AppStrings.verifyCurrentAdmin, style: GoogleFonts.cairo(fontWeight: FontWeight.w800, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'لحماية النظام، يرجى إدخال اسم المستخدم وكلمة المرور لحسابك الحالي أولاً للمتابعة:',
              style: GoogleFonts.cairo(fontSize: 12.5, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),
            CustomTextField(
              controller: currentUsernameController,
              label: AppStrings.username,
              prefixIcon: Icons.person_outline_rounded,
            ),
            const SizedBox(height: 10),
            CustomTextField(
              controller: currentPasswordController,
              label: AppStrings.password,
              prefixIcon: Icons.lock_outline_rounded,
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(authCtx),
            child: Text(AppStrings.cancel, style: GoogleFonts.cairo(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () async {
              final user = currentUsernameController.text.trim();
              final pass = currentPasswordController.text.trim();

              final settingsRepo = ref.read(settingsRepoProvider);
              final isValid = await settingsRepo.verifyCredentials(user, pass);

              if (authCtx.mounted) Navigator.pop(authCtx);

              if (isValid && mounted) {
                _showNewAdminFormDialog();
              } else if (mounted) {
                AppNotification.showError(context, AppStrings.invalidAdminCredentials);
              }
            },
            child: Text('تحقق ومتابعة', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showNewAdminFormDialog() {
    final newUsernameController = TextEditingController();
    final newDisplayNameController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(AppStrings.addAdmin, style: GoogleFonts.cairo(fontWeight: FontWeight.w800, fontSize: 16)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(
                controller: newUsernameController,
                label: 'اسم المستخدم للدخول (إنجليزي أو عربي)',
                prefixIcon: Icons.person_add_alt_1_rounded,
              ),
              const SizedBox(height: 10),
              CustomTextField(
                controller: newDisplayNameController,
                label: AppStrings.adminDisplayName,
                prefixIcon: Icons.badge_outlined,
              ),
              const SizedBox(height: 10),
              CustomTextField(
                controller: newPasswordController,
                label: AppStrings.password,
                prefixIcon: Icons.lock_outline_rounded,
                obscureText: true,
              ),
              const SizedBox(height: 10),
              CustomTextField(
                controller: confirmPasswordController,
                label: AppStrings.confirmPassword,
                prefixIcon: Icons.lock_reset_rounded,
                obscureText: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppStrings.cancel, style: GoogleFonts.cairo(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () async {
              final u = newUsernameController.text.trim();
              final d = newDisplayNameController.text.trim();
              final p = newPasswordController.text.trim();
              final cp = confirmPasswordController.text.trim();

              if (u.isEmpty || p.isEmpty) {
                AppNotification.showWarning(context, 'يرجى ملء جميع الحقول المطلوبة');
                return;
              }
              if (p.length < 4) {
                AppNotification.showWarning(context, AppStrings.passwordTooShort);
                return;
              }
              if (p != cp) {
                AppNotification.showWarning(context, AppStrings.passwordsDoNotMatch);
                return;
              }

              final settingsRepo = ref.read(settingsRepoProvider);
              final success = await settingsRepo.addAdmin(
                username: u,
                rawPassword: p,
                displayName: d.isNotEmpty ? d : u,
              );

              if (ctx.mounted) Navigator.pop(ctx);
              if (!mounted) return;

              if (success) {
                await _loadAdmins();
                if (mounted) {
                  AppNotification.showSuccess(context, AppStrings.adminAddedSuccess);
                }
              } else {
                AppNotification.showError(context, 'اسم المستخدم ($u) مسجل مسبقاً لمسؤول آخر');
              }
            },
            child: Text(AppStrings.save, style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(AppStrings.changePassword, style: GoogleFonts.cairo(fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomTextField(
              controller: currentPasswordController,
              label: AppStrings.currentPassword,
              obscureText: true,
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: newPasswordController,
              label: AppStrings.newPassword,
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppStrings.cancel, style: GoogleFonts.cairo(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () async {
              final oldP = currentPasswordController.text;
              final newP = newPasswordController.text;
              if (newP.length < 4) {
                AppNotification.showWarning(context, AppStrings.passwordTooShort);
                return;
              }

              final currentAdmin = ref.read(authProvider).owner;
              final settingsRepo = ref.read(settingsRepoProvider);
              final success = await settingsRepo.changePassword(
                oldP,
                newP,
                username: currentAdmin?.username,
              );
              if (ctx.mounted) Navigator.pop(ctx);

              if (mounted) {
                if (success) {
                  AppNotification.showSuccess(context, AppStrings.passwordChangedSuccess);
                } else {
                  AppNotification.showError(context, 'كلمة المرور الحالية غير صحيحة');
                }
              }
            },
            child: Text(AppStrings.save, style: GoogleFonts.cairo(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _sendTestNotification() async {
    try {
      await NotificationService.instance.showNotification(
        id: 999,
        title: 'MY GYM 🔔 تجربة التنبيهات الفورية',
        body: 'التنبيهات تعمل بنجاح! ستصلك إشعارات يومية لمتابعة الاشتراكات المنتهية والغائبين.',
      );
      if (mounted) {
        AppNotification.showSuccess(context, AppStrings.testNotificationSent);
      }
    } catch (e) {
      if (mounted) {
        AppNotification.showError(context, 'تعذر إرسال الإشعار: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsNotifierProvider);
    final currentAdmin = ref.watch(authProvider).owner;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppHeader(
        title: AppStrings.settingsTitle,
      ),
      body: settingsAsync.when(
        data: (settings) {
          _populate(settings);

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Plans Management Row
                ModuleRow(
                  icon: Icons.card_membership_rounded,
                  title: AppStrings.plansTitle,
                  subtitle: 'إضافة وتعديل وحذف باقات الاشتراك وأسعارها',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const PlansScreen()),
                    );
                  },
                ),

                const SizedBox(height: 18),

                // General Settings Card
                _buildCard(
                  title: AppStrings.generalSettings,
                  icon: Icons.tune_rounded,
                  children: [
                    CustomTextField(
                      controller: _warningDaysController,
                      label: AppStrings.warningDaysBeforeExpiry,
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.access_time_rounded,
                    ),
                    const SizedBox(height: 14),
                    CustomTextField(
                      controller: _absenceDaysController,
                      label: AppStrings.absenceThresholdDays,
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.event_busy_rounded,
                    ),
                    const SizedBox(height: 14),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      activeColor: AppColors.primary,
                      title: Text(
                        AppStrings.enableBiometrics,
                        style: GoogleFonts.cairo(fontSize: 13.5, fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        'إتاحة تسجيل الدخول ببصمة الإصبع أو الوجه',
                        style: GoogleFonts.cairo(fontSize: 11.5, color: AppColors.textSecondary),
                      ),
                      value: settings.biometricsEnabled,
                      onChanged: (val) async {
                        if (val) {
                          final canAuth = await BiometricService.instance.canAuthenticate();
                          if (!mounted) return;
                          if (!canAuth) {
                            AppNotification.showWarning(this.context, 'البصمة غير مدعومة أو غير مسجلة على هذا الهاتف');
                            return;
                          }
                          // Physical biometric validation check before activating
                          final bioResult = await BiometricService.instance.authenticate(
                            reason: 'يرجى تأكيد بصمة الإصبع للتحقق وتفعيل القفل بالبصمة',
                          );
                          if (!mounted) return;
                          if (!bioResult.isSuccess) {
                            AppNotification.showError(this.context, bioResult.message);
                            return;
                          }
                        }
                        await ref.read(settingsNotifierProvider.notifier).updateSettings(
                              settings.copyWith(biometricsEnabled: val),
                            );
                        if (mounted) {
                          AppNotification.showSuccess(
                            this.context,
                            val ? 'تم تفعيل التحقق بالبصمة بنجاح' : 'تم تعطيل التحقق بالبصمة',
                          );
                        }
                      },
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      activeColor: AppColors.primary,
                      title: Text(
                        AppStrings.dailyReminder,
                        style: GoogleFonts.cairo(fontSize: 13.5, fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        'إرسال إشعار للمسؤول بالاشتراكات المنتهية والغائبين',
                        style: GoogleFonts.cairo(fontSize: 11.5, color: AppColors.textSecondary),
                      ),
                      value: settings.dailyReminderEnabled,
                      onChanged: (val) async {
                        await ref.read(settingsNotifierProvider.notifier).updateSettings(
                              settings.copyWith(dailyReminderEnabled: val),
                            );
                      },
                    ),
                    if (settings.dailyReminderEnabled) ...[
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary, width: 1.2),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.notifications_active_outlined, size: 16),
                          label: Text(
                            AppStrings.testNotification,
                            style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                          onPressed: _sendTestNotification,
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    CustomButton(
                      label: AppStrings.save,
                      height: 46,
                      onPressed: () => _saveGeneralSettings(settings),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // Multi-Admins Management Card
                _buildCard(
                  title: AppStrings.adminSectionTitle,
                  icon: Icons.people_outline_rounded,
                  children: [
                    Text(
                      'يمكنك إضافة أكثر من كابتن أو مسؤول لإدارة الجيم بأمان:',
                      style: GoogleFonts.cairo(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 12),
                    // Admins list
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _admins.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, idx) {
                        final admin = _admins[idx];
                        final isCurrent = currentAdmin?.username.toLowerCase() == admin.username.toLowerCase();

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isCurrent ? AppColors.statusTealBg.withOpacity(0.4) : AppColors.surfaceSecondary,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isCurrent ? AppColors.statusTealFg.withOpacity(0.3) : Colors.transparent,
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: isCurrent ? AppColors.statusTealFg : AppColors.primary,
                                child: Text(
                                  admin.displayName.isNotEmpty ? admin.displayName[0] : 'A',
                                  style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w800),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          admin.displayName,
                                          style: GoogleFonts.cairo(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        if (isCurrent) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: AppColors.statusTealFg,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              'حسابك الحالي',
                                              style: GoogleFonts.cairo(fontSize: 9.5, color: Colors.white, fontWeight: FontWeight.w700),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    Text(
                                      '@${admin.username}',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (!isCurrent && _admins.length > 1) ...[
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.statusRedFg, size: 20),
                                  onPressed: () async {
                                    final confirmed = await showDialog<bool>(
                                      context: this.context,
                                      builder: (ctx) => AlertDialog(
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        title: Text('حذف المسؤول؟', style: GoogleFonts.cairo(fontWeight: FontWeight.w800)),
                                        content: Text(
                                          'هل أنت متأكد من حذف حساب المسؤول (${admin.displayName})؟ لن يتمكن من تسجيل الدخول بعد الآن.',
                                          style: GoogleFonts.cairo(),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx, false),
                                            child: Text(AppStrings.cancel, style: GoogleFonts.cairo(color: AppColors.textSecondary)),
                                          ),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.statusRedFg),
                                            onPressed: () => Navigator.pop(ctx, true),
                                            child: Text(AppStrings.delete, style: GoogleFonts.cairo(color: Colors.white)),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (confirmed == true) {
                                      final settingsRepo = ref.read(settingsRepoProvider);
                                      await settingsRepo.deleteAdmin(admin.username);
                                      if (!mounted) return;
                                      await _loadAdmins();
                                      if (mounted) {
                                        AppNotification.showSuccess(this.context, AppStrings.adminDeletedSuccess);
                                      }
                                    }
                                  },
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary, width: 1.2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        minimumSize: const Size(double.infinity, 44),
                      ),
                      icon: const Icon(Icons.person_add_rounded, size: 18),
                      label: Text(
                        AppStrings.addAdmin,
                        style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                      onPressed: _startAddAdminFlow,
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // WhatsApp Templates Card with Instant Reset
                _buildCard(
                  title: AppStrings.templatesTitle,
                  icon: Icons.chat_outlined,
                  children: [
                    Text(
                      AppStrings.templateHelp,
                      style: GoogleFonts.cairo(fontSize: 11.5, color: AppColors.primary, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 14),

                    // Expiry Template + Reset Button
                    _buildTemplateRowWithReset(
                      label: AppStrings.templateExpiryPrompt,
                      controller: _expiryTemplateController,
                      defaultText: AppStrings.defaultExpiryTemplate,
                    ),
                    const SizedBox(height: 14),

                    // Overdue Template + Reset Button
                    _buildTemplateRowWithReset(
                      label: AppStrings.templateOverduePrompt,
                      controller: _overdueTemplateController,
                      defaultText: AppStrings.defaultOverdueTemplate,
                    ),
                    const SizedBox(height: 14),

                    // Absent Template + Reset Button
                    _buildTemplateRowWithReset(
                      label: AppStrings.templateAbsentPrompt,
                      controller: _absentTemplateController,
                      defaultText: AppStrings.defaultAbsentTemplate,
                    ),
                    const SizedBox(height: 16),

                    CustomButton(
                      label: 'حفظ قوالب الرسائل',
                      height: 46,
                      onPressed: () => _saveGeneralSettings(settings),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // Backup & Restore Card
                _buildCard(
                  title: AppStrings.backupSection,
                  icon: Icons.shield_outlined,
                  children: [
                    Row(
                      children: [
                        Text(
                          AppStrings.lastBackupDate,
                          style: GoogleFonts.cairo(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          settings.lastBackupDate != null
                              ? DateHelper.formatDateTime(settings.lastBackupDate!)
                              : AppStrings.neverBackedUp,
                          style: GoogleFonts.cairo(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    CustomButton(
                      label: AppStrings.exportBackupJson,
                      icon: Icons.file_download_outlined,
                      isLoading: _isExporting,
                      onPressed: _exportBackupJson,
                    ),
                    const SizedBox(height: 10),
                    CustomButton(
                      label: AppStrings.exportMembersCsv,
                      icon: Icons.table_chart_outlined,
                      type: ButtonType.secondary,
                      onPressed: _exportMembersCsv,
                    ),
                    const SizedBox(height: 10),
                    CustomButton(
                      label: AppStrings.importBackupJson,
                      icon: Icons.file_upload_outlined,
                      type: ButtonType.secondary,
                      isLoading: _isRestoring,
                      onPressed: _importBackupJson,
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // Security & Password Card
                _buildCard(
                  title: AppStrings.securitySection,
                  icon: Icons.lock_outline_rounded,
                  children: [
                    CustomButton(
                      label: AppStrings.changePassword,
                      icon: Icons.password_rounded,
                      type: ButtonType.secondary,
                      onPressed: _showChangePasswordDialog,
                    ),
                    const SizedBox(height: 12),
                    CustomButton(
                      label: 'تسجيل الخروج',
                      icon: Icons.logout_rounded,
                      type: ButtonType.danger,
                      onPressed: () {
                        ref.read(authProvider.notifier).logout();
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                          (route) => false,
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 32),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text('خطأ: $e')),
      ),
    );
  }

  Widget _buildTemplateRowWithReset({
    required String label,
    required TextEditingController controller,
    required String defaultText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            TextButton.icon(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: const Icon(Icons.restart_alt_rounded, size: 15, color: AppColors.primary),
              label: Text(
                AppStrings.resetToDefault,
                style: GoogleFonts.cairo(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              onPressed: () {
                setState(() {
                  controller.text = defaultText;
                });
                AppNotification.showInfo(context, 'تمت استعادة النص الأصلي');
              },
            ),
          ],
        ),
        const SizedBox(height: 6),
        CustomTextField(
          controller: controller,
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x0C1B1F3B)),
        boxShadow: const [
          BoxShadow(color: Color(0x051B1F3B), blurRadius: 10, offset: Offset(0, 3)),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}
