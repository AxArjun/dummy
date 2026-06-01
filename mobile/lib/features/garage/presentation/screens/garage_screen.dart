// FuelIQ — Garage Screen
// Premium vehicle management hub

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/garage_provider.dart';
import '../../../../core/router/app_router.dart';
import '../../../../shared/models/models.dart';

class GarageScreen extends ConsumerStatefulWidget {
  const GarageScreen({super.key});

  @override
  ConsumerState<GarageScreen> createState() => _GarageScreenState();
}

class _GarageScreenState extends ConsumerState<GarageScreen> {
  final _searchController = TextEditingController();

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
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final garageState = ref.watch(garageNotifierProvider);

    return Scaffold(
      backgroundColor: _bg,
      body: RefreshIndicator(
        color: _gold,
        backgroundColor: _card,
        onRefresh: () => ref.read(garageNotifierProvider.notifier).refresh(),
        child: CustomScrollView(
          slivers: [
            // ── App Bar ──────────────────────────────────────────────────
            SliverAppBar(
              backgroundColor: _bg,
              floating: true,
              snap: true,
              title: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(
                        colors: [Color(0xFFD4AF37), Color(0xFF8B6914)],
                      ),
                    ),
                    child: const Icon(
                        Icons.local_gas_station_rounded,
                        color: Color(0xFF0B0B0B),
                        size: 16),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'My Garage',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: _textPrimary,
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.add_circle_rounded,
                      color: _gold, size: 28),
                  onPressed: () => context.go(AppRoutes.addVehicle),
                ),
                const SizedBox(width: 8),
              ],
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    // ── Search bar ─────────────────────────────────────
                    _buildSearchBar(garageState),
                    const SizedBox(height: 12),

                    // ── Filter chips ───────────────────────────────────
                    _buildFilterChips(garageState),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),

