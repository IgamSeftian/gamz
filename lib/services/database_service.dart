import 'package:hive_flutter/hive_flutter.dart';

/// Service untuk menginisialisasi dan mengakses database lokal Hive.
///
/// Hive menyimpan data dalam "box" (mirip tabel). Di sini kita punya:
/// - [usersBoxName]     : menyimpan data akun user (key = email)
/// - [sessionBoxName]   : menyimpan sesi login yang sedang aktif
/// - [itemsBoxName]     : menyimpan master item (kue)
/// - [customersBoxName] : menyimpan master customer
/// - [penjualanBoxName] : menyimpan transaksi penjualan (master penjualan)
///
/// Hive dipilih karena berjalan di semua platform (Android, iOS, Windows,
/// macOS, Linux, dan Web) tanpa konfigurasi tambahan.
class DatabaseService {
  DatabaseService._();

  static const String usersBoxName = 'users';
  static const String sessionBoxName = 'session';
  static const String itemsBoxName = 'items';
  static const String customersBoxName = 'customers';
  static const String penjualanBoxName = 'penjualan';

  /// Dipanggil sekali saat aplikasi start.
  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(usersBoxName);
    await Hive.openBox(sessionBoxName);
    await Hive.openBox(itemsBoxName);
    await Hive.openBox(customersBoxName);
    await Hive.openBox(penjualanBoxName);
  }

  /// Box berisi seluruh akun user.
  static Box get users => Hive.box(usersBoxName);

  /// Box berisi sesi login aktif.
  static Box get session => Hive.box(sessionBoxName);

  /// Box berisi master item (kue).
  static Box get items => Hive.box(itemsBoxName);

  /// Box berisi master customer.
  static Box get customers => Hive.box(customersBoxName);

  /// Box berisi transaksi penjualan (master penjualan).
  static Box get penjualan => Hive.box(penjualanBoxName);
}
