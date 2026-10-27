import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../data/models/member_model.dart';
import '../../providers/members_provider.dart';
import '../../providers/revenue_provider.dart';
import 'add_edit_member_screen.dart';
import 'member_details_screen.dart';

class MembersListScreen extends ConsumerStatefulWidget {
  const MembersListScreen({super.key});

  @override
  ConsumerState<MembersListScreen> createState() => _MembersListScreenState();
}

class _MembersListScreenState extends ConsumerState<MembersListScreen> {
  final _searchController = TextEditingController();

  final List<Map<String, String>> _filters = [
    {'key': 'all', 'label': AppStrings.filterAll},
    {'key': 'active', 'label': AppStrings.filterActive},
    {'key': 'expiring', 'label': AppStrings.filterExpiring},
    {'key': 'expired', 'label': AppStrings.filterExpired},
    {'key': 'unpaid', 'label': AppStrings.filterUnpaid},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onTogglePaid(MemberModel member) async {
    final sub = member.currentSubscription;
    if (sub == null || sub.id == null) return;

    final currentIsPaid = sub.isPaid && !sub.hasRemainingDebt;
    final newIsPaid = !currentIsPaid;

    await ref.read(membersProvider.notifier).toggleSubscriptionPaid(
          memberId: member.id,
          subscriptionId: sub.id!,
          markPaid: newIsPaid,
        );

    ref.invalidate(dashboardStatsProvider);

    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Text(
            newIsPaid ? 'تم تحديد العضو (${member.name}) كـ مدفوع بالكامل' : 'تم تحديد العضو (${member.name}) كـ غير مسدد',
            style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          action: SnackBarAction(
            label: AppStrings.undo,
            textColor: AppColors.primaryLight,
            onPressed: () async {
              await ref.read(membersProvider.notifier).toggleSubscriptionPaid(
                    memberId: member.id,
                    subscriptionId: sub.id!,
                    markPaid: currentIsPaid,
                  );
              ref.invalidate(dashboardStatsProvider);
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final membersState = ref.watch(membersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(132),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(bottom: BorderSide(color: Color(0x0F1B1F3B), width: 1)),
          ),
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Title and Add Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Text(
                        AppStrings.membersTitle,
                        style: GoogleFonts.cairo(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          minimumSize: const Size(0, 38),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: Text(
                          'إضافة',
                          style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                        onPressed: () async {
                          final added = await Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const AddEditMemberScreen()),
                          );
                          if (added == true) {
                            ref.read(membersProvider.notifier).loadMembers();
                          }
                        },
                      ),
                    ],
                  ),
                ),
                // Search Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSecondary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) {
                        ref.read(membersProvider.notifier).setSearchQuery(val);
                      },
                      style: GoogleFonts.cairo(fontSize: 13.5, color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: AppStrings.searchHint,
                        hintStyle: GoogleFonts.cairo(fontSize: 12.5, color: AppColors.textSecondary.withOpacity(0.7)),
                        prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.textSecondary),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18, color: AppColors.textSecondary),
                                onPressed: () {
                                  _searchController.clear();
                                  ref.read(membersProvider.notifier).setSearchQuery('');
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Filter Chips Horizontal Bar
          Container(
            height: 48,
            color: AppColors.surface,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final f = _filters[index];
                final isSelected = membersState.activeFilter == f['key'];
                return ChoiceChip(
                  label: Text(f['label']!),
                  selected: isSelected,
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.surfaceSecondary,
                  labelStyle: GoogleFonts.cairo(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                  showCheckmark: false,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide.none,
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      ref.read(membersProvider.notifier).setFilter(f['key']!);
                    }
                  },
                );
              },
            ),
          ),
          const Divider(height: 1),

          // Members List View (Lazy builder)
          Expanded(
            child: membersState.membersAsync.when(
              data: (members) {
                if (members.isEmpty) {
                  return EmptyStateView(
                    icon: Icons.people_outline_rounded,
                    title: AppStrings.noMembersFound,
                    description: AppStrings.noMembersHint,
                    buttonLabel: AppStrings.quickAddMember,
                    onButtonPressed: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AddEditMemberScreen()),
                      );
                      ref.read(membersProvider.notifier).loadMembers();
                    },
                  );
                }

                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async {
                    ref.read(membersProvider.notifier).loadMembers();
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    cacheExtent: 200,
                    addRepaintBoundaries: true,
                    addAutomaticKeepAlives: false,
                    itemCount: members.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final member = members[index];
                      final sub = member.currentSubscription;
                      final isPaid = sub != null && sub.isPaid && !sub.hasRemainingDebt;

                      return _buildMemberCard(context, member, sub, isPaid);
                    },
                  ),
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (e, _) => Center(
                child: Text('خطأ في تحميل الأعضاء: $e', style: GoogleFonts.cairo()),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_rounded),
        label: Text(
          'عضو جديد',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
        ),
        onPressed: () async {
          final added = await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddEditMemberScreen()),
          );
          if (added == true) {
            ref.read(membersProvider.notifier).loadMembers();
          }
        },
      ),
    );
  }

  Widget _buildMemberCard(BuildContext context, MemberModel member, dynamic sub, bool isPaid) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x0C1B1F3B), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x051B1F3B),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => MemberDetailsScreen(memberId: member.id)),
            );
            ref.read(membersProvider.notifier).loadMembers();
          },
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                // Sequential ID badge
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSecondary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'ID',
                        style: GoogleFonts.cairo(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                          height: 1,
                        ),
                      ),
                      Text(
                        member.id.toString(),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // Name & Plan & Days left (Wrapped in Expanded)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
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
                      const SizedBox(height: 3),
                      Text(
                        sub?.planName ?? 'بدون باقة',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary.withOpacity(0.85),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (sub != null) ...[
                            Text(
                              sub.isSessionBased
                                  ? 'حصة ${sub.attendedSessions}/${sub.totalSessions}'
                                  : (sub.isActive ? 'متبقي ${sub.daysLeft} يوم' : 'منتهي'),
                              style: GoogleFonts.cairo(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: sub.isActive
                                    ? (sub.daysLeft <= 3 ? AppColors.statusAmberFg : AppColors.statusTealFg)
                                    : AppColors.statusRedFg,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text('•', style: GoogleFonts.cairo(fontSize: 11, color: AppColors.textSecondary)),
                            const SizedBox(width: 4),
                            Text(
                              'حضر ${member.subVisits}ي',
                              style: GoogleFonts.cairo(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.statusBlueFg,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text('•', style: GoogleFonts.cairo(fontSize: 11, color: AppColors.textSecondary)),
                            const SizedBox(width: 4),
                          ],
                          Flexible(
                            child: Text(
                              member.phone,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Paid / Unpaid Toggle Chip that flips with one tap
                if (sub != null) ...[
                  InkWell(
                    onTap: () => _onTogglePaid(member),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isPaid ? AppColors.statusGreenBg : AppColors.statusRedBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: (isPaid ? AppColors.statusGreenFg : AppColors.statusRedFg).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isPaid ? Icons.check_circle_rounded : Icons.cancel_rounded,
                            size: 13,
                            color: isPaid ? AppColors.statusGreenFg : AppColors.statusRedFg,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isPaid ? 'مدفوع' : 'غير مسدد',
                            style: GoogleFonts.cairo(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isPaid ? AppColors.statusGreenFg : AppColors.statusRedFg,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_left_rounded,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
