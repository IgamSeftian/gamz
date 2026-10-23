import 'dart:typed_data';

import 'package:hive_flutter/hive_flutter.dart';

import '../models/toko_profile.dart';
import 'database_service.dart';

class TokoProfileService {
  TokoProfileService._();

  static Box get _box => DatabaseService.tokoProfile;
  static const String _keyProfile = 'profile';
  static const String _keyLogo = 'logo';
  static const String _keyBankLogo = 'bank_logo';

  static TokoProfile get() {
    final Map<dynamic, dynamic>? map =
        _box.get(_keyProfile) as Map<dynamic, dynamic>?;
    TokoProfile base = const TokoProfile();
    if (map != null) {
      base = base.copyWith(
        namaToko: (map['namaToko'] ?? '') as String,
        alamat: (map['alamat'] ?? '') as String,
        whatsapp: (map['whatsapp'] ?? '') as String,
        noRekening: (map['noRekening'] ?? '') as String,
        atasNama: (map['atasNama'] ?? '') as String,
      );
    }
    final Uint8List? logo = _box.get(_keyLogo) as Uint8List?;
    final Uint8List? bankLogo = _box.get(_keyBankLogo) as Uint8List?;
    return base.copyWith(logoBytes: logo, bankLogoBytes: bankLogo);
  }

  static Future<void> save(TokoProfile profile) async {
    await _box.put(
      _keyProfile,
      <String, dynamic>{
        'namaToko': profile.namaToko,
        'alamat': profile.alamat,
        'whatsapp': profile.whatsapp,
        'noRekening': profile.noRekening,
        'atasNama': profile.atasNama,
      },
    );
    if (profile.logoBytes != null) {
      await _box.put(_keyLogo, profile.logoBytes);
    } else if (_box.containsKey(_keyLogo)) {
      await _box.delete(_keyLogo);
    }
    if (profile.bankLogoBytes != null) {
      await _box.put(_keyBankLogo, profile.bankLogoBytes);
    } else if (_box.containsKey(_keyBankLogo)) {
      await _box.delete(_keyBankLogo);
    }
  }
}
