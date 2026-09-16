import 'package:intl/intl.dart';

/// Single place for date/time display formatting, same reasoning as
/// core/utils/money.dart — one spot to change the format later.
class AppDateFormat {
  AppDateFormat._();

  static final _dayMonthTime = DateFormat('d MMM, h:mm a');
  static final _dateOnly = DateFormat('yyyy-MM-dd');

  /// "12 Sep, 3:45 PM" — used in lists (recent sales, transactions).
  static String short(DateTime dt) => _dayMonthTime.format(dt);

  static bool isToday(DateTime dt) {
    final now = DateTime.now();
    return dt.year == now.year && dt.month == now.month && dt.day == now.day;
  }

  /// "2026-09-12" — stable key for grouping/filtering by calendar day.
  static String dayKey(DateTime dt) => _dateOnly.format(dt);
}
