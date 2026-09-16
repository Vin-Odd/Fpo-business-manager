import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/money.dart';
import '../../../../database/app_database.dart';
import '../../../../database/database_provider.dart';

/// Shows a searchable product list; returns the tapped Product via
/// Navigator.pop, or null if dismissed without a selection.
class ProductPickerSheet extends ConsumerStatefulWidget {
  const ProductPickerSheet({super.key});

  static Future<Product?> show(BuildContext context) {
    return showModalBottomSheet<Product>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const ProductPickerSheet(),
    );
  }

  @override
  ConsumerState<ProductPickerSheet> createState() =>
      _ProductPickerSheetState();
}

class _ProductPickerSheetState extends ConsumerState<ProductPickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsStreamProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Add a Product', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              TextField(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Search products',
                ),
                onChanged: (v) => setState(() => _query = v.toLowerCase()),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: productsAsync.when(
                  data: (products) {
                    final filtered = _query.isEmpty
                        ? products
                        : products
                            .where((p) =>
                                p.title.toLowerCase().contains(_query) ||
                                p.sku.toLowerCase().contains(_query))
                            .toList();

                    if (filtered.isEmpty) {
                      return const Center(child: Text('No products found.'));
                    }

                    return ListView.builder(
                      controller: scrollController,
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final product = filtered[index];
                        return ListTile(
                          title: Text(product.title),
                          subtitle: Text(
                            '${product.sku} · ${product.stockQuantity} in stock',
                          ),
                          trailing: Text(Money.format(product.priceInPaise)),
                          onTap: () => Navigator.pop(context, product),
                        );
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, __) =>
                      const Center(child: Text('Could not load products.')),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
