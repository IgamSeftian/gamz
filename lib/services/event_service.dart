import 'package:hive/hive.dart';

import '../models/event.dart';
import 'database_service.dart';

/// Service CRUD master event.
class EventService {
  EventService._();

  static Box get _box => DatabaseService.events;

  /// Daftar seluruh event, diurutkan berdasarkan kode event.
  static List<MasterEvent> all() {
    final List<MasterEvent> result = <MasterEvent>[];
    for (final value in _box.values) {
      result.add(MasterEvent.fromMap(Map<dynamic, dynamic>.from(value as Map)));
    }
    result.sort((a, b) => a.kdEvent.compareTo(b.kdEvent));
    return result;
  }

  static MasterEvent? byCode(String kdEvent) {
    final data = _box.get(kdEvent);
    if (data == null) return null;
    return MasterEvent.fromMap(Map<dynamic, dynamic>.from(data as Map));
  }

  /// Daftar nama event yang unik, dipakai untuk pilihan pada form penjualan.
  static List<String> get names {
    final Set<String> set = <String>{};
    for (final event in all()) {
      if (event.nEvent.trim().isNotEmpty) set.add(event.nEvent.trim());
    }
    return set.toList()..sort();
  }

  /// Nama event yang aktif pada [date], dipakai sebagai nilai default saat
  /// input penjualan baru. Bila ada beberapa event yang beririsan, dipilih
  /// event dengan tanggal awal paling baru.
  static String nameForDate(DateTime date) {
    MasterEvent? selected;
    for (final event in all()) {
      if (!event.covers(date)) continue;
      if (selected == null || event.tglAwal.isAfter(selected.tglAwal)) {
        selected = event;
      }
    }
    return selected?.nEvent ?? '';
  }

  /// Membuat kode event berikutnya, contoh: E001, E002.
  static String nextNumber() {
    int max = 0;
    for (final key in _box.keys) {
      final num = int.tryParse(
        key.toString().replaceAll(RegExp(r'[^0-9]'), ''),
      );
      if (num != null && num > max) max = num;
    }
    return 'E${(max + 1).toString().padLeft(3, '0')}';
  }

  static Future<void> save(MasterEvent event) async {
    await _box.put(event.kdEvent, event.toMap());
  }

  static Future<void> delete(String kdEvent) async {
    await _box.delete(kdEvent);
  }
}
