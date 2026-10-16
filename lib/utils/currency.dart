import 'package:flutter/services.dart';

/// Membuat format angka dengan pemisah ribuan titik, contoh: 1000000 -> "1.000.000".
String formatThousands(num value) {
  final int rounded = value.round();
  final String digits = rounded.abs().toString();
  final StringBuffer buffer = StringBuffer();

  for (int i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) {
      buffer.write('.');
    }
    buffer.write(digits[i]);
  }

  final String sign = rounded < 0 ? '-' : '';
  return '$sign$buffer';
}

/// Membuat format Rupiah dengan pemisah ribuan titik, contoh: 85000 -> "Rp 85.000".
String formatRupiah(num value) {
  return 'Rp ${formatThousands(value)}';
}

/// Mengubah teks berformat ribuan ("1.000.000") menjadi angka.
int? parseThousands(String text) {
  final String digits = text.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.isEmpty) return null;
  return int.tryParse(digits);
}

/// Formatter input agar angka otomatis berformat ribuan saat diketik.
/// Contoh: mengetik 1000000 menghasilkan tampilan "1.000.000".
class ThousandsInputFormatter extends TextInputFormatter {
  const ThousandsInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final String digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    // Buang angka nol di depan (kecuali satu digit).
    final String normalized =
        digits.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    final String formatted = formatThousands(int.parse(normalized));

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
