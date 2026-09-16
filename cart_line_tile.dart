import 'package:flutter/material.dart';

import '../../../../core/utils/money.dart';
import '../../../../database/app_database.dart';

class CartLine {
  CartLine({required this.product, this.quantity = 1});

  final Product product;
  int quantity;

  int get lineTotalInPaise => product.priceInPaise * quantity;

  /// Selling more than what's currently on record as in stock. Shown
  /// as a soft warning, not blocked — stock counts can lag reality
  /// (e.g. a fresh delivery not entered yet), and forcing a hard block
  /// here would be more disruptive than helpful for a small FPO outlet.
  bool get exceedsStock => quantity > product.stockQuantity;
}

class CartLineTile extends StatelessWidget {
  const CartLineTile({
    super.key,
    required this.line,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
  });

  final CartLine line;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      title: Text(line.product.title),
      subtitle: line.exceedsStock
          ? Text(
              'Only ${line.product.stockQuantity} in stock',
              style: TextStyle(color: theme.colorScheme.error),
            )
          : Text(Money.format(line.product.priceInPaise)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: onDecrement,
          ),
          Text('${line.quantity}', style: theme.textTheme.titleMedium),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: onIncrement,
          ),
          const SizedBox(width: 4),
          SizedBox(
            width: 72,
            child: Text(
              Money.format(line.lineTotalInPaise),
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}
