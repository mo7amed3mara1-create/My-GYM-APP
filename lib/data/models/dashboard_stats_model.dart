class DashboardStatsModel {
  final int activeMembers;
  final int expiringSoon;
  final int expiredOverdue;
  final int todayCheckIns;
  final double collectedThisMonth;
  final double expectedThisMonth;
  final double outstandingAmount;
  final Map<String, double> recentMonthsRevenue;
  final Map<String, int> planDistribution;

  DashboardStatsModel({
    this.activeMembers = 0,
    this.expiringSoon = 0,
    this.expiredOverdue = 0,
    this.todayCheckIns = 0,
    this.collectedThisMonth = 0.0,
    this.expectedThisMonth = 0.0,
    this.outstandingAmount = 0.0,
    this.recentMonthsRevenue = const {},
    this.planDistribution = const {},
  });
}
