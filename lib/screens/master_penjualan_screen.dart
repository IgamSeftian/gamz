import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

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
///
/// Satu kartu mewakili satu invoice (bisa berisi banyak item).
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

  String _itemsSummary(Penjualan penjualan) {
    final names = penjualan.items
        .map((line) => ItemService.byNo(line.noItm)?.nama ?? line.noItm)
        .toList();
    if (names.length <= 2) return names.join(', ');
    return '${names.take(2).join(', ')}, +${names.length - 2} item lain';
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
        content: Text(
          'Apakah anda yakin akan menghapus invoice ${penjualan.noInv} '
          'beserta seluruh item di dalamnya?',
        ),
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
                  title: _customerLabel(penjualan.noCust),
                  lines: <String>[
                    'Tahun: ${penjualan.tahun}',
                    'Waktu Input: '
                        '${penjualan.addTime == null ? '-' : DateFormat('dd/MM/yyyy HH:mm').format(penjualan.addTime!)}',
                    'Item (${penjualan.items.length}): '
                        '${_itemsSummary(penjualan)}',
                    'Total Qty: ${formatThousands(penjualan.qty)}  •  '
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

/// Form input / edit penjualan, mendukung banyak item per invoice.
class PenjualanFormScreen extends StatefulWidget {
  const PenjualanFormScreen({super.key, this.penjualan});

  /// Invoice yang diedit; null = input baru.
  final Penjualan? penjualan;

  @override
  State<PenjualanFormScreen> createState() => _PenjualanFormScreenState();
}

/// Satu baris item dalam form (draft sebelum disimpan).
class _ItemRow {
  _ItemRow({this.noItm, String? qty}) : qty = TextEditingController(text: qty);

  String? noItm;
  final TextEditingController qty;
  final TextEditingController harga = TextEditingController();
  final TextEditingController gross = TextEditingController();

  void dispose() {
    qty.dispose();
    harga.dispose();
    gross.dispose();
  }
}

class _PenjualanFormScreenState extends State<PenjualanFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final List<Customer> _customers = CustomerService.all();
  late final List<Item> _items = ItemService.all();

  late final TextEditingController _tahun;
  late final String _noInv;
  String? _noCust;

  late final List<_ItemRow> _rows;

  bool get _isEdit => widget.penjualan != null;

  @override
  void initState() {
    super.initState();
    final penjualan = widget.penjualan;
    _noInv = penjualan?.noInv ?? PenjualanService.nextNumber();
    _noCust = penjualan?.noCust;
    _tahun = TextEditingController(
      text: '${penjualan?.tahun ?? DateTime.now().year}',
    );

    if (penjualan == null || penjualan.items.isEmpty) {
      _rows = <_ItemRow>[_ItemRow()];
    } else {
      _rows = penjualan.items
          .map(
            (line) => _ItemRow(
              noItm: line.noItm,
              qty: formatThousands(line.qty),
            ),
          )
          .toList();
    }
    for (final row in _rows) {
      _recompute(row);
    }
  }

  @override
  void dispose() {
    _tahun.dispose();
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  Item? _itemOf(String? noItm) {
    if (noItm == null) return null;
    for (final item in _items) {
      if (item.noItm == noItm) return item;
    }
    return null;
  }

  /// Menghitung ulang Harga (dari item) & Gross (Harga x Qty) milik [row].
  void _recompute(_ItemRow row) {
    final Item? item = _itemOf(row.noItm);
    final int qty = parseThousands(row.qty.text) ?? 0;
    final double harga = item?.harga ?? 0;

    row.harga.text = formatThousands(harga);
    row.gross.text = formatThousands(harga * qty);
  }

  void _addRow() {
    setState(() => _rows.add(_ItemRow()));
  }

  void _removeRow(_ItemRow row) {
    setState(() {
      row.dispose();
      _rows.remove(row);
    });
  }

  double get _totalGross => _rows.fold<double>(0, (sum, row) {
        final int qty = parseThousands(row.qty.text) ?? 0;
        final double harga = _itemOf(row.noItm)?.harga ?? 0;
        return sum + harga * qty;
      });

  int get _totalQty => _rows.fold<int>(0, (sum, row) {
        return sum + (parseThousands(row.qty.text) ?? 0);
      });

  String? _validateRow(_ItemRow row) {
    if (row.noItm == null) return 'Item wajib dipilih';
    final qty = parseThousands(row.qty.text);
    if (qty == null || qty <= 0) return 'Qty wajib diisi';
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_noCust == null) return;

    final List<PenjualanLine> lines = <PenjualanLine>[];
    for (final row in _rows) {
      final error = _validateRow(row);
      if (error != null) {
        _snack(error);
        return;
      }
      final Item? item = _itemOf(row.noItm);
      lines.add(
        PenjualanLine(
          noItm: row.noItm!,
          qty: parseThousands(row.qty.text) ?? 0,
          harga: item?.harga ?? 0,
        ),
      );
    }
    if (lines.isEmpty) {
      _snack('Minimal harus ada 1 item pesanan');
      return;
    }

    final penjualan = Penjualan(
      noInv: _noInv,
      tahun: int.tryParse(_tahun.text) ?? DateTime.now().year,
      noCust: _noCust!,
      items: lines,
    );
    await PenjualanService.save(penjualan);
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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
              const SizedBox(height: 24),
              Row(
                children: <Widget>[
                  const Icon(
                    Icons.shopping_cart_outlined,
                    size: 20,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Pesanan',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_rows.length} item',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              for (int i = 0; i < _rows.length; i++) ...<Widget>[
                _buildItemRow(i),
                const SizedBox(height: 12),
              ],
              OutlinedButton.icon(
                onPressed: emptyMaster ? null : _addRow,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  minimumSize: const Size.fromHeight(48),
                ),
                icon: const Icon(Icons.add),
                label: const Text('Tambah Item'),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: <Widget>[
                    const Expanded(
                      child: Text(
                        'Total',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                    Text(
                      '${formatThousands(_totalQty)} pcs',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textLight,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      formatRupiah(_totalGross),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
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

  Widget _buildItemRow(int index) {
    final _ItemRow row = _rows[index];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE0E2EE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '#${index + 1}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _items.any((i) => i.noItm == row.noItm)
                      ? row.noItm
                      : null,
                  isExpanded: true,
                  hint: const Text('Pilih item'),
                  isDense: true,
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    prefixIcon: Padding(
                      padding: EdgeInsets.only(left: 8, right: 4),
                      child: Icon(
                        Icons.cake_outlined,
                        color: AppColors.textLight,
                        size: 20,
                      ),
                    ),
                  ),
                  items: _items
                      .map(
                        (i) => DropdownMenuItem<String>(
                          value: i.noItm,
                          child: Text(
                            '${i.nama} (${i.noItm})',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() {
                    row.noItm = value;
                    _recompute(row);
                  }),
                ),
              ),
              if (_rows.length > 1) ...<Widget>[
                const SizedBox(width: 6),
                IconButton(
                  onPressed: () => _removeRow(row),
                  tooltip: 'Hapus item',
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppColors.danger,
                    size: 22,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: TextFormField(
                  controller: row.qty,
                  keyboardType: TextInputType.number,
                  inputFormatters: const <TextInputFormatter>[
                    ThousandsInputFormatter(),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Qty',
                    hintText: '0',
                    isDense: true,
                    prefixIcon: Icon(
                      Icons.numbers,
                      color: AppColors.textLight,
                      size: 20,
                    ),
                  ),
                  onChanged: (_) => setState(() => _recompute(row)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: row.harga,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Harga',
                    hintText: '0',
                    isDense: true,
                    prefixIcon: Icon(
                      Icons.payments_outlined,
                      color: AppColors.textLight,
                      size: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: row.gross,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Gross',
                    hintText: '0',
                    isDense: true,
                    prefixIcon: Icon(
                      Icons.calculate_outlined,
                      color: AppColors.textLight,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
