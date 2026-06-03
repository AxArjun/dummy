// FuelIQ — Analytics Screen
// Full vehicle analytics with fl_chart visualizations

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/analytics_provider.dart';
import '../../domain/analytics_models.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key, required this.vehicleId});

  final String vehicleId;

  static const Color _bg = Color(0xFF0B0B0B);
  static const Color _surface = Color(0xFF121212);
  static const Color _card = Color(0xFF1A1A1A);
  static const Color _border = Color(0xFF262626);
  static const Color _gold = Color(0xFFD4AF37);
  static const Color _silver = Color(0xFFC0C0C0);
  static const Color _textPrimary = Color(0xFFF5F5F5);
  static const Color _textSub = Color(0xFF9E9E9E);
  static const Color _success = Color(0xFF4CAF50);
  static const Color _warning = Color(0xFFFF9800);
  static const Color _danger = Color(0xFFF44336);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsState = ref.watch(vehicleAnalyticsProvider(vehicleId));

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _border),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: _textPrimary, size: 16),
          ),
        ),
        title: const Text(
          'Analytics',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: _textPrimary,
          ),
        ),
      ),
      body: analyticsState.when(
        data: (summary) => _buildContent(context, summary),
        loading: () => const Center(
            child: CircularProgressIndicator(color: _gold, strokeWidth: 2.5)),
        error: (e, st) => Center(
          child: Text(
            'Failed to load analytics:\n$e',
            textAlign: TextAlign.center,
            style: const TextStyle(color: _danger),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, VehicleAnalyticsSummary summary) {
    if (summary.totalFills == 0) {
      return _buildEmptyState();
    }

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── KPI cards ─────────────────────────────────────────────
          _buildKpiRow(summary).animate().fadeIn(duration: 500.ms),

          const SizedBox(height: 24),

          // ── Monthly spend chart ────────────────────────────────────
          _buildSectionHeader('Monthly Fuel Spend'),
          const SizedBox(height: 12),
          _buildMonthlySpendChart(summary)
              .animate()
              .fadeIn(delay: 150.ms, duration: 500.ms),

          const SizedBox(height: 24),

          // ── Efficiency trend chart ─────────────────────────────────
          _buildSectionHeader('Fuel Efficiency Trend'),
          const SizedBox(height: 12),
          _buildEfficiencyTrendChart(summary)
              .animate()
              .fadeIn(delay: 250.ms, duration: 500.ms),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  // ─── KPI Row ───────────────────────────────────────────────────────────────

  Widget _buildKpiRow(VehicleAnalyticsSummary summary) {
    final totalVolume = summary.monthlyStats.fold<double>(0, (s, m) => s + m.totalLiters);

    return Column(
      children: [
        Row(
          children: [
            _KpiCard(
              label: 'Total Spend',
              value: '₹${(summary.totalFuelCost / 1000).toStringAsFixed(1)}k',
              icon: Icons.currency_rupee_rounded,
              color: _gold,
            ),
            const SizedBox(width: 12),
            _KpiCard(
              label: 'Total Volume',
              value: '${totalVolume.toStringAsFixed(0)} L',
              icon: Icons.local_gas_station_rounded,
              color: _silver,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _KpiCard(
              label: 'Avg Efficiency',
              value: summary.avgEfficiencyLper100km == null
                  ? '--'
                  : '${summary.avgEfficiencyLper100km!.toStringAsFixed(1)} L/100km',
              icon: Icons.speed_rounded,
              color: _success,
            ),
            const SizedBox(width: 12),
            _KpiCard(
              label: 'Fill-ups',
              value: '${summary.totalFills}',
              icon: Icons.receipt_long_rounded,
              color: _warning,
            ),
          ],
        ),
      ],
    );
  }

  // ─── Monthly Spend Bar Chart ───────────────────────────────────────────────

  Widget _buildMonthlySpendChart(VehicleAnalyticsSummary summary) {
    if (summary.monthlyStats.isEmpty) {
      return _buildChartPlaceholder('No monthly data');
    }

    final entries = summary.monthlyStats;
    final maxY = entries.fold<double>(0, (m, e) => e.totalCost > m ? e.totalCost : m);
    final maxYRounded = ((maxY / 1000).ceil() * 1000).toDouble() + 1000;

    return Container(
      height: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxYRounded,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => const Color(0xFF262626),
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '₹${rod.toY.toStringAsFixed(0)}',
                  const TextStyle(
                    fontFamily: 'Inter',
                    color: _gold,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= entries.length) {
                    return const SizedBox.shrink();
                  }
                  final month = entries[index].month;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '${month.month}/${month.year % 100}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        color: _textSub,
                      ),
                    ),
                  );
                },
                reservedSize: 28,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 48,
                getTitlesWidget: (value, meta) {
                  if (value == 0) return const SizedBox.shrink();
                  return Text(
                    '₹${(value / 1000).toStringAsFixed(1)}k',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 9,
                      color: _textSub,
                    ),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            getDrawingHorizontalLine: (value) => FlLine(
              color: _border,
              strokeWidth: 1,
              dashArray: [4, 4],
            ),
            drawVerticalLine: false,
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(entries.length, (index) {
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: entries[index].totalCost,
                  gradient: const LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Color(0xFF8B6914), Color(0xFFD4AF37)],
                  ),
                  width: 22,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                ),
              ],
            );
          }),
        ),
        swapAnimationDuration: const Duration(milliseconds: 800),
        swapAnimationCurve: Curves.easeOutQuart,
      ),
    );
  }

  // ─── Efficiency Trend Line Chart ───────────────────────────────────────────

  Widget _buildEfficiencyTrendChart(VehicleAnalyticsSummary summary) {
    if (summary.efficiencyTrend.isEmpty) {
      return _buildChartPlaceholder('Not enough data for efficiency trend');
    }

    final trend = summary.efficiencyTrend;
    final spots = trend.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.efficiencyLper100km);
    }).toList();

    final minY = spots.fold<double>(double.infinity, (m, s) => s.y < m ? s.y : m);
    final maxY = spots.fold<double>(0, (m, s) => s.y > m ? s.y : m);
    final paddedMin = (minY - 1.0).clamp(0.0, double.infinity);
    final paddedMax = maxY + 1.0;

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: LineChart(
        LineChartData(
          minY: paddedMin,
          maxY: paddedMax,
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => const Color(0xFF262626),
              getTooltipItems: (spots) => spots
                  .map((s) => LineTooltipItem(
                        '${s.y.toStringAsFixed(1)} L/100km',
                        const TextStyle(
                          fontFamily: 'Inter',
                          color: _success,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ))
                  .toList(),
            ),
          ),
          gridData: FlGridData(
            show: true,
            getDrawingHorizontalLine: (v) =>
                FlLine(color: _border, strokeWidth: 1, dashArray: [4, 4]),
            drawVerticalLine: false,
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= trend.length) {
                    return const SizedBox.shrink();
                  }
                  final d = trend[index].filledAt;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '${d.day}/${d.month}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 9,
                        color: _textSub,
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 44,
                getTitlesWidget: (v, m) => Text(
                  '${v.toStringAsFixed(1)}L',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 9,
                    color: _textSub,
                  ),
                ),
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.4,
              color: _success,
              barWidth: 2.5,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                  radius: 3.5,
                  color: _success,
                  strokeWidth: 1.5,
                  strokeColor: _card,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _success.withOpacity(0.2),
                    _success.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeOutQuart,
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: _textPrimary,
      ),
    );
  }

  Widget _buildChartPlaceholder(String message) {
    return Container(
      height: 160,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            color: _textSub,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: _card,
                shape: BoxShape.circle,
                border: Border.all(color: _border),
              ),
              child: const Icon(Icons.bar_chart_rounded,
                  color: _gold, size: 44),
            ).animate().fadeIn(duration: 500.ms),
            const SizedBox(height: 24),
            const Text(
              'No data yet',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: _textPrimary,
              ),
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 8),
            const Text(
              'Add fuel entries to see\nanalytics and charts.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: _textSub,
                height: 1.6,
              ),
            ).animate().fadeIn(delay: 350.ms),
          ],
        ),
      ),
    );
  }
}

// ─── KPI Card ─────────────────────────────────────────────────────────────────

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  static const Color _card = Color(0xFF1A1A1A);
  static const Color _border = Color(0xFF262626);
  static const Color _textPrimary = Color(0xFFF5F5F5);
  static const Color _textSub = Color(0xFF9E9E9E);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 16),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _textSub,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: _textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
