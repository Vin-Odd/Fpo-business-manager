import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/business_settings_table.dart';

part 'settings_dao.g.dart';

@DriftAccessor(tables: [BusinessSettings])
class SettingsDao extends DatabaseAccessor<AppDatabase>
    with _$SettingsDaoMixin {
  SettingsDao(super.db);

  /// Reactive stream of the single settings row (id = 1), seeded in
  /// AppDatabase.migration so this never returns nothing.
  Stream<BusinessSetting> watchSettings() =>
      (select(businessSettings)..where((t) => t.id.equals(1)))
          .watchSingle();

  Future<void> updateSettings(BusinessSettingsCompanion settings) =>
      (update(businessSettings)..where((t) => t.id.equals(1)))
          .write(settings);
}
