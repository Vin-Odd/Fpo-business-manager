import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/empty_state.dart';
import '../../../database/app_database.dart';
import '../../../database/database_provider.dart';
import '../../../routing/app_routes.dart';
import '../providers/inventory_providers.dart';
import 'widgets/product_list_tile.dart';

class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Inventory')),
      body: productsAsync.when(
        data: (products) => products.isEmpty
            ? const EmptyState(
                icon: Icons.inventory_2_outlined,
                title: 'No products yet',
                subtitle: 'Tap the + button to add your first product.',
              )
            : ListView.separated(
                itemCount: products.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final product = products[index];
                  return ProductListTile(
                    product: product,
                    onTap: () =>
                        context.go('${AppRoutes.inventory}/edit/${product.id}'),
                    onDelete: () => _confirmDelete(context, ref, product),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text(
            'Could not load products.',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('${AppRoutes.inventory}/add'),
        tooltip: 'Add product',
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Product product,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete product?'),
        content: Text('This will remove "${product.title}" from inventory.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(productDaoProvider).deleteProduct(product.id);
    }
  }
}
