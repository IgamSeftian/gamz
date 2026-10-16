/// Model master customer.
class Customer {
  const Customer({
    required this.noCust,
    required this.nama,
    required this.kontak,
    required this.alamat,
  });

  /// Nomor customer, contoh: C001, C002.
  final String noCust;

  /// Nama customer (input NamaC).
  final String nama;

  /// Nomor HP / kontak (input HpNmr).
  final String kontak;

  /// Alamat (input Alamat, maksimal 200 karakter).
  final String alamat;

  factory Customer.fromMap(Map<dynamic, dynamic> map) {
    return Customer(
      noCust: (map['noCust'] ?? '') as String,
      nama: (map['nama'] ?? '') as String,
      kontak: (map['kontak'] ?? '') as String,
      alamat: (map['alamat'] ?? '') as String,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'noCust': noCust,
      'nama': nama,
      'kontak': kontak,
      'alamat': alamat,
    };
  }
}
