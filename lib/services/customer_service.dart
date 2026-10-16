import 'package:hive/hive.dart';

import '../models/customer.dart';
import 'database_service.dart';

/// Service CRUD master customer.
class CustomerService {
  CustomerService._();

  static Box get _box => DatabaseService.customers;

  /// Daftar seluruh customer, diurutkan berdasarkan nomor.
  static List<Customer> all() {
    final List<Customer> result = <Customer>[];
    for (final value in _box.values) {
      result.add(Customer.fromMap(Map<dynamic, dynamic>.from(value as Map)));
    }
    result.sort((a, b) => a.noCust.compareTo(b.noCust));
    return result;
  }

  static Customer? byNo(String noCust) {
    final data = _box.get(noCust);
    if (data == null) return null;
    return Customer.fromMap(Map<dynamic, dynamic>.from(data as Map));
  }

  /// Membuat nomor customer berikutnya, contoh: C001, C002.
  static String nextNumber() {
    int max = 0;
    for (final key in _box.keys) {
      final num = int.tryParse(key.toString().replaceAll(RegExp(r'[^0-9]'), ''));
      if (num != null && num > max) max = num;
    }
    return 'C${(max + 1).toString().padLeft(3, '0')}';
  }

  static Future<void> save(Customer customer) async {
    await _box.put(customer.noCust, customer.toMap());
  }

  static Future<void> delete(String noCust) async {
    await _box.delete(noCust);
  }
}
