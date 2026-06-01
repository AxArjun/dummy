import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/models.dart';

class VehicleRepository {
  Future<List<Vehicle>> getVehicles() async {
    await Future.delayed(const Duration(milliseconds: 800));
    return [
      Vehicle(
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
      Vehicle(
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
  }

  Future<Vehicle> addVehicle(Vehicle vehicle) async {
    await Future.delayed(const Duration(milliseconds: 600));
    return vehicle;
  }

  Future<void> deleteVehicle(String id) async {
    await Future.delayed(const Duration(milliseconds: 600));
  }
}

final vehicleRepositoryProvider = Provider<VehicleRepository>((ref) {
  return VehicleRepository();
});
