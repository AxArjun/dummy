// FuelIQ — Fuel History Screen
// Complete fuel log timeline

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/fuel_provider.dart';
import '../../../../shared/models/models.dart';

class FuelHistoryScreen extends ConsumerWidget {
  const FuelHistoryScreen({super.key, required this.vehicleId});

  final String vehicleId;

  static const Color _bg = Color(0xFF0B0B0B);
  static const Color _card = Color(0xFF1A1A1A);
  static const Color _border = Color(0xFF262626);
  static const Color _gold = Color(0xFFD4AF37);
  static const Color _silver = Color(0xFFC0C0C0);
  static const Color _textPrimary = Color(0xFFF5F5F5);
  static const Color _textSub = Color(0xFF9E9E9E);
  static const Color _success = Color(0xFF4CAF50);
  static const Color _warning = Color(0xFFFF9800);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fuelState = ref.watch(fuelNotifierProvider(vehicleId));
    final logs = fuelState.valueOrNull ?? [];

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
          'Fuel History',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: _textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_rounded,
                color: _gold, size: 26),
            onPressed: () => context.go('/garage/$vehicleId/add-fuel'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        color: _gold,
        backgroundColor: _card,
        onRefresh: () =>
            ref.read(fuelNotifierProvider(vehicleId).notifier).refresh(),
        child: fuelState.isLoading
            ? const Center(
                child: CircularProgressIndicator(
                    color: _gold, strokeWidth: 2.5))
            : logs.isEmpty
                ? _buildEmptyState(context)
                : CustomScrollView(
                    slivers: [
                      // ── Summary cards ────────────────────────────────
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: _buildSummaryRow(logs),
                        ),
                      ),

                      // ── Section header ───────────────────────────────
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          child: Text(
                            '${logs.length} entries',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              color: _textSub,
                            ),
                          ),
                        ),
                      ),

                      // ── Fuel log list ────────────────────────────────
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final log = logs[index];
                              return Padding(
                                padding:
                                    const EdgeInsets.only(bottom: 12),
                                child: _FuelLogCard(log: log)
                                    .animate()
                                    .fadeIn(
                                        delay: Duration(
                                            milliseconds: 60 * index),
                                        duration: 400.ms)
                                    .slideX(begin: 0.1, end: 0),
                              );
                            },
                            childCount: logs.length,
                          ),
                        ),
                      ),

                      const SliverToBoxAdapter(
                          child: SizedBox(height: 100)),
                    ],
                  ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/garage/$vehicleId/add-fuel'),
        backgroundColor: _gold,
        foregroundColor: const Color(0xFF0B0B0B),
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Add Fuel',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(List<FuelLog> logs) {
    final totalCost =
        logs.fold<double>(0, (sum, l) => sum + l.totalCost);
    final totalVolume =
        logs.fold<double>(0, (sum, l) => sum + l.volumeLiters);
    final avgEfficiency = logs
        .where((l) => l.efficiencyLper100km != null)
        .map((l) => l.efficiencyLper100km!)
        .fold<double>(0, (a, b) => a + b);
    final effCount = logs
        .where((l) => l.efficiencyLper100km != null)
        .length;
    final avgEff = effCount > 0 ? avgEfficiency / effCount : 0.0;

    return Row(
      children: [
        _SummaryMini(
          label: 'Total Spend',
          value: '₹${(totalCost / 1000).toStringAsFixed(1)}k',
          icon: Icons.currency_rupee_rounded,
          color: _gold,
        ),
        const SizedBox(width: 10),
        _SummaryMini(
          label: 'Total Volume',
          value: '${totalVolume.toStringAsFixed(0)} L',
          icon: Icons.local_gas_station_rounded,
          color: _silver,
        ),
        const SizedBox(width: 10),
        _SummaryMini(
          label: 'Avg Efficiency',
          value: effCount > 0
              ? '${avgEff.toStringAsFixed(1)} L/100'
              : '--',
          icon: Icons.speed_rounded,
          color: _success,
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
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
              child: const Icon(Icons.local_gas_station_outlined,
                  color: _gold, size: 44),
            ).animate().fadeIn(duration: 500.ms),
            const SizedBox(height: 24),
            const Text(
              'No fuel entries',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: _textPrimary,
              ),
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 8),
            const Text(
              'Start logging your fuel fills\nto track costs and efficiency.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: _textSub,
                height: 1.6,
              ),
            ).animate().fadeIn(delay: 350.ms),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () =>
                  context.go('/garage/$vehicleId/add-fuel'),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add First Entry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _gold,
                foregroundColor: const Color(0xFF0B0B0B),
                minimumSize: const Size(190, 48),
                textStyle: const TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                ),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ).animate().fadeIn(delay: 500.ms),
          ],
        ),
      ),
    );
  }
}

// ─── Fuel Log Card ────────────────────────────────────────────────────────────

class _FuelLogCard extends StatelessWidget {
  const _FuelLogCard({required this.log});

  final FuelLog log;

  static const Color _card = Color(0xFF1A1A1A);
  static const Color _border = Color(0xFF262626);
  static const Color _gold = Color(0xFFD4AF37);
  static const Color _textPrimary = Color(0xFFF5F5F5);
  static const Color _textSub = Color(0xFF9E9E9E);
  static const Color _success = Color(0xFF4CAF50);
  static const Color _warning = Color(0xFFFF9800);

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final efficiency = log.efficiencyLper100km;

    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border, width: 1),
      ),
      child: Column(
        children: [
          // ── Header ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _gold.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.local_gas_station_rounded,
                      color: _gold, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        log.stationName ?? 'Fuel Station',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _formatDate(log.filledAt),
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: _textSub,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${log.totalCost.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: _gold,
                      ),
                    ),
                    if (log.isFullTank)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'FULL',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: _success,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // ── Stats row ─────────────────────────────────────────────
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF0F0F0F),
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(16)),
              border: Border(
                  top: BorderSide(color: _border, width: 1)),
            ),
            child: Row(
              children: [
                _MiniStat(
                    label: 'Volume',
                    value: '${log.volumeLiters.toStringAsFixed(1)} L'),
                _Divider(),
                _MiniStat(
                    label: 'Odometer',
                    value:
                        '${log.odometerReading.toStringAsFixed(0)} km'),
                _Divider(),
                _MiniStat(
                    label: 'Price/L',
                    value:
                        '₹${log.pricePerLiter.toStringAsFixed(1)}'),
                _Divider(),
                _MiniStat(
                    label: 'Efficiency',
                    value: efficiency != null
                        ? '${efficiency.toStringAsFixed(1)} L/100'
                        : '--',
                    color: efficiency != null
                        ? (efficiency < 8 ? _success : _warning)
                        : _textSub),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value, this.color});

  final String label;
  final String value;
  final Color? color;

  static const Color _textPrimary = Color(0xFFF5F5F5);
  static const Color _textSub = Color(0xFF9E9E9E);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color ?? _textPrimary,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              color: _textSub,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
        width: 1,
        height: 28,
        color: const Color(0xFF262626),
        margin: const EdgeInsets.symmetric(horizontal: 2));
  }
}

class _SummaryMini extends StatelessWidget {
  const _SummaryMini({
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
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 10,
                color: _textSub,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
