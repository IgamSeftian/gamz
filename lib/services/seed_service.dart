import '../models/customer.dart';
import '../models/item.dart';
import '../models/penjualan.dart';
import 'customer_service.dart';
import 'item_service.dart';
import 'penjualan_service.dart';

/// Mengisi data contoh ke master item, customer, dan penjualan saat database
/// masih kosong. Data ini menggantikan "sales" lama yang kini disatukan ke
/// master penjualan.
class SeedService {
  SeedService._();

  /// Hanya mengisi bila ketiga tabel sama-sama kosong (instalasi baru).
  static Future<void> seedIfEmpty() async {
    final bool kosong = ItemService.all().isEmpty &&
        CustomerService.all().isEmpty &&
        PenjualanService.all().isEmpty;
    if (!kosong) return;

    await _seedItems();
    await _seedCustomers();
    await _seedPenjualan();
  }

  static Future<void> _seedItems() async {
    const List<Item> items = <Item>[
      Item(noItm: 'I001', nama: 'Nastar Keju', singkatan: 'Nastar', harga: 90000),
      Item(noItm: 'I002', nama: 'Nastar Keong', singkatan: 'Keong', harga: 85000),
      Item(noItm: 'I003', nama: 'Kastengel', singkatan: 'Kastengel', harga: 98000),
      Item(noItm: 'I004', nama: 'Putri Salju', singkatan: 'Putri Salju', harga: 95000),
      Item(noItm: 'I005', nama: 'Lapis Legit', singkatan: 'Lapis', harga: 250000),
    ];
    for (final item in items) {
      await ItemService.save(item);
    }
  }

  static Future<void> _seedCustomers() async {
    const List<Customer> customers = <Customer>[
      Customer(noCust: 'C001', nama: 'Umum', kontak: '', alamat: ''),
    ];
    for (final customer in customers) {
      await CustomerService.save(customer);
    }
  }

  static Future<void> _seedPenjualan() async {
    const List<Penjualan> penjualan = <Penjualan>[
      // 2023
      Penjualan(noInv: 'P001', tahun: 2023, noCust: 'C001', items: <PenjualanLine>[
        PenjualanLine(noItm: 'I001', qty: 120, harga: 85000),
      ]),
      Penjualan(noInv: 'P002', tahun: 2023, noCust: 'C001', items: <PenjualanLine>[
        PenjualanLine(noItm: 'I002', qty: 90, harga: 80000),
      ]),
      Penjualan(noInv: 'P003', tahun: 2023, noCust: 'C001', items: <PenjualanLine>[
        PenjualanLine(noItm: 'I003', qty: 75, harga: 90000),
      ]),
      // 2024
      Penjualan(noInv: 'P004', tahun: 2024, noCust: 'C001', items: <PenjualanLine>[
        PenjualanLine(noItm: 'I001', qty: 150, harga: 88000),
      ]),
      Penjualan(noInv: 'P005', tahun: 2024, noCust: 'C001', items: <PenjualanLine>[
        PenjualanLine(noItm: 'I002', qty: 110, harga: 82000),
      ]),
      Penjualan(
        noInv: 'P006',
        tahun: 2024,
        noCust: 'C001',
        items: <PenjualanLine>[
          PenjualanLine(noItm: 'I003', qty: 95, harga: 95000),
          PenjualanLine(noItm: 'I004', qty: 60, harga: 90000),
        ],
      ),
      // 2025
      Penjualan(noInv: 'P007', tahun: 2025, noCust: 'C001', items: <PenjualanLine>[
        PenjualanLine(noItm: 'I001', qty: 180, harga: 90000),
      ]),
      Penjualan(noInv: 'P008', tahun: 2025, noCust: 'C001', items: <PenjualanLine>[
        PenjualanLine(noItm: 'I002', qty: 140, harga: 85000),
      ]),
      Penjualan(noInv: 'P009', tahun: 2025, noCust: 'C001', items: <PenjualanLine>[
        PenjualanLine(noItm: 'I003', qty: 120, harga: 98000),
      ]),
      // Contoh invoice multi-item (sama seperti input manual):
      // P010; 2025; C001; [Nastar Keong x3 @85.000, Nastar Keju x2 @90.000]
      Penjualan(
        noInv: 'P010',
        tahun: 2025,
        noCust: 'C001',
        items: <PenjualanLine>[
          PenjualanLine(noItm: 'I002', qty: 3, harga: 85000),
          PenjualanLine(noItm: 'I001', qty: 2, harga: 90000),
        ],
      ),
      Penjualan(noInv: 'P011', tahun: 2025, noCust: 'C001', items: <PenjualanLine>[
        PenjualanLine(noItm: 'I005', qty: 40, harga: 250000),
      ]),
    ];
    for (final p in penjualan) {
      await PenjualanService.save(p);
    }
  }
}
