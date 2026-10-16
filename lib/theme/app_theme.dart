import 'package:flutter/material.dart';

/// Kumpulan warna & tema aplikasi agar tampilan konsisten.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF4845EE);
  static const Color primaryDark = Color(0xFF322FB0);
  static const Color accent = Color(0xFF6C63FF);
  static const Color background = Color(0xFFF4F5FB);
  static const Color textDark = Color(0xFF1F2233);
  static const Color textLight = Color(0xFF8A8FA3);
  static const Color danger = Color(0xFFE5484D);
  static const Color success = Color(0xFF2FA84F);

  /// Warna navy yang selaras dengan latar logo Dapoer Iboe.
  static const Color brandNavy = Color(0xFF153172);
  static const Color brandNavyDark = Color(0xFF0C1C45);

  /// Gradient utama untuk background halaman auth.
  static const LinearGradient gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[primary, accent],
  );

  /// Gradient navy untuk halaman auth, serasi dengan gambar logo.
  static const LinearGradient authGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[brandNavyDark, brandNavy, Color(0xFF1B3E86)],
  );
}

/// Tema global aplikasi.
class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE0E2EE)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE0E2EE)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.6),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
