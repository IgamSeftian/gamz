import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../models/penjualan.dart';
import '../services/report_service.dart';
import '../theme/app_theme.dart';
import '../utils/currency.dart';
import '../utils/customer_invoice_pdf.dart';
import '../utils/report_pdf.dart';

/// Halaman Laporan Penjualan dengan filter Periode Tahun.
///
/// Berisi tab Per Customer, Modal, Margin, Ringkasan, Per Item, dan Detail
/// Transaksi, serta tombol Cetak (Print) dan Bagikan PDF.
class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  late int _selectedYear;
  ReportPaperSize _paperSize = ReportPaperSize.thermal;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final years = ReportService.years;
    _selectedYear = years.isNotEmpty ? years.first : DateTime.now().year;
  }

  Future<void> _printPdf() async {
    setState(() => _busy = true);
    try {
      final bytes = await buildReportPdf(_selectedYear, paperSize: _paperSize);
      await Printing.layoutPdf(
        onLayout: (_) async => bytes,
        name: 'Laporan_Penjualan_$_selectedYear',
      );
    } catch (e) {
      _snack('Gagal membuka cetak: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sharePdf() async {
    setState(() => _busy = true);
    try {
      final bytes = await buildReportPdf(_selectedYear, paperSize: _paperSize);
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'Laporan_Penjualan_$_selectedYear.pdf',
      );
    } catch (e) {
      _snack('Gagal membagikan PDF: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final years = ReportService.years;
    final int tahun =
        years.contains(_selectedYear)
            ? _selectedYear
            : (years.isNotEmpty ? years.first : _selectedYear);

    final summary = ReportService.summary(tahun);
    final perItem = ReportService.perItem(tahun);
    final perCustomer = ReportService.perCustomer(tahun);
    final detail = ReportService.detail(tahun);

    return DefaultTabController(
      length: 6,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Laporan Penjualan'),
          actions: <Widget>[
            if (_busy)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                ),
              )
            else
              PopupMenuButton<String>(
                icon: const Icon(Icons.ios_share),
                onSelected: (value) {
                  if (value == 'print') {
                    _printPdf();
                  } else {
                    _sharePdf();
                  }
                },
                itemBuilder:
                    (context) => const <PopupMenuEntry<String>>[
                      PopupMenuItem<String>(
                        value: 'print',
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.print_outlined),
                          title: Text('Cetak / Print'),
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'share',
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.picture_as_pdf_outlined),
                          title: Text('Bagikan PDF'),
                        ),
                      ),
                    ],
              ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: <Widget>[
              Tab(text: 'Per Customer'),
              Tab(text: 'Modal'),
              Tab(text: 'Margin'),
              Tab(text: 'Ringkasan'),
              Tab(text: 'Per Item'),
              Tab(text: 'Detail'),
            ],
          ),
        ),
        body: Column(
          children: <Widget>[
            Container(
              width: double.infinity,
              color: AppColors.primary.withValues(alpha: 0.06),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      const Icon(
                        Icons.calendar_month,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Periode Tahun',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE0E2EE)),
                        ),
                        child: DropdownButton<int>(
                          value:
                              years.contains(_selectedYear)
                                  ? _selectedYear
                                  : null,
                          underline: const SizedBox.shrink(),
                          isDense: true,
                          hint: Text('$tahun'),
                          icon: const Icon(
                            Icons.arrow_drop_down,
                            color: AppColors.primary,
                          ),
                          style: const TextStyle(
                            color: AppColors.textDark,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                          onChanged:
                              years.isEmpty
                                  ? null
                                  : (value) {
                                    if (value == null) return;
                                    setState(() => _selectedYear = value);
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
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: <Widget>[
                      const Icon(
                        Icons.description_outlined,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Ukuran Kertas',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE0E2EE)),
                        ),
                        child: DropdownButton<ReportPaperSize>(
                          value: _paperSize,
                          underline: const SizedBox.shrink(),
                          isDense: true,
                          icon: const Icon(
                            Icons.arrow_drop_down,
                            color: AppColors.primary,
                          ),
                          style: const TextStyle(
                            color: AppColors.textDark,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() => _paperSize = value);
                          },
                          items: const <DropdownMenuItem<ReportPaperSize>>[
                            DropdownMenuItem<ReportPaperSize>(
                              value: ReportPaperSize.a4,
                              child: Text('A4'),
                            ),
                            DropdownMenuItem<ReportPaperSize>(
                              value: ReportPaperSize.thermal,
                              child: Text('Thermal'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: <Widget>[
                  _CustomerTab(rows: perCustomer, tahun: tahun),
                  _ModalTab(
                    rows: perItem,
                    totalModal: summary.totalModal,
                    tahun: tahun,
                  ),
                  _MarginTab(
                    rows: perItem,
                    totalMargin: summary.totalMargin,
                    tahun: tahun,
                  ),
                  _RingkasanTab(summary: summary),
                  _ItemTab(rows: perItem),
                  _DetailTab(rows: detail),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RingkasanTab extends StatelessWidget {
  const _RingkasanTab({required this.summary});

  final ReportSummary summary;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        _StatCard(
          icon: Icons.payments_outlined,
          label: 'Total Omzet',
          value: formatRupiah(summary.totalGross),
          highlight: true,
        ),
        _StatCard(
          icon: Icons.inventory_2_outlined,
          label: 'Total Qty Terjual',
          value: '${formatThousands(summary.totalQty)} pcs',
        ),
        _StatCard(
          icon: Icons.receipt_long_outlined,
          label: 'Jumlah Transaksi',
          value: '${summary.totalTransaksi}',
        ),
        _StatCard(
          icon: Icons.cake_outlined,
          label: 'Jumlah Item Terjual',
          value: '${summary.jumlahItem}',
        ),
        _StatCard(
          icon: Icons.people_alt_outlined,
          label: 'Jumlah Customer',
          value: '${summary.jumlahCustomer}',
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: highlight ? 20 : 18,
                      fontWeight: FontWeight.bold,
                      color: highlight ? AppColors.primary : AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemTab extends StatelessWidget {
  const _ItemTab({required this.rows});

  final List<ReportItemRow> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const _Empty(message: 'Belum ada data penjualan pada tahun ini.');
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: rows.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final row = rows[index];
        return _RekapCard(
          badge: row.item.noItm,
          title: row.item.nama,
          value: formatRupiah(row.gross),
          details: <String>[
            'Qty: ${formatThousands(row.qty)}',
            'Transaksi: ${row.transaksi}',
          ],
        );
      },
    );
  }
}

class _CustomerTab extends StatelessWidget {
  const _CustomerTab({required this.rows, required this.tahun});

  final List<ReportCustomerRow> rows;
  final int tahun;

  Future<void> _openPdf(BuildContext context, String noCust) async {
    try {
      final bytes = await buildCustomerInvoicePdf(tahun: tahun, noCust: noCust);
      await Printing.layoutPdf(
        onLayout: (_) async => bytes,
        name: 'Invoice_Customer_$noCust',
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal buka PDF: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const _Empty(message: 'Belum ada data penjualan pada tahun ini.');
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: rows.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final row = rows[index];
        return InkWell(
          onTap: () => _openPdf(context, row.customer.noCust),
          borderRadius: BorderRadius.circular(16),
          child: _RekapCard(
            badge: row.customer.noCust,
            title: row.customer.nama,
            value: formatRupiah(row.gross),
            details: <String>[
              'Qty: ${formatThousands(row.qty)}',
              'Transaksi: ${row.transaksi}',
            ],
          ),
        );
      },
    );
  }
}

class _ModalTab extends StatelessWidget {
  const _ModalTab({
    required this.rows,
    required this.totalModal,
    required this.tahun,
  });

  final List<ReportItemRow> rows;
  final double totalModal;
  final int tahun;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        _StatCard(
          icon: Icons.account_balance_wallet_outlined,
          label: 'Jumlah Modal Tahun $tahun',
          value: formatRupiah(totalModal),
          highlight: true,
        ),
        if (rows.isEmpty)
          const _Empty(message: 'Belum ada data penjualan pada tahun ini.')
        else
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _RekapCard(
                badge: row.item.noItm,
                title: row.item.nama,
                value: formatRupiah(row.modal),
                details: <String>[
                  'Qty: ${formatThousands(row.qty)}',
                  'HPP: ${formatRupiah(row.item.hpp)}',
                ],
              ),
            ),
      ],
    );
  }
}

class _MarginTab extends StatelessWidget {
  const _MarginTab({
    required this.rows,
    required this.totalMargin,
    required this.tahun,
  });

  final List<ReportItemRow> rows;
  final double totalMargin;
  final int tahun;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        _StatCard(
          icon: Icons.trending_up_outlined,
          label: 'Jumlah Keuntungan Tahun $tahun',
          value: formatRupiah(totalMargin),
          highlight: true,
        ),
        if (rows.isEmpty)
          const _Empty(message: 'Belum ada data penjualan pada tahun ini.')
        else
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _RekapCard(
                badge: row.item.noItm,
                title: row.item.nama,
                value: formatRupiah(row.margin),
                details: <String>[
                  'Qty: ${formatThousands(row.qty)}',
                  'HPP: ${formatRupiah(row.item.hpp)}',
                  'Modal: ${formatRupiah(row.modal)}',
                ],
              ),
            ),
      ],
    );
  }
}

class _DetailTab extends StatelessWidget {
  const _DetailTab({required this.rows});

  final List<Penjualan> rows;

  @override
  Widget build(BuildContext context) {
    // Flatten: satu baris per item di dalam tiap invoice.
    final List<PenjualanLine> lines = <PenjualanLine>[];
    final List<Penjualan> sources = <Penjualan>[];
    for (final p in rows) {
      for (final line in p.items) {
        lines.add(line);
        sources.add(p);
      }
    }

    if (lines.isEmpty) {
      return const _Empty(message: 'Belum ada data penjualan pada tahun ini.');
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: lines.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final p = sources[index];
        final line = lines[index];
        return _RekapCard(
          badge: p.noInv,
          title: ReportService.namaItem(line.noItm),
          value: formatRupiah(line.gross),
          details: <String>[
            'Customer: ${ReportService.namaCustomer(p.noCust)}',
            'Qty: ${formatThousands(line.qty)}  -  '
                'Harga: ${formatRupiah(line.harga)}',
          ],
        );
      },
    );
  }
}

class _RekapCard extends StatelessWidget {
  const _RekapCard({
    required this.badge,
    required this.title,
    required this.value,
    required this.details,
  });

  final String badge;
  final String title;
  final String value;
  final List<String> details;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                badge,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  for (final line in details) ...<Widget>[
                    const SizedBox(height: 3),
                    Text(
                      line,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(
            Icons.inbox_outlined,
            size: 64,
            color: AppColors.textLight,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textLight),
          ),
        ],
      ),
    );
  }
}
