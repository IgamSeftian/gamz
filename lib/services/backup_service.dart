import 'dart:convert';
import 'dart:typed_data';

import 'package:hive/hive.dart';

import 'database_service.dart';

/// Export/import seluruh data aplikasi ke satu file JSON.
class BackupService {
  BackupService._();

  static const String _appId = 'DapoerIbu';
  static const int _formatVersion = 1;

  static const List<String> _boxNames = <String>[
    DatabaseService.usersBoxName,
    DatabaseService.sessionBoxName,
    DatabaseService.itemsBoxName,
    DatabaseService.customersBoxName,
    DatabaseService.penjualanBoxName,
    DatabaseService.tokoProfileBoxName,
  ];

  /// Membuat isi file backup dalam format JSON.
  static String buildBackupJson() {
    final Map<String, dynamic> boxes = <String, dynamic>{};
    for (final name in _boxNames) {
      final box = Hive.box(name);
      final Map<String, dynamic> entries = <String, dynamic>{};
      for (final key in box.keys) {
        entries[key.toString()] = _encodeValue(box.get(key));
      }
      boxes[name] = entries;
    }

    return const JsonEncoder.withIndent('  ').convert(<String, dynamic>{
      'app': _appId,
      'version': _formatVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'boxes': boxes,
    });
  }

  /// Mengembalikan jumlah data yang dipulihkan.
  static Future<int> restoreFromJson(String jsonText) async {
    dynamic decoded;
    try {
      decoded = jsonDecode(jsonText);
    } catch (_) {
      throw const FormatException('File backup tidak valid.');
    }

    if (decoded is! Map) {
      throw const FormatException('File backup tidak valid.');
    }

    final Map<dynamic, dynamic> root = decoded;
    if (root['app'] != _appId) {
      throw const FormatException('File backup bukan dari aplikasi ini.');
    }

    final dynamic version = root['version'];
    if (version is! int || version > _formatVersion) {
      throw const FormatException('Versi file backup tidak didukung.');
    }

    final dynamic rawBoxes = root['boxes'];
    if (rawBoxes is! Map) {
      throw const FormatException('File backup tidak memiliki data.');
    }

    final Map<String, Map<String, dynamic>> parsed =
        <String, Map<String, dynamic>>{};
    for (final name in _boxNames) {
      final dynamic raw = rawBoxes[name];
      if (raw == null) continue;
      if (raw is! Map) {
        throw const FormatException('Struktur data backup tidak valid.');
      }
      final Map<String, dynamic> values = <String, dynamic>{};
      raw.forEach((dynamic key, dynamic value) {
        values[key.toString()] = _decodeValue(value);
      });
      parsed[name] = values;
    }

    if (parsed.isEmpty) {
      throw const FormatException('File backup tidak memiliki data.');
    }

    int total = 0;
    for (final entry in parsed.entries) {
      final box = Hive.box(entry.key);
      await box.clear();
      await box.putAll(entry.value);
      total += entry.value.length;
    }
    return total;
  }

  static dynamic _encodeValue(dynamic value) {
    if (value is Uint8List) {
      return <String, dynamic>{'__type': 'bytes', 'data': base64Encode(value)};
    }
    if (value is List) {
      return value.map<dynamic>(_encodeValue).toList();
    }
    if (value is Map) {
      final Map<String, dynamic> result = <String, dynamic>{};
      value.forEach((dynamic key, dynamic item) {
        result[key.toString()] = _encodeValue(item);
      });
      return result;
    }
    return value;
  }

  static dynamic _decodeValue(dynamic value) {
    if (value is List) {
      return value.map<dynamic>(_decodeValue).toList();
    }
    if (value is Map) {
      final Map<String, dynamic> map = <String, dynamic>{};
      value.forEach((dynamic key, dynamic item) {
        map[key.toString()] = item;
      });
      if (map['__type'] == 'bytes' && map['data'] is String) {
        return base64Decode(map['data'] as String);
      }
      final Map<String, dynamic> result = <String, dynamic>{};
      map.forEach((String key, dynamic item) {
        result[key] = _decodeValue(item);
      });
      return result;
    }
    return value;
  }
}
