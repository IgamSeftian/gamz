import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/customer.dart';
import '../models/item.dart';
import '../models/penjualan.dart';
import '../services/customer_service.dart';
import '../services/item_service.dart';
import '../services/penjualan_service.dart';
import '../theme/app_theme.dart';
import '../utils/currency.dart';
import '../widgets/form_widgets.dart';

/// Halaman daftar transaksi master penjualan dengan aksi Input / Edit / Hapus.
class MasterPenjualanScreen extends StatefulWidget {
  const MasterPenjualanScreen({super.key});

  @override
  State<MasterPenjualanScreen> createState() => _MasterPenjualanScreenState();
}

class _MasterPenjualanScreenState extends State<MasterPenjualanScreen> {
  late List<Penjualan> _penjualan = PenjualanService.all();

  void _reload() => setState(() => _penjualan = PenjualanService.all());

  String _customerLabel(String noCust) {
    final customer = CustomerService.byNo(noCust);
    return customer == null ? noCust : '${customer.nama} ($noCust)';
  }

  String _itemLabel(String noItm) {
    final item = ItemService.byNo(noItm);
    return item == null ? noItm : '${item.nama} ($noItm)';
  }

  Future<void> _openForm({Penjualan? penjualan}) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => PenjualanFormScreen(penjualan: penjualan),
      ),
    );
    if (saved == true) _reload();
  }

  Future<void> _delete(Penjualan penjualan) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Penjualan'),
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
    await PenjualanService.delete(penjualan.noInv);
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Master Penjualan')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Tambah'),
      ),
      body: _penjualan.isEmpty
          ? const EmptyList(
              message:
                  'Belum ada penjualan.\nTekan "Tambah" untuk membuat.',
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: _penjualan.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final penjualan = _penjualan[index];
                return MasterListCard(
                  badge: penjualan.noInv,
                  title: _itemLabel(penjualan.noItm),
                  lines: <String>[
                    'Tahun: ${penjualan.tahun}',
                    'Customer: ${_customerLabel(penjualan.noCust)}',
                    'Qty: ${formatThousands(penjualan.qty)}  •  '
                        'Harga: ${formatRupiah(penjualan.harga)}',
                    'Gross: ${formatRupiah(penjualan.gross)}',
                  ],
                  onEdit: () => _openForm(penjualan: penjualan),
                  onDelete: () => _delete(penjualan),
                );
              },
            ),
    );
  }
}

/// Form input / edit penjualan.
class PenjualanFormScreen extends StatefulWidget {
  const PenjualanFormScreen({super.key, this.penjualan});

  final Penjualan? penjualan;

  @override
  State<PenjualanFormScreen> createState() => _PenjualanFormScreenState();
}

