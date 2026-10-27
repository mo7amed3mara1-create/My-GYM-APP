import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/app_notification.dart';
import '../../../core/utils/date_helper.dart';
import '../../../core/utils/phone_helper.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../data/models/member_model.dart';
import '../../providers/alerts_provider.dart';
import '../../providers/settings_provider.dart';
import '../members/member_details_screen.dart';
import '../members/renew_subscription_dialog.dart';

class AlertsScreen extends ConsumerStatefulWidget {
  const AlertsScreen({super.key});

  @override
  ConsumerState<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends ConsumerState<AlertsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _sendWhatsAppReminder(MemberModel member, String type) {
    final settings = ref.read(settingsNotifierProvider).value;
    final sub = member.currentSubscription;

    String template;
    switch (type) {
      case 'expiring':
        template = settings?.templateExpiry ?? AppStrings.defaultExpiryTemplate;
        break;
      case 'expired':
        template = settings?.templateOverdue ?? AppStrings.defaultOverdueTemplate;
        break;
      case 'absent':
        template = settings?.templateAbsent ?? AppStrings.defaultAbsentTemplate;
        break;
      default:
        template = settings?.templateExpiry ?? AppStrings.defaultExpiryTemplate;
    }

    final daysLeft = sub != null ? sub.daysLeft : 0;
    final endDateStr = sub != null ? DateHelper.formatDate(sub.endDate) : '-';
    final amountStr = sub != null ? sub.remainingAmount.toStringAsFixed(0) : '0';

    final message = template
        .replaceAll('{name}', member.name)
        .replaceAll('{end_date}', endDateStr)
        .replaceAll('{days_left}', daysLeft.abs().toString())
        .replaceAll('{amount}', amountStr)
        .replaceAll('{id}', member.id.toString())
        .replaceAll('{gym}', AppStrings.appName);

    PhoneHelper.launchWhatsApp(member.phone, message);
  }

  Future<void> _quickRenew(MemberModel member) async {
    final renewed = await showDialog<bool>(
      context: context,
      builder: (ctx) => RenewSubscriptionDialog(member: member),
    );
    if (renewed == true) {
      ref.read(alertsProvider.notifier).loadAlerts();
      if (mounted) {
        AppNotification.showSuccess(context, 'تم تجديد اشتراك العضو (${member.name}) بنجاح');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final alertsState = ref.watch(alertsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(118),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(bottom: BorderSide(color: Color(0x0F1B1F3B), width: 1)),
          ),
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: AppColors.statusAmberBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.notifications_active_rounded, size: 20, color: AppColors.statusAmberFg),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        AppStrings.alertsTitle,
                        style: GoogleFonts.cairo(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
                        onPressed: () {
                          ref.read(alertsProvider.notifier).loadAlerts();
                        },
                      ),
                    ],
                  ),
                ),
                TabBar(
                  controller: _tabController,
                  indicatorColor: AppColors.primary,
                  indicatorWeight: 3,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textSecondary,
                  labelStyle: GoogleFonts.cairo(fontSize: 12.5, fontWeight: FontWeight.w800),
                  unselectedLabelStyle: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w600),
                  tabs: [
                    Tab(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(AppStrings.tabExpiringSoon),
                            if (alertsState.expiringSoon.isNotEmpty) ...[
                              const SizedBox(width: 4),
                              _buildCountBadge(alertsState.expiringSoon.length, AppColors.statusAmberBg, AppColors.statusAmberFg),
                            ],
                          ],
                        ),
                      ),
                    ),
                    Tab(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(AppStrings.tabExpired),
                            if (alertsState.expiredOverdue.isNotEmpty) ...[
                              const SizedBox(width: 4),
                              _buildCountBadge(alertsState.expiredOverdue.length, AppColors.statusRedBg, AppColors.statusRedFg),
                            ],
                          ],
                        ),
                      ),
                    ),
                    Tab(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(AppStrings.tabAbsent),
                            if (alertsState.absent.isNotEmpty) ...[
                              const SizedBox(width: 4),
                              _buildCountBadge(alertsState.absent.length, AppColors.statusBlueBg, AppColors.statusBlueFg),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: alertsState.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildAlertList(
                  items: alertsState.expiringSoon,
                  type: 'expiring',
                  emptyMessage: 'لا توجد أي اشتراكات تنتهي قريباً، جميع المشتركين نشطون!',
                ),
                _buildAlertList(
                  items: alertsState.expiredOverdue,
                  type: 'expired',
                  emptyMessage: 'ممتاز! لا توجد اشتراكات منتهية أو متأخرات معلقة.',
                ),
                _buildAlertList(
                  items: alertsState.absent,
                  type: 'absent',
                  emptyMessage: 'رائع! لا يوجد أعضاء غائبون، الجميع يمارسون تمارينهم!',
                ),
              ],
            ),
    );
  }

  Widget _buildCountBadge(int count, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        count.toString(),
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: fg,
        ),
      ),
    );
  }

  Widget _buildAlertList({
    required List<MemberModel> items,
    required String type,
    required String emptyMessage,
  }) {
    if (items.isEmpty) {
      return EmptyStateView(
        icon: Icons.verified_outlined,
        title: AppStrings.noAlerts,
        description: emptyMessage,
        iconColor: AppColors.statusGreenFg,
        iconBgColor: AppColors.statusGreenBg,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final member = items[index];
        final sub = member.currentSubscription;

        String caption = '';
        Color captionColor = AppColors.textSecondary;
        if (type == 'expiring' && sub != null) {
          caption = 'ينتهي خلال ${sub.daysLeft} يوم في ${DateHelper.formatDate(sub.endDate)}';
          captionColor = AppColors.statusAmberFg;
        } else if (type == 'expired') {
          if (sub != null && sub.isExpired) {
            caption = 'انتهى في ${DateHelper.formatDate(sub.endDate)}';
          } else if (sub != null && sub.hasRemainingDebt) {
            caption = 'متبقي غير مسدد: ${sub.remainingAmount.toStringAsFixed(0)} ${AppStrings.currency}';
          }
          captionColor = AppColors.statusRedFg;
        } else if (type == 'absent') {
          if (member.lastVisit != null) {
            final days = DateTime.now().difference(member.lastVisit!).inDays;
            caption = '${AppStrings.absentDays} $days ${AppStrings.days} (آخر حضور: ${DateHelper.formatDate(member.lastVisit!)})';
          } else {
            caption = 'لم يسجل أي زيارة منذ اشتراكه';
          }
          captionColor = AppColors.statusBlueFg;
        }

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0x0C1B1F3B), width: 1),
            boxShadow: const [
              BoxShadow(
                color: Color(0x051B1F3B),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Member Info Row
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSecondary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      member.id.toString(),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          member.name,
                          style: GoogleFonts.cairo(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          caption,
                          style: GoogleFonts.cairo(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: captionColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.info_outline_rounded, color: AppColors.textSecondary, size: 20),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => MemberDetailsScreen(memberId: member.id)),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Action buttons: WhatsApp & Quick Renew
              Row(
                children: [
                  // WhatsApp Button
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 40),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      icon: const Icon(Icons.chat_rounded, size: 16),
                      label: Text(
                        AppStrings.sendReminderWhatsApp,
                        style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                      onPressed: () => _sendWhatsAppReminder(member, type),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Quick Renew Button
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 40),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: Text(
                        AppStrings.quickRenew,
                        style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                      onPressed: () => _quickRenew(member),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
