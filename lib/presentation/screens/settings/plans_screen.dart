import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../data/models/plan_model.dart';
import '../../providers/plans_provider.dart';

class PlansScreen extends ConsumerWidget {
  const PlansScreen({super.key});

  void _showAddEditPlanDialog(BuildContext context, WidgetRef ref, [PlanModel? planToEdit]) {
    final nameController = TextEditingController(text: planToEdit?.name ?? '');
    final monthsController = TextEditingController(text: planToEdit?.durationMonths.toString() ?? '1');
    final priceController = TextEditingController(text: planToEdit?.price.toStringAsFixed(0) ?? '');
    final sessionsController = TextEditingController(text: planToEdit?.totalSessions?.toString() ?? '');
    bool isActive = planToEdit?.isActive ?? true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            planToEdit == null ? AppStrings.addPlan : AppStrings.editPlan,
            style: GoogleFonts.cairo(fontWeight: FontWeight.w800),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CustomTextField(
                  controller: nameController,
                  label: AppStrings.planName,
                  hint: AppStrings.planNameHint,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: monthsController,
                  label: AppStrings.planDurationMonths,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: priceController,
                  label: AppStrings.planPrice,
                  hint: AppStrings.planPriceHint,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: sessionsController,
                  label: 'عدد الحصص (اختياري)',
                  hint: 'اتركه فارغاً إذا كانت الباقة مفتوحة بالأيام',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(AppStrings.activePlan, style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w600)),
                    Switch(
                      value: isActive,
                      activeColor: AppColors.primary,
                      onChanged: (v) => setDialogState(() => isActive = v),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(AppStrings.cancel, style: GoogleFonts.cairo(color: AppColors.textSecondary, fontWeight: FontWeight.w700)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () async {
                final name = nameController.text.trim();
                final months = int.tryParse(monthsController.text) ?? 1;
                final price = double.tryParse(priceController.text) ?? 0.0;
                final sessions = int.tryParse(sessionsController.text.trim());
                if (name.isEmpty || price <= 0) return;

                if (planToEdit != null) {
                  final updated = planToEdit.copyWith(
                    name: name,
                    durationMonths: months,
                    price: price,
                    isActive: isActive,
                    totalSessions: sessions,
                  );
                  await ref.read(plansProvider.notifier).updatePlan(updated);
                } else {
                  final newPlan = PlanModel(
                    name: name,
                    durationMonths: months,
                    price: price,
                    isActive: isActive,
                    totalSessions: sessions,
                  );
                  await ref.read(plansProvider.notifier).addPlan(newPlan);
                }

                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: Text(AppStrings.save, style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeletePlan(BuildContext context, WidgetRef ref, PlanModel plan) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(AppStrings.confirmDeletePlan, style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
        content: Text(
          'هل تريد بالتأكيد حذف أو تعطيل باقة (${plan.name})؟',
          style: GoogleFonts.cairo(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppStrings.cancel, style: GoogleFonts.cairo(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.statusRedFg),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(AppStrings.delete, style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed == true && plan.id != null) {
      await ref.read(plansProvider.notifier).deletePlan(plan.id!);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plansAsync = ref.watch(plansProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppHeader(
        title: AppStrings.plansTitle,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary),
            onPressed: () => _showAddEditPlanDialog(context, ref),
          ),
        ],
      ),
      body: plansAsync.when(
        data: (plans) {
          if (plans.isEmpty) {
            return Center(
              child: Text('لا توجد باقات مضافة', style: GoogleFonts.cairo()),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            itemCount: plans.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final plan = plans[index];
              return Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0x0C1B1F3B)),
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: plan.isActive ? AppColors.statusTealBg : AppColors.surfaceSecondary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.card_membership_rounded,
                        color: plan.isActive ? AppColors.statusTealFg : AppColors.textSecondary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            plan.name,
                            style: GoogleFonts.cairo(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'المدة: ${plan.durationMonths} شهر ${plan.isSessionBased ? '• ${plan.totalSessions} حصة' : '• مفتوح'} • ${plan.isActive ? 'مفعلة' : 'معطلة'}',
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              color: plan.isActive ? AppColors.statusTealFg : AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${plan.price.toStringAsFixed(0)} ${AppStrings.currency}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.textSecondary),
                      onPressed: () => _showAddEditPlanDialog(context, ref, plan),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.statusRedFg),
                      onPressed: () => _confirmDeletePlan(context, ref, plan),
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text('خطأ: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(AppStrings.addPlan, style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
        onPressed: () => _showAddEditPlanDialog(context, ref),
      ),
    );
  }
}