class _PenjualanFormScreenState extends State<PenjualanFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final List<Customer> _customers = CustomerService.all();
  late final List<Item> _items = ItemService.all();

  late final TextEditingController _qty;
  final TextEditingController _harga = TextEditingController();
  final TextEditingController _gross = TextEditingController();
  late final TextEditingController _tahun;
  late final String _noInv;

  String? _noCust;
  String? _noItm;

  bool get _isEdit => widget.penjualan != null;

  Item? get _selectedItem {
    if (_noItm == null) return null;
    for (final item in _items) {
      if (item.noItm == _noItm) return item;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    final penjualan = widget.penjualan;
    _noInv = penjualan?.noInv ?? PenjualanService.nextNumber();
    _noCust = penjualan?.noCust;
    _noItm = penjualan?.noItm;
    _qty = TextEditingController(
      text: penjualan == null ? '' : formatThousands(penjualan.qty),
    );
    _tahun = TextEditingController(
      text: '${penjualan?.tahun ?? DateTime.now().year}',
    );
    _recompute();
  }

  @override
  void dispose() {
    _qty.dispose();
    _harga.dispose();
    _gross.dispose();
    _tahun.dispose();
    super.dispose();
  }

  /// Menghitung ulang Harga (dari item) & Gross (Harga x Qty).
  void _recompute() {
    final Item? item = _selectedItem;
    final int qty = parseThousands(_qty.text) ?? 0;
    final double harga = item?.harga ?? 0;

    _harga.text = formatThousands(harga);
    _gross.text = formatThousands(harga * qty);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_noCust == null || _noItm == null) return;

    final penjualan = Penjualan(
      noInv: _noInv,
      tahun: int.tryParse(_tahun.text) ?? DateTime.now().year,
      noCust: _noCust!,
      noItm: _noItm!,
      qty: parseThousands(_qty.text) ?? 0,
      harga: _selectedItem?.harga ?? 0,
    );
    await PenjualanService.save(penjualan);
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final bool emptyMaster = _customers.isEmpty || _items.isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Penjualan' : 'Input Penjualan'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: <Widget>[
              if (emptyMaster)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Lengkapi Master Item dan Master Customer terlebih dahulu.',
                    style: TextStyle(color: AppColors.danger),
                  ),
                ),
              LabeledField(
                label: 'Invoice',
                child: MasterTextField(
                  controller: TextEditingController(text: _noInv),
                  icon: Icons.receipt_long_outlined,
                  readOnly: true,
                ),
              ),
              const SizedBox(height: 16),
              LabeledField(
                label: 'Tahun',
                child: MasterTextField(
                  controller: _tahun,
                  hint: 'Contoh: ${DateTime.now().year}',
                  icon: Icons.calendar_month_outlined,
                  keyboardType: TextInputType.number,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    final tahun = int.tryParse((value ?? '').trim());
                    if (tahun == null || tahun < 1900 || tahun > 2200) {
                      return 'Tahun tidak valid';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 16),
              LabeledField(
                label: 'Customer',
                child: DropdownButtonFormField<String>(
                  value: _customers.any((c) => c.noCust == _noCust)
                      ? _noCust
                      : null,
                  isExpanded: true,
                  hint: const Text('Pilih customer'),
                  decoration: const InputDecoration(
                    prefixIcon:
                        Icon(Icons.person_outline, color: AppColors.textLight),
                  ),
                  items: _customers
                      .map(
                        (c) => DropdownMenuItem<String>(
                          value: c.noCust,
                          child: Text('${c.nama} (${c.noCust})'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _noCust = value),
                  validator: (value) =>
                      value == null ? 'Customer wajib dipilih' : null,
                ),
              ),
              const SizedBox(height: 16),
              LabeledField(
                label: 'Item',
                child: DropdownButtonFormField<String>(
                  value: _items.any((i) => i.noItm == _noItm) ? _noItm : null,
                  isExpanded: true,
                  hint: const Text('Pilih item'),
                  decoration: const InputDecoration(
                    prefixIcon:
                        Icon(Icons.cake_outlined, color: AppColors.textLight),
                  ),
                  items: _items
                      .map(
                        (i) => DropdownMenuItem<String>(
                          value: i.noItm,
                          child: Text('${i.nama} (${i.noItm})'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() {
                    _noItm = value;
                    _recompute();
                  }),
                  validator: (value) =>
                      value == null ? 'Item wajib dipilih' : null,
                ),
              ),
              const SizedBox(height: 16),
              LabeledField(
                label: 'Qty',
                child: MasterTextField(
                  controller: _qty,
                  hint: '0',
                  icon: Icons.numbers,
                  keyboardType: TextInputType.number,
                  inputFormatters: const <TextInputFormatter>[
                    ThousandsInputFormatter(),
                  ],
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => setState(_recompute),
                  validator: (value) {
                    final qty = parseThousands(value ?? '');
                    if (qty == null || qty <= 0) {
                      return 'Qty wajib diisi';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 16),
              LabeledField(
                label: 'Harga',
                child: MasterTextField(
                  controller: _harga,
                  icon: Icons.payments_outlined,
                  readOnly: true,
                  hint: '0',
                ),
              ),
              const SizedBox(height: 16),
              LabeledField(
                label: 'Gross',
                child: MasterTextField(
                  controller: _gross,
                  icon: Icons.calculate_outlined,
                  readOnly: true,
                  hint: '0',
                ),
              ),
              const SizedBox(height: 28),
              FilledButton(
                onPressed: emptyMaster ? null : _save,
                child: const Text('Simpan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
