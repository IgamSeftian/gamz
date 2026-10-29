import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../models/toko_profile.dart';
import '../services/backup_service.dart';
import '../services/penjualan_service.dart';
import '../services/toko_profile_service.dart';
import '../theme/app_theme.dart';
import '../widgets/form_widgets.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nama = TextEditingController();
  final _alamat = TextEditingController();
  final _wa = TextEditingController();
  final _rek = TextEditingController();
  final _an = TextEditingController();

  Uint8List? _logo;
  Uint8List? _bankLogo;

  bool _loading = false;
  bool _backupBusy = false;
  bool _deleteBusy = false;
  int? _deleteYear;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    final List<int> years = PenjualanService.years;
    _deleteYear = years.isNotEmpty ? years.first : null;
  }

  void _loadProfile() {
    final p = TokoProfileService.get();
    _nama.text = p.namaToko;
    _alamat.text = p.alamat;
    _wa.text = p.whatsapp;
    _rek.text = p.noRekening;
    _an.text = p.atasNama;
    _logo = p.logoBytes;
    _bankLogo = p.bankLogoBytes;
  }

  @override
  void dispose() {
    _nama.dispose();
    _alamat.dispose();
    _wa.dispose();
    _rek.dispose();
    _an.dispose();
    super.dispose();
  }

  Future<Uint8List?> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
    );
    if (file == null) return null;
    return await File(file.path).readAsBytes();
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    final p = TokoProfile(
      namaToko: _nama.text.trim().isEmpty ? 'Dapoer Iboe' : _nama.text.trim(),
      alamat: _alamat.text.trim(),
      whatsapp: _wa.text.trim(),
      logoBytes: _logo,
      bankLogoBytes: _bankLogo,
      noRekening: _rek.text.trim(),
      atasNama: _an.text.trim(),
    );
    await TokoProfileService.save(p);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profil toko tersimpan')));
      Navigator.pop(context);
    }
    setState(() => _loading = false);
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _exportData() async {
    setState(() => _backupBusy = true);
    try {
      final String json = BackupService.buildBackupJson();
      final String fileName =
          'DapoerIbu_backup_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.json';
      final String? path = await FilePicker.saveFile(
        dialogTitle: 'Simpan backup data',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: <String>['json'],
        bytes: Uint8List.fromList(utf8.encode(json)),
      );
      if (!mounted) return;
      if (path == null) {
        _snack('Export dibatalkan.');
      } else {
        _snack('Backup berhasil disimpan.');
      }
    } catch (e) {
      _snack('Gagal export data: $e');
    } finally {
      if (mounted) setState(() => _backupBusy = false);
    }
  }

  Future<void> _importData() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Import Data'),
            content: const Text(
              'Data yang ada saat ini akan diganti dengan data dari file backup. '
              'Pastikan Anda sudah melakukan export terlebih dahulu.',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Batal'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Import'),
              ),
            ],
          ),
    );
    if (confirm != true) return;

    setState(() => _backupBusy = true);
    try {
      final FilePickerResult? result = await FilePicker.pickFiles(
        dialogTitle: 'Pilih file backup',
        type: FileType.custom,
        allowedExtensions: <String>['json'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) {
        if (mounted) _snack('Import dibatalkan.');
        return;
      }

      final PlatformFile file = result.files.single;
      Uint8List? bytes = file.bytes;
      if (bytes == null && file.path != null) {
        bytes = await File(file.path!).readAsBytes();
      }
      if (bytes == null) {
        throw const FormatException('File backup tidak bisa dibaca.');
      }

      final int total = await BackupService.restoreFromJson(utf8.decode(bytes));
      if (!mounted) return;
      setState(_loadProfile);
      _snack('Import berhasil. $total data dipulihkan.');
    } catch (e) {
      _snack('Gagal import data: $e');
    } finally {
      if (mounted) setState(() => _backupBusy = false);
    }
  }

  Future<void> _deleteAllPenjualan() async {
    final List<int> years = PenjualanService.years;
    final int? year = _deleteYear;
    if (year == null || !years.contains(year)) {
      _snack('Pilih tahun penjualan yang ingin dihapus.');
      return;
    }

    final int total = PenjualanService.byYear(year).length;
    if (total == 0) {
      _snack('Tidak ada data penjualan pada tahun $year.');
      return;
    }

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Delete All Penjualan'),
            content: Text(
              'Hapus seluruh $total transaksi penjualan tahun $year? '
              'Tindakan ini tidak bisa dibatalkan.',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Batal'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.danger,
                ),
                child: const Text('Hapus'),
              ),
            ],
          ),
    );
    if (confirm != true) return;

    setState(() => _deleteBusy = true);
    try {
      final int deleted = await PenjualanService.deleteByYear(year);
      if (!mounted) return;
      setState(() {
        final List<int> remaining = PenjualanService.years;
        _deleteYear = remaining.isNotEmpty ? remaining.first : null;
      });
      _snack('$deleted transaksi penjualan tahun $year berhasil dihapus.');
    } catch (e) {
      _snack('Gagal menghapus data penjualan: $e');
    } finally {
      if (mounted) setState(() => _deleteBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<int> years = PenjualanService.years;
    final int? selectedYear = years.contains(_deleteYear) ? _deleteYear : null;
    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          LabeledField(
            label: 'Nama Toko',
            child: MasterTextField(controller: _nama),
          ),
          const SizedBox(height: 16),
          LabeledField(
            label: 'Alamat (untuk header report)',
            child: MasterTextField(controller: _alamat, maxLines: 3),
          ),
          const SizedBox(height: 16),
          LabeledField(
            label: 'WA/No HP (untuk footer report)',
            child: MasterTextField(controller: _wa),
          ),
          const SizedBox(height: 16),
          _ImagePicker(
            label: 'Logo Toko (Header Report Invoice)',
            bytes: _logo,
            onPick: () async {
              final b = await _pickImage();
              if (b != null) setState(() => _logo = b);
            },
            onClear: () => setState(() => _logo = null),
          ),
          const SizedBox(height: 16),
          LabeledField(
            label: 'No Rekening Bank',
            child: MasterTextField(controller: _rek),
          ),
          const SizedBox(height: 16),
          LabeledField(
            label: 'Atas Nama (Bank)',
            child: MasterTextField(controller: _an),
          ),
          const SizedBox(height: 16),
          _ImagePicker(
            label: 'Logo Bank (Footer Report)',
            bytes: _bankLogo,
            onPick: () async {
              final b = await _pickImage();
              if (b != null) setState(() => _bankLogo = b);
            },
            onClear: () => setState(() => _bankLogo = null),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: (_loading || _backupBusy) ? null : _save,
            child: Text(_loading ? 'Menyimpan...' : 'Simpan'),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 8),
          const Text(
            'Backup Data',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Export data agar bisa di-import kembali setelah aplikasi '
            'dipasang ulang.',
            style: TextStyle(fontSize: 12, color: AppColors.textLight),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: (_loading || _backupBusy) ? null : _exportData,
                  icon: const Icon(Icons.file_upload_outlined),
                  label: const Text('Export Data'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: (_loading || _backupBusy) ? null : _importData,
                  icon: const Icon(Icons.file_download_outlined),
                  label: const Text('Import Data'),
                ),
              ),
            ],
          ),
          if (_backupBusy) ...<Widget>[
            const SizedBox(height: 12),
            const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ],
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 8),
          const Text(
            'Delete All Penjualan',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Hapus seluruh transaksi penjualan pada tahun yang dipilih.',
            style: TextStyle(fontSize: 12, color: AppColors.textLight),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE0E2EE)),
            ),
            child: DropdownButton<int>(
              value: selectedYear,
              isExpanded: true,
              underline: const SizedBox.shrink(),
              hint: const Text('Pilih tahun'),
              icon: const Icon(Icons.arrow_drop_down, color: AppColors.primary),
              style: const TextStyle(
                color: AppColors.textDark,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              onChanged:
                  _deleteBusy
                      ? null
                      : (value) {
                        if (value == null) return;
                        setState(() => _deleteYear = value);
                      },
              items:
                  years
                      .map(
                        (year) => DropdownMenuItem<int>(
                          value: year,
                          child: Text('$year'),
                        ),
                      )
                      .toList(),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed:
                  (_loading || _backupBusy || _deleteBusy || years.isEmpty)
                      ? null
                      : _deleteAllPenjualan,
              icon: const Icon(Icons.delete_forever_outlined),
              label: Text(
                _deleteBusy ? 'Menghapus...' : 'Delete All Penjualan',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: const BorderSide(color: AppColors.danger),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImagePicker extends StatelessWidget {
  const _ImagePicker({
    required this.label,
    required this.bytes,
    required this.onPick,
    required this.onClear,
  });

  final String label;
  final Uint8List? bytes;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 140,
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE0E2EE)),
            borderRadius: BorderRadius.circular(14),
            color: Colors.white,
          ),
          child:
              bytes == null
                  ? InkWell(
                    onTap: onPick,
                    borderRadius: BorderRadius.circular(14),
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Icon(Icons.add_photo_alternate_outlined, size: 28),
                          SizedBox(height: 4),
                          Text('Pilih gambar'),
                        ],
                      ),
                    ),
                  )
                  : Stack(
                    fit: StackFit.expand,
                    children: <Widget>[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.memory(bytes!, fit: BoxFit.contain),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Row(
                          children: <Widget>[
                            IconButton(
                              onPressed: onPick,
                              icon: const Icon(Icons.edit, color: Colors.white),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.black54,
                              ),
                            ),
                            IconButton(
                              onPressed: onClear,
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.white,
                              ),
                              style: IconButton.styleFrom(
                                backgroundColor: AppColors.danger,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
        ),
      ],
    );
  }
}