            // ── Vehicle list ─────────────────────────────────────────
            if (garageState.isLoading)
              SliverFillRemaining(child: _buildLoadingState())
            else if (garageState.filteredVehicles.isEmpty)
              SliverFillRemaining(child: _buildEmptyState())
            else
              SliverPadding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final vehicle = garageState.filteredVehicles[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _VehicleCard(vehicle: vehicle)
                            .animate()
                            .fadeIn(
                                delay: Duration(milliseconds: 80 * index),
                                duration: 400.ms)
                            .slideY(begin: 0.15, end: 0),
                      );
                    },
                    childCount: garageState.filteredVehicles.length,
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
      floatingActionButton: garageState.isLoading
          ? null
          : FloatingActionButton.extended(
              onPressed: () => context.go(AppRoutes.addVehicle),
              backgroundColor: _gold,
              foregroundColor: const Color(0xFF0B0B0B),
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Add Vehicle',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ).animate().scale(
              begin: const Offset(0, 0),
              end: const Offset(1, 1),
              curve: Curves.easeOutBack,
              delay: 600.ms,
            ),
    );
  }

  Widget _buildSearchBar(GarageState garageState) {
    return TextField(
      controller: _searchController,
      onChanged: (query) =>
          ref.read(garageNotifierProvider.notifier).setSearchQuery(query),
      style: const TextStyle(
        fontFamily: 'Inter',
        color: _textPrimary,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        hintText: 'Search vehicles...',
        hintStyle: const TextStyle(color: _textSub, fontSize: 14),
        fillColor: _card,
        filled: true,
        prefixIcon: const Icon(Icons.search_rounded, color: _textSub, size: 20),
        suffixIcon: garageState.searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.close_rounded,
                    color: _textSub, size: 18),
                onPressed: () {
                  _searchController.clear();
                  ref
                      .read(garageNotifierProvider.notifier)
                      .setSearchQuery('');
                },
              )
            : null,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _gold, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildFilterChips(GarageState garageState) {
    final fuelTypes = [null, FuelType.petrol, FuelType.diesel, FuelType.electric, FuelType.cng];
    final labels = ['All', 'Petrol', 'Diesel', 'Electric', 'CNG'];

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: fuelTypes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final isSelected = garageState.filterFuelType == fuelTypes[index];
          return GestureDetector(
            onTap: () => ref
                .read(garageNotifierProvider.notifier)
                .setFilter(fuelTypes[index]),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? _gold : _card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? _gold : _border,
                  width: 1,
                ),
              ),
              child: Text(
                labels[index],
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? const Color(0xFF0B0B0B) : _textSub,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(color: _gold, strokeWidth: 2.5),
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
              child: const Icon(
                Icons.garage_outlined,
                color: _gold,
                size: 44,
              ),
            )
                .animate()
                .fadeIn(duration: 500.ms)
                .scale(begin: const Offset(0.5, 0.5), end: const Offset(1, 1)),
            const SizedBox(height: 24),
            const Text(
              'No vehicles yet',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: _textPrimary,
              ),
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 8),
            const Text(
              'Add your first vehicle to start\ntracking fuel and analytics.',
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
              onPressed: () => context.go(AppRoutes.addVehicle),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add Vehicle'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _gold,
                foregroundColor: const Color(0xFF0B0B0B),
                minimumSize: const Size(180, 48),
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

// ─── Vehicle Card ─────────────────────────────────────────────────────────────

class _VehicleCard extends StatelessWidget {
  const _VehicleCard({required this.vehicle});

  final Vehicle vehicle;

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

  @override
  Widget build(BuildContext context) {
    final healthScore = vehicleHealthScore(vehicle);
    final healthColor = _healthColor(healthScore);

    return GestureDetector(
      onTap: () => context.go('/garage/${vehicle.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _border, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // ── Vehicle hero ─────────────────────────────────────────
            Container(
              height: 140,
              decoration: BoxDecoration(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: vehicle.isPrimary
                      ? [const Color(0xFF2C2100), const Color(0xFF1A1400)]
                      : [const Color(0xFF1E1E1E), const Color(0xFF141414)],
                ),
              ),
              child: Stack(
                children: [
                  // Vehicle icon
                  Center(
                    child: Icon(
                      vehicle.vehicleType == VehicleType.motorcycle ||
                              vehicle.vehicleType == VehicleType.scooter
                          ? Icons.two_wheeler_rounded
                          : Icons.directions_car_rounded,
                      size: 80,
                      color: vehicle.isPrimary
                          ? _gold.withOpacity(0.2)
                          : _silver.withOpacity(0.12),
                    ),
                  ),

                  // Primary badge
                  if (vehicle.isPrimary)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _gold.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: _gold.withOpacity(0.4), width: 1),
                        ),
                        child: const Text(
                          'PRIMARY',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: _gold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),

                  // Fuel type badge
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0B0B0B).withOpacity(0.6),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: _border, width: 1),
                      ),
                      child: Text(
                        _fuelTypeLabel(vehicle.fuelType),
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _silver,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),

                  // Health score
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: healthColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: healthColor.withOpacity(0.4),
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
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
                  ),
                ],
              ),
            ),

            // ── Vehicle info ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${vehicle.year} ${vehicle.make} ${vehicle.model}',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: _textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: _textSub,
                        size: 20,
                      ),
                    ],
                  ),

                  if (vehicle.licensePlate != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      vehicle.licensePlate!,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: _textSub,
                        letterSpacing: 1,
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // ── Stats row ───────────────────────────────────────
                  Row(
                    children: [
                      _StatChip(
                        icon: Icons.speed_rounded,
                        label: 'Odometer',
                        value:
                            '${(vehicle.currentOdometer / 1000).toStringAsFixed(1)}k km',
                      ),
                      const SizedBox(width: 10),
                      _StatChip(
                        icon: Icons.local_gas_station_rounded,
                        label: 'Efficiency',
                        value: vehicle.avgEfficiencyLper100km != null
                            ? '${vehicle.avgEfficiencyLper100km!.toStringAsFixed(1)} L/100km'
                            : '--',
                      ),
                      const SizedBox(width: 10),
                      _StatChip(
                        icon: Icons.currency_rupee_rounded,
                        label: 'Total Spend',
                        value: vehicle.totalFuelCost != null
                            ? '₹${(vehicle.totalFuelCost! / 1000).toStringAsFixed(1)}k'
                            : '--',
                      ),
                    ],
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

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  static const Color _card = Color(0xFF0F0F0F);
  static const Color _border = Color(0xFF1E1E1E);
  static const Color _gold = Color(0xFFD4AF37);
  static const Color _textPrimary = Color(0xFFF5F5F5);
  static const Color _textSub = Color(0xFF9E9E9E);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _border, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: _gold, size: 14),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
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
