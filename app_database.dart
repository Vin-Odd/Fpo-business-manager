import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'daos/product_dao.dart';
import 'daos/settings_dao.dart';
import 'daos/transaction_dao.dart';
import 'tables/business_settings_table.dart';
import 'tables/products_table.dart';
import 'tables/transaction_items_table.dart';
import 'tables/transactions_table.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [Products, Transactions, TransactionItems, BusinessSettings],
  daos: [ProductDao, TransactionDao, SettingsDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          // Seed the single settings row so the app always has one to read.
          await into(businessSettings).insert(
            const BusinessSettingsCompanion(),
            mode: InsertMode.insertOrIgnore,
          );
        },
        // Add onUpgrade(m, from, to) steps here as schemaVersion increases
        // in later phases — never edit onCreate once the app has shipped.
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'fpo_business.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
