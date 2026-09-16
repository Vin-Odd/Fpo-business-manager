import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../database/app_database.dart';
import '../../../database/database_provider.dart';

final businessSettingsProvider = StreamProvider<BusinessSetting>((ref) {
  return ref.watch(settingsDaoProvider).watchSettings();
});
