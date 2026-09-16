import 'package:flutter/material.dart';

import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/money.dart';
import '../../../../database/app_database.dart';
import '../../../../shared/enums.dart';

class RecentSalesList extends StatelessWidget {
  const RecentSalesList({super.key, required this.transactions});

  final List<Transaction> transactions;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final t in transactions) _SaleRow(transaction: t),
      ],
    );
  }
}

class _SaleRow extends StatelessWidget {
  const _SaleRow({required this.transaction});

  final Transaction transaction;

  @override
  Widget build(BuildContext context) {
    final status = transaction.status.toPaymentStatus();
    return ListTile(
      contentPadding: EdgeInsets.zero,
      // Matches the reference app's "Walk-in Customer" fallback for
      // sales with no customer name recorded.
      title: Text(transaction.customerName?.trim().isNotEmpty == true
          ? transaction.customerName!
          : 'Walk-in Customer'),
      subtitle: Text(AppDateFormat.short(transaction.timestamp)),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            Money.format(transaction.totalAmountInPaise),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          _StatusChip(status: status),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final PaymentStatus status;

  Color _color(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return switch (status) {
      PaymentStatus.paid => Colors.green,
      PaymentStatus.pending => Colors.orange,
      PaymentStatus.partiallyPaid => Colors.amber.shade800,
      PaymentStatus.cancelled => scheme.error,
    };
  }

  @override
  Widget build(BuildContext context) {
    final color = _color(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
