import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/item.dart';
import '../services/item_service.dart';
import '../theme/app_theme.dart';
import '../utils/currency.dart';
import '../widgets/form_widgets.dart';

/// Halaman daftar master item (kue) dengan aksi Input / Edit / Hapus.
class MasterItemScreen extends StatefulWidget {
  const MasterItemScreen({super.key});

  @override
  State<MasterItemScreen> createState() => _MasterItemScreenState();
}

class _MasterItemScreenState extends State<MasterItemScreen> {
  late List<Item> _items = ItemService.all();

  void _reload() => setState(() => _items = ItemService.all());

  Future<void> _openForm({Item? item}) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => ItemFormScreen(item: item)),
    );
    if (saved == true) _reload();
  }

  Future<void> _delete(Item item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Item'),
        content: const Text('Apakah anda yakin akan menghapus data ini?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await ItemService.delete(item.noItm);
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Master Item')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Tambah'),
      ),
      body: _items.isEmpty
          ? const EmptyList(
              message: 'Belum ada item.\nTekan "Tambah" untuk membuat.',
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: _items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = _items[index];
                return MasterListCard(
                  badge: item.noItm,
                  title: item.nama,
                  lines: <String>[
                    if (item.singkatan.isNotEmpty)
                      'Singkatan: ${item.singkatan}',
                    'Harga: ${formatRupiah(item.harga)}',
                  ],
                  onEdit: () => _openForm(item: item),
                  onDelete: () => _delete(item),
                );
              },
            ),
    );
  }
}

/// Form input / edit item.
class ItemFormScreen extends StatefulWidget {
  const ItemFormScreen({super.key, this.item});

  final Item? item;

  @override
  State<ItemFormScreen> createState() => _ItemFormScreenState();
}

class _ItemFormScreenState extends State<ItemFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nama;
  late final TextEditingController _singkatan;
  late final TextEditingController _harga;
  late final String _noItm;

  bool get _isEdit => widget.item != null;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _noItm = item?.noItm ?? ItemService.nextNumber();
    _nama = TextEditingController(text: item?.nama ?? '');
    _singkatan = TextEditingController(text: item?.singkatan ?? '');
    _harga = TextEditingController(
      text: item == null ? '' : formatThousands(item.harga),
    );
  }

  @override
  void dispose() {
    _nama.dispose();
    _singkatan.dispose();
    _harga.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final item = Item(
      noItm: _noItm,
      nama: _nama.text.trim(),
      singkatan: _singkatan.text.trim(),
      harga: (parseThousands(_harga.text) ?? 0).toDouble(),
    );
    await ItemService.save(item);
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit Item' : 'Input Item')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: <Widget>[
              LabeledField(
                label: 'Nomor',
                child: MasterTextField(
                  controller: TextEditingController(text: _noItm),
                  icon: Icons.tag,
                  readOnly: true,
                ),
              ),
              const SizedBox(height: 16),
              LabeledField(
                label: 'Nama',
                child: MasterTextField(
                  controller: _nama,
                  hint: 'Nama item',
                  icon: Icons.cake_outlined,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nama wajib diisi';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 16),
              LabeledField(
                label: 'Singkatan',
                child: MasterTextField(
                  controller: _singkatan,
                  hint: 'Singkatan / deskripsi',
                  icon: Icons.short_text,
                  textInputAction: TextInputAction.next,
                ),
              ),
              const SizedBox(height: 16),
              LabeledField(
                label: 'Harga',
                child: MasterTextField(
                  controller: _harga,
                  hint: '0',
                  icon: Icons.payments_outlined,
                  keyboardType: TextInputType.number,
                  inputFormatters: const <TextInputFormatter>[
                    ThousandsInputFormatter(),
                  ],
                  textInputAction: TextInputAction.done,
                  validator: (value) {
                    final parsed = parseThousands(value ?? '');
                    if (parsed == null || parsed <= 0) {
                      return 'Harga wajib diisi';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 28),
              FilledButton(
                onPressed: _save,
                child: const Text('Simpan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
