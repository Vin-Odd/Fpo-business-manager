import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/money.dart';
import '../../../database/app_database.dart';
import '../../../database/database_provider.dart';
import '../providers/inventory_providers.dart';

class ProductFormScreen extends ConsumerStatefulWidget {
  const ProductFormScreen({super.key, this.productId});

  /// Null means "add new"; set means "edit existing".
  final String? productId;

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _skuController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _categoryController = TextEditingController();

  late bool _isLoadingExisting = _isEditing;
  bool _saving = false;

  bool get _isEditing => widget.productId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _loadExisting();
    }
  }

  Future<void> _loadExisting() async {
    final product = await ref.read(productDaoProvider).getById(widget.productId!);
    if (!mounted) return;
    if (product != null) {
      _titleController.text = product.title;
      _skuController.text = product.sku;
      _priceController.text =
          Money.paiseToRupees(product.priceInPaise).toStringAsFixed(2);
      _stockController.text = product.stockQuantity.toString();
      _categoryController.text = product.category;
    }
    setState(() => _isLoadingExisting = false);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _skuController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    final dao = ref.read(productDaoProvider);
    final category = _categoryController.text.trim();
    final companion = ProductsCompanion(
      title: Value(_titleController.text.trim()),
      sku: Value(_skuController.text.trim()),
      priceInPaise:
          Value(Money.rupeesToPaise(double.parse(_priceController.text))),
      stockQuantity: Value(int.parse(_stockController.text)),
      category: Value(category.isEmpty ? 'General' : category),
    );

    try {
      if (_isEditing) {
        await dao.updateProduct(widget.productId!, companion);
      } else {
        await dao.insertProduct(companion);
      }
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(_friendlyError(e))));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // The SKU column has a unique constraint (products_table.dart) —
  // that's the realistic failure case here, so it gets a specific
  // message instead of a raw SQLite error string.
  String _friendlyError(Object error) {
    final message = error.toString().toLowerCase();
    if (message.contains('unique')) {
      return 'A product with this SKU already exists.';
    }
    return 'Could not save product. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingExisting) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Product')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final categories = ref.watch(knownCategoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Product' : 'Add Product'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Product Title'),
              textCapitalization: TextCapitalization.sentences,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _skuController,
              decoration: const InputDecoration(labelText: 'SKU'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(labelText: 'Price (₹)'),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                final parsed = double.tryParse(v ?? '');
                if (parsed == null || parsed < 0) return 'Enter a valid price';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _stockController,
              decoration: const InputDecoration(labelText: 'Stock Quantity'),
              keyboardType: TextInputType.number,
              validator: (v) {
                final parsed = int.tryParse(v ?? '');
                if (parsed == null || parsed < 0) {
                  return 'Enter a valid quantity';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _categoryController,
              decoration: const InputDecoration(labelText: 'Category'),
              textCapitalization: TextCapitalization.words,
            ),
            if (categories.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: -8,
                children: [
                  for (final category in categories)
                    ActionChip(
                      label: Text(category),
                      onPressed: () => setState(
                        () => _categoryController.text = category,
                      ),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_isEditing ? 'Update Product' : 'Save Product'),
            ),
          ],
        ),
      ),
    );
  }
}
