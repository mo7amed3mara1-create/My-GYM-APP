import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/date_helper.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../data/models/member_model.dart';
import '../../../data/models/plan_model.dart';
import '../../providers/plans_provider.dart';
import '../../providers/members_provider.dart';
import '../../providers/revenue_provider.dart';

class RenewSubscriptionDialog extends ConsumerStatefulWidget {
  final MemberModel member;

  const RenewSubscriptionDialog({super.key, required this.member});

  @override
  ConsumerState<RenewSubscriptionDialog> createState() => _RenewSubscriptionDialogState();
}

class _RenewSubscriptionDialogState extends ConsumerState<RenewSubscriptionDialog> {
  final _amountPaidController = TextEditingController();
  late DateTime _startDate;
  PlanModel? _selectedPlan;
  bool _isInit = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final subRepo = ref.read(subscriptionRepoProvider);
    _startDate = subRepo.calculateDefaultRenewalStartDate(widget.member.currentSubscription);
  }

  @override
  void dispose() {
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

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _confirmRenew() async {
    if (_selectedPlan == null) return;
    setState(() => _isLoading = true);

    final subRepo = ref.read(subscriptionRepoProvider);
    final amountPaid = double.tryParse(_amountPaidController.text) ?? _selectedPlan!.price;

    try {
      await subRepo.renewSubscription(
        memberId: widget.member.id,
        plan: _selectedPlan!,
        startDate: _startDate,
        amountPaid: amountPaid,
      );

      ref.read(membersProvider.notifier).loadMembers();
      ref.invalidate(dashboardStatsProvider);

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم تجديد اشتراك (${widget.member.name}) بنجاح'),
            backgroundColor: AppColors.statusGreenFg,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في التجديد: $e'), backgroundColor: AppColors.statusRedFg),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final plansAsync = ref.watch(activePlansProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: AppColors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.statusTealBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.autorenew_rounded, size: 22, color: AppColors.statusTealFg),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${AppStrings.renewTitle} - ${widget.member.name}',
                    style: GoogleFonts.cairo(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              AppStrings.autoRenewalNote,
              style: GoogleFonts.cairo(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),

            // Plan Dropdown
            plansAsync.when(
              data: (plans) {
                if (_selectedPlan == null && _isInit && plans.isNotEmpty) {
                  _isInit = false;
                  _selectedPlan = plans.first;
                  _amountPaidController.text = _selectedPlan!.price.toStringAsFixed(0);
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.plan,
                      style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSecondary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<PlanModel>(
                          isExpanded: true,
                          value: _selectedPlan,
                          items: plans.map((p) {
                            final sessionInfo = p.isSessionBased ? ' (${p.totalSessions} حصة)' : '';
                            return DropdownMenuItem<PlanModel>(
                              value: p,
                              child: Text(
                                '${p.name}$sessionInfo (${p.price.toStringAsFixed(0)} ${AppStrings.currency})',
                                style: GoogleFonts.cairo(fontSize: 13.5, fontWeight: FontWeight.w600),
                              ),
                            );
                          }).toList(),
                          onChanged: (p) {
                            setState(() {
                              _selectedPlan = p;
                              if (p != null) {
                                _amountPaidController.text = p.price.toStringAsFixed(0);
                              }
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('خطأ: $e'),
            ),

            const SizedBox(height: 14),

            // Start Date
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.renewStartDate,
                  style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 6),
                InkWell(
                  onTap: _pickStartDate,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSecondary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateHelper.formatDate(_startDate),
                          style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                        const Icon(Icons.calendar_month_outlined, size: 18, color: AppColors.primary),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // End date preview
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.statusTealBg.withOpacity(0.4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'تاريخ الانتهاء الجديد:',
                    style: GoogleFonts.cairo(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.statusTealFg),
                  ),
                  Text(
                    DateHelper.formatDate(_calculatedEndDate),
                    style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.statusTealFg),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Amount Paid
            CustomTextField(
              controller: _amountPaidController,
              label: AppStrings.amountPaid,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
            ),

            const SizedBox(height: 24),

            // Buttons
            CustomButton(
              label: 'تأكيد التجديد',
              icon: Icons.check_circle_outline_rounded,
              isLoading: _isLoading,
              onPressed: _confirmRenew,
            ),
            const SizedBox(height: 10),
            CustomButton(
              label: AppStrings.cancel,
              type: ButtonType.secondary,
              onPressed: () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      ),
    );
  }
}
