import 'package:drift/drift.dart';

import 'syncable_columns.dart';

class Transactions extends Table with SyncableColumns {
  DateTimeColumn get timestamp => dateTime().withDefault(currentDateAndTime)();
  TextColumn get customerName => text().nullable()();

  // Sum of all line items — stored as paise, see core/utils/money.dart.
  IntColumn get totalAmountInPaise => integer()();

  // Enum name stored as text — see shared/enums.dart (PaymentMethod).
  TextColumn get paymentMethod => text()();
  // Enum name stored as text — see shared/enums.dart (PaymentStatus).
  TextColumn get status => text()();

  TextColumn get notes => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
