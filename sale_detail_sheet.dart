import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/money.dart';
import '../../../../database/app_database.dart';
import '../../../../database/database_provider.dart';
import '../../../../shared/enums.dart';

class SaleDetailSheet extends ConsumerStatefulWidget {
  const SaleDetailSheet({super.key, required this.transaction});

  final Transaction transaction;

  static Future<void> show(BuildContext context, Transaction transaction) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SaleDetailSheet(transaction: transaction),
    );
  }

  @override
  ConsumerState<SaleDetailSheet> createState() => _SaleDetailSheetState();
}

class _SaleDetailSheetState extends ConsumerState<SaleDetailSheet> {
  // Fetched once in initState, not on every build — itemsFor() returns
  // a fresh Future each call, so calling it directly inside build()
  // would re-trigger the FutureBuilder's loading state on any rebuild.
  late final Future<List<TransactionItem>> _itemsFuture =
      ref.read(transactionDaoProvider).itemsFor(widget.transaction.id);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final transaction = widget.transaction;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                transaction.customerName?.trim().isNotEmpty == true
                    ? transaction.customerName!
                    : 'Walk-in Customer',
                style: theme.textTheme.titleLarge,
              ),
              Text(
                AppDateFormat.short(transaction.timestamp),
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                children: [
                  Chip(
                    label: Text(transaction.paymentMethod.toPaymentMethod().label),
                  ),
                  Chip(label: Text(transaction.status.toPaymentStatus().label)),
                ],
              ),
              const Divider(height: 24),
              Expanded(
                child: FutureBuilder<List<TransactionItem>>(
                  future: _itemsFuture,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final items = snapshot.data!;
                    return ListView.builder(
                      controller: scrollController,
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return ListTile(
                          dense: true,
                          title: Text(
                            '${item.quantity} × ${Money.format(item.unitPriceInPaise)}',
                          ),
                          trailing: Text(Money.format(item.lineTotalInPaise)),
                        );
                      },
                    );
                  },
                ),
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Grand Total', style: theme.textTheme.titleMedium),
                  Text(
                    Money.format(transaction.totalAmountInPaise),
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              if (transaction.notes?.trim().isNotEmpty == true) ...[
                const SizedBox(height: 8),
                Text(
                  'Notes: ${transaction.notes}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
