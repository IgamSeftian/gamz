import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/event.dart';
import '../services/event_service.dart';
import '../theme/app_theme.dart';
import '../widgets/form_widgets.dart';

/// Halaman daftar master event (periode PO) dengan aksi Input / Edit / Hapus.
class MasterEventScreen extends StatefulWidget {
  const MasterEventScreen({super.key});

  @override
  State<MasterEventScreen> createState() => _MasterEventScreenState();
}

class _MasterEventScreenState extends State<MasterEventScreen> {
  late List<MasterEvent> _events = EventService.all();
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  void _reload() => setState(() => _events = EventService.all());

  Future<void> _openForm({MasterEvent? event}) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => EventFormScreen(event: event)),
    );
    if (saved == true) _reload();
  }

  Future<void> _delete(MasterEvent event) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Hapus Event'),
            content: Text(
              'Apakah anda yakin akan menghapus event ${event.nEvent}?',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Batal'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.danger,
                ),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Hapus'),
              ),
            ],
          ),
    );
    if (confirm != true) return;
    await EventService.delete(event.kdEvent);
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Master Event')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Tambah'),
      ),
      body:
          _events.isEmpty
              ? const EmptyList(
                message: 'Belum ada event.\nTekan "Tambah" untuk membuat.',
              )
              : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                itemCount: _events.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final event = _events[index];
                  return MasterListCard(
                    badge: event.kdEvent,
                    title: event.nEvent,
                    lines: <String>[
                      'Periode Event: '
                          '${_dateFormat.format(event.tglAwal)} - '
                          '${_dateFormat.format(event.tglAkhir)}',
                    ],
                    onEdit: () => _openForm(event: event),
                    onDelete: () => _delete(event),
                  );
                },
              ),
    );
  }
}

/// Form input / edit event.
class EventFormScreen extends StatefulWidget {
  const EventFormScreen({super.key, this.event});

  final MasterEvent? event;

  @override
  State<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends State<EventFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nama;
  late final String _kdEvent;
  DateTime? _tglAwal;
  DateTime? _tglAkhir;

  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  bool get _isEdit => widget.event != null;

  @override
  void initState() {
    super.initState();
    final event = widget.event;
    _kdEvent = event?.kdEvent ?? EventService.nextNumber();
    _nama = TextEditingController(text: event?.nEvent ?? '');
    _tglAwal = event?.tglAwal;
    _tglAkhir = event?.tglAkhir;
  }

  @override
  void dispose() {
    _nama.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final DateTime initial = (isStart ? _tglAwal : _tglAkhir) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _tglAwal = picked;
      } else {
        _tglAkhir = picked;
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_tglAwal == null || _tglAkhir == null) {
      _snack('Periode event wajib diisi');
      return;
    }
    if (_tglAkhir!.isBefore(_tglAwal!)) {
      _snack('Tanggal akhir tidak boleh lebih awal dari tanggal awal');
      return;
    }

    final event = MasterEvent(
      kdEvent: _kdEvent,
      nEvent: _nama.text.trim(),
      tglAwal: _tglAwal!,
      tglAkhir: _tglAkhir!,
    );
    await EventService.save(event);
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit Event' : 'Input Event')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: <Widget>[
              LabeledField(
                label: 'Kode Event',
                child: MasterTextField(
                  controller: TextEditingController(text: _kdEvent),
                  icon: Icons.tag,
                  readOnly: true,
                ),
              ),
              const SizedBox(height: 16),
              LabeledField(
                label: 'Nama Event',
                child: MasterTextField(
                  controller: _nama,
                  hint: 'Contoh: Event Tahun Baru',
                  icon: Icons.event_outlined,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nama event wajib diisi';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 16),
              LabeledField(
                label: 'Periode Awal',
                child: _DateField(
                  value:
                      _tglAwal == null ? null : _dateFormat.format(_tglAwal!),
                  onTap: () => _pickDate(isStart: true),
                ),
              ),
              const SizedBox(height: 16),
              LabeledField(
                label: 'Periode Akhir',
                child: _DateField(
                  value:
                      _tglAkhir == null ? null : _dateFormat.format(_tglAkhir!),
                  onTap: () => _pickDate(isStart: false),
                ),
              ),
              const SizedBox(height: 28),
              FilledButton(onPressed: _save, child: const Text('Simpan')),
            ],
          ),
        ),
      ),
    );
  }
}

/// Field tanggal yang membuka date picker ketika ditekan.
class _DateField extends StatelessWidget {
  const _DateField({required this.value, required this.onTap});

  final String? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: const InputDecoration(
          prefixIcon: Icon(
            Icons.calendar_month_outlined,
            color: AppColors.textLight,
          ),
        ),
        child: Text(
          value ?? 'Pilih tanggal',
          style: TextStyle(
            color: value == null ? AppColors.textLight : AppColors.textDark,
          ),
        ),
      ),
    );
  }
}
