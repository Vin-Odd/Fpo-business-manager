import 'package:drift/drift.dart';

import 'products_table.dart';
import 'syncable_columns.dart';
import 'transactions_table.dart';

/// The spec's `Transaction.items[]` array is normalized into this join
/// table instead of a JSON blob column. Reasons:
///  - can query "units of Product X sold this month" directly in SQL
///  - each line snapshots unitPriceInPaise at sale time, so editing a
///    product's price later never rewrites past invoices
class TransactionItems extends Table with SyncableColumns {
  TextColumn get transactionId =>
      text().references(Transactions, #id, onDelete: KeyAction.cascade)();

  TextColumn get productId =>
      text().references(Products, #id, onDelete: KeyAction.restrict)();

  IntColumn get quantity => integer()();

  // Snapshot of Products.priceInPaise at the moment of sale.
  IntColumn get unitPriceInPaise => integer()();
  IntColumn get lineTotalInPaise => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
