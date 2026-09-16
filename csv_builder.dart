/// Minimal CSV encoder — good enough for exporting plain business data
/// (no formulas, no huge datasets). Handles the common escaping cases
/// per RFC 4180: a field containing a comma, quote, or newline gets
/// wrapped in quotes with internal quotes doubled.
///
/// Hand-rolled instead of adding a `csv` package dependency — the
/// format is simple enough that it's not worth pulling in a package I
/// can't verify installs cleanly without pub.dev access from here.
class CsvBuilder {
  final List<List<Object?>> _rows = [];

  void addRow(List<Object?> row) => _rows.add(row);

  String build() => _rows.map(_encodeRow).join('\r\n');

  String _encodeRow(List<Object?> row) => row.map(_encodeField).join(',');

  String _encodeField(Object? field) {
    final text = field?.toString() ?? '';
    final needsQuoting = text.contains(',') ||
        text.contains('"') ||
        text.contains('\n') ||
        text.contains('\r');
    if (!needsQuoting) return text;
    return '"${text.replaceAll('"', '""')}"';
  }
}
