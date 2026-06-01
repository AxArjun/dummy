// FuelIQ — Vehicle Detail Screen
// Full vehicle intelligence hub

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/vehicle_provider.dart';
import '../../../../shared/models/models.dart';
import '../../../fuel/presentation/providers/fuel_provider.dart';

class VehicleDetailScreen extends ConsumerWidget {
  const VehicleDetailScreen({super.key, required this.vehicleId});

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

  Color _healthColor(int score) {
    if (score >= 80) return _success;
    if (score >= 60) return _warning;
    return _danger;
  }

  String _fuelTypeLabel(FuelType t) {
    switch (t) {
      case FuelType.petrol:
        return 'Petrol';
      case FuelType.diesel:
        return 'Diesel';
      case FuelType.cng:
        return 'CNG';
      case FuelType.electric:
        return 'Electric';
      case FuelType.hybrid:
        return 'Hybrid';
      case FuelType.lpg:
        return 'LPG';
    }
  }

  String _vehicleTypeLabel(VehicleType t) {
    switch (t) {
      case VehicleType.car:
        return 'Car';
      case VehicleType.motorcycle:
        return 'Motorcycle';
      case VehicleType.scooter:
        return 'Scooter';
      case VehicleType.truck:
        return 'Truck';
      case VehicleType.van:
        return 'Van';
      case VehicleType.bus:
        return 'Bus';
      case VehicleType.other:
        return 'Other';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicle = ref.watch(vehicleByIdProvider(vehicleId));

    if (vehicle == null) {
      return Scaffold(
        backgroundColor: _bg,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, color: _danger, size: 56),
              const SizedBox(height: 16),
              const Text(
                'Vehicle Not Found',
                style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: _textPrimary),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => context.pop(),
                child: const Text('Go Back',
                    style: TextStyle(color: _gold, fontFamily: 'Inter')),
              ),
            ],
          ),
        ),
      );
    }

    final healthScore = vehicleHealthScore(vehicle);
    final healthColor = _healthColor(healthScore);
    final fuelLogs = ref.watch(fuelLogsProvider(vehicleId));
    final lastLog = fuelLogs.isEmpty ? null : fuelLogs.first;

    return Scaffold(
      backgroundColor: _bg,
      body: CustomScrollView(
        slivers: [
          // ── Hero App Bar ─────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            backgroundColor: _bg,
            leading: GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 16),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.add_circle_rounded,
                    color: _gold, size: 26),
                onPressed: () =>
                    context.go('/garage/$vehicleId/add-fuel'),
                tooltip: 'Add Fuel',
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _buildHeroBanner(vehicle, healthScore, healthColor),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Quick Action Buttons ─────────────────────────
                  _buildQuickActions(context),

                  const SizedBox(height: 24),

                  // ── Stats grid ───────────────────────────────────
                  _buildSectionHeader('Vehicle Stats'),
                  const SizedBox(height: 12),
                  _buildStatsGrid(vehicle, lastLog),

                  const SizedBox(height: 24),

                  // ── Specs ────────────────────────────────────────
                  _buildSectionHeader('Specifications'),
                  const SizedBox(height: 12),
                  _buildSpecCard(vehicle),

                  const SizedBox(height: 24),

                  // ── Recent fuel entries ──────────────────────────
                  _buildSectionHeader('Recent Fuel Entries',
                      action: TextButton(
                        onPressed: () => context
                            .go('/garage/$vehicleId/fuel-history'),
                        child: const Text('View All',
                            style: TextStyle(
                                fontFamily: 'Inter',
                                color: _gold,
                                fontWeight: FontWeight.w600,
                                fontSize: 13)),
                      )),
                  const SizedBox(height: 12),
                  _buildRecentFuel(fuelLogs),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroBanner(Vehicle vehicle, int healthScore, Color healthColor) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: vehicle.isPrimary
              ? [const Color(0xFF2C2100), const Color(0xFF0B0B0B)]
              : [const Color(0xFF1A1A1A), const Color(0xFF0B0B0B)],
        ),
      ),
      child: Stack(
        children: [
          Center(
            child: Icon(
              vehicle.vehicleType == VehicleType.motorcycle ||
                      vehicle.vehicleType == VehicleType.scooter
                  ? Icons.two_wheeler_rounded
                  : Icons.directions_car_rounded,
              size: 160,
              color: vehicle.isPrimary
                  ? _gold.withOpacity(0.08)
                  : _silver.withOpacity(0.06),
            ),
          ),
          Positioned(
            bottom: 24,
            left: 20,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${vehicle.year} ${vehicle.make}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: _textSub,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  vehicle.model,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (vehicle.licensePlate != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0B0B0B).withOpacity(0.7),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: _border, width: 1),
                        ),
                        child: Text(
                          vehicle.licensePlate!,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _silver,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: healthColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                              color: healthColor.withOpacity(0.5),
                              blurRadius: 6,
                              spreadRadius: 1),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$healthScore% Health',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: healthColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        _QuickAction(
          icon: Icons.local_gas_station_rounded,
          label: 'Add Fuel',
          onTap: () => context.go('/garage/$vehicleId/add-fuel'),
        ),
        const SizedBox(width: 10),
        _QuickAction(
          icon: Icons.history_rounded,
          label: 'Fuel History',
          onTap: () => context.go('/garage/$vehicleId/fuel-history'),
        ),
        const SizedBox(width: 10),
        _QuickAction(
          icon: Icons.bar_chart_rounded,
          label: 'Analytics',
          onTap: () => context.go('/garage/$vehicleId/analytics'),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, {Widget? action}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _textPrimary,
          ),
        ),
        if (action != null) action,
      ],
    );
  }

  Widget _buildStatsGrid(Vehicle vehicle, FuelLog? lastLog) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _StatCard(
          icon: Icons.speed_rounded,
          label: 'Odometer',
          value:
              '${vehicle.currentOdometer.toStringAsFixed(0)} km',
          color: _gold,
        ),
        _StatCard(
          icon: Icons.local_gas_station_rounded,
          label: 'Avg Efficiency',
          value: vehicle.avgEfficiencyLper100km != null
              ? '${vehicle.avgEfficiencyLper100km!.toStringAsFixed(1)} L/100km'
              : '--',
          color: const Color(0xFF4CAF50),
        ),
        _StatCard(
          icon: Icons.currency_rupee_rounded,
          label: 'Total Fuel Cost',
          value: vehicle.totalFuelCost != null
              ? '₹${(vehicle.totalFuelCost! / 1000).toStringAsFixed(1)}k'
              : '--',
          color: const Color(0xFFFF9800),
        ),
        _StatCard(
          icon: Icons.route_rounded,
          label: 'Total Distance',
          value: vehicle.totalDistanceKm != null
              ? '${(vehicle.totalDistanceKm! / 1000).toStringAsFixed(1)}k km'
              : '--',
          color: _silver,
        ),
      ],
    );
  }

  Widget _buildSpecCard(Vehicle vehicle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border, width: 1),
      ),
      child: Column(
        children: [
          _SpecRow(label: 'Make', value: vehicle.make),
          const Divider(color: _border, height: 20),
          _SpecRow(label: 'Model', value: vehicle.model),
          const Divider(color: _border, height: 20),
          _SpecRow(label: 'Year', value: vehicle.year.toString()),
          const Divider(color: _border, height: 20),
          _SpecRow(
              label: 'Type',
              value: _vehicleTypeLabel(vehicle.vehicleType)),
          const Divider(color: _border, height: 20),
          _SpecRow(
              label: 'Fuel Type',
              value: _fuelTypeLabel(vehicle.fuelType)),
          if (vehicle.tankCapacityLiters != null) ...[
            const Divider(color: _border, height: 20),
            _SpecRow(
                label: 'Tank Capacity',
                value: '${vehicle.tankCapacityLiters!.toStringAsFixed(0)} L'),
          ],
          if (vehicle.color != null) ...[
            const Divider(color: _border, height: 20),
            _SpecRow(label: 'Color', value: vehicle.color!),
          ],
        ],
      ),
    );
  }

  Widget _buildRecentFuel(List<FuelLog> logs) {
    if (logs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
        ),
        child: const Center(
          child: Text(
            'No fuel entries yet',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: _textSub,
            ),
          ),
        ),
      );
    }

    final recent = logs.take(3).toList();
    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: recent.length,
        separatorBuilder: (_, __) =>
            const Divider(color: _border, height: 1),
        itemBuilder: (context, index) {
          final log = recent[index];
          return ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _gold.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.local_gas_station_rounded,
                  color: _gold, size: 18),
            ),
            title: Text(
              '${log.volumeLiters.toStringAsFixed(1)} L · ₹${log.totalCost.toStringAsFixed(0)}',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _textPrimary,
              ),
            ),
            subtitle: Text(
              log.stationName ??
                  '${log.odometerReading.toStringAsFixed(0)} km odometer',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: _textSub,
              ),
            ),
            trailing: Text(
              '${log.filledAt.day}/${log.filledAt.month}',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: _textSub,
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Supporting Widgets ───────────────────────────────────────────────────────

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  static const Color _card = Color(0xFF1A1A1A);
  static const Color _border = Color(0xFF262626);
  static const Color _gold = Color(0xFFD4AF37);
  static const Color _textPrimary = Color(0xFFF5F5F5);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _border, width: 1),
          ),
          child: Column(
            children: [
              Icon(icon, color: _gold, size: 22),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  static const Color _card = Color(0xFF1A1A1A);
  static const Color _border = Color(0xFF262626);
  static const Color _textPrimary = Color(0xFFF5F5F5);
  static const Color _textSub = Color(0xFF9E9E9E);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: _textSub,
            ),
          ),
        ],
      ),
    );
  }
}

class _SpecRow extends StatelessWidget {
  const _SpecRow({required this.label, required this.value});

  final String label;
  final String value;

  static const Color _textPrimary = Color(0xFFF5F5F5);
  static const Color _textSub = Color(0xFF9E9E9E);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            color: _textSub,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _textPrimary,
          ),
        ),
      ],
    );
  }
}
