import 'package:intl/intl.dart';

/// All money values are stored and passed around as integer PAISE
/// (1/100 of a rupee) throughout the app — never as double — to avoid
/// floating-point rounding errors in totals, tax, and stored invoices.
///
/// This class is the only place formatting happens, so the display
/// format can change in one spot later (e.g. different currency/locale).
class Money {
  Money._();

  static String format(int paise, {String symbol = '₹'}) {
    final rupees = paise / 100;
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: symbol,
      decimalDigits: 2,
    );
    return formatter.format(rupees);
  }

  static int rupeesToPaise(double rupees) => (rupees * 100).round();

  static double paiseToRupees(int paise) => paise / 100;
}
