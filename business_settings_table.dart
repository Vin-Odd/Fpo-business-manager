import 'package:drift/drift.dart';

/// Single-row table holding business-wide configuration. The app always
/// reads/writes the row with id = 1 (seeded in AppDatabase.migration).
class BusinessSettings extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  TextColumn get businessName =>
      text().withDefault(const Constant('My FPO'))();
  TextColumn get address => text().withDefault(const Constant(''))();
  TextColumn get gstOrTaxId => text().nullable()();
  RealColumn get taxRatePercent => real().withDefault(const Constant(0))();
  TextColumn get currencySymbol => text().withDefault(const Constant('₹'))();
  TextColumn get invoicePrefix =>
      text().withDefault(const Constant('INV-'))();
  IntColumn get nextInvoiceNumber =>
      integer().withDefault(const Constant(1))();
  TextColumn get logoPath => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
