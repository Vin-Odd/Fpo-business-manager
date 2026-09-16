import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../routing/app_routes.dart';

/// "New Sale" deep-links straight to the sale form (built in Phase 4).
/// "Add Product" still just switches to the Inventory tab root and
/// waits for the FAB tap — the product form doesn't have a natural
/// "quick add" shortcut the way a sale does, since you'd still need to
/// fill in title/SKU/price regardless of how you got there.
class QuickActionsRow extends StatelessWidget {
  const QuickActionsRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: () => context.go('${AppRoutes.sales}/new'),
            icon: const Icon(Icons.point_of_sale),
            label: const Text('New Sale'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => context.go(AppRoutes.inventory),
            icon: const Icon(Icons.add_box_outlined),
            label: const Text('Add Product'),
          ),
        ),
      ],
    );
  }
}
