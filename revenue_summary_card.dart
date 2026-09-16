import 'package:flutter/material.dart';

import '../../../../core/utils/money.dart';
import '../../providers/dashboard_providers.dart';

class RevenueSummaryCard extends StatelessWidget {
  const RevenueSummaryCard({super.key, required this.stats});

  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: _StatColumn(
                label: 'Total Revenue',
                value: Money.format(stats.totalRevenueInPaise),
                emphasize: true,
              ),
            ),
            Container(
              width: 1,
              height: 40,
              color: theme.colorScheme.outlineVariant,
            ),
            Expanded(
              child: _StatColumn(
                label: "Today's Revenue",
                value: Money.format(stats.todayRevenueInPaise),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(label, style: theme.textTheme.bodySmall),
        const SizedBox(height: 4),
        Text(
          value,
          style: emphasize
              ? theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold)
              : theme.textTheme.titleLarge,
        ),
      ],
    );
  }
}
