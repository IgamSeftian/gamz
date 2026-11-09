import 'package:hive/hive.dart';

import '../models/penjualan.dart';
import 'database_service.dart';
import 'item_service.dart';

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

  /// Nama event yang unik dari data penjualan (Distinct Penjualan.Event).
  static List<String> get eventNames {
    final Set<String> set = <String>{};
    for (final penjualan in all()) {
      final String event = penjualan.event.trim();
      if (event.isNotEmpty) set.add(event);
    }
    return set.toList()..sort();
  }

  /// Daftar transaksi pada [tahun] tertentu, opsional difilter [event].
  static List<Penjualan> byYearAndEvent(int tahun, {String? event}) {
    final List<Penjualan> result = <Penjualan>[];
    for (final penjualan in all()) {
      if (penjualan.tahun != tahun) continue;
      if (event != null && event.isNotEmpty && penjualan.event != event) {
        continue;
      }
      result.add(penjualan);
    }
    return result;
  }

  /// Daftar transaksi pada [tahun] tertentu.
  static List<Penjualan> byYear(int tahun) => byYearAndEvent(tahun);

  /// Total pendapatan (gross) untuk [tahun] tertentu.
  static double totalForYear(int tahun, {String? event}) {
    return byYearAndEvent(
      tahun,
      event: event,
    ).fold<double>(0, (sum, p) => sum + p.gross);
  }

  /// Total qty untuk [tahun] tertentu.
  static int totalQtyForYear(int tahun, {String? event}) {
    return byYearAndEvent(
      tahun,
      event: event,
    ).fold<int>(0, (sum, p) => sum + p.qty);
  }

  /// Membuat nomor invoice berikutnya, contoh: P001, P002.
  static String nextNumber() {
    int max = 0;
    for (final key in _box.keys) {
      final num = int.tryParse(
        key.toString().replaceAll(RegExp(r'[^0-9]'), ''),
      );
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
      potPitem: penjualan.potPitem,
      potLan: penjualan.potLan,
      event: penjualan.event,
      tglKirim: penjualan.tglKirim,
    );
    await _box.put(saved.noInv, saved.toMap());
  }

  /// Melengkapi snapshot HPP & gross pada transaksi lama.
  ///
  /// Data lama belum menyimpan HPP/gross per baris sehingga nilainya mengikuti
  /// master item. Migrasi ini membekukan nilai tersebut satu kali agar tidak
  /// berubah ketika master item diubah.
  static Future<void> migrateSnapshots() async {
    for (final key in _box.keys.toList()) {
      final data = _box.get(key);
      if (data is! Map) continue;
      final Map<dynamic, dynamic> map = Map<dynamic, dynamic>.from(data);
      final dynamic rawItems = map['items'];
      if (rawItems is! List) continue;

      bool changed = false;
      final List<dynamic> newItems = <dynamic>[];
      for (final dynamic entry in rawItems) {
        if (entry is! Map) {
          newItems.add(entry);
          continue;
        }
        final Map<dynamic, dynamic> line = Map<dynamic, dynamic>.from(entry);
        if (!line.containsKey('hpp')) {
          final String noItm = (line['noItm'] ?? '') as String;
          line['hpp'] = ItemService.byNo(noItm)?.hpp ?? 0;
          changed = true;
        }
        if (!line.containsKey('gross')) {
          final double harga = (line['harga'] as num?)?.toDouble() ?? 0;
          final int qty = (line['qty'] as num?)?.toInt() ?? 0;
          line['gross'] = harga * qty;
          changed = true;
        }
        newItems.add(line);
      }

      if (!map.containsKey('gross') || !map.containsKey('hpp')) {
        double gross = 0;
        double hpp = 0;
        for (final dynamic entry in newItems) {
          if (entry is! Map) continue;
          final double lineGross =
              (entry['gross'] as num?)?.toDouble() ??
              ((entry['harga'] as num?)?.toDouble() ?? 0) *
                  ((entry['qty'] as num?)?.toInt() ?? 0);
          final double lineHpp = (entry['hpp'] as num?)?.toDouble() ?? 0;
          gross += lineGross;
          hpp += lineHpp * ((entry['qty'] as num?)?.toInt() ?? 0);
        }
        map['gross'] = gross;
        map['hpp'] = hpp;
        changed = true;
      }

      if (changed) {
        map['items'] = newItems;
        await _box.put(key, map);
      }
    }
  }

  static Future<void> delete(String noInv) async {
    await _box.delete(noInv);
  }

  /// Menghapus seluruh transaksi pada [tahun]. Mengembalikan jumlah terhapus.
  static Future<int> deleteByYear(int tahun) async {
    final List<String> keys = <String>[];
    for (final key in _box.keys) {
      final data = _box.get(key);
      if (data is Map && (data['tahun'] as num?)?.toInt() == tahun) {
        keys.add(key.toString());
      }
    }
    await _box.deleteAll(keys);
    return keys.length;
  }
}
