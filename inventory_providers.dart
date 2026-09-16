import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../database/database_provider.dart';

// Re-exported so inventory_screen.dart and product_form_screen.dart can
// keep importing this one file without also reaching into database/ —
// the actual stream now lives in database_provider.dart (see the
// comment there) since Sales needs it too.
export '../../../database/database_provider.dart' show productsStreamProvider;

/// Distinct categories already in use, shown as tappable suggestions on
/// the add/edit form — keeps free-text categories reasonably consistent
/// without forcing a fixed list (see shared/enums.dart for why category
/// isn't an enum).
final knownCategoriesProvider = Provider<List<String>>((ref) {
  final products = ref.watch(productsStreamProvider).value ?? [];
  final categories = products.map((p) => p.category).toSet().toList()
    ..sort();
  return categories;
});
