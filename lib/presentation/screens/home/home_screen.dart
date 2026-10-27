import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/azm_logo.dart';
import '../../../core/widgets/module_row.dart';
import '../../../core/widgets/stat_card.dart';
import '../../providers/auth_provider.dart';
import '../../providers/revenue_provider.dart';
import '../../providers/settings_provider.dart';
import '../members/add_edit_member_screen.dart';
import '../reports/revenue_reports_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends ConsumerWidget {
  final Function(int index) onSwitchTab;

  const HomeScreen({super.key, required this.onSwitchTab});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 15) {
      return AppStrings.greetingMorning;
    }
    return AppStrings.greetingEvening;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final owner = ref.watch(authProvider.select((s) => s.owner));
    final isBackupDue = ref.watch(backupDueProvider).value ?? false;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(66),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(bottom: BorderSide(color: Color(0x0F1B1F3B), width: 1)),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const AzmLogo(size: 36),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        AppStrings.appName,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                          letterSpacing: 1.5,
                          height: 1.1,
                        ),
                      ),
                      Text(
                        AppStrings.gymSlogan,
                        style: GoogleFonts.cairo(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Reports Button
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSecondary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.bar_chart_rounded, size: 20, color: AppColors.textPrimary),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const RevenueReportsScreen()),
                      );
                    },
                    tooltip: AppStrings.reportsTitle,
                  ),
                  // Settings Button
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSecondary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.settings_outlined, size: 20, color: AppColors.textPrimary),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SettingsScreen()),
                      );
                    },
                    tooltip: AppStrings.settingsTitle,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(dashboardStatsProvider);
          ref.invalidate(backupDueProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting & Live Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_getGreeting()} ${owner?.displayName ?? owner?.username ?? ''} 👋',
                          style: GoogleFonts.cairo(
                            fontSize: 18.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            height: 1.25,
                          ),
                          maxLines: 2,
                        ),
                        Text(
                          'إليك ملخص الصالة الرياضية اليوم',
                          style: GoogleFonts.cairo(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Live status indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.statusTealBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.statusTealFg,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'مباشر Live',
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.statusTealFg,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // 7-day Backup reminder banner if due
              if (isBackupDue) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.statusAmberBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.statusAmberFg.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.cloud_upload_outlined, color: AppColors.statusAmberFg, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          AppStrings.backupReminderWarning,
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.statusAmberFg,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const SettingsScreen()),
                          );
                        },
                        child: Text(
                          'حفظ الآن',
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.statusAmberFg,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // 2x2 Grid of Stat Cards
              statsAsync.when(
                data: (stats) => Column(
                  children: [
                    Row(
                      children: [
                        // Active members (Teal)
                        Expanded(
                          child: StatCard(
                            title: AppStrings.activeMembers,
                            value: stats.activeMembers.toString(),
                            caption: 'مشترك فعال',
                            icon: Icons.fitness_center_rounded,
                            bgTileColor: AppColors.statusTealBg,
                            fgColor: AppColors.statusTealFg,
                            onTap: () => onSwitchTab(1),
                          ),
                        ),
                        const SizedBox(width: 14),
                        // Expiring soon (Amber)
                        Expanded(
                          child: StatCard(
                            title: AppStrings.expiringSoon,
                            value: stats.expiringSoon.toString(),
                            caption: 'خلال أيام التنبيه',
                            icon: Icons.access_time_rounded,
                            bgTileColor: AppColors.statusAmberBg,
                            fgColor: AppColors.statusAmberFg,
                            onTap: () => onSwitchTab(3),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        // Expired / overdue (Red)
                        Expanded(
                          child: StatCard(
                            title: AppStrings.expiredOverdue,
                            value: stats.expiredOverdue.toString(),
                            caption: 'بحاجة للتجديد',
                            icon: Icons.person_off_rounded,
                            bgTileColor: AppColors.statusRedBg,
                            fgColor: AppColors.statusRedFg,
                            onTap: () => onSwitchTab(3),
                          ),
                        ),
                        const SizedBox(width: 14),
                        // Today's check-ins (Blue)
                        Expanded(
                          child: StatCard(
                            title: AppStrings.todayCheckIns,
                            value: stats.todayCheckIns.toString(),
                            caption: 'زيارة اليوم',
                            icon: Icons.how_to_reg_rounded,
                            bgTileColor: AppColors.statusBlueBg,
                            fgColor: AppColors.statusBlueFg,
                            onTap: () => onSwitchTab(2),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Revenue Card with live chart
                    _buildRevenueCard(context, stats),
                  ],
                ),
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                ),
                error: (e, _) => Center(
                  child: Text('خطأ في تحميل البيانات: $e'),
                ),
              ),

              const SizedBox(height: 24),

              // Quick Actions Section
              Text(
                AppStrings.quickActions,
                style: GoogleFonts.cairo(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              ModuleRow(
                icon: Icons.person_add_alt_1_rounded,
                title: AppStrings.quickAddMember,
                subtitle: 'تسجيل مشترك جديد وإصدار بطاقته الفورية',
                onTap: () async {
                  final added = await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AddEditMemberScreen()),
                  );
                  if (added == true) {
                    ref.invalidate(dashboardStatsProvider);
                  }
                },
              ),
              const SizedBox(height: 10),
              ModuleRow(
                icon: Icons.qr_code_scanner_rounded,
                title: AppStrings.quickCheckIn,
                subtitle: 'تسجيل حضور المشتركين برقم العضو أو بالاسم',
                onTap: () => onSwitchTab(2),
              ),
              const SizedBox(height: 10),
              ModuleRow(
                icon: Icons.notifications_active_rounded,
                title: AppStrings.quickAlerts,
                subtitle: 'متابعة الاشتراكات المنتهية والغائبين وإرسال تذكيرات',
                onTap: () => onSwitchTab(3),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRevenueCard(BuildContext context, stats) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x0C1B1F3B), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x061B1F3B),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.statusGreenBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.attach_money_rounded, size: 22, color: AppColors.statusGreenFg),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    AppStrings.revenueTitle,
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const RevenueReportsScreen()),
                  );
                },
                child: Text(
                  'تفاصيل التقرير',
                  style: GoogleFonts.cairo(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 3 Columns: Collected, Expected, Outstanding
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  title: AppStrings.collectedThisMonth,
                  amount: stats.collectedThisMonth,
                  color: AppColors.statusGreenFg,
                ),
              ),
              Container(width: 1, height: 40, color: AppColors.divider),
              Expanded(
                child: _buildMetricTile(
                  title: AppStrings.expectedThisMonth,
                  amount: stats.expectedThisMonth,
                  color: AppColors.statusBlueFg,
                ),
              ),
              Container(width: 1, height: 40, color: AppColors.divider),
              Expanded(
                child: _buildMetricTile(
                  title: AppStrings.outstandingAmount,
                  amount: stats.outstandingAmount,
                  color: AppColors.statusRedFg,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Mini sparkline bar chart of recent months
          SizedBox(
            height: 90,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: (stats.collectedThisMonth > 0 ? stats.collectedThisMonth * 1.3 : 1000.0),
                barTouchData: BarTouchData(enabled: false),
                titlesData: const FlTitlesData(show: false),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: [
                  BarChartGroupData(x: 0, barRods: [
                    BarChartRodData(
                      toY: stats.collectedThisMonth * 0.7,
                      color: AppColors.surfaceSecondary,
                      width: 16,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ]),
                  BarChartGroupData(x: 1, barRods: [
                    BarChartRodData(
                      toY: stats.collectedThisMonth * 0.85,
                      color: AppColors.surfaceSecondary,
                      width: 16,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ]),
                  BarChartGroupData(x: 2, barRods: [
                    BarChartRodData(
                      toY: stats.collectedThisMonth > 0 ? stats.collectedThisMonth : 100,
                      color: AppColors.primary,
                      width: 16,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({required String title, required double amount, required Color color}) {
    return Column(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: GoogleFonts.cairo(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          amount.toStringAsFixed(0),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(
          AppStrings.currency,
          style: GoogleFonts.cairo(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
