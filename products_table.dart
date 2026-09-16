import 'package:drift/drift.dart';

import 'syncable_columns.dart';

class Products extends Table with SyncableColumns {
  TextColumn get title => text().withLength(min: 1, max: 200)();
  TextColumn get sku => text().withLength(min: 1, max: 64)();

  // Stored as paise (1/100 rupee) — see core/utils/money.dart.
  IntColumn get priceInPaise => integer()();

  IntColumn get stockQuantity => integer().withDefault(const Constant(0))();

  // Free text on purpose — see shared/enums.dart for rationale.
  TextColumn get category => text().withDefault(const Constant('General'))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
        {sku},
      ];
}
