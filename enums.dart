/// Fixed, small value sets get real enums (stored as text in SQLite).
/// `Product.category` deliberately stays a free-text field instead — FPO
/// produce categories vary by season and don't fit a fixed list well.

enum PaymentMethod { cash, upi, bankTransfer, cheque, credit }

enum PaymentStatus { paid, pending, partiallyPaid, cancelled }

extension PaymentMethodX on PaymentMethod {
  String get label => switch (this) {
        PaymentMethod.cash => 'Cash',
        PaymentMethod.upi => 'UPI',
        PaymentMethod.bankTransfer => 'Bank Transfer',
        PaymentMethod.cheque => 'Cheque',
        PaymentMethod.credit => 'Credit (Udhaar)',
      };
}

extension PaymentStatusX on PaymentStatus {
  String get label => switch (this) {
        PaymentStatus.paid => 'Paid',
        PaymentStatus.pending => 'Pending',
        PaymentStatus.partiallyPaid => 'Partially Paid',
        PaymentStatus.cancelled => 'Cancelled',
      };
}

// Transactions.status/paymentMethod are stored as the enum's `.name`
// string (e.g. 'paid') — these parse that string back into the enum
// wherever a row is read from the database for display.
extension PaymentStatusParse on String {
  PaymentStatus toPaymentStatus() => PaymentStatus.values.firstWhere(
        (e) => e.name == this,
        orElse: () => PaymentStatus.pending,
      );
}

extension PaymentMethodParse on String {
  PaymentMethod toPaymentMethod() => PaymentMethod.values.firstWhere(
        (e) => e.name == this,
        orElse: () => PaymentMethod.cash,
      );
}
