import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../services/report_service.dart';
import '../theme/app_theme.dart';
import '../utils/currency.dart';

/// Mode agregasi chart penjualan: per customer atau per item.
enum ChartMode { customer, item }

/// Mode nilai chart: omzet (Rupiah/gross) atau Qty terjual.
enum ChartValueMode { gross, qty }

/// Penampilan singkat untuk nama item/customer pada sumbu chart.
String shortLabel(String text, {int max = 10}) {
  if (text.length <= max) return text;
  return '${text.substring(0, max - 1)}…';
}

/// Format angka ringkas untuk sumbu chart, contoh: 1500000 -> "1,5jt".
String compactRupiah(num value) {
  String trim(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

  if (value >= 1000000000) return '${trim(value / 1000000000)}M';
  if (value >= 1000000) return '${trim(value / 1000000)}jt';
  if (value >= 1000) return '${trim(value / 1000)}rb';
  return formatThousands(value);
}

/// Widget grafik batang "Chart Penjualan" untuk Menu Utama.
///
/// Menampilkan omzet (gross) atau qty pada tahun berjalan, bisa dipilih
/// By Customer / By Item dan nilai Rupiah / Qty. Pilihan ini juga
/// dipakai oleh Chart Pie.
class ChartPenjualanWidget extends StatelessWidget {
  const ChartPenjualanWidget({
    super.key,
    required this.tahun,
    required this.mode,
    required this.onModeChanged,
    required this.valueMode,
    required this.onValueChanged,
  });

  final int tahun;
  final ChartMode mode;
  final ValueChanged<ChartMode> onModeChanged;
  final ChartValueMode valueMode;
  final ValueChanged<ChartValueMode> onValueChanged;

  double _valueOf(num gross, int qty) =>
      valueMode == ChartValueMode.gross ? gross.toDouble() : qty.toDouble();

  List<_ChartEntry> _entries() {
    final List<_ChartEntry> entries = <_ChartEntry>[];

    if (mode == ChartMode.customer) {
      for (final row in ReportService.perCustomer(tahun)) {
        entries.add(
          _ChartEntry(
            label: row.customer.nama,
            value: _valueOf(row.gross, row.qty),
          ),
        );
      }
    } else {
      for (final row in ReportService.perItem(tahun)) {
        entries.add(
          _ChartEntry(
            label: row.item.singkatan.isNotEmpty
                ? row.item.singkatan
                : row.item.nama,
            value: _valueOf(row.gross, row.qty),
          ),
        );
      }
    }
    return entries;
  }

  @override
  Widget build(BuildContext context) {
    final List<_ChartEntry> entries = _entries();
    final List<_ChartEntry> top = entries.take(8).toList();
    final double maxBar = top.fold<double>(0, (max, e) => math.max(max, e.value));

    return Card(
      elevation: 2,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
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
                    Icons.bar_chart_rounded,
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
                        'Chart Penjualan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${valueMode == ChartValueMode.gross ? 'Omzet' : 'Qty'} per ${mode == ChartMode.customer ? 'Customer' : 'Item'} • $tahun',
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
            const SizedBox(height: 14),
            _ModeToggle(mode: mode, onChanged: onModeChanged),
            const SizedBox(height: 8),
            _ValueToggle(valueMode: valueMode, onChanged: onValueChanged),
            const SizedBox(height: 18),
            if (top.isEmpty)
              const _EmptyChart(message: 'Belum ada data penjualan pada tahun ini')
            else
              SizedBox(
                height: 240,
                child: BarChart(
                  BarChartData(
                    maxY: maxBar <= 0 ? 1 : maxBar * 1.25,
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (_) => AppColors.textDark,
                        tooltipPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          return BarTooltipItem(
                            '${top[group.x].label}\n',
                            const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            children: <TextSpan>[
                              TextSpan(
                                text: valueMode == ChartValueMode.gross
                                    ? formatRupiah(rod.toY)
                                    : '${formatThousands(rod.toY)} pcs',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 52,
                          getTitlesWidget: (value, meta) => Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Text(
                              valueMode == ChartValueMode.gross
                                  ? compactRupiah(value)
                                  : formatThousands(value),
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textLight,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 34,
                          getTitlesWidget: (value, meta) {
                            final int index = value.toInt();
                            if (index < 0 || index >= top.length) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: SizedBox(
                                width: 56,
                                child: Text(
                                  shortLabel(top[index].label),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textDark,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: maxBar <= 0 ? 1 : _niceInterval(maxBar),
                      getDrawingHorizontalLine: (_) => const FlLine(
                        color: Color(0xFFEDEFF7),
                        strokeWidth: 1,
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: List<BarChartGroupData>.generate(
                      top.length,
                      (i) => BarChartGroupData(
                        x: i,
                        barRods: <BarChartRodData>[
                          BarChartRodData(
                            toY: top[i].value,
                            width: 22,
                            borderRadius: BorderRadius.circular(7),
                            gradient: const LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: <Color>[
                                AppColors.primary,
                                AppColors.accent,
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  duration: const Duration(milliseconds: 450),
                  curve: Curves.easeOutCubic,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Interval grid horizontal yang "bulat" agar sumbu Y enak dibaca.
  static double _niceInterval(double max) {
    final double raw = max / 4;
    final double magnitude = math.pow(10, (math.log(raw) / math.ln10).floor())
        .toDouble();
    final double normalized = raw / magnitude;
    double step;
    if (normalized <= 1) {
      step = 1;
    } else if (normalized <= 2) {
      step = 2;
    } else if (normalized <= 5) {
      step = 5;
    } else {
      step = 10;
    }
    return step * magnitude;
  }
}

class _ChartEntry {
  const _ChartEntry({required this.label, required this.value});

  final String label;
  final double value;
}

/// Toggle pill By Customer / By Item, mengikuti gaya _DetailToggle.
class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.mode, required this.onChanged});

  final ChartMode mode;
  final ValueChanged<ChartMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: _ModeButton(
              label: 'By Customer',
              icon: Icons.people_alt_outlined,
              selected: mode == ChartMode.customer,
              onTap: () => onChanged(ChartMode.customer),
            ),
          ),
          Expanded(
            child: _ModeButton(
              label: 'By Item',
              icon: Icons.cake_outlined,
              selected: mode == ChartMode.item,
              onTap: () => onChanged(ChartMode.item),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? Colors.white : Colors.transparent,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: selected
                ? <BoxShadow>[
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                icon,
                size: 17,
                color: selected ? AppColors.primary : AppColors.textLight,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected ? AppColors.primary : AppColors.textLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Toggle pill Rupiah (Gross) / Qty, dipakai di Chart Penjualan.
class _ValueToggle extends StatelessWidget {
  const _ValueToggle({required this.valueMode, required this.onChanged});

  final ChartValueMode valueMode;
  final ValueChanged<ChartValueMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: _ModeButton(
              label: 'Rupiah (Gross)',
              icon: Icons.payments_outlined,
              selected: valueMode == ChartValueMode.gross,
              onTap: () => onChanged(ChartValueMode.gross),
            ),
          ),
          Expanded(
            child: _ModeButton(
              label: 'Qty',
              icon: Icons.inventory_2_outlined,
              selected: valueMode == ChartValueMode.qty,
              onTap: () => onChanged(ChartValueMode.qty),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyChart extends StatelessWidget {
  const _EmptyChart({required this.message});

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
            Icons.insert_chart_outlined,
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
