import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/empty_state.dart';
import '../providers/dashboard_providers.dart';
import 'widgets/quick_actions_row.dart';
import 'widgets/recent_sales_list.dart';
import 'widgets/revenue_summary_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(dashboardStatsProvider);
    final recentSalesAsync = ref.watch(recentSalesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: RefreshIndicator(
        // Data is already reactive (drift streams), so there's nothing
        // to actually refetch — this just gives a familiar pull gesture.
        onRefresh: () async {},
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            RevenueSummaryCard(stats: stats),
            const SizedBox(height: 16),
            const QuickActionsRow(),
            const SizedBox(height: 24),
            Text(
              'Recent Sales',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            recentSalesAsync.when(
              data: (sales) => sales.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.only(top: 24),
                      child: EmptyState(
                        icon: Icons.receipt_long_outlined,
                        title: 'No sales yet',
                        subtitle: 'Recorded sales will show up here.',
                      ),
                    )
                  : RecentSalesList(transactions: sales),
              loading: () => const Padding(
                padding: EdgeInsets.only(top: 24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Text(
                  'Could not load recent sales.',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
