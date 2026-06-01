// FuelIQ — Garage Providers
// Mock Riverpod providers for vehicle data

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../shared/models/models.dart';

part 'garage_provider.g.dart';

// ─── Mock data ────────────────────────────────────────────────────────────────

final _mockVehicles = [
  const Vehicle(
    id: 'v001',
    make: 'BMW',
    model: '3 Series',
    year: 2023,
    fuelType: FuelType.petrol,
    vehicleType: VehicleType.car,
    licensePlate: 'MH 01 AB 1234',
    color: 'Alpine White',
    tankCapacityLiters: 59,
    initialOdometer: 0,
    currentOdometer: 24850,
    isPrimary: true,
    isArchived: false,
    createdAt: DateTime(2023, 1, 15),
    totalDistanceKm: 24850,
    totalFuelCost: 112400,
    avgEfficiencyLper100km: 9.2,
  ),
  const Vehicle(
    id: 'v002',
    make: 'Royal Enfield',
    model: 'Classic 350',
    year: 2022,
    fuelType: FuelType.petrol,
    vehicleType: VehicleType.motorcycle,
    licensePlate: 'MH 02 XY 5678',
    color: 'Stealth Black',
    tankCapacityLiters: 13.5,
    initialOdometer: 0,
    currentOdometer: 8420,
    isPrimary: false,
    isArchived: false,
    createdAt: DateTime(2022, 6, 10),
    totalDistanceKm: 8420,
    totalFuelCost: 18600,
    avgEfficiencyLper100km: 4.1,
  ),
];

// ─── Garage State ─────────────────────────────────────────────────────────────

class GarageState {
  const GarageState({
    this.vehicles = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
    this.filterFuelType,
  });

  final List<Vehicle> vehicles;
  final bool isLoading;
  final String? error;
  final String searchQuery;
  final FuelType? filterFuelType;

  List<Vehicle> get filteredVehicles {
    var result = vehicles.where((v) => !v.isArchived).toList();
    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      result = result
          .where((v) =>
              v.make.toLowerCase().contains(q) ||
              v.model.toLowerCase().contains(q) ||
              (v.licensePlate?.toLowerCase().contains(q) ?? false))
          .toList();
    }
    if (filterFuelType != null) {
      result = result.where((v) => v.fuelType == filterFuelType).toList();
    }
    return result;
  }

  GarageState copyWith({
    List<Vehicle>? vehicles,
    bool? isLoading,
    String? error,
    String? searchQuery,
    FuelType? filterFuelType,
    bool clearFilter = false,
  }) {
    return GarageState(
      vehicles: vehicles ?? this.vehicles,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
      filterFuelType: clearFilter ? null : (filterFuelType ?? this.filterFuelType),
    );
  }
}

// ─── Garage Notifier ──────────────────────────────────────────────────────────

@riverpod
class GarageNotifier extends _$GarageNotifier {
  @override
  GarageState build() {
    _loadVehicles();
    return const GarageState(isLoading: true);
  }

  Future<void> _loadVehicles() async {
    await Future.delayed(const Duration(milliseconds: 800));
    state = GarageState(vehicles: _mockVehicles);
  }

  Future<void> addVehicle(Vehicle vehicle) async {
    state = state.copyWith(isLoading: true);
    await Future.delayed(const Duration(milliseconds: 600));
    final updated = [...state.vehicles, vehicle];
    state = GarageState(vehicles: updated);
  }

  Future<void> deleteVehicle(String vehicleId) async {
    final updated = state.vehicles.map((v) {
      if (v.id == vehicleId) return v.copyWith(isArchived: true);
      return v;
    }).toList();
    state = state.copyWith(vehicles: updated);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setFilter(FuelType? fuelType) {
    if (fuelType == null) {
      state = state.copyWith(clearFilter: true);
    } else {
      state = state.copyWith(filterFuelType: fuelType);
    }
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);
    await Future.delayed(const Duration(milliseconds: 600));
    state = GarageState(vehicles: _mockVehicles);
  }
}

// ─── Single vehicle provider ──────────────────────────────────────────────────

@riverpod
Vehicle? vehicleById(VehicleByIdRef ref, String vehicleId) {
  final state = ref.watch(garageNotifierProvider);
  try {
    return state.vehicles.firstWhere((v) => v.id == vehicleId);
  } catch (_) {
    return null;
  }
}

// ─── Health Score (mock derived) ─────────────────────────────────────────────

int vehicleHealthScore(Vehicle vehicle) {
  final odometer = vehicle.currentOdometer;
  if (odometer < 10000) return 95;
  if (odometer < 30000) return 82;
  if (odometer < 60000) return 70;
  if (odometer < 100000) return 58;
  return 45;
}
