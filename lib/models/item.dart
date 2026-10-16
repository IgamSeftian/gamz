/// Model master item (kue).
class Item {
  const Item({
    required this.noItm,
    required this.nama,
    required this.singkatan,
    required this.harga,
  });

  /// Nomor item, contoh: I001, I002.
  final String noItm;

  /// Nama item (input NamaI).
  final String nama;

  /// Singkatan / deskripsi (input Desc2).
  final String singkatan;

  /// Harga satuan dalam Rupiah.
  final double harga;

  factory Item.fromMap(Map<dynamic, dynamic> map) {
    return Item(
      noItm: (map['noItm'] ?? '') as String,
      nama: (map['nama'] ?? '') as String,
      singkatan: (map['singkatan'] ?? '') as String,
      harga: (map['harga'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'noItm': noItm,
      'nama': nama,
      'singkatan': singkatan,
      'harga': harga,
    };
  }
}
