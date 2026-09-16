import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/products_table.dart';

part 'product_dao.g.dart';

@DriftAccessor(tables: [Products])
class ProductDao extends DatabaseAccessor<AppDatabase> with _$ProductDaoMixin {
  ProductDao(super.db);

  /// Reactive stream — Inventory list and Dashboard stock widgets rebuild
  /// automatically whenever product data changes. Soft-deleted rows are
  /// excluded — they still exist locally until the delete has synced.
  Stream<List<Product>> watchAllProducts() => (select(products)
        ..where((t) => t.isDeleted.equals(false))
        ..orderBy([(t) => OrderingTerm(expression: t.title)]))
      .watch();

  Future<Product?> getById(String id) =>
      (select(products)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// One-off snapshot for CSV export — not reactive like watchAllProducts,
  /// since an export is a point-in-time file, not a live view.
  Future<List<Product>> getAllForExport() => (select(products)
        ..where((t) => t.isDeleted.equals(false))
        ..orderBy([(t) => OrderingTerm(expression: t.title)]))
      .get();

  /// Rows the sync service still needs to push to the backend.
  Future<List<Product>> getPendingSync() => (select(products)
        ..where((t) => t.syncStatus.equals('pending')))
      .get();

  /// id is left unset so the UUID clientDefault mints one — that same
  /// ID is what gets pushed to the server later, so there's no
  /// server-vs-local ID remapping to deal with.
  Future<void> insertProduct(ProductsCompanion product) =>
      into(products).insert(product);

  /// Any local edit resets syncStatus to 'pending', even if the row was
  /// previously synced — the sync service is what flips it back.
  Future<void> updateProduct(String id, ProductsCompanion changes) =>
      (update(products)..where((t) => t.id.equals(id))).write(
        changes.copyWith(
          syncStatus: const Value('pending'),
          updatedAt: Value(DateTime.now()),
        ),
      );

  /// Soft delete — a hard DELETE would never make it to the server if
  /// the device is offline when the user deletes something. The row
  /// stays local (hidden from watchAllProducts) until sync confirms
  /// the server has the tombstone.
  Future<void> deleteProduct(String id) =>
      (update(products)..where((t) => t.id.equals(id))).write(
        ProductsCompanion(
          isDeleted: const Value(true),
          syncStatus: const Value('pending'),
          updatedAt: Value(DateTime.now()),
        ),
      );

  /// Used by the Sales flow to decrement stock when a sale is recorded.
  Future<void> adjustStock(String productId, int delta) async {
    final product = await getById(productId);
    if (product == null) return;
    await (update(products)..where((t) => t.id.equals(productId))).write(
      ProductsCompanion(
        stockQuantity: Value(product.stockQuantity + delta),
        syncStatus: const Value('pending'),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Called by the sync service once the server has accepted a push.
  Future<void> markSynced(String id) =>
      (update(products)..where((t) => t.id.equals(id))).write(
        const ProductsCompanion(syncStatus: Value('synced')),
      );
}
