/// Satu baris item di dalam invoice penjualan.
///
/// [harga] dan [hpp] adalah nilai snapshot saat transaksi disimpan, sehingga
/// perubahan pada master item tidak mengubah nilai penjualan yang sudah ada.
class PenjualanLine {
  const PenjualanLine({
    required this.noItm,
    required this.qty,
    required this.harga,
    this.hpp = 0,
    this.storedGross,
  });

  /// Nomor item (referensi ke master item).
  final String noItm;

  /// Jumlah (Qty).
  final int qty;

  /// Harga satuan (snapshot dari master item saat transaksi dibuat).
  final double harga;

  /// HPP satuan (snapshot dari master item saat transaksi dibuat).
  final double hpp;

  /// Gross tersimpan; bila null (data lama) dihitung dari harga x qty.
  final double? storedGross;

  /// Gross = harga x qty.
  double get gross => storedGross ?? harga * qty;

  /// Modal = HPP x qty.
  double get modal => hpp * qty;

  factory PenjualanLine.fromMap(Map<dynamic, dynamic> map) {
    return PenjualanLine(
      noItm: (map['noItm'] ?? '') as String,
      qty: (map['qty'] as num?)?.toInt() ?? 0,
      harga: (map['harga'] as num?)?.toDouble() ?? 0,
      hpp: ((map['hpp'] ?? map['HPP']) as num?)?.toDouble() ?? 0,
      storedGross: ((map['gross'] ?? map['Gross']) as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'noItm': noItm,
      'qty': qty,
      'harga': harga,
      'hpp': hpp,
      'gross': gross,
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
    this.potPitem = 0,
    this.potLan = 0,
    this.event = '',
    this.tglKirim,
    this.storedGross,
    this.storedHpp,
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

  /// Potongan per item (PotPitem).
  final double potPitem;

  /// Potongan langsung (PotLan).
  final double potLan;

  /// Nama event (pemisah periode PO), contoh: "Event Tahun Baru".
  final String event;

  /// Tanggal kirim (acuan pengiriman). Null berarti belum ditentukan.
  final DateTime? tglKirim;

  /// Gross tersimpan (snapshot transaksi); null = dihitung dari baris item.
  final double? storedGross;

  /// HPP tersimpan (snapshot transaksi); null = dihitung dari baris item.
  final double? storedHpp;

  /// Total qty seluruh item dalam invoice.
  int get qty => items.fold<int>(0, (sum, line) => sum + line.qty);

  /// Total gross (omzet) seluruh item dalam invoice.
  double get gross =>
      storedGross ?? items.fold<double>(0, (sum, line) => sum + line.gross);

  /// Total HPP (modal) seluruh item dalam invoice.
  double get hpp =>
      storedHpp ?? items.fold<double>(0, (sum, line) => sum + line.modal);

  /// Total potongan invoice: (PotPitem × Qty) atau PotLan.
  double get potongan => potPitem * qty + potLan;

  /// Gross setelah potongan.
  double get netGross => gross - potongan;

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
          hpp: ((map['hpp'] ?? map['HPP']) as num?)?.toDouble() ?? 0,
        ),
      );
    }

    return Penjualan(
      noInv: (map['noInv'] ?? '') as String,
      tahun: (map['tahun'] as num?)?.toInt() ?? 0,
      noCust: (map['noCust'] ?? '') as String,
      items: lines,
      addTime: _parseDate(map['addTime']),
      potPitem: ((map['potPitem'] ?? map['PotPitem']) as num?)?.toDouble() ?? 0,
      potLan: ((map['potLan'] ?? map['PotLan']) as num?)?.toDouble() ?? 0,
      event: (map['event'] ?? map['Event'] ?? '') as String,
      tglKirim: _parseDate(
        map['tglKirim'] ?? map['tgl_Kirim'] ?? map['Tgl_Kirim'],
      ),
      storedGross: ((map['gross'] ?? map['Gross']) as num?)?.toDouble(),
      storedHpp: ((map['hpp'] ?? map['HPP']) as num?)?.toDouble(),
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
      'potPitem': potPitem,
      'potLan': potLan,
      'event': event,
      'gross': gross,
      'hpp': hpp,
      if (tglKirim != null) 'tglKirim': tglKirim!.toIso8601String(),
      if (addTime != null) 'addTime': addTime!.toIso8601String(),
    };
  }
}
