import 'package:flutter/material.dart';

import '../models/customer.dart';
import '../services/customer_service.dart';
import '../theme/app_theme.dart';
import '../widgets/form_widgets.dart';

/// Halaman daftar master customer dengan aksi Input / Edit / Hapus.
class MasterCustomerScreen extends StatefulWidget {
  const MasterCustomerScreen({super.key});

  @override
  State<MasterCustomerScreen> createState() => _MasterCustomerScreenState();
}

class _MasterCustomerScreenState extends State<MasterCustomerScreen> {
  late List<Customer> _customers = CustomerService.all();

  void _reload() => setState(() => _customers = CustomerService.all());

  Future<void> _openForm({Customer? customer}) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => CustomerFormScreen(customer: customer),
      ),
    );
    if (saved == true) _reload();
  }

  Future<void> _delete(Customer customer) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Customer'),
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
    await CustomerService.delete(customer.noCust);
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Master Customer')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Tambah'),
      ),
      body: _customers.isEmpty
          ? const EmptyList(
              message:
                  'Belum ada customer.\nTekan "Tambah" untuk membuat.',
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: _customers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final customer = _customers[index];
                return MasterListCard(
                  badge: customer.noCust,
                  title: customer.nama,
                  lines: <String>[
                    if (customer.kontak.isNotEmpty)
                      'Kontak: ${customer.kontak}',
                    if (customer.alamat.isNotEmpty)
                      'Alamat: ${customer.alamat}',
                  ],
                  onEdit: () => _openForm(customer: customer),
                  onDelete: () => _delete(customer),
                );
              },
            ),
    );
  }
}

/// Form input / edit customer.
class CustomerFormScreen extends StatefulWidget {
  const CustomerFormScreen({super.key, this.customer});

  final Customer? customer;

  @override
  State<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends State<CustomerFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nama;
  late final TextEditingController _kontak;
  late final TextEditingController _alamat;
  late final String _noCust;

  bool get _isEdit => widget.customer != null;

  @override
  void initState() {
    super.initState();
    final customer = widget.customer;
    _noCust = customer?.noCust ?? CustomerService.nextNumber();
    _nama = TextEditingController(text: customer?.nama ?? '');
    _kontak = TextEditingController(text: customer?.kontak ?? '');
    _alamat = TextEditingController(text: customer?.alamat ?? '');
  }

  @override
  void dispose() {
    _nama.dispose();
    _kontak.dispose();
    _alamat.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final customer = Customer(
      noCust: _noCust,
      nama: _nama.text.trim(),
      kontak: _kontak.text.trim(),
      alamat: _alamat.text.trim(),
    );
    await CustomerService.save(customer);
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit Customer' : 'Input Customer')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: <Widget>[
              LabeledField(
                label: 'Nomor',
                child: MasterTextField(
                  controller: TextEditingController(text: _noCust),
                  icon: Icons.tag,
                  readOnly: true,
                ),
              ),
              const SizedBox(height: 16),
              LabeledField(
                label: 'Nama',
                child: MasterTextField(
                  controller: _nama,
                  hint: 'Nama customer',
                  icon: Icons.person_outline,
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
                label: 'Kontak',
                child: MasterTextField(
                  controller: _kontak,
                  hint: 'Nomor HP',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                ),
              ),
              const SizedBox(height: 16),
              LabeledField(
                label: 'Alamat',
                child: MasterTextField(
                  controller: _alamat,
                  hint: 'Alamat (maks 200 karakter)',
                  icon: Icons.home_outlined,
                  maxLength: 200,
                  maxLines: 3,
                  textInputAction: TextInputAction.newline,
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
