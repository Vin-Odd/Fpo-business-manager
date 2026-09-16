import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_formatter.dart';
import '../../../database/app_database.dart';
import '../../../database/database_provider.dart';
import '../../../shared/enums.dart';

class DashboardStats {
  const DashboardStats({
    required this.totalRevenueInPaise,
    required this.todayRevenueInPaise,
  });

  final int totalRevenueInPaise;
  final int todayRevenueInPaise;
}

/// Both the stats and the recent-sales list below derive from the one
/// shared stream in database_provider.dart — recording a sale updates
/// the whole dashboard in one go via drift's reactive stream, and Sales
/// reuses the same subscription instead of opening a second one.
/// Cancelled sales don't count as revenue. There's no separate
/// "amount actually collected" field yet (Transaction only has a
/// total + status, no partial-payment amount) — so a partially-paid
/// sale still counts at its full value here, same as a fully-paid one.
/// Worth adding an amountPaidInPaise field later if you want a true
/// "dues outstanding" figure.
final dashboardStatsProvider = Provider<DashboardStats>((ref) {
  final transactions = ref.watch(allTransactionsStreamProvider).value ?? [];

  var total = 0;
  var today = 0;
  for (final t in transactions) {
    if (t.status.toPaymentStatus() == PaymentStatus.cancelled) continue;
    total += t.totalAmountInPaise;
    if (AppDateFormat.isToday(t.timestamp)) {
      today += t.totalAmountInPaise;
    }
  }
  return DashboardStats(totalRevenueInPaise: total, todayRevenueInPaise: today);
});

/// Most recent 5 sales for the dashboard list.
final recentSalesProvider = StreamProvider<List<Transaction>>((ref) {
  return ref.watch(transactionDaoProvider).watchRecent(5);
});
