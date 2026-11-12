import 'package:intl/intl.dart';

final NumberFormat _inrDecimalFormat = NumberFormat('#,##,##0.00', 'en_IN');
final NumberFormat _inrCompactFormat = NumberFormat('#,##,##0.##', 'en_IN');
final NumberFormat _inrIntFormat = NumberFormat('#,##,##0', 'en_IN');

String formatInr(num amount, {bool withSymbol = true, bool decimals = true}) {
  final formatted = decimals
      ? _inrDecimalFormat.format(amount)
      : _inrCompactFormat.format(amount);
  return withSymbol ? '₹$formatted' : formatted;
}

String formatIndianCount(num count) => _inrIntFormat.format(count);

/// Converts a currency amount to Indian English words (Crore/Lakh/Thousand/Hundred)
/// matching the A4 Tax Invoice print template.
String numberToWordsInr(double amount) {
  final numValue = amount.round();
  if (numValue == 0) return 'Zero Rupees Only';

  const a = [
    '',
    'One ',
    'Two ',
    'Three ',
    'Four ',
    'Five ',
    'Six ',
    'Seven ',
    'Eight ',
    'Nine ',
    'Ten ',
    'Eleven ',
    'Twelve ',
    'Thirteen ',
    'Fourteen ',
    'Fifteen ',
    'Sixteen ',
    'Seventeen ',
    'Eighteen ',
    'Nineteen ',
  ];
  const b = [
    '',
    '',
    'Twenty',
    'Thirty',
    'Forty',
    'Fifty',
    'Sixty',
    'Seventy',
    'Eighty',
    'Ninety',
  ];

  String twoDigits(String s) {
    final val = int.tryParse(s) ?? 0;
    if (val == 0) return '';
    if (val < 20) return a[val];
    return '${b[int.parse(s[0])]} ${a[int.parse(s[1])]}';
  }

  final absStr = numValue.abs().toString();
  if (absStr.length > 9) return 'Rupees ${formatIndianCount(numValue)} Only';

  final padded = absStr.padLeft(9, '0');
  final n1 = int.parse(padded.substring(0, 2)); // Crore
  final n2 = int.parse(padded.substring(2, 4)); // Lakh
  final n3 = int.parse(padded.substring(4, 6)); // Thousand
  final n4 = int.parse(padded.substring(6, 7)); // Hundred
  final n5 = int.parse(padded.substring(7, 9)); // Units

  final buffer = StringBuffer();
  if (numValue < 0) buffer.write('Minus ');
  if (n1 != 0) buffer.write('${twoDigits(padded.substring(0, 2))}Crore ');
  if (n2 != 0) buffer.write('${twoDigits(padded.substring(2, 4))}Lakh ');
  if (n3 != 0) buffer.write('${twoDigits(padded.substring(4, 6))}Thousand ');
  if (n4 != 0) buffer.write('${a[n4]}Hundred ');
  if (n5 != 0) {
    if (buffer.isNotEmpty) buffer.write('and ');
    buffer.write(twoDigits(padded.substring(7, 9)));
  }

  final prefix = buffer.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
  return '$prefix Rupees Only';
}

