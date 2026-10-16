/// Model transaksi penjualan (master penjualan).
class Penjualan {
  const Penjualan({
    required this.noInv,
    required this.tahun,
    required this.noCust,
    required this.noItm,
    required this.qty,
    required this.harga,
  });

  /// Nomor invoice, contoh: P001, P002.
  final String noInv;

  /// Tahun transaksi, dipakai untuk filter "Periode Tahun" di menu utama.
  final int tahun;

  /// Nomor customer (referensi ke master customer).
  final String noCust;

  /// Nomor item (referensi ke master item).
  final String noItm;

  /// Jumlah (Qty).
  final int qty;

  /// Harga satuan, diambil dari master item saat transaksi dibuat.
  final double harga;

  /// Gross = harga x qty.
  double get gross => harga * qty;

  factory Penjualan.fromMap(Map<dynamic, dynamic> map) {
    return Penjualan(
      noInv: (map['noInv'] ?? '') as String,
      tahun: (map['tahun'] as num?)?.toInt() ?? 0,
      noCust: (map['noCust'] ?? '') as String,
      noItm: (map['noItm'] ?? '') as String,
      qty: (map['qty'] as num?)?.toInt() ?? 0,
      harga: (map['harga'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'noInv': noInv,
      'tahun': tahun,
      'noCust': noCust,
      'noItm': noItm,
      'qty': qty,
      'harga': harga,
    };
  }
}
