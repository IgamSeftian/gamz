/// Model master event (periode PO).
///
/// Contoh: "Event Tahun Baru", "Event Lebaran". Event dipakai sebagai pemisah
/// data penjualan berdasarkan periode [tglAwal] sampai [tglAkhir].
class MasterEvent {
  const MasterEvent({
    required this.kdEvent,
    required this.nEvent,
    required this.tglAwal,
    required this.tglAkhir,
  });

  /// Kode event, contoh: E001, E002.
  final String kdEvent;

  /// Nama event, dipakai sebagai nilai kolom Event pada penjualan.
  final String nEvent;

  /// Tanggal awal periode event.
  final DateTime tglAwal;

  /// Tanggal akhir periode event.
  final DateTime tglAkhir;

  /// True bila [date] berada di dalam periode event (inklusif).
  bool covers(DateTime date) {
    final DateTime day = DateTime(date.year, date.month, date.day);
    final DateTime start = DateTime(tglAwal.year, tglAwal.month, tglAwal.day);
    final DateTime end = DateTime(tglAkhir.year, tglAkhir.month, tglAkhir.day);
    return !day.isBefore(start) && !day.isAfter(end);
  }

  factory MasterEvent.fromMap(Map<dynamic, dynamic> map) {
    final DateTime now = DateTime.now();
    return MasterEvent(
      kdEvent: (map['kdEvent'] ?? '') as String,
      nEvent: (map['nEvent'] ?? '') as String,
      tglAwal:
          _parseDate(map['tgl_awal'] ?? map['tglAwal']) ??
          DateTime(now.year, now.month, now.day),
      tglAkhir:
          _parseDate(map['tgl_akhir'] ?? map['tglAkhir']) ??
          DateTime(now.year, now.month, now.day),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return null;
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'kdEvent': kdEvent,
      'nEvent': nEvent,
      'tgl_awal': tglAwal.toIso8601String(),
      'tgl_akhir': tglAkhir.toIso8601String(),
    };
  }
}
