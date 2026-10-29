import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../services/report_service.dart';
import '../theme/app_theme.dart';
import '../utils/currency.dart';
import 'chart_penjualan.dart';

/// Widget grafik lingkaran "Chart Pie" untuk Menu Utama.
///
/// Mengikuti pilihan mode (By Customer / By Item) dan nilai
/// (Rupiah / Qty / Margin) milik Chart Penjualan.
class ChartPieWidget extends StatelessWidget {
  const ChartPieWidget({
    super.key,
    required this.tahun,
    required this.mode,
    required this.valueMode,
  });

  final int tahun;
  final ChartMode mode;
  final ChartValueMode valueMode;

  static const List<Color> _palette = <Color>[
    AppColors.primary,
    AppColors.accent,
    AppColors.success,
    Color(0xFFF5A623),
    Color(0xFFE5484D),
    Color(0xFF12B5CA),
  ];

  double _valueOf(double gross, int qty, double margin) {
    switch (valueMode) {
      case ChartValueMode.gross:
      case ChartValueMode.all:
        return gross;
      case ChartValueMode.qty:
        return qty.toDouble();
      case ChartValueMode.margin:
        return margin;
    }
  }

  String get _nilaiLabel {
    switch (valueMode) {
      case ChartValueMode.gross:
      case ChartValueMode.all:
        return 'Omzet';
      case ChartValueMode.qty:
        return 'Qty';
      case ChartValueMode.margin:
        return 'Margin';
    }
  }

  /// True bila nilai ditampilkan dalam Rupiah.
  bool get _isRupiah => valueMode != ChartValueMode.qty;

  List<_PieEntry> _entries() {
    final List<_PieEntry> entries = <_PieEntry>[];

    if (mode == ChartMode.customer) {
      for (final row in ReportService.perCustomer(tahun)) {
        entries.add(
          _PieEntry(
            label: row.customer.nama,
            value: _valueOf(row.gross, row.qty, row.margin),
          ),
        );
      }
    } else {
      for (final row in ReportService.perItem(tahun)) {
        entries.add(
          _PieEntry(
            label:
                row.item.singkatan.isNotEmpty
                    ? row.item.singkatan
                    : row.item.nama,
            value: _valueOf(row.gross, row.qty, row.margin),
          ),
        );
      }
    }
    return entries;
  }

  @override
  Widget build(BuildContext context) {
    final List<_PieEntry> all = _entries();
    final List<_PieEntry> top = all.take(5).toList();
    final double lainnya = all
        .skip(5)
        .fold<double>(0, (sum, e) => sum + e.value);
    final double total = all.fold<double>(0, (sum, e) => sum + e.value);

    final List<_PieEntry> sections = <_PieEntry>[...top];
    if (lainnya > 0) {
      sections.add(_PieEntry(label: 'Lainnya', value: lainnya));
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
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
                    Icons.pie_chart_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'Chart Pie',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Proporsi $_nilaiLabel per ${mode == ChartMode.customer ? 'Customer' : 'Item'} • $tahun',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textLight,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    mode == ChartMode.customer ? 'By Customer' : 'By Item',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (sections.isEmpty || total <= 0)
              const _EmptyPie(
                message: 'Belum ada data penjualan pada tahun ini',
              )
            else ...<Widget>[
              SizedBox(
                height: 210,
                child: Center(
                  child: SizedBox(
                    height: 210,
                    child: PieChart(
                      PieChartData(
                        centerSpaceRadius: 52,
                        sectionsSpace: 3,
                        startDegreeOffset: -90,
                        sections: List<PieChartSectionData>.generate(
                          sections.length,
                          (i) {
                            final _PieEntry entry = sections[i];
                            final double percent = (entry.value / total) * 100;
                            return PieChartSectionData(
                              value: entry.value,
                              color: _palette[i % _palette.length],
                              radius: 62,
                              showTitle: percent >= 8,
                              title: '${percent.toStringAsFixed(1)}%',
                              titleStyle: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            );
                          },
                        ),
                      ),
                      duration: const Duration(milliseconds: 450),
                      curve: Curves.easeOutCubic,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Total $_nilaiLabel',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textLight,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Center(
                child: Text(
                  _isRupiah
                      ? formatRupiah(total)
                      : '${formatThousands(total)} pcs',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Divider(height: 1, color: Color(0xFFEDEFF7)),
              const SizedBox(height: 12),
              ...List<Widget>.generate(sections.length, (i) {
                final _PieEntry entry = sections[i];
                final double percent = (entry.value / total) * 100;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _palette[i % _palette.length],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          entry.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                      Text(
                        '${percent.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 92,
                        child: Text(
                          _isRupiah
                              ? formatRupiah(entry.value)
                              : formatThousands(entry.value),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}

class _PieEntry {
  const _PieEntry({required this.label, required this.value});

  final String label;
  final double value;
}

class _EmptyPie extends StatelessWidget {
  const _EmptyPie({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(
            Icons.donut_large_outlined,
            size: 36,
            color: AppColors.textLight.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppColors.textLight),
          ),
        ],
      ),
    );
  }
}
