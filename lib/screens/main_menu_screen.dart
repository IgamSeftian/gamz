import 'package:flutter/material.dart';

import '../models/penjualan.dart';
import '../services/auth_service.dart';
import '../services/customer_service.dart';
import '../services/item_service.dart';
import '../services/penjualan_service.dart';
import '../theme/app_theme.dart';
import '../utils/currency.dart';
import '../widgets/chart_penjualan.dart';
import '../widgets/chart_pie.dart';
import 'login_screen.dart';
import 'master_customer_screen.dart';
import 'master_item_screen.dart';
import 'master_penjualan_screen.dart';
import 'profile_screen.dart';
import 'report_screen.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  late int _selectedYear;
  late List<Penjualan> _penjualan;

  /// True = detail ditampilkan, False = detail disembunyikan.
  bool _showDetail = false;

  /// Mode agregasi chart (By Customer / By Item), dipakai bersama.
  ChartMode _chartMode = ChartMode.customer;

  /// Mode nilai chart (Rupiah/Qty).
  ChartValueMode _chartValueMode = ChartValueMode.gross;

  @override
  void initState() {
    super.initState();
    final years = PenjualanService.years;
    _selectedYear = years.isNotEmpty ? years.first : DateTime.now().year;
    _penjualan = PenjualanService.byYear(_selectedYear);
  }

  /// Memuat ulang tahun & data, dipakai setelah kembali dari halaman master.
  void _reload() {
    final years = PenjualanService.years;
    if (!years.contains(_selectedYear)) {
      _selectedYear = years.isNotEmpty ? years.first : DateTime.now().year;
    }
    _penjualan = PenjualanService.byYear(_selectedYear);
  }

  void _onYearChanged(int? year) {
    if (year == null) return;
    setState(() {
      _selectedYear = year;
      _penjualan = PenjualanService.byYear(year);
      _showDetail = false;
    });
  }

  /// Membuka halaman master lalu menyegarkan data menu utama saat kembali.
  Future<void> _openMaster(Widget screen) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => screen),
    );
    if (!mounted) return;
    setState(_reload);
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Yakin ingin keluar dari akun ini?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await AuthService.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final years = PenjualanService.years;
    final double grandTotal = PenjualanService.totalForYear(_selectedYear);
    final int totalQty = _penjualan.fold<int>(0, (sum, p) => sum + p.qty);

    return Scaffold(
      appBar: AppBar(title: const Text('Menu Utama')),
      drawer: _buildDrawer(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _buildHeader(years, grandTotal, totalQty),
            ChartPenjualanWidget(
              tahun: _selectedYear,
              mode: _chartMode,
              onModeChanged: (mode) => setState(() => _chartMode = mode),
              valueMode: _chartValueMode,
              onValueChanged: (mode) => setState(() => _chartValueMode = mode),
            ),
            ChartPieWidget(tahun: _selectedYear, mode: _chartMode, valueMode: _chartValueMode),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final user = AuthService.currentUser;
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: const BoxDecoration(color: AppColors.primary),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                const CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 32, color: AppColors.primary),
                ),
                const SizedBox(height: 12),
                Text(
                  user?.name ?? 'Tamu',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user?.email ?? '',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.grid_view_rounded),
            title: const Text(' Menu Utama '),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.cake_outlined),
            title: const Text(' List Item '),
            onTap: () {
              Navigator.pop(context);
              _openMaster(const MasterItemScreen());
            },
          ),
          ListTile(
            leading: const Icon(Icons.people_alt_outlined),
            title: const Text(' List Customer '),
            onTap: () {
              Navigator.pop(context);
              _openMaster(const MasterCustomerScreen());
            },
          ),
          ListTile(
            leading: const Icon(Icons.receipt_long_outlined),
            title: const Text(' List Penjualan '),
            onTap: () {
              Navigator.pop(context);
              _openMaster(const MasterPenjualanScreen());
            },
          ),
          ListTile(
            leading: const Icon(Icons.insert_chart_outlined),
            title: const Text(' Laporan '),
            onTap: () {
              Navigator.pop(context);
              _openMaster(const ReportScreen());
            },
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text(' My Profile '),
            onTap: () {
              Navigator.pop(context);
              _openMaster(const ProfileScreen());
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.danger),
            title: const Text(
              'LogOut',
              style: TextStyle(color: AppColors.danger),
            ),
            onTap: () => _logout(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(List<int> years, double grandTotal, int totalQty) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.gradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.calendar_month, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Periode Tahun',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              _YearDropdown(
                years: years,
                value: _selectedYear,
                onChanged: _onYearChanged,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: _SummaryTile(
                  label: 'Total Penjualan',
                  value: formatRupiah(grandTotal),
                  icon: Icons.payments_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryTile(
                  label: 'Total Qty',
                  value: '$totalQty pcs',
                  icon: Icons.inventory_2_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _DetailToggle(
            showDetail: _showDetail,
            onTap: () => setState(() => _showDetail = !_showDetail),
          ),
          if (_showDetail) ...<Widget>[
            const SizedBox(height: 16),
            if (_penjualan.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    'Belum ada data penjualan pada tahun ini',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                    const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 360,
                  mainAxisExtent: 220,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                ),
                itemCount: _penjualan.length,
                itemBuilder: (context, index) =>
                    _PenjualanCard(penjualan: _penjualan[index]),
              ),
          ],
        ],
      ),
    );
  }
}

class _YearDropdown extends StatelessWidget {
  const _YearDropdown({
    required this.years,
    required this.value,
    required this.onChanged,
  });

  final List<int> years;
  final int value;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButton<int>(
        value: years.contains(value) ? value : null,
        underline: const SizedBox.shrink(),
        isDense: true,
        icon: const Icon(Icons.arrow_drop_down, color: AppColors.primary),
        style: const TextStyle(
          color: AppColors.textDark,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        onChanged: onChanged,
        items: years
            .map(
              (year) => DropdownMenuItem<int>(
                value: year,
                child: Text('$year'),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _DetailToggle extends StatelessWidget {
  const _DetailToggle({
    required this.showDetail,
    required this.onTap,
  });

  final bool showDetail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: <Widget>[
              Icon(
                showDetail
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                color: AppColors.primary,
                size: 22,
              ),
              const SizedBox(width: 10),
              Text(
                showDetail ? 'Sembunyikan Detail' : 'Tampilkan Detail',
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.touch_app_rounded,
                color: AppColors.textLight,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PenjualanCard extends StatelessWidget {
  const _PenjualanCard({required this.penjualan});

  final Penjualan penjualan;

  String get _namaCustomer {
    final customer = CustomerService.byNo(penjualan.noCust);
    return customer?.nama ?? penjualan.noCust;
  }

  String _namaItem(String noItm) {
    final item = ItemService.byNo(noItm);
    return item?.nama ?? noItm;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.cake_outlined,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        penjualan.noInv,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$_namaCustomer • ${penjualan.items.length} item',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: <Widget>[
                    for (final line in penjualan.items)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                '${_namaItem(line.noItm)} x${line.qty}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ),
                            Text(
                              formatRupiah(line.gross),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                _Field(label: 'Qty', value: '${penjualan.qty}'),
                _divider(),
                _Field(
                  label: 'Gross',
                  value: formatRupiah(penjualan.gross),
                  highlight: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider() {
    return Container(
      width: 1,
      height: 30,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      color: const Color(0xFFE0E2EE),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.textLight),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: highlight ? AppColors.primary : AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}
