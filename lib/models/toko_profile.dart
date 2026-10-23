import 'dart:typed_data';

/// Profil toko untuk keperluan laporan/invoice (struk).
class TokoProfile {
  const TokoProfile({
    this.namaToko = 'Dapoer Iboe',
    this.alamat = '',
    this.whatsapp = '',
    this.logoBytes,
    this.bankLogoBytes,
    this.noRekening = '',
    this.atasNama = '',
  });

  final String namaToko;
  final String alamat;
  final String whatsapp;

  /// Byte logo toko untuk header report.
  final Uint8List? logoBytes;

  /// Byte logo bank untuk footer report.
  final Uint8List? bankLogoBytes;

  final String noRekening;
  final String atasNama;

  bool get hasLogo => logoBytes != null && logoBytes!.isNotEmpty;
  bool get hasBankLogo => bankLogoBytes != null && bankLogoBytes!.isNotEmpty;

  TokoProfile copyWith({
    String? namaToko,
    String? alamat,
    String? whatsapp,
    Uint8List? logoBytes,
    Uint8List? bankLogoBytes,
    String? noRekening,
    String? atasNama,
    bool clearLogo = false,
    bool clearBankLogo = false,
  }) {
    return TokoProfile(
      namaToko: namaToko ?? this.namaToko,
      alamat: alamat ?? this.alamat,
      whatsapp: whatsapp ?? this.whatsapp,
      logoBytes: clearLogo ? null : (logoBytes ?? this.logoBytes),
      bankLogoBytes:
          clearBankLogo ? null : (bankLogoBytes ?? this.bankLogoBytes),
      noRekening: noRekening ?? this.noRekening,
      atasNama: atasNama ?? this.atasNama,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'namaToko': namaToko,
      'alamat': alamat,
      'whatsapp': whatsapp,
      'noRekening': noRekening,
      'atasNama': atasNama,
      // gambar disimpan terpisah (key byte[] tidak aman di Map biasa)
      // kita pakai key terpisah via service
    };
  }
}
