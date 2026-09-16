import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

/// Shared columns for any table that needs to sync to a backend later.
///
/// Key decision: primary keys are client-generated UUIDs, not
/// autoincrement integers. An autoincrement int only makes sense once
/// there is a single source of truth (the server) — for local-first
/// creation (recording a sale with no signal), the device must be able
/// to mint an ID that will never collide with another device's ID or
/// the server's own numbering. A UUID does that for free.
mixin SyncableColumns on Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();

  /// 'pending'  — created/edited locally, not yet pushed
  /// 'synced'   — matches the server as of updatedAt
  /// 'conflict' — server rejected the push or had a newer edit
  TextColumn get syncStatus =>
      text().withDefault(const Constant('pending'))();

  /// Soft delete — deletions must sync as a tombstone, not vanish
  /// locally before the server has heard about them.
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Also doubles as the last-write-wins conflict resolution key when
  /// pulling remote changes.
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
