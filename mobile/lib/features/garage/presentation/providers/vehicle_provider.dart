import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/models.dart';
import '../data/vehicle_repository.dart';

// ─── Search and Filter State ──────────────────────────────────────────────────

final vehicleSearchQueryProvider = StateProvider.autoDispose<String>((ref) => '');
final vehicleFilterProvider = StateProvider.autoDispose<FuelType?>((ref) => null);

// ─── Vehicle List Notifier ────────────────────────────────────────────────────

class VehicleListNotifier extends AutoDisposeAsyncNotifier<List<Vehicle>> {
  @override
  Future<List<Vehicle>> build() async {
    return ref.read(vehicleRepositoryProvider).getVehicles();
  }

  Future<void> addVehicle(Vehicle vehicle) async {
    // Keep previous state while loading
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(vehicleRepositoryProvider);
      await repo.addVehicle(vehicle);
      // Fetch fresh list
      return repo.getVehicles();
    });
  }

  Future<void> deleteVehicle(String id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(vehicleRepositoryProvider);
      await repo.deleteVehicle(id);
      return repo.getVehicles();
    });
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(vehicleRepositoryProvider).getVehicles());
  }
}

final vehicleListProvider = AutoDisposeAsyncNotifierProvider<VehicleListNotifier, List<Vehicle>>(() {
  return VehicleListNotifier();
});

// ─── Filtered Vehicles Provider ───────────────────────────────────────────────

class GarageScreenState {
  final AsyncValue<List<Vehicle>> vehiclesState;
  final String searchQuery;
  final FuelType? filterFuelType;

  const GarageScreenState({
    required this.vehiclesState,
    required this.searchQuery,
    this.filterFuelType,
  });

  List<Vehicle> get filteredVehicles {
    final list = vehiclesState.valueOrNull ?? [];
    var result = list.where((v) => !v.isArchived).toList();
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
}

final garageScreenStateProvider = Provider.autoDispose<GarageScreenState>((ref) {
  final vehiclesState = ref.watch(vehicleListProvider);
  final searchQuery = ref.watch(vehicleSearchQueryProvider);
  final filterFuelType = ref.watch(vehicleFilterProvider);

  return GarageScreenState(
    vehiclesState: vehiclesState,
    searchQuery: searchQuery,
    filterFuelType: filterFuelType,
  );
});

// ─── Single vehicle provider ──────────────────────────────────────────────────

final vehicleByIdProvider = AutoDisposeProviderFamily<Vehicle?, String>((ref, vehicleId) {
  final vehiclesState = ref.watch(vehicleListProvider);
  final list = vehiclesState.valueOrNull ?? [];
  try {
    return list.firstWhere((v) => v.id == vehicleId);
  } catch (_) {
    return null;
  }
});

// ─── Health Score (mock derived) ─────────────────────────────────────────────

int vehicleHealthScore(Vehicle vehicle) {
  final odometer = vehicle.currentOdometer;
  if (odometer < 10000) return 95;
  if (odometer < 30000) return 82;
  if (odometer < 60000) return 70;
  if (odometer < 100000) return 58;
  return 45;
}
