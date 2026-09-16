import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/products_table.dart';
import '../tables/transaction_items_table.dart';
import '../tables/transactions_table.dart';

part 'transaction_dao.g.dart';

@DriftAccessor(tables: [Transactions, TransactionItems, Products])
class TransactionDao extends DatabaseAccessor<AppDatabase>
    with _$TransactionDaoMixin {
  TransactionDao(super.db);

  Stream<List<Transaction>> watchAllTransactions() => (select(transactions)
        ..where((t) => t.isDeleted.equals(false))
        ..orderBy([
          (t) =>
              OrderingTerm(expression: t.timestamp, mode: OrderingMode.desc)
        ]))
      .watch();

  /// Used by the Dashboard's "recent sales" list.
  Stream<List<Transaction>> watchRecent(int limit) => (select(transactions)
        ..where((t) => t.isDeleted.equals(false))
        ..orderBy([
          (t) =>
              OrderingTerm(expression: t.timestamp, mode: OrderingMode.desc)
        ])
        ..limit(limit))
      .watch();

  Future<List<TransactionItem>> itemsFor(String transactionId) =>
      (select(transactionItems)
            ..where((t) => t.transactionId.equals(transactionId)))
          .get();

  /// Rows the sync service still needs to push to the backend.
  Future<List<Transaction>> getPendingSync() => (select(transactions)
        ..where((t) => t.syncStatus.equals('pending')))
      .get();

  /// One-off snapshot for CSV export — see ProductDao.getAllForExport
  /// for why this isn't a stream.
  Future<List<Transaction>> getAllForExport() => (select(transactions)
        ..where((t) => t.isDeleted.equals(false))
        ..orderBy([(t) => OrderingTerm(expression: t.timestamp)]))
      .get();

  /// Wraps the sale header, its line items, AND the resulting stock
  /// decrements in one DB transaction. Stock is part of this same
  /// transaction (not a separate step called afterwards) so a crash
  /// mid-save can never leave recorded sales out of sync with stock
  /// counts — either the whole sale (items + stock) commits, or none
  /// of it does.
  Future<String> recordSale({
    required TransactionsCompanion sale,
    required List<TransactionItemsCompanion> items,
  }) {
    return transaction(() async {
      final row = await into(transactions).insertReturning(sale);

      for (final item in items) {
        final line = item.copyWith(transactionId: Value(row.id));
        await into(transactionItems).insert(line);

        final productId = line.productId.value;
        final quantitySold = line.quantity.value;
        final product = await (select(products)
              ..where((t) => t.id.equals(productId)))
            .getSingleOrNull();
        if (product != null) {
          await (update(products)..where((t) => t.id.equals(productId)))
              .write(
            ProductsCompanion(
              stockQuantity: Value(product.stockQuantity - quantitySold),
              syncStatus: const Value('pending'),
              updatedAt: Value(DateTime.now()),
            ),
          );
        }
      }

      return row.id;
    });
  }

  /// Called by the sync service once the server has accepted a push.
  Future<void> markSynced(String id) =>
      (update(transactions)..where((t) => t.id.equals(id))).write(
        const TransactionsCompanion(syncStatus: Value('synced')),
      );
}
