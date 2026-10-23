import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/customer.dart';
import '../models/penjualan.dart';
import '../models/toko_profile.dart';
import '../services/customer_service.dart';
import '../services/item_service.dart';
import '../services/penjualan_service.dart';
import '../services/toko_profile_service.dart';
import 'currency.dart';

Future<Uint8List> buildCustomerInvoicePdf({
  required int tahun,
  required String noCust,
}) async {
  final doc = pw.Document();
  final profile = TokoProfileService.get();
  final customer =
      CustomerService.byNo(noCust) ??
      (Customer(noCust: noCust, nama: noCust, kontak: '', alamat: ''));
  final all =
      PenjualanService.byYear(tahun).where((p) => p.noCust == noCust).toList();
  all.sort((a, b) {
    final ta = a.addTime ?? DateTime(0);
    final tb = b.addTime ?? DateTime(0);
    return ta.compareTo(tb);
  });

  final dateFmt = DateFormat('dd/MM/yyyy HH:mm');
  const PdfPageFormat strukFormat = PdfPageFormat.roll80;
  final double grandTotal = all.fold<double>(0, (sum, inv) => sum + inv.gross);

  final List<pw.Widget> body = <pw.Widget>[
    pw.SizedBox(height: 2),
    pw.Center(
      child: pw.Text(
        customer.nama,
        style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
      ),
    ),
    pw.SizedBox(height: 2),
    pw.Center(
      child: pw.Text(
        'ID Pelanggan: ${customer.noCust}',
        style: const pw.TextStyle(fontSize: 7),
      ),
    ),
    pw.Center(
      child: pw.Text(
        'Periode Tahun: $tahun',
        style: const pw.TextStyle(fontSize: 7),
      ),
    ),
    pw.Divider(height: 12),
  ];

  if (all.isEmpty) {
    body.add(
      pw.Text(
        'Belum ada data.',
        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
      ),
    );
  } else {
    for (int i = 0; i < all.length; i++) {
      if (i > 0) body.add(pw.SizedBox(height: 10));
      body.add(_invoiceSection(all[i], dateFmt));
    }
    body.addAll(<pw.Widget>[
      pw.Divider(height: 14),
      pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text(
          'Total ${all.length} Pesanan = ${formatRupiah(grandTotal)}',
          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
        ),
      ),
    ]);
  }

  doc.addPage(
    pw.Page(
      pageFormat: strukFormat,
      build:
          (ctx) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: <pw.Widget>[
              _header(profile),
              ...body,
              pw.SizedBox(height: 8),
              _footer(profile, ctx),
            ],
          ),
    ),
  );
  return doc.save();
}

pw.Widget _invoiceSection(Penjualan inv, DateFormat dateFmt) {
  final String tanggal = dateFmt.format(inv.addTime ?? DateTime.now());

  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: <pw.Widget>[
      pw.Text(
        'Kode Pesanan: ${inv.noInv}',
        style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
      ),
      pw.Text(
        'Tanggal Transaksi: $tanggal',
        style: const pw.TextStyle(fontSize: 7),
      ),
      pw.Text('Cashier: Kasir', style: const pw.TextStyle(fontSize: 7)),
      pw.SizedBox(height: 4),
      pw.Table(
        border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey400),
        columnWidths: const <int, pw.TableColumnWidth>{
          0: pw.FlexColumnWidth(4.2),
          1: pw.FlexColumnWidth(2.2),
        },
        children: <pw.TableRow>[
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.grey200),
            children: <pw.Widget>[
              _cell('Barang', bold: true),
              _cell('Subtotal', bold: true, align: pw.TextAlign.right),
            ],
          ),
          ...inv.items.map((line) {
            final nama = ItemService.byNo(line.noItm)?.nama ?? line.noItm;
            return pw.TableRow(
              children: <pw.Widget>[
                _itemCell(nama, '  ${line.qty} x ${formatRupiah(line.harga)}'),
                _cell(formatRupiah(line.gross), align: pw.TextAlign.right),
              ],
            );
          }),
        ],
      ),
      pw.SizedBox(height: 3),
      pw.Text(
        'Jumlah Item: ${inv.items.length} (${formatThousands(inv.qty)} Toples)',
        style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold),
      ),
      pw.SizedBox(height: 2),
      pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text(
          'Total = ${formatRupiah(inv.gross)}',
          style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
        ),
      ),
    ],
  );
}

pw.Widget _header(TokoProfile profile) {
  return pw.Container(
    margin: const pw.EdgeInsets.only(bottom: 4),
    child: pw.Column(
      children: <pw.Widget>[
        pw.Center(
          child: pw.Text(
            profile.namaToko,
            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
          ),
        ),
        if (profile.alamat.isNotEmpty) ...<pw.Widget>[
          pw.SizedBox(height: 2),
          pw.Center(
            child: pw.Text(
              profile.alamat,
              style: const pw.TextStyle(fontSize: 7),
              textAlign: pw.TextAlign.center,
            ),
          ),
        ],
        pw.SizedBox(height: 4),
      ],
    ),
  );
}

pw.Widget _footer(TokoProfile profile, pw.Context ctx) {
  return pw.Container(
    margin: const pw.EdgeInsets.only(top: 8),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: <pw.Widget>[
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: <pw.Widget>[
              if (profile.whatsapp.isNotEmpty)
                pw.Text(
                  'WA/HP: ${profile.whatsapp}',
                  style: const pw.TextStyle(fontSize: 7),
                ),
              pw.Text(
                'Halaman ${ctx.pageNumber} dari ${ctx.pagesCount}',
                style: const pw.TextStyle(
                  fontSize: 7,
                  color: PdfColors.grey700,
                ),
              ),
            ],
          ),
        ),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: <pw.Widget>[
              if (profile.hasBankLogo)
                pw.Center(
                  child: pw.Image(
                    pw.MemoryImage(profile.bankLogoBytes!),
                    height: 16,
                    fit: pw.BoxFit.contain,
                  ),
                ),
              if (profile.noRekening.isNotEmpty || profile.atasNama.isNotEmpty)
                pw.SizedBox(height: 1),
              if (profile.noRekening.isNotEmpty)
                pw.Text(
                  'Rek: ${profile.noRekening}',
                  style: const pw.TextStyle(fontSize: 7),
                  textAlign: pw.TextAlign.center,
                ),
              if (profile.atasNama.isNotEmpty)
                pw.Text(
                  profile.atasNama,
                  style: const pw.TextStyle(fontSize: 7),
                  textAlign: pw.TextAlign.center,
                ),
            ],
          ),
        ),
        pw.Expanded(child: pw.SizedBox()),
      ],
    ),
  );
}

pw.Widget _cell(
  String text, {
  bool bold = false,
  pw.TextAlign align = pw.TextAlign.left,
}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 3),
    child: pw.Text(
      text,
      style: pw.TextStyle(
        fontSize: 7,
        fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
      ),
      textAlign: align,
    ),
  );
}

pw.Widget _itemCell(String nama, String qtyHarga) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 3),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: <pw.Widget>[
        pw.Text(nama, style: const pw.TextStyle(fontSize: 7)),
        pw.SizedBox(height: 1),
        pw.Text(
          qtyHarga,
          style: const pw.TextStyle(fontSize: 6, color: PdfColors.grey700),
        ),
      ],
    ),
  );
}
