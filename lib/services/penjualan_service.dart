import 'package:hive/hive.dart';

import '../models/penjualan.dart';
import 'database_service.dart';

/// Service CRUD master penjualan (transaksi).
class PenjualanService {
  PenjualanService._();

  static Box get _box => DatabaseService.penjualan;

  /// Daftar seluruh transaksi, diurutkan berdasarkan nomor invoice.
  static List<Penjualan> all() {
    final List<Penjualan> result = <Penjualan>[];
    for (final value in _box.values) {
      result.add(Penjualan.fromMap(Map<dynamic, dynamic>.from(value as Map)));
    }
    result.sort((a, b) => a.noInv.compareTo(b.noInv));
    return result;
  }

  static Penjualan? byNo(String noInv) {
    final data = _box.get(noInv);
    if (data == null) return null;
    return Penjualan.fromMap(Map<dynamic, dynamic>.from(data as Map));
  }

  /// Semua tahun yang tersedia, diurutkan dari yang terbaru.
  static List<int> get years {
    final Set<int> set = <int>{};
    for (final penjualan in all()) {
      if (penjualan.tahun > 0) set.add(penjualan.tahun);
    }
    return set.toList()..sort((a, b) => b.compareTo(a));
  }

  /// Daftar transaksi pada [tahun] tertentu.
  static List<Penjualan> byYear(int tahun) {
    final List<Penjualan> result = <Penjualan>[];
    for (final penjualan in all()) {
      if (penjualan.tahun == tahun) result.add(penjualan);
    }
    return result;
  }

  /// Total pendapatan (gross) untuk [tahun] tertentu.
  static double totalForYear(int tahun) {
    return byYear(tahun).fold<double>(0, (sum, p) => sum + p.gross);
  }

  /// Total qty untuk [tahun] tertentu.
  static int totalQtyForYear(int tahun) {
    return byYear(tahun).fold<int>(0, (sum, p) => sum + p.qty);
  }

  /// Membuat nomor invoice berikutnya, contoh: P001, P002.
  static String nextNumber() {
    int max = 0;
    for (final key in _box.keys) {
      final num = int.tryParse(key.toString().replaceAll(RegExp(r'[^0-9]'), ''));
      if (num != null && num > max) max = num;
    }
    return 'P${(max + 1).toString().padLeft(3, '0')}';
  }

  static Future<void> save(Penjualan penjualan) async {
    final now = DateTime.now();
    final saved = Penjualan(
      noInv: penjualan.noInv,
      tahun: penjualan.tahun,
      noCust: penjualan.noCust,
      items: penjualan.items,
      addTime: penjualan.addTime ?? now,
    );
    await _box.put(saved.noInv, saved.toMap());
  }

  static Future<void> delete(String noInv) async {
    await _box.delete(noInv);
  }
}
