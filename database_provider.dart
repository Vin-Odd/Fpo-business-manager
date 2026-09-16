import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final productDaoProvider =
    Provider((ref) => ref.watch(appDatabaseProvider).productDao);

final transactionDaoProvider =
    Provider((ref) => ref.watch(appDatabaseProvider).transactionDao);

final settingsDaoProvider =
    Provider((ref) => ref.watch(appDatabaseProvider).settingsDao);

// Shared reactive streams — kept here (not inside one feature's
// providers file) because Dashboard, Inventory, and Sales all read the
// same underlying tables. Defining each stream once means one live
// subscription per table, no matter how many screens watch it.
final productsStreamProvider = StreamProvider<List<Product>>((ref) {
  return ref.watch(productDaoProvider).watchAllProducts();
});

final allTransactionsStreamProvider = StreamProvider<List<Transaction>>((ref) {
  return ref.watch(transactionDaoProvider).watchAllTransactions();
});
