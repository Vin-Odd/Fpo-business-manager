import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../database/app_database.dart';
import '../../../database/database_provider.dart';
import '../../../routing/app_routes.dart';
import '../../../shared/enums.dart';
import 'widgets/sale_detail_sheet.dart';

class SalesScreen extends ConsumerWidget {
  const SalesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(allTransactionsStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Sales')),
      body: transactionsAsync.when(
        data: (transactions) => transactions.isEmpty
            ? const EmptyState(
                icon: Icons.point_of_sale_outlined,
                title: 'No sales recorded yet',
                subtitle: 'Tap the + button to record your first sale.',
              )
            : ListView.separated(
                itemCount: transactions.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final txn = transactions[index];
                  return _SaleRow(
                    transaction: txn,
                    onTap: () => SaleDetailSheet.show(context, txn),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text(
            'Could not load sales.',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('${AppRoutes.sales}/new'),
        tooltip: 'Record a sale',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _SaleRow extends StatelessWidget {
  const _SaleRow({required this.transaction, required this.onTap});

  final Transaction transaction;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final status = transaction.status.toPaymentStatus();
    return ListTile(
      onTap: onTap,
      title: Text(
        transaction.customerName?.trim().isNotEmpty == true
            ? transaction.customerName!
            : 'Walk-in Customer',
      ),
      subtitle: Text(
        '${AppDateFormat.short(transaction.timestamp)} · '
        '${transaction.paymentMethod.toPaymentMethod().label}',
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            Money.format(transaction.totalAmountInPaise),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text(status.label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
