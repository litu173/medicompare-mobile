/// Formatting helpers, matching web/src/lib/format.ts.
library;

String taka(num? n) {
  if (n == null) return '—';
  final fixed = n < 100 ? n.toStringAsFixed(2) : _trim(n.toStringAsFixed(2));
  final parts = fixed.split('.');
  final whole = parts[0].replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
  return '৳$whole${parts.length > 1 ? '.${parts[1]}' : ''}';
}

String _trim(String s) => s.replaceFirst(RegExp(r'\.?0+$'), '');

/// "/tablet", "/ml" …
String perUnit(String? unit) => unit == null || unit.isEmpty ? '' : '/$unit';

int savingsPct(num price, num reference) {
  if (!(reference > 0) || price >= reference) return 0;
  return ((reference - price) / reference * 100).round();
}

/// A single tablet/capsule/piece is bought as a strip of 10 by default.
bool isPerPiece(String? label) => label != null && RegExp(r'^1 (tablet|capsule|piece)$').hasMatch(label);

String formatNumber(int n) => n.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

String formatDate(DateTime d, {bool time = true}) {
  final date = '${d.day} ${_months[d.month - 1]} ${d.year}';
  if (!time) return date;
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  return '$date, $h:${d.minute.toString().padLeft(2, '0')} ${d.hour < 12 ? 'am' : 'pm'}';
}

final bdPhone = RegExp(r'^(?:\+?88)?01[3-9]\d{8}$');

String normalizePhone(String s) => s.replaceAll(RegExp(r'[\s-]'), '');
