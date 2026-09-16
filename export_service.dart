import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/utils/csv_builder.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/money.dart';
import '../../../database/database_provider.dart';
import '../../../shared/enums.dart';

/// Exports Products and Sales as two CSV files and opens the device's
/// share sheet (Drive, email, WhatsApp, Files — whatever's installed)
/// so the business can get the data off the device. There's no backend
/// to export "to" yet, so a share sheet is the most useful thing this
/// can do right now.
class ExportService {
  ExportService(this._ref);
  final Ref _ref;

  Future<void> exportAll() async {
    final productDao = _ref.read(productDaoProvider);
    final transactionDao = _ref.read(transactionDaoProvider);

    final products = await productDao.getAllForExport();
    final transactions = await transactionDao.getAllForExport();

    final productsCsv = CsvBuilder()
      ..addRow(['Title', 'SKU', 'Category', 'Price (Rs)', 'Stock Quantity']);
    for (final product in products) {
      productsCsv.addRow([
        product.title,
        product.sku,
        product.category,
        Money.paiseToRupees(product.priceInPaise).toStringAsFixed(2),
        product.stockQuantity,
      ]);
    }

    // One row per line item, not per transaction — matches how the
    // reference app's "Raw Sales Data" report is shaped, and is more
    // useful for reconciling what actually sold than a header-only row.
    final salesCsv = CsvBuilder()
      ..addRow([
        'Date',
        'Customer',
        'Product',
        'SKU',
        'Quantity',
        'Unit Price (Rs)',
        'Line Total (Rs)',
        'Payment Method',
        'Status',
        'Notes',
      ]);
    for (final txn in transactions) {
      final items = await transactionDao.itemsFor(txn.id);
      for (final item in items) {
        final product = await productDao.getById(item.productId);
        salesCsv.addRow([
          AppDateFormat.short(txn.timestamp),
          (txn.customerName?.trim().isNotEmpty ?? false)
              ? txn.customerName
              : 'Walk-in Customer',
          product?.title ?? '(deleted product)',
          product?.sku ?? '',
          item.quantity,
          Money.paiseToRupees(item.unitPriceInPaise).toStringAsFixed(2),
          Money.paiseToRupees(item.lineTotalInPaise).toStringAsFixed(2),
          txn.paymentMethod.toPaymentMethod().label,
          txn.status.toPaymentStatus().label,
          txn.notes ?? '',
        ]);
      }
    }

    final dir = await getTemporaryDirectory();
    final productsFile = File(p.join(dir.path, 'products_export.csv'));
    final salesFile = File(p.join(dir.path, 'sales_export.csv'));
    await productsFile.writeAsString(productsCsv.build());
    await salesFile.writeAsString(salesCsv.build());

    await Share.shareXFiles(
      [XFile(productsFile.path), XFile(salesFile.path)],
      text: 'Business data export',
    );
  }
}

final exportServiceProvider = Provider((ref) => ExportService(ref));
