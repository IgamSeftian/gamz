import '../models/customer.dart';
import '../models/item.dart';
import '../models/penjualan.dart';
import 'customer_service.dart';
import 'item_service.dart';
import 'penjualan_service.dart';

/// Ringkasan laporan penjualan untuk satu periode tahun.
class ReportSummary {
  const ReportSummary({
    required this.tahun,
    required this.totalGross,
    required this.totalModal,
    required this.totalMargin,
    required this.totalQty,
    required this.totalTransaksi,
    required this.jumlahItem,
    required this.jumlahCustomer,
  });

  final int tahun;
  final double totalGross;
  final double totalModal;
  final double totalMargin;
  final int totalQty;
  final int totalTransaksi;
  final int jumlahItem;
  final int jumlahCustomer;
}

/// Baris rekap penjualan per item.
class ReportItemRow {
  const ReportItemRow({
    required this.item,
    required this.qty,
    required this.gross,
    required this.margin,
    required this.transaksi,
  });

  final Item item;
  final int qty;
  final double gross;
  final double margin;
  final int transaksi;

  /// Modal baris ini: HPP x qty.
  double get modal => item.hpp * qty;
}

/// Baris rekap penjualan per customer.
class ReportCustomerRow {
  const ReportCustomerRow({
    required this.customer,
    required this.qty,
    required this.gross,
    required this.margin,
    required this.transaksi,
  });

  final Customer customer;
  final int qty;
  final double gross;
  final double margin;
  final int transaksi;
}

class _Acc {
  int qty = 0;
  double gross = 0;
  double margin = 0;
  int transaksi = 0;
}

/// Service untuk menyusun data laporan dari master penjualan.
class ReportService {
  ReportService._();

  /// Semua tahun yang tersedia (dari master penjualan).
  static List<int> get years => PenjualanService.years;

  /// Ringkasan untuk [tahun] tertentu.
  static ReportSummary summary(int tahun) {
    final List<Penjualan> list = PenjualanService.byYear(tahun);
    double gross = 0;
    double modal = 0;
    double margin = 0;
    int qty = 0;
    final Set<String> items = <String>{};
    final Set<String> customers = <String>{};
    for (final p in list) {
      gross += p.gross;
      qty += p.qty;
      customers.add(p.noCust);
      for (final line in p.items) {
        items.add(line.noItm);
        final double hpp = _hppOf(line.noItm);
        modal += hpp * line.qty;
        // Margin = (Gross satuan - HPP) x Qty.
        margin += (line.harga - hpp) * line.qty;
      }
    }
    return ReportSummary(
      tahun: tahun,
      totalGross: gross,
      totalModal: modal,
      totalMargin: margin,
      totalQty: qty,
      totalTransaksi: list.length,
      jumlahItem: items.length,
      jumlahCustomer: customers.length,
    );
  }

  /// Rekap per item, diurutkan dari omzet terbesar.
  static List<ReportItemRow> perItem(int tahun) {
    final Map<String, _Acc> map = <String, _Acc>{};
    for (final p in PenjualanService.byYear(tahun)) {
      for (final line in p.items) {
        final acc = map.putIfAbsent(line.noItm, () => _Acc());
        acc.qty += line.qty;
        acc.gross += line.gross;
        // Margin = (Gross satuan - HPP) x Qty.
        acc.margin += (line.harga - _hppOf(line.noItm)) * line.qty;
        acc.transaksi += 1;
      }
    }
    final List<ReportItemRow> rows =
        map.entries.map((e) {
          final item =
              ItemService.byNo(e.key) ??
              Item(noItm: e.key, nama: e.key, singkatan: '', harga: 0);
          return ReportItemRow(
            item: item,
            qty: e.value.qty,
            gross: e.value.gross,
            margin: e.value.margin,
            transaksi: e.value.transaksi,
          );
        }).toList();
    rows.sort((a, b) => b.gross.compareTo(a.gross));
    return rows;
  }

  /// Rekap per customer, diurutkan dari omzet terbesar.
  static List<ReportCustomerRow> perCustomer(int tahun) {
    final Map<String, _Acc> map = <String, _Acc>{};
    for (final p in PenjualanService.byYear(tahun)) {
      final acc = map.putIfAbsent(p.noCust, () => _Acc());
      acc.qty += p.qty;
      acc.gross += p.gross;
      for (final line in p.items) {
        // Margin = (Gross satuan - HPP) x Qty.
        acc.margin += (line.harga - _hppOf(line.noItm)) * line.qty;
      }
      acc.transaksi += 1;
    }
    final List<ReportCustomerRow> rows =
        map.entries.map((e) {
          final customer =
              CustomerService.byNo(e.key) ??
              Customer(noCust: e.key, nama: e.key, kontak: '', alamat: '');
          return ReportCustomerRow(
            customer: customer,
            qty: e.value.qty,
            gross: e.value.gross,
            margin: e.value.margin,
            transaksi: e.value.transaksi,
          );
        }).toList();
    rows.sort((a, b) => b.gross.compareTo(a.gross));
    return rows;
  }

  /// Detail seluruh transaksi pada [tahun] tertentu.
  static List<Penjualan> detail(int tahun) => PenjualanService.byYear(tahun);

  static double _hppOf(String noItm) => ItemService.byNo(noItm)?.hpp ?? 0;

  /// Nama item dari nomor item (fallback ke nomor bila tidak ada).
  static String namaItem(String noItm) =>
      ItemService.byNo(noItm)?.nama ?? noItm;

  /// Nama customer dari nomor customer (fallback ke nomor bila tidak ada).
  static String namaCustomer(String noCust) =>
      CustomerService.byNo(noCust)?.nama ?? noCust;
}
