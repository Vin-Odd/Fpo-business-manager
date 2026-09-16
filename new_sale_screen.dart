import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/money.dart';
import '../../../database/app_database.dart';
import '../../../database/database_provider.dart';
import '../../../shared/enums.dart';
import 'widgets/cart_line_tile.dart';
import 'widgets/product_picker_sheet.dart';

class NewSaleScreen extends ConsumerStatefulWidget {
  const NewSaleScreen({super.key});

  @override
  ConsumerState<NewSaleScreen> createState() => _NewSaleScreenState();
}

class _NewSaleScreenState extends ConsumerState<NewSaleScreen> {
  final _customerNameController = TextEditingController();
  final _notesController = TextEditingController();

  final List<CartLine> _cart = [];
  PaymentMethod _paymentMethod = PaymentMethod.cash;

  // Cancelled is deliberately not offered here — it doesn't make sense
  // to record a brand-new sale as already cancelled. Voiding an
  // existing sale is a separate action to add later, not part of
  // creating one.
  PaymentStatus _paymentStatus = PaymentStatus.paid;

  bool _saving = false;

  int get _grandTotalInPaise =>
      _cart.fold(0, (sum, line) => sum + line.lineTotalInPaise);

  @override
  void dispose() {
    _customerNameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _addProduct() async {
    final product = await ProductPickerSheet.show(context);
    if (product == null) return;

    setState(() {
      final existing = _cart.where((l) => l.product.id == product.id);
      if (existing.isNotEmpty) {
        existing.first.quantity++;
      } else {
        _cart.add(CartLine(product: product));
      }
    });
  }

  Future<void> _save() async {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one item to the sale.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final transactionDao = ref.read(transactionDaoProvider);

      final customerName = _customerNameController.text.trim();
      final notes = _notesController.text.trim();

      // recordSale saves the sale, its line items, and decrements each
      // product's stock all in one DB transaction — see transaction_dao.dart.
      await transactionDao.recordSale(
        sale: TransactionsCompanion(
          customerName: Value(customerName.isEmpty ? null : customerName),
          totalAmountInPaise: Value(_grandTotalInPaise),
          paymentMethod: Value(_paymentMethod.name),
          status: Value(_paymentStatus.name),
          notes: Value(notes.isEmpty ? null : notes),
        ),
        items: [
          for (final line in _cart)
            TransactionItemsCompanion.insert(
              transactionId: '', // overwritten by recordSale with the real id
              productId: line.product.id,
              quantity: line.quantity,
              unitPriceInPaise: line.product.priceInPaise,
              lineTotalInPaise: line.lineTotalInPaise,
            ),
        ],
      );

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Sale recorded.')));
        context.pop();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save the sale. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('New Sale')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _customerNameController,
            decoration: const InputDecoration(
              labelText: 'Customer Name (optional)',
              hintText: 'Leave blank for a walk-in customer',
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Items', style: theme.textTheme.titleMedium),
              TextButton.icon(
                onPressed: _addProduct,
                icon: const Icon(Icons.add),
                label: const Text('Add Item'),
              ),
            ],
          ),
          if (_cart.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('No items added yet.'),
            )
          else
            for (final line in _cart)
              CartLineTile(
                line: line,
                onIncrement: () => setState(() => line.quantity++),
                onDecrement: () => setState(() {
                  if (line.quantity > 1) {
                    line.quantity--;
                  } else {
                    _cart.remove(line);
                  }
                }),
                onRemove: () => setState(() => _cart.remove(line)),
              ),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Grand Total', style: theme.textTheme.titleMedium),
              Text(
                Money.format(_grandTotalInPaise),
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 24),
          DropdownButtonFormField<PaymentMethod>(
            value: _paymentMethod,
            decoration: const InputDecoration(labelText: 'Payment Method'),
            items: [
              for (final method in PaymentMethod.values)
                DropdownMenuItem(value: method, child: Text(method.label)),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _paymentMethod = value);
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<PaymentStatus>(
            value: _paymentStatus,
            decoration: const InputDecoration(labelText: 'Payment Status'),
            items: [
              for (final status in PaymentStatus.values)
                if (status != PaymentStatus.cancelled)
                  DropdownMenuItem(value: status, child: Text(status.label)),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _paymentStatus = value);
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(labelText: 'Notes (optional)'),
            maxLines: 2,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save Sale'),
          ),
        ],
      ),
    );
  }
}
