import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/app_header.dart';
import '../../providers/revenue_provider.dart';

class RevenueReportsScreen extends ConsumerWidget {
  const RevenueReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMonth = ref.watch(selectedReportMonthProvider);
    final metricsAsync = ref.watch(monthlyReportMetricsProvider);

    final monthLabel = DateFormat('MMMM yyyy', 'ar').format(selectedMonth);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppHeader(
        title: AppStrings.reportsTitle,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Month Selector Header Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0x0C1B1F3B)),
                boxShadow: const [
                  BoxShadow(color: Color(0x051B1F3B), blurRadius: 10, offset: Offset(0, 3)),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
                    onPressed: () {
                      ref.read(selectedReportMonthProvider.notifier).state =
                          DateTime(selectedMonth.year, selectedMonth.month - 1, 1);
                    },
                  ),
                  Column(
                    children: [
                      Text(
                        AppStrings.monthSelector,
                        style: GoogleFonts.cairo(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                      ),
                      Text(
                        monthLabel,
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_rounded, size: 18),
                    onPressed: () {
                      ref.read(selectedReportMonthProvider.notifier).state =
                          DateTime(selectedMonth.year, selectedMonth.month + 1, 1);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            metricsAsync.when(
              data: (metrics) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Financial Overview Cards (Collected, Expected, Outstanding)
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0x0C1B1F3B)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.financialSummary,
                          style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildFinancialTile(
                                title: AppStrings.collectedThisMonth,
                                amount: metrics.collectedThisMonth,
                                bg: AppColors.statusGreenBg,
                                fg: AppColors.statusGreenFg,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildFinancialTile(
                                title: AppStrings.expectedThisMonth,
                                amount: metrics.expectedThisMonth,
                                bg: AppColors.statusBlueBg,
                                fg: AppColors.statusBlueFg,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildFinancialTile(
                                title: AppStrings.outstandingAmount,
                                amount: metrics.outstandingAmount,
                                bg: AppColors.statusRedBg,
                                fg: AppColors.statusRedFg,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Operations Overview: New Members, Renewals, Expired
                  Row(
                    children: [
                      Expanded(
                        child: _buildOpStatCard(
                          title: AppStrings.newMembersCount,
                          value: metrics.newMembersCount.toString(),
                          icon: Icons.person_add_rounded,
                          color: AppColors.statusTealFg,
                          bg: AppColors.statusTealBg,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildOpStatCard(
                          title: AppStrings.renewalsCount,
                          value: metrics.renewalsCount.toString(),
                          icon: Icons.autorenew_rounded,
                          color: AppColors.statusAmberFg,
                          bg: AppColors.statusAmberBg,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildOpStatCard(
                          title: AppStrings.expiredSubscriptionsCount,
                          value: metrics.expiredCount.toString(),
                          icon: Icons.event_busy_rounded,
                          color: AppColors.statusRedFg,
                          bg: AppColors.statusRedBg,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Bar Chart of Past 6 Months Revenue
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0x0C1B1F3B)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.monthlyRevenueBarChart,
                          style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 180,
                          child: BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              maxY: _calcMaxY(metrics.pastMonthsRevenue),
                              barTouchData: BarTouchData(
                                enabled: true,
                                touchTooltipData: BarTouchTooltipData(
                                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                    return BarTooltipItem(
                                      '${rod.toY.toStringAsFixed(0)} ${AppStrings.currency}',
                                      GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold),
                                    );
                                  },
                                ),
                              ),
                              titlesData: FlTitlesData(
                                show: true,
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (val, meta) {
                                      final keys = metrics.pastMonthsRevenue.keys.toList();
                                      final index = val.toInt();
                                      if (index >= 0 && index < keys.length) {
                                        return Padding(
                                          padding: const EdgeInsets.only(top: 8),
                                          child: Text(
                                            keys[index].split(' ').first,
                                            style: GoogleFonts.cairo(fontSize: 10, fontWeight: FontWeight.w600),
                                          ),
                                        );
                                      }
                                      return const SizedBox.shrink();
                                    },
                                    reservedSize: 26,
                                  ),
                                ),
                                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              ),
                              gridData: const FlGridData(show: false),
                              borderData: FlBorderData(show: false),
                              barGroups: _generateBarGroups(metrics.pastMonthsRevenue),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Plan Distribution Breakdown
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0x0C1B1F3B)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.planDistribution,
                          style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 14),
                        if (metrics.planBreakdown.isEmpty)
                          Text('لا توجد بيانات اشتراكات نشطة', style: GoogleFonts.cairo(color: AppColors.textSecondary))
                        else
                          ...metrics.planBreakdown.entries.map((entry) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      entry.key,
                                      style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  Text(
                                    '${entry.value} مشترك',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
              error: (e, _) => Center(child: Text('خطأ: $e')),
            ),
          ],
        ),
      ),
    );
  }

  double _calcMaxY(Map<String, double> data) {
    double max = 1000;
    for (final v in data.values) {
      if (v > max) max = v;
    }
    return max * 1.25;
  }

  List<BarChartGroupData> _generateBarGroups(Map<String, double> data) {
    final list = <BarChartGroupData>[];
    int idx = 0;
    final keys = data.keys.toList();
    for (int i = 0; i < keys.length; i++) {
      final val = data[keys[i]] ?? 0;
      final isLast = i == keys.length - 1;
      list.add(
        BarChartGroupData(
          x: idx++,
          barRods: [
            BarChartRodData(
              toY: val,
              color: isLast ? AppColors.primary : AppColors.surfaceSecondary,
              width: 18,
              borderRadius: BorderRadius.circular(6),
            ),
          ],
        ),
      );
    }
    return list;
  }

  Widget _buildFinancialTile({
    required String title,
    required double amount,
    required Color bg,
    required Color fg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: bg.withOpacity(0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.w700, color: fg),
          ),
          const SizedBox(height: 4),
          Text(
            amount.toStringAsFixed(0),
            style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w900, color: fg),
          ),
          Text(
            AppStrings.currency,
            style: GoogleFonts.cairo(fontSize: 10, fontWeight: FontWeight.w600, color: fg),
          ),
        ],
      ),
    );
  }

  Widget _buildOpStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x0C1B1F3B)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
          ),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
