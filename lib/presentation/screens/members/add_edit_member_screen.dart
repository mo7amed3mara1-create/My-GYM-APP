import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/app_notification.dart';
import '../../../core/utils/date_helper.dart';
import '../../../core/utils/phone_helper.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../data/models/member_model.dart';
import '../../../data/models/plan_model.dart';
import '../../../data/models/subscription_model.dart';
import '../../providers/members_provider.dart';
import '../../providers/plans_provider.dart';
import '../../providers/revenue_provider.dart';

class AddEditMemberScreen extends ConsumerStatefulWidget {
  final MemberModel? memberToEdit;

  const AddEditMemberScreen({super.key, this.memberToEdit});

  @override
  ConsumerState<AddEditMemberScreen> createState() => _AddEditMemberScreenState();
}

class _AddEditMemberScreenState extends ConsumerState<AddEditMemberScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();
  final _amountPaidController = TextEditingController();

  int? _generatedId;
  DateTime _startDate = DateHelper.dateOnly(DateTime.now());
  PlanModel? _selectedPlan;
  bool _isPaid = true;
  bool _isLoading = false;
  bool _isInit = true;

  @override
  void initState() {
    super.initState();
    if (widget.memberToEdit != null) {
      final m = widget.memberToEdit!;
      _nameController.text = m.name;
      _phoneController.text = m.phone;
      _notesController.text = m.notes ?? '';
      _generatedId = m.id;
    } else {
      _initNewMemberId();
    }
  }

  Future<void> _initNewMemberId() async {
    final memberRepo = ref.read(memberRepoProvider);
    final id = await memberRepo.generateUniqueMemberId();
    if (mounted) {
      setState(() {
        _generatedId = id;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    _amountPaidController.dispose();
    super.dispose();
  }

  DateTime get _calculatedEndDate {
    if (_selectedPlan == null) return _startDate;
    return DateHelper.calculateEndDate(
      _startDate,
      durationMonths: _selectedPlan!.durationMonths,
      durationDays: _selectedPlan!.durationDays,
    );
  }

  void _onPlanChanged(PlanModel? plan) {
    setState(() {
      _selectedPlan = plan;
      if (plan != null && _isPaid) {
        _amountPaidController.text = plan.price.toStringAsFixed(0);
      }
    });
  }

  void _onPaidToggled(bool value) {
    setState(() {
      _isPaid = value;
      if (value && _selectedPlan != null) {
        _amountPaidController.text = _selectedPlan!.price.toStringAsFixed(0);
      } else if (!value) {
        _amountPaidController.text = '0';
      }
    });
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final memberRepo = ref.read(memberRepoProvider);
    final phone = _phoneController.text.trim();

    // Check duplicate phone
    final phoneTaken = await memberRepo.isPhoneTaken(phone, widget.memberToEdit?.id);
    if (phoneTaken && mounted) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text('رقم الهاتف مكرر', style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
          content: Text(AppStrings.duplicatePhoneWarning, style: GoogleFonts.cairo(fontSize: 13)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(AppStrings.cancel, style: GoogleFonts.cairo(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(AppStrings.confirm, style: GoogleFonts.cairo(color: Colors.white)),
            ),
          ],
        ),
      );
      if (proceed != true) return;
    }

    setState(() => _isLoading = true);

    try {
      if (widget.memberToEdit != null) {
        // Edit existing member basic info
        final updated = widget.memberToEdit!.copyWith(
          name: _nameController.text.trim(),
          phone: phone,
          notes: _notesController.text.trim(),
        );
        await memberRepo.updateMember(updated);
      } else {
        // Create new member with initial subscription & payment
        final member = MemberModel(
          id: _generatedId!,
          name: _nameController.text.trim(),
          phone: phone,
          notes: _notesController.text.trim(),
          createdAt: DateTime.now(),
        );

        final amountPaid = double.tryParse(_amountPaidController.text) ?? 0.0;
        final sub = SubscriptionModel(
          memberId: member.id,
          planId: _selectedPlan!.id!,
          startDate: _startDate,
          endDate: _calculatedEndDate,
          price: _selectedPlan!.price,
          amountPaid: amountPaid,
          isPaid: _isPaid || amountPaid >= _selectedPlan!.price,
          paidAt: amountPaid > 0 ? DateTime.now() : null,
          totalSessions: _selectedPlan!.totalSessions,
          createdAt: DateTime.now(),
        );

        await memberRepo.createMemberWithSubscription(
          member: member,
          subscription: sub,
        );
      }

      ref.read(membersProvider.notifier).loadMembers();
      ref.invalidate(dashboardStatsProvider);

      if (mounted) {
        AppNotification.showSuccess(context, AppStrings.saveSuccess);
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        AppNotification.showError(context, 'خطأ أثناء الحفظ: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final plansAsync = ref.watch(activePlansProvider);
    final isEditing = widget.memberToEdit != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppHeader(
        title: isEditing ? AppStrings.editMemberTitle : AppStrings.addMemberTitle,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Auto-generated ID Live Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0x0C1B1F3B)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.statusTealBg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.badge_rounded, size: 20, color: AppColors.statusTealFg),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          AppStrings.autoGeneratedId,
                          style: GoogleFonts.cairo(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _generatedId != null ? _generatedId.toString() : '...',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Full Name
              CustomTextField(
                controller: _nameController,
                label: AppStrings.fullName,
                hint: AppStrings.fullNameHint,
                prefixIcon: Icons.person_outline_rounded,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return AppStrings.fieldRequired;
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Phone Number
              CustomTextField(
                controller: _phoneController,
                label: AppStrings.phoneNumber,
                hint: '01xxxxxxxxx',
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(11),
                ],
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return AppStrings.fieldRequired;
                  }
                  if (!PhoneHelper.isValidEgyptianMobile(val)) {
                    return 'رقم الهاتف يجب أن يتكون من 11 رقماً ويبدأ بـ 01 (مثل: 01012345678)';
                  }
                  return null;
                },
              ),

              if (!isEditing) ...[
                const SizedBox(height: 16),

                // Plan Dropdown
                plansAsync.when(
                  data: (plans) {
                    if (plans.isEmpty) {
                      return Text('يرجى إضافة باقات من الإعدادات أولاً', style: GoogleFonts.cairo(color: AppColors.statusRedFg));
                    }
                    if (_selectedPlan == null && _isInit) {
                      _isInit = false;
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _onPlanChanged(plans.first);
                      });
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceSecondary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.card_membership_rounded, size: 16, color: AppColors.primary),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              AppStrings.plan,
                              style: GoogleFonts.cairo(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 7),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: const [
                              BoxShadow(color: Color(0x061B1F3B), blurRadius: 10, offset: Offset(0, 3)),
                            ],
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<PlanModel>(
                              isExpanded: true,
                              value: _selectedPlan ?? plans.first,
                              items: plans.map((p) {
                                final sessionInfo = p.isSessionBased ? ' (${p.totalSessions} حصة)' : '';
                                return DropdownMenuItem<PlanModel>(
                                  value: p,
                                  child: Text(
                                    '${p.name}$sessionInfo - ${p.price.toStringAsFixed(0)} ${AppStrings.currency}',
                                    style: GoogleFonts.cairo(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: _onPlanChanged,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('خطأ في تحميل الباقات: $e'),
                ),

                const SizedBox(height: 16),

                // Start Date Picker
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceSecondary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.primary),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          AppStrings.startDate,
                          style: GoogleFonts.cairo(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    InkWell(
                      onTap: _pickStartDate,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: const [
                            BoxShadow(color: Color(0x061B1F3B), blurRadius: 10, offset: Offset(0, 3)),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateHelper.formatDate(_startDate),
                              style: GoogleFonts.cairo(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const Icon(Icons.date_range_rounded, color: AppColors.primary, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Calculated End Date Live Preview Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.statusTealBg.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.statusTealFg.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.event_available_rounded, size: 20, color: AppColors.statusTealFg),
                          const SizedBox(width: 8),
                          Text(
                            AppStrings.calculatedEndDate,
                            style: GoogleFonts.cairo(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.statusTealFg,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        DateHelper.formatDate(_calculatedEndDate),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.statusTealFg,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // Paid toggle
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0x0C1B1F3B)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppStrings.paidToggle,
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Switch(
                        value: _isPaid,
                        activeColor: AppColors.primary,
                        onChanged: _onPaidToggled,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Amount Paid field
                CustomTextField(
                  controller: _amountPaidController,
                  label: AppStrings.amountPaid,
                  hint: AppStrings.amountPaidHint,
                  prefixIcon: Icons.payments_outlined,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                ),
              ],

              const SizedBox(height: 16),

              // Notes
              CustomTextField(
                controller: _notesController,
                label: AppStrings.notes,
                hint: AppStrings.notesHint,
                prefixIcon: Icons.notes_rounded,
                maxLines: 2,
              ),

              const SizedBox(height: 32),

              // Action Buttons: Save and Cancel
              CustomButton(
                label: AppStrings.saveMember,
                icon: Icons.check_circle_outline_rounded,
                isLoading: _isLoading,
                onPressed: _save,
              ),
              const SizedBox(height: 12),
              CustomButton(
                label: AppStrings.cancel,
                type: ButtonType.secondary,
                onPressed: () => Navigator.of(context).pop(),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
