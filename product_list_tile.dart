import 'package:flutter/material.dart';

import '../../../../core/utils/money.dart';
import '../../../../database/app_database.dart';

class ProductListTile extends StatelessWidget {
  const ProductListTile({
    super.key,
    required this.product,
    required this.onTap,
    required this.onDelete,
  });

  final Product product;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  // Not a configurable setting yet — just a visual nudge on the row.
  // Move to BusinessSettings later if it needs to be per-business.
  static const _lowStockThreshold = 5;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLowStock = product.stockQuantity <= _lowStockThreshold;

    return ListTile(
      onTap: onTap,
      title: Text(product.title),
      subtitle: Text('${product.sku} · ${product.category}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(Money.format(product.priceInPaise)),
              const SizedBox(height: 2),
              Text(
                '${product.stockQuantity} in stock',
                style: TextStyle(
                  fontSize: 12,
                  color: isLowStock ? theme.colorScheme.error : null,
                  fontWeight: isLowStock ? FontWeight.w600 : null,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete product',
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
