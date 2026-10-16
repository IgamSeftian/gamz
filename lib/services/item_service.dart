import 'package:hive/hive.dart';

import '../models/item.dart';
import 'database_service.dart';

/// Service CRUD master item.
class ItemService {
  ItemService._();

  static Box get _box => DatabaseService.items;

  /// Daftar seluruh item, diurutkan berdasarkan nomor.
  static List<Item> all() {
    final List<Item> result = <Item>[];
    for (final value in _box.values) {
      result.add(Item.fromMap(Map<dynamic, dynamic>.from(value as Map)));
    }
    result.sort((a, b) => a.noItm.compareTo(b.noItm));
    return result;
  }

  static Item? byNo(String noItm) {
    final data = _box.get(noItm);
    if (data == null) return null;
    return Item.fromMap(Map<dynamic, dynamic>.from(data as Map));
  }

  /// Membuat nomor item berikutnya, contoh: I001, I002.
  static String nextNumber() {
    int max = 0;
    for (final key in _box.keys) {
      final num = int.tryParse(key.toString().replaceAll(RegExp(r'[^0-9]'), ''));
      if (num != null && num > max) max = num;
    }
    return 'I${(max + 1).toString().padLeft(3, '0')}';
  }

  static Future<void> save(Item item) async {
    await _box.put(item.noItm, item.toMap());
  }

  static Future<void> delete(String noItm) async {
    await _box.delete(noItm);
  }
}
