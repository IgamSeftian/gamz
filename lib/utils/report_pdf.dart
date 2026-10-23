import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/toko_profile.dart';
import '../services/report_service.dart';
import '../services/toko_profile_service.dart';
import 'currency.dart';

enum ReportPaperSize { a4, thermal }

/// Membangun file PDF laporan penjualan untuk [tahun] tertentu.
Future<Uint8List> buildReportPdf(
  int tahun, {
  ReportPaperSize paperSize = ReportPaperSize.thermal,
}) async {
  final pw.Document doc = pw.Document();

  final ReportSummary summary = ReportService.summary(tahun);
  final List<ReportItemRow> perItem = ReportService.perItem(tahun);
  final List<ReportCustomerRow> perCustomer = ReportService.perCustomer(tahun);
  final detail = ReportService.detail(tahun);
  final TokoProfile profile = TokoProfileService.get();

  final bool thermal = paperSize == ReportPaperSize.thermal;
  final pw.TextStyle sectionStyle = pw.TextStyle(
    fontSize: thermal ? 11 : 13,
    fontWeight: pw.FontWeight.bold,
  );

  final PdfPageFormat pageFormat =
      thermal
          ? PdfPageFormat(PdfPageFormat.mm * 80, PdfPageFormat.a4.height)
          : PdfPageFormat.a4;

  doc.addPage(
    pw.MultiPage(
      pageFormat: pageFormat,
      margin: pw.EdgeInsets.all(thermal ? 5 * PdfPageFormat.mm : 24),
      header:
          (context) => pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 16),
            child: pw.Column(
              children: <pw.Widget>[
                if (profile.hasLogo)
                  pw.Center(
                    child: pw.Image(
                      pw.MemoryImage(profile.logoBytes!),
                      height: 64,
                      fit: pw.BoxFit.contain,
                    ),
                  )
                else
                  pw.Center(
                    child: pw.Text(
                      profile.namaToko,
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                if (profile.alamat.isNotEmpty) ...<pw.Widget>[
                  pw.SizedBox(height: 4),
                  pw.Center(
                    child: pw.Text(
                      profile.alamat,
                      style: const pw.TextStyle(fontSize: 9),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                ],
                pw.SizedBox(height: 4),
                pw.Center(
                  child: pw.Text(
                    'Laporan Penjualan - Periode Tahun: $tahun',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
      footer:
          (context) => pw.Container(
            margin: const pw.EdgeInsets.only(top: 12),
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
                          style: const pw.TextStyle(fontSize: 8),
                        ),
                      pw.Text(
                        'Halaman ${context.pageNumber} dari ${context.pagesCount}',
                        style: const pw.TextStyle(
                          fontSize: 8,
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
                            height: 18,
                            fit: pw.BoxFit.contain,
                          ),
                        ),
                      if (profile.noRekening.isNotEmpty ||
                          profile.atasNama.isNotEmpty)
                        pw.SizedBox(height: 2),
                      if (profile.noRekening.isNotEmpty)
                        pw.Text(
                          'Rek: ${profile.noRekening}',
                          style: const pw.TextStyle(fontSize: 8),
                          textAlign: pw.TextAlign.center,
                        ),
                      if (profile.atasNama.isNotEmpty)
                        pw.Text(
                          profile.atasNama,
                          style: const pw.TextStyle(fontSize: 8),
                          textAlign: pw.TextAlign.center,
                        ),
                    ],
                  ),
                ),
                pw.Expanded(child: pw.SizedBox()),
              ],
            ),
          ),
      build:
          (context) => <pw.Widget>[
            pw.SizedBox(height: 4),

            // Ringkasan
            pw.Text('Ringkasan', style: sectionStyle),
            pw.SizedBox(height: 6),
            _table(
              fontSize: thermal ? 6.5 : 9,
              headers: <String>['Keterangan', 'Nilai'],
              rows: <List<String>>[
                <String>['Total Omzet', formatRupiah(summary.totalGross)],
                <String>['Total Modal', formatRupiah(summary.totalModal)],
                <String>['Total Keuntungan', formatRupiah(summary.totalMargin)],
                <String>[
                  'Total Qty',
                  '${formatThousands(summary.totalQty)} pcs',
                ],
                <String>['Jumlah Transaksi', '${summary.totalTransaksi}'],
                <String>['Jumlah Item Terjual', '${summary.jumlahItem}'],
                <String>['Jumlah Customer', '${summary.jumlahCustomer}'],
              ],
            ),
            pw.SizedBox(height: 18),

            // Laporan modal
            pw.Text(
              'Laporan Modal - Total: ${formatRupiah(summary.totalModal)}',
              style: sectionStyle,
            ),
            pw.SizedBox(height: 6),
            if (perItem.isEmpty)
              _kosong()
            else
              _table(
                fontSize: thermal ? 6.5 : 9,
                headers: <String>['No', 'Item', 'HPP', 'Qty', 'Modal'],
                rows: <List<String>>[
                  for (int i = 0; i < perItem.length; i++)
                    <String>[
                      '${i + 1}',
                      perItem[i].item.nama,
                      formatRupiah(perItem[i].item.hpp),
                      formatThousands(perItem[i].qty),
                      formatRupiah(perItem[i].modal),
                    ],
                ],
              ),
            pw.SizedBox(height: 18),

            // Laporan margin
            pw.Text(
              'Laporan Margin - Total: ${formatRupiah(summary.totalMargin)}',
              style: sectionStyle,
            ),
            pw.SizedBox(height: 6),
            if (perItem.isEmpty)
              _kosong()
            else
              _table(
                fontSize: thermal ? 6.5 : 9,
                headers: <String>[
                  'No',
                  'Item',
                  'Harga',
                  'HPP',
                  'Qty',
                  'Margin',
                ],
                rows: <List<String>>[
                  for (int i = 0; i < perItem.length; i++)
                    <String>[
                      '${i + 1}',
                      perItem[i].item.nama,
                      formatRupiah(perItem[i].item.harga),
                      formatRupiah(perItem[i].item.hpp),
                      formatThousands(perItem[i].qty),
                      formatRupiah(perItem[i].margin),
                    ],
                ],
              ),
            pw.SizedBox(height: 18),

            // Rekap per item
            pw.Text('Rekap per Item', style: sectionStyle),
            pw.SizedBox(height: 6),
            if (perItem.isEmpty)
              _kosong()
            else
              _table(
                fontSize: thermal ? 6.5 : 9,
                headers: <String>['No', 'Item', 'Qty', 'Transaksi', 'Omzet'],
                rows: <List<String>>[
                  for (int i = 0; i < perItem.length; i++)
                    <String>[
                      '${i + 1}',
                      perItem[i].item.nama,
                      formatThousands(perItem[i].qty),
                      '${perItem[i].transaksi}',
                      formatRupiah(perItem[i].gross),
                    ],
                ],
              ),
            pw.SizedBox(height: 18),

            // Rekap per customer
            pw.Text('Rekap per Customer', style: sectionStyle),
            pw.SizedBox(height: 6),
            if (perCustomer.isEmpty)
              _kosong()
            else
              _table(
                fontSize: thermal ? 6.5 : 9,
                headers: <String>[
                  'No',
                  'Customer',
                  'Transaksi',
                  'Qty',
                  'Omzet',
                ],
                rows: <List<String>>[
                  for (int i = 0; i < perCustomer.length; i++)
                    <String>[
                      '${i + 1}',
                      perCustomer[i].customer.nama,
                      '${perCustomer[i].transaksi}',
                      formatThousands(perCustomer[i].qty),
                      formatRupiah(perCustomer[i].gross),
                    ],
                ],
              ),
            pw.SizedBox(height: 18),

            // Detail transaksi
            pw.Text('Detail Transaksi', style: sectionStyle),
            pw.SizedBox(height: 6),
            if (detail.isEmpty)
              _kosong()
            else
              _table(
                fontSize: thermal ? 6.5 : 9,
                headers: <String>[
                  'Invoice',
                  'Customer',
                  'Item',
                  'Qty',
                  'Harga',
                  'Gross',
                ],
                rows: <List<String>>[
                  for (final p in detail)
                    for (final line in p.items)
                      <String>[
                        p.noInv,
                        ReportService.namaCustomer(p.noCust),
                        ReportService.namaItem(line.noItm),
                        '${line.qty}',
                        formatRupiah(line.harga),
                        formatRupiah(line.gross),
                      ],
                ],
              ),
          ],
    ),
  );

  return doc.save();
}

pw.Widget _kosong() => pw.Text(
  'Belum ada data.',
  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
);

pw.Widget _table({
  required List<String> headers,
  required List<List<String>> rows,
  required double fontSize,
}) {
  const pw.TableBorder border = pw.TableBorder(
    horizontalInside: pw.BorderSide(color: PdfColors.grey400, width: 0.5),
    bottom: pw.BorderSide(color: PdfColors.grey600, width: 0.8),
    top: pw.BorderSide(color: PdfColors.grey600, width: 0.8),
  );

  pw.Widget cell(String text, {required bool head}) => pw.Padding(
    padding: pw.EdgeInsets.symmetric(
      horizontal: fontSize < 8 ? 2 : 3,
      vertical: 3,
    ),
    child: pw.Text(
      text,
      style: pw.TextStyle(
        fontSize: fontSize,
        fontWeight: head ? pw.FontWeight.bold : pw.FontWeight.normal,
      ),
    ),
  );

  return pw.Table(
    border: border,
    columnWidths: const <int, pw.TableColumnWidth>{0: pw.FlexColumnWidth()},
    children: <pw.TableRow>[
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey200),
        children: <pw.Widget>[for (final h in headers) cell(h, head: true)],
      ),
      for (final row in rows)
        pw.TableRow(
          children: <pw.Widget>[
            for (final value in row) cell(value, head: false),
          ],
        ),
    ],
  );
}
