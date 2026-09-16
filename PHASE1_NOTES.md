# FPO Business Manager — Phase 1 Scaffold

## What's included
- Flutter project skeleton, feature-first folder structure
- Drift (SQLite) database: Products, Transactions, TransactionItems, BusinessSettings
- Riverpod wiring for the database + DAOs (database/database_provider.dart)
- go_router bottom-navigation shell across Dashboard / Inventory / Sales / Settings
- Placeholder screens for all 4 tabs so the app runs today, before any feature is built

## Setup
Easiest: run `./setup.sh` from inside this extracted folder (Mac/Linux/WSL/Git
Bash — requires Flutter already installed). It does steps 1–4 below and
tells you the final command to run it.

Manual steps, same thing spelled out:
1. Create a Flutter project (or copy these files into an existing one):
   flutter create fpo_business_manager
2. Copy pubspec.yaml and the lib/ folder from this scaffold in, overwriting the defaults.
3. Install packages:
   flutter pub get
4. Generate the drift/riverpod code — required, app_database.g.dart etc. don't
   exist yet:
   dart run build_runner build --delete-conflicting-outputs
5. Run it:
   flutter run

You should get a working app with a 4-tab bottom nav and placeholder text on
each screen — nothing functional yet, but the skeleton compiles and runs.

## Key design decisions — please review before Phase 2
- **Money stored as integer paise, not double.** Avoids floating-point
  rounding bugs in totals/tax. `Money.format()` (core/utils/money.dart) is
  the one place that converts to a display string.
- **`items[]` normalized into a TransactionItems join table**, not a JSON
  blob column. This lets you query things like "units of Product X sold
  this month" directly in SQL, and each line item snapshots its unit price
  at sale time — so editing a product's price later never rewrites the
  numbers on a past invoice.
- **`category` is free text**, not an enum. FPO produce categories vary by
  season and I didn't want to hardcode a fixed list. Easy to convert to an
  enum later if you'd rather constrain it.
- **PaymentMethod / PaymentStatus are enums** (shared/enums.dart), stored as
  text in SQLite — small, fixed sets of values.
- **Riverpod + drift streams.** Once Phase 2 wires up the Dashboard, the
  revenue total and recent-sales list will update the instant a sale is
  recorded — no manual refresh/setState plumbing needed.
- **State management: Riverpod.** Chosen over Provider/Bloc/GetX for
  compile-time-safe providers and first-class support for streaming DB
  queries straight into widgets.
- **DB: drift over plain sqflite.** Type-safe queries and schema, generated
  data classes, and reactive `.watch()` streams — worth the extra
  build_runner step for an app with several related tables.

## Update: local-first + sync (this revision)
Originally this was pure local SQLite with no backend. After discussing
the reference app's architecture, the plan is now **hybrid**: local
SQLite stays the source of truth for the UI (instant, works offline),
and a sync layer pushes changes to a backend when one exists. What
changed to support that:

- **Primary keys are now client-generated UUIDs** (`lib/database/tables/syncable_columns.dart`),
  not autoincrement integers. A device creating a sale offline needs an
  ID that will never collide with another device's or the server's —
  autoincrement only works when there's one source of truth. The same
  UUID becomes the row's ID on the server too, so there's no
  local-ID-to-server-ID remapping step.
- **Products and Transactions now carry `syncStatus` and `isDeleted`.**
  Any local insert/update sets `syncStatus: 'pending'`; deletes are
  soft (`isDeleted: true`) so a deletion made offline still has
  something to push once the device is back online. `watchAllProducts`/
  `watchAllTransactions` filter out `isDeleted` rows automatically.
- **`lib/sync/`** — `SyncService.pushPending()` walks pending
  Products/Transactions and pushes each via `ApiClient`, marking it
  synced on success and leaving it pending (to retry later) on
  failure. `ApiClient`'s methods are stubs (`UnimplementedError`) since
  there's no backend yet — the shapes are there so wiring up real
  endpoints later doesn't touch the DAOs or schema again.
- **Deliberately push-only for now.** Pulling remote changes
  (`pullProductsSince`/`pullTransactionsSince` are already on the
  `ApiClient` interface) matters once more than one device can edit
  the same record — out of scope for the single-role spec, but the
  interface won't need to change when that's added.
- **`BusinessSettings` stays local-only for now** — not part of the
  sync layer yet. Revisit once there's a reason it needs to leave the
  device (e.g. multi-outlet).

This does mean Phase 1's earlier schemas changed shape (UUID keys
instead of int autoincrement) — worth a look before Phase 2 screens
get built against them.

## Not yet included (later phases)
- PDF invoice generation (the `pdf` and `printing` packages are already in
  pubspec.yaml, ready to use — Invoice Prefix / Next Invoice Number in
  Settings are there waiting for it, but nothing generates a PDF yet)

## Phase 5 (Settings) decisions
- **`currencySymbol` and `logoPath` are in the schema but not in the
  Settings form.** Every screen already hardcodes ₹ via `Money.format()`
  — wiring a configurable currency through every screen that displays
  money is a real cross-cutting change, and for an FPO in India it's
  arguably not worth doing at all. Left the field in the schema in case
  that changes; didn't want a Settings field that looks like it does
  something but doesn't actually affect the rest of the app.
- **CSV export is hand-rolled** (`core/utils/csv_builder.dart`), not
  the `csv` package — the format's simple enough, and it avoids adding
  a dependency I can't verify installs cleanly without pub.dev access
  from here.
- **Sales export is one row per line item, not per transaction** —
  matches the reference app's "Raw Sales Data" shape and is more useful
  for reconciling what actually sold than a header-only row per sale.
- Export uses `share_plus`'s OS share sheet rather than saving directly
  to a folder — there's no backend to export "to" yet, so handing the
  file to Drive/email/WhatsApp/Files is the most useful thing available.

## About the decompiled APK
Once you share the decompiled code, I'll use it as a feature-parity
reference (what fields/flows the old app had) rather than porting it
line-by-line — decompiled Java/Kotlin doesn't translate directly into
Dart/Flutter anyway, and starting fresh keeps this codebase clean and
maintainable against the schema above.
