import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/date_helper.dart';
import '../../../core/utils/phone_helper.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../data/models/member_model.dart';
import '../../../data/models/attendance_model.dart';
import '../../../data/models/payment_model.dart';
import '../../../data/models/subscription_model.dart';
import '../../providers/members_provider.dart';
import '../../providers/revenue_provider.dart';
import 'add_edit_member_screen.dart';
import 'renew_subscription_dialog.dart';

class MemberDetailsScreen extends ConsumerStatefulWidget {
  final int memberId;

  const MemberDetailsScreen({super.key, required this.memberId});

  @override
  ConsumerState<MemberDetailsScreen> createState() => _MemberDetailsScreenState();
}

class _MemberDetailsScreenState extends ConsumerState<MemberDetailsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  MemberModel? _member;
  List<AttendanceModel> _attendance = [];
  List<SubscriptionModel> _subscriptions = [];
  List<PaymentModel> _payments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadMemberData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMemberData() async {
    setState(() => _isLoading = true);
    final repo = ref.read(memberRepoProvider);
    final m = await repo.getMemberById(widget.memberId);
    if (m != null) {
      final att = await repo.getAttendanceHistory(widget.memberId);
      final subs = await repo.getSubscriptionHistory(widget.memberId);
      final pays = await repo.getPaymentHistory(widget.memberId);
      if (mounted) {
        setState(() {
          _member = m;
          _attendance = att;
          _subscriptions = subs;
          _payments = pays;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _callMember() {
    if (_member != null) {
      PhoneHelper.launchPhoneCall(_member!.phone);
    }
  }

  void _sendWhatsApp() {
    if (_member != null) {
      final msg = 'مرحباً ${_member!.name}، نتواصل معك من ${AppStrings.appName}. نتشرف دائماً بوجودك معنا!';
      PhoneHelper.launchWhatsApp(_member!.phone, msg);
    }
  }

  Future<void> _renew() async {
    if (_member == null) return;
    final renewed = await showDialog<bool>(
      context: context,
      builder: (ctx) => RenewSubscriptionDialog(member: _member!),
    );
    if (renewed == true) {
      _loadMemberData();
    }
  }

  Future<void> _editMember() async {
    if (_member == null) return;
    final edited = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AddEditMemberScreen(memberToEdit: _member)),
    );
    if (edited == true) {
      _loadMemberData();
    }
  }

  Future<void> _confirmDelete() async {
    if (_member == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.statusRedFg),
            const SizedBox(width: 8),
            Text(AppStrings.confirmDeleteMember, style: GoogleFonts.cairo(fontWeight: FontWeight.w800)),
          ],
        ),
        content: Text(
          AppStrings.deleteMemberWarning,
          style: GoogleFonts.cairo(fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppStrings.cancel, style: GoogleFonts.cairo(color: AppColors.textSecondary, fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.statusRedFg),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(AppStrings.delete, style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(membersProvider.notifier).deleteMember(_member!.id);
      ref.invalidate(dashboardStatsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.memberDeleted),
            backgroundColor: AppColors.textPrimary,
          ),
        );
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppHeader(title: AppStrings.memberDetails),
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (_member == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: const AppHeader(title: AppStrings.memberDetails),
        body: Center(
          child: Text('العضو غير موجود', style: GoogleFonts.cairo(fontSize: 16)),
        ),
      );
    }

    final m = _member!;
    final sub = m.currentSubscription;
    final isActive = sub != null && sub.isActive;
    final isPaid = sub != null && sub.isPaid && !sub.hasRemainingDebt;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppHeader(
        title: AppStrings.memberDetails,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.textPrimary),
            onPressed: _editMember,
            tooltip: AppStrings.edit,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.statusRedFg),
            onPressed: _confirmDelete,
            tooltip: AppStrings.delete,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Member Header Card
            Container(
              color: AppColors.surface,
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Large ID Box
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSecondary,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.primary.withOpacity(0.15)),
                        ),
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'ID',
                              style: GoogleFonts.cairo(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                            ),
                            Text(
                              m.id.toString(),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Name & Phone & Badges
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              m.name,
                              style: GoogleFonts.cairo(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            InkWell(
                              onTap: _callMember,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.phone_rounded, size: 16, color: AppColors.primary),
                                  const SizedBox(width: 6),
                                  Text(
                                    m.phone,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                StatusBadge(
                                  status: isActive
                                      ? (sub.daysLeft <= 3 ? MemberStatusType.expiring : MemberStatusType.active)
                                      : MemberStatusType.expired,
                                  customText: isActive
                                      ? (sub.daysLeft <= 3 ? 'ينتهي قريباً (${sub.daysLeft} يوم)' : 'اشتراك ساري')
                                      : 'منتهي الصلاحية',
                                ),
                                if (sub != null)
                                  StatusBadge(
                                    status: isPaid ? MemberStatusType.paid : MemberStatusType.unpaid,
                                    customText: isPaid ? 'مسدد بالكامل' : 'متبقي ${sub.remainingAmount.toStringAsFixed(0)} ${AppStrings.currency}',
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Communication Buttons (Call & WhatsApp)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.primary),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            minimumSize: const Size(0, 44),
                          ),
                          icon: const Icon(Icons.phone_rounded, size: 18, color: AppColors.primary),
                          label: Text(
                            AppStrings.callMember,
                            style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary),
                          ),
                          onPressed: _callMember,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF25D366),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            minimumSize: const Size(0, 44),
                          ),
                          icon: const Icon(Icons.chat_rounded, size: 18),
                          label: Text(
                            AppStrings.sendWhatsApp,
                            style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w700),
                          ),
                          onPressed: _sendWhatsApp,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Current Subscription Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0x0C1B1F3B)),
                  boxShadow: const [
                    BoxShadow(color: Color(0x041B1F3B), blurRadius: 10, offset: Offset(0, 3)),
                  ],
                ),
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceSecondary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.fitness_center_rounded, size: 18, color: AppColors.primary),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              AppStrings.currentSubscription,
                              style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                            ),
                          ],
                        ),
                        // Renew Button
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            minimumSize: const Size(0, 36),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.autorenew_rounded, size: 16),
                          label: Text(
                            AppStrings.renewSubscription,
                            style: GoogleFonts.cairo(fontSize: 12.5, fontWeight: FontWeight.w700),
                          ),
                          onPressed: _renew,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (sub != null) ...[
                      Row(
                        children: [
                          Expanded(
                            child: _buildDetailTile(
                              title: 'الباقة',
                              value: sub.planName ?? 'مخصصة',
                            ),
                          ),
                          Expanded(
                            child: _buildDetailTile(
                              title: 'السعر',
                              value: '${sub.price.toStringAsFixed(0)} ${AppStrings.currency}',
                            ),
                          ),
                          Expanded(
                            child: _buildDetailTile(
                              title: 'المسدد',
                              value: '${sub.amountPaid.toStringAsFixed(0)} ${AppStrings.currency}',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildDetailTile(
                              title: 'تاريخ البدء',
                              value: DateHelper.formatDate(sub.startDate),
                            ),
                          ),
                          Expanded(
                            child: _buildDetailTile(
                              title: 'تاريخ الانتهاء',
                              value: DateHelper.formatDate(sub.endDate),
                            ),
                          ),
                          Expanded(
                            child: _buildDetailTile(
                              title: sub.isSessionBased ? 'الحصص المتبقية' : 'الأيام المتبقية',
                              value: sub.isSessionBased ? '${sub.remainingSessions} من ${sub.totalSessions}' : '${sub.daysLeft} يوم',
                              valueColor: sub.isActive ? AppColors.statusTealFg : AppColors.statusRedFg,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSecondary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'الحضور والالتزام:',
                              style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                            ),
                            Text(
                              '${sub.attendedSessions} يوم • التزام ${sub.consistencyRate.toInt()}% (${sub.consistencyBadge})',
                              style: GoogleFonts.cairo(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: sub.consistencyRate >= 65 ? AppColors.statusTealFg : AppColors.statusAmberFg,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      Text('لا يوجد اشتراك نشط حالياً', style: GoogleFonts.cairo(color: AppColors.textSecondary)),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Tab bar for: Attendance History, Subscriptions History, Payments
            Container(
              color: AppColors.surface,
              child: TabBar(
                controller: _tabController,
                indicatorColor: AppColors.primary,
                indicatorWeight: 3,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w800),
                unselectedLabelStyle: GoogleFonts.cairo(fontSize: 12.5, fontWeight: FontWeight.w600),
                tabs: [
                  Tab(text: '${AppStrings.attendanceHistory} (${_attendance.length})'),
                  Tab(text: '${AppStrings.subscriptionHistory} (${_subscriptions.length})'),
                  Tab(text: '${AppStrings.paymentHistory} (${_payments.length})'),
                ],
              ),
            ),

            // Tab Views Content
            SizedBox(
              height: 380,
              child: TabBarView(
                controller: _tabController,
                children: [
                  // 1. Attendance Tab
                  _buildAttendanceTab(),
                  // 2. Subscriptions Tab
                  _buildSubscriptionsTab(),
                  // 3. Payments Tab
                  _buildPaymentsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailTile({required String title, required String value, Color? valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13.5,
            fontWeight: FontWeight.w800,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceTab() {
    if (_attendance.isEmpty) {
      return Center(
        child: Text(AppStrings.noVisitsYet, style: GoogleFonts.cairo(color: AppColors.textSecondary)),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _attendance.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final att = _attendance[index];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0x0A1B1F3B)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.check_circle_outline_rounded, color: AppColors.statusTealFg, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    att.date,
                    style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              Text(
                att.time,
                style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppColors.textSecondary),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSubscriptionsTab() {
    if (_subscriptions.isEmpty) {
      return Center(
        child: Text('لا توجد اشتراكات سابقة', style: GoogleFonts.cairo(color: AppColors.textSecondary)),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _subscriptions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final s = _subscriptions[index];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0x0C1B1F3B)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    s.planName ?? 'باقة',
                    style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  ),
                  Text(
                    '${s.price.toStringAsFixed(0)} ${AppStrings.currency}',
                    style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.primary),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'من: ${DateHelper.formatDate(s.startDate)} إلى: ${DateHelper.formatDate(s.endDate)}',
                style: GoogleFonts.cairo(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPaymentsTab() {
    if (_payments.isEmpty) {
      return Center(
        child: Text('لا توجد مدفوعات مسجلة', style: GoogleFonts.cairo(color: AppColors.textSecondary)),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _payments.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final p = _payments[index];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0x0A1B1F3B)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.receipt_long_rounded, color: AppColors.statusGreenFg, size: 20),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateHelper.formatDate(p.date),
                        style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        p.planName ?? 'سداد اشتراك',
                        style: GoogleFonts.cairo(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
              Text(
                '+ ${p.amount.toStringAsFixed(0)} ${AppStrings.currency}',
                style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.statusGreenFg),
              ),
            ],
          ),
        );
      },
    );
  }
}
