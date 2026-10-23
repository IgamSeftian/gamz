/// Satu baris item di dalam invoice penjualan.
class PenjualanLine {
  const PenjualanLine({
    required this.noItm,
    required this.qty,
    required this.harga,
  });

  /// Nomor item (referensi ke master item).
  final String noItm;

  /// Jumlah (Qty).
  final int qty;

  /// Harga satuan, diambil dari master item saat transaksi dibuat.
  final double harga;

  /// Gross = harga x qty.
  double get gross => harga * qty;

  factory PenjualanLine.fromMap(Map<dynamic, dynamic> map) {
    return PenjualanLine(
      noItm: (map['noItm'] ?? '') as String,
      qty: (map['qty'] as num?)?.toInt() ?? 0,
      harga: (map['harga'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'noItm': noItm,
      'qty': qty,
      'harga': harga,
    };
  }
}

/// Model transaksi penjualan (master penjualan).
///
/// Satu invoice bisa berisi banyak item (banyak [PenjualanLine]).
class Penjualan {
  const Penjualan({
    required this.noInv,
    required this.tahun,
    required this.noCust,
    required this.items,
    this.addTime,
  });

  /// Nomor invoice, contoh: P001, P002.
  final String noInv;

  /// Tahun transaksi, dipakai untuk filter "Periode Tahun" di menu utama.
  final int tahun;

  /// Nomor customer (referensi ke master customer).
  final String noCust;

  /// Daftar item yang dipesan pada invoice ini.
  final List<PenjualanLine> items;

  /// Waktu penyimpanan transaksi (auto time save). Disembunyikan di UI.
  final DateTime? addTime;

  /// Total qty seluruh item dalam invoice.
  int get qty => items.fold<int>(0, (sum, line) => sum + line.qty);

  /// Total gross (omzet) seluruh item dalam invoice.
  double get gross => items.fold<double>(0, (sum, line) => sum + line.gross);

  factory Penjualan.fromMap(Map<dynamic, dynamic> map) {
    final List<PenjualanLine> lines = <PenjualanLine>[];

    final dynamic rawItems = map['items'];
    if (rawItems is List) {
      for (final dynamic entry in rawItems) {
        lines.add(
          PenjualanLine.fromMap(Map<dynamic, dynamic>.from(entry as Map)),
        );
      }
    } else if (map['noItm'] != null) {
      // Format lama: satu item per invoice (sebelum multi-item).
      lines.add(
        PenjualanLine(
          noItm: (map['noItm'] ?? '') as String,
          qty: (map['qty'] as num?)?.toInt() ?? 0,
          harga: (map['harga'] as num?)?.toDouble() ?? 0,
        ),
      );
    }

    return Penjualan(
      noInv: (map['noInv'] ?? '') as String,
      tahun: (map['tahun'] as num?)?.toInt() ?? 0,
      noCust: (map['noCust'] ?? '') as String,
      items: lines,
      addTime: _parseDate(map['addTime']),
    );
  }

  static DateTime? _parseDate(dynamic v) {
    if (v is DateTime) return v;
    if (v is int) {
      // try milliseconds/seconds
      if (v > 1000000000000) return DateTime.fromMillisecondsSinceEpoch(v);
      if (v > 1000000000) return DateTime.fromMillisecondsSinceEpoch(v * 1000);
      return DateTime.fromMillisecondsSinceEpoch(v);
    }
    if (v is String && v.isNotEmpty) {
      return DateTime.tryParse(v);
    }
    return null;
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'noInv': noInv,
      'tahun': tahun,
      'noCust': noCust,
      'items': items.map((line) => line.toMap()).toList(),
      if (addTime != null) 'addTime': addTime!.toIso8601String(),
    };
  }
}
