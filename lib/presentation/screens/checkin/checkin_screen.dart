import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/app_notification.dart';
import '../../../core/utils/phone_helper.dart';
import '../../../core/widgets/azm_logo.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../data/models/attendance_model.dart';
import '../../../data/models/member_model.dart';
import '../../../data/repositories/attendance_repository.dart';
import '../../providers/checkin_provider.dart';
import '../../providers/members_provider.dart';
import '../../providers/revenue_provider.dart';
import '../members/renew_subscription_dialog.dart';
import '../members/add_edit_member_screen.dart';

class CheckInScreen extends ConsumerStatefulWidget {
  const CheckInScreen({super.key});

  @override
  ConsumerState<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends ConsumerState<CheckInScreen> with SingleTickerProviderStateMixin {
  final _idController = TextEditingController();
  final _memberSearchController = TextEditingController();
  final _focusNode = FocusNode();
  late TabController _tabController;

  String _searchQuery = '';
  String _activeFilter = 'all'; // all, active, expiring, expired

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _idController.dispose();
    _memberSearchController.dispose();
    _focusNode.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleCheckIn([int? forcedId]) async {
    final text = forcedId != null ? forcedId.toString() : _idController.text.trim();
    if (text.isEmpty) {
      AppNotification.showWarning(context, 'يرجى إدخال رقم العضو أولاً');
      return;
    }

    final id = int.tryParse(text);
    if (id == null) {
      AppNotification.showWarning(context, 'يرجى إدخال رقم صحيح');
      return;
    }

    final result = await ref.read(checkInProvider.notifier).submitCheckIn(id);

    if (result.isSuccessOrWarning) {
      SystemSound.play(SystemSoundType.click);
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.vibrate();
    }

    _idController.clear();
    _focusNode.unfocus();
  }

  void _shareAttendanceReport(List<AttendanceModel> list) {
    if (list.isEmpty) {
      AppNotification.showInfo(context, 'لا توجد سجلات حضور مسجلة اليوم للمشاركة');
      return;
    }

    final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final buffer = StringBuffer();
    buffer.writeln('📋 تقرير الحضور اليومي - MY GYM');
    buffer.writeln('📅 التاريخ: $dateStr');
    buffer.writeln('👥 إجمالي الحاضرين: ${list.length} مشترك');
    buffer.writeln('────────────────────');

    for (int i = 0; i < list.length; i++) {
      final item = list[i];
      buffer.writeln('${i + 1}. ${item.memberName ?? 'عضو'} (رقم: ${item.memberId}) ⏰ ${item.time}');
    }

    buffer.writeln('────────────────────');
    buffer.writeln('💪 تم التصدير عبر تطبيق MY GYM');

    Share.share(buffer.toString(), subject: 'تقرير حضور MY GYM ليوم $dateStr');
  }

  @override
  Widget build(BuildContext context) {
    final checkInState = ref.watch(checkInProvider);
    final membersState = ref.watch(membersProvider);

    final todayList = checkInState.todayListAsync.value ?? [];
    final todayCheckedInIds = <int, AttendanceModel>{
      for (final a in todayList) a.memberId: a,
    };

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 16,
        title: Row(
          children: [
            const AzmLogo(size: 32),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    AppStrings.checkInTitle,
                    style: GoogleFonts.cairo(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'تسجيل الحضور الفوري ومتابعة اليوم',
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Share Today's Report Button
          if (todayList.isNotEmpty)
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.share_outlined, size: 18, color: AppColors.primary),
              ),
              tooltip: 'مشاركة كشف الحضور اليومي',
              onPressed: () => _shareAttendanceReport(todayList),
            ),
          // Refresh Button
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.surfaceSecondary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.refresh_rounded, size: 18, color: AppColors.textPrimary),
            ),
            tooltip: 'تحديث البيانات',
            onPressed: () {
              ref.read(checkInProvider.notifier).loadTodayCheckIns();
              ref.read(membersProvider.notifier).loadMembers();
              ref.invalidate(dashboardStatsProvider);
            },
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(bottom: BorderSide(color: Color(0x0F1B1F3B), width: 1)),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w800),
              unselectedLabelStyle: GoogleFonts.cairo(fontSize: 12.5, fontWeight: FontWeight.w600),
              tabs: [
                const Tab(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('تسجيل الحضور'),
                  ),
                ),
                Tab(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('حضور اليوم'),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _tabController.index == 1 ? AppColors.primary : AppColors.surfaceSecondary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${todayList.length}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: _tabController.index == 1 ? Colors.white : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Quick ID Bar (Pinned on Top)
          _buildInputCard(checkInState),

          // Live Result Banner
          if (checkInState.lastResult != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: _buildResultCard(checkInState.lastResult!),
            ),

          // Tabs Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Member Check-In List (Never Empty!)
                RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async {
                    await ref.read(checkInProvider.notifier).loadTodayCheckIns();
                    await ref.read(membersProvider.notifier).loadMembers();
                    ref.invalidate(dashboardStatsProvider);
                  },
                  child: _buildMembersCheckInTab(membersState, todayCheckedInIds),
                ),

                // Tab 2: Today's Check-Ins Log
                RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async {
                    await ref.read(checkInProvider.notifier).loadTodayCheckIns();
                    await ref.read(membersProvider.notifier).loadMembers();
                    ref.invalidate(dashboardStatsProvider);
                  },
                  child: _buildTodayCheckInsLogTab(checkInState, todayList),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputCard(CheckInState checkInState) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x0C1B1F3B), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x041B1F3B),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: AppColors.statusBlueBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.badge_rounded, color: AppColors.statusBlueFg, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'تسجيل حضور برقم العضو (ID)',
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // Numeric ID Field
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSecondary,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _focusNode.hasFocus ? AppColors.primary : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: TextField(
                    key: const Key('checkin_id_field'),
                    controller: _idController,
                    focusNode: _focusNode,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.go,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    onSubmitted: (_) => _handleCheckIn(),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      color: AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'أدخل رقم العضو (مثل: 1)',
                      hintStyle: GoogleFonts.cairo(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary.withOpacity(0.6),
                      ),
                      border: InputBorder.none,
                      prefixIcon: const Icon(Icons.tag_rounded, size: 20, color: AppColors.primary),
                      suffixIcon: _idController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 16),
                              onPressed: () => setState(() => _idController.clear()),
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Check-in Submit Button
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size(0, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    elevation: 0,
                  ),
                  onPressed: checkInState.isSubmitting ? null : () => _handleCheckIn(),
                  child: checkInState.isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_rounded, size: 18, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(
                              AppStrings.submitCheckIn,
                              style: GoogleFonts.cairo(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(CheckInResult res) {
    Color bg;
    Color fg;
    IconData icon;
    String statusTitle;

    switch (res.status) {
      case CheckInStatus.success:
        bg = AppColors.statusGreenBg;
        fg = AppColors.statusGreenFg;
        icon = Icons.check_circle_rounded;
        statusTitle = 'تم تسجيل الحضور بنجاح ✓';
        break;
      case CheckInStatus.warningExpiring:
      case CheckInStatus.warningUnpaid:
      case CheckInStatus.alreadyToday:
        bg = AppColors.statusAmberBg;
        fg = AppColors.statusAmberFg;
        icon = Icons.warning_amber_rounded;
        statusTitle = res.status == CheckInStatus.alreadyToday
            ? 'تنبيه: مسجل مسبقاً اليوم'
            : 'تم التسجيل مع وجود تنبيه!';
        break;
      case CheckInStatus.expired:
      case CheckInStatus.notFound:
        bg = AppColors.statusRedBg;
        fg = AppColors.statusRedFg;
        icon = Icons.cancel_rounded;
        statusTitle = res.status == CheckInStatus.notFound
            ? 'عضو غير موجود'
            : 'اشتراك منتهي الصلاحية';
        break;
    }

    final member = res.member;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: fg.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: fg, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  statusTitle,
                  style: GoogleFonts.cairo(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: fg,
                  ),
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(Icons.close_rounded, size: 18, color: fg),
                onPressed: () {
                  ref.read(checkInProvider.notifier).clearResult();
                },
              ),
            ],
          ),
          if (member != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  '${member.name} (رقم: ${member.id})',
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                if (member.currentSubscription != null) ...[
                  Text(
                    member.currentSubscription!.isActive
                        ? '${member.currentSubscription!.daysLeft} يوم متبقي'
                        : 'منتهي',
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: fg,
                    ),
                  ),
                ],
              ],
            ),
          ],
          const SizedBox(height: 4),
          Text(
            res.message,
            style: GoogleFonts.cairo(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
          if (res.status == CheckInStatus.expired && member != null) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.autorenew_rounded, size: 16),
                label: Text(
                  'تجديد اشتراك العضو الآن',
                  style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w800),
                ),
                onPressed: () async {
                  final renewed = await showDialog<bool>(
                    context: context,
                    builder: (_) => RenewSubscriptionDialog(member: member),
                  );
                  if (renewed == true) {
                    ref.invalidate(dashboardStatsProvider);
                    ref.read(membersProvider.notifier).loadMembers();
                    _handleCheckIn(member.id);
                  }
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMembersCheckInTab(MembersState membersState, Map<int, AttendanceModel> todayCheckedInIds) {
    return membersState.membersAsync.when(
      data: (allMembers) {
        if (allMembers.isEmpty) {
          return EmptyStateView(
            icon: Icons.people_outline_rounded,
            title: 'لا يوجد أعضاء مسجلين بعد',
            description: 'قم بإضافة المشتركين أولاً لتتمكن من تسجيل حضورهم بنقرة واحدة.',
            buttonLabel: 'إضافة عضو جديد',
            onButtonPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AddEditMemberScreen()),
              );
              ref.read(membersProvider.notifier).loadMembers();
            },
          );
        }

        // Apply local filter and search
        final filtered = allMembers.where((m) {
          final q = _searchQuery.trim().toLowerCase();
          final matchesSearch = q.isEmpty ||
              m.name.toLowerCase().contains(q) ||
              m.phone.contains(q) ||
              m.id.toString().contains(q);

          if (!matchesSearch) return false;

          final sub = m.currentSubscription;
          switch (_activeFilter) {
            case 'active':
              return sub != null && sub.isActive;
            case 'expiring':
              return sub != null && sub.isExpiringSoon(3);
            case 'expired':
              return sub == null || sub.isExpired;
            default:
              return true;
          }
        }).toList();

        return Column(
          children: [
            // Search field
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
              child: Container(
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0x0C1B1F3B)),
                ),
                child: TextField(
                  controller: _memberSearchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  style: GoogleFonts.cairo(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'ابحث بالاسم، رقم العضو، أو رقم الهاتف...',
                    hintStyle: GoogleFonts.cairo(fontSize: 12, color: AppColors.textSecondary),
                    prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.textSecondary),
                    suffixIcon: _memberSearchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 16),
                            onPressed: () {
                              _memberSearchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                ),
              ),
            ),

            // Quick Filter Chips
            Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildFilterChip('all', 'الكل (${allMembers.length})'),
                  const SizedBox(width: 6),
                  _buildFilterChip('active', 'النشطون'),
                  const SizedBox(width: 6),
                  _buildFilterChip('expiring', 'ينتهي قريباً'),
                  const SizedBox(width: 6),
                  _buildFilterChip('expired', 'المنتهي'),
                ],
              ),
            ),
            const SizedBox(height: 4),

            // Members List with Direct Check-in Buttons
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        'لا يوجد أعضاء مطابقون للبحث',
                        style: GoogleFonts.cairo(fontSize: 13, color: AppColors.textSecondary),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
                      cacheExtent: 200,
                      addRepaintBoundaries: true,
                      addAutomaticKeepAlives: false,
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, idx) {
                        final member = filtered[idx];
                        final sub = member.currentSubscription;
                        final isActive = sub != null && sub.isActive;
                        final checkedInRecord = todayCheckedInIds[member.id];
                        final isAlreadyCheckedIn = checkedInRecord != null;

                        return _buildMemberCheckInCard(member, sub, isActive, isAlreadyCheckedIn, checkedInRecord);
                      },
                    ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (e, _) => Center(child: Text('خطأ: $e', style: GoogleFonts.cairo())),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _activeFilter == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.surface,
      labelStyle: GoogleFonts.cairo(
        fontSize: 11.5,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
        color: isSelected ? Colors.white : AppColors.textSecondary,
      ),
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isSelected ? AppColors.primary : const Color(0x0C1B1F3B)),
      ),
      onSelected: (_) => setState(() => _activeFilter = key),
    );
  }

  Widget _buildMemberCheckInCard(
    MemberModel member,
    dynamic sub,
    bool isActive,
    bool isAlreadyCheckedIn,
    AttendanceModel? checkedInRecord,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isAlreadyCheckedIn
              ? AppColors.statusGreenFg.withOpacity(0.35)
              : const Color(0x0C1B1F3B),
          width: isAlreadyCheckedIn ? 1.5 : 1,
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x041B1F3B), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          // Sequential ID Badge
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isAlreadyCheckedIn ? AppColors.statusGreenBg : AppColors.surfaceSecondary,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(
              '#${member.id}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: isAlreadyCheckedIn ? AppColors.statusGreenFg : AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Name and Subscription Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  member.name,
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  sub != null
                      ? (sub.isSessionBased
                          ? '${sub.planName ?? 'باقة'} • حصة ${sub.attendedSessions} من ${sub.totalSessions} (متبقي ${sub.remainingSessions})'
                          : '${sub.planName ?? 'باقة'} • حضر ${member.subVisits} يوم • ${isActive ? '${sub.daysLeft} يوم متبقي' : 'منتهي الصلاحية'}')
                      : 'بدون باقة مسجلة',
                  style: GoogleFonts.cairo(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: isActive
                        ? (sub.daysLeft <= 3 ? AppColors.statusAmberFg : AppColors.textSecondary)
                        : AppColors.statusRedFg,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (sub != null && isActive) ...[
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: sub.consistencyRate >= 65
                          ? AppColors.statusTealBg
                          : (sub.consistencyRate >= 40 ? AppColors.statusBlueBg : AppColors.statusAmberBg),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'التزام ${sub.consistencyRate.toInt()}% • ${sub.consistencyBadge}',
                      style: GoogleFonts.cairo(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: sub.consistencyRate >= 65
                            ? AppColors.statusTealFg
                            : (sub.consistencyRate >= 40 ? AppColors.statusBlueFg : AppColors.statusAmberFg),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),

          // 1-Tap Action Button: Record Check-In / Already Checked In / Renew
          if (isAlreadyCheckedIn) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.statusGreenBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.statusGreenFg.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle_rounded, size: 14, color: AppColors.statusGreenFg),
                  const SizedBox(width: 4),
                  Text(
                    'مسجل ✓ ${checkedInRecord?.time ?? ''}',
                    style: GoogleFonts.cairo(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.statusGreenFg,
                    ),
                  ),
                ],
              ),
            ),
          ] else if (isActive) ...[
            SizedBox(
              height: 38,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.statusGreenFg,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 38),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  elevation: 0,
                ),
                icon: const Icon(Icons.check_rounded, size: 16),
                label: Text(
                  'تسجيل حضور',
                  style: GoogleFonts.cairo(fontSize: 12.5, fontWeight: FontWeight.w800),
                ),
                onPressed: () => _handleCheckIn(member.id),
              ),
            ),
          ] else ...[
            SizedBox(
              height: 38,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.statusRedFg,
                  minimumSize: const Size(0, 38),
                  side: const BorderSide(color: AppColors.statusRedFg, width: 1.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
                icon: const Icon(Icons.autorenew_rounded, size: 15),
                label: Text(
                  'تجديد',
                  style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w800),
                ),
                onPressed: () async {
                  final renewed = await showDialog<bool>(
                    context: context,
                    builder: (_) => RenewSubscriptionDialog(member: member),
                  );
                  if (renewed == true) {
                    ref.invalidate(dashboardStatsProvider);
                    ref.read(membersProvider.notifier).loadMembers();
                    _handleCheckIn(member.id);
                  }
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTodayCheckInsLogTab(CheckInState checkInState, List<AttendanceModel> list) {
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.statusBlueBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.how_to_reg_outlined, size: 36, color: AppColors.statusBlueFg),
              ),
              const SizedBox(height: 16),
              Text(
                AppStrings.noCheckInsToday,
                style: GoogleFonts.cairo(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'لم يتم تسجيل حضور أي عضو اليوم بعد.\nيمكنك تسجيل الحضور فوراً من تبويب "تسجيل حضور الأعضاء" أو بكتابة رقم العضو أعلاه.',
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      cacheExtent: 200,
      addRepaintBoundaries: true,
      addAutomaticKeepAlives: false,
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = list[index];
        return _buildTodayCheckInRow(item);
      },
    );
  }

  Widget _buildTodayCheckInRow(AttendanceModel item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x0C1B1F3B)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.statusTealBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '#${item.memberId}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: AppColors.statusTealFg,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.memberName ?? 'عضو رقم ${item.memberId}',
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${item.planName ?? 'باقة'} ${item.daysLeft != null ? '• ${item.daysLeft} يوم متبقي' : ''}',
                  style: GoogleFonts.cairo(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surfaceSecondary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              item.time,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          if (item.phone != null && item.phone!.isNotEmpty) ...[
            const SizedBox(width: 4),
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18, color: AppColors.statusGreenFg),
              tooltip: 'مراسلة عبر واتساب',
              onPressed: () {
                PhoneHelper.launchWhatsApp(item.phone!, 'مرحباً ${item.memberName ?? 'كابتن'}، أهلاً بك في MY GYM! 💪');
              },
            ),
          ],
          const SizedBox(width: 4),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.statusRedFg),
            tooltip: 'إلغاء تسجيل الحضور',
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  title: Text('إلغاء تسجيل الحضور؟', style: GoogleFonts.cairo(fontWeight: FontWeight.w800)),
                  content: Text(
                    'هل تريد إلغاء تسجيل حضور العضو (${item.memberName}) لهذا اليوم؟',
                    style: GoogleFonts.cairo(),
                  ),
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

              if (confirmed == true && item.id != null) {
                await ref.read(checkInProvider.notifier).deleteAttendance(item.id!);
                ref.invalidate(dashboardStatsProvider);
                if (mounted) {
                  AppNotification.showSuccess(context, 'تم إلغاء تسجيل الحضور');
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
