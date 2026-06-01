import 'package:freezed_annotation/freezed_annotation.dart';
import 'enums.dart';

part 'vehicle.freezed.dart';
part 'vehicle.g.dart';

@freezed
class Vehicle with _$Vehicle {
  const factory Vehicle({
    required String id,
    required String make,
    required String model,
    required int year,
    required FuelType fuelType,
    required VehicleType vehicleType,
    String? licensePlate,
    String? color,
    double? tankCapacityLiters,
    required double initialOdometer,
    required double currentOdometer,
    String? photoUrl,
    required bool isPrimary,
    required bool isArchived,
    required DateTime createdAt,
    double? totalDistanceKm,
    double? totalFuelCost,
    double? avgEfficiencyLper100km,
  }) = _Vehicle;

  factory Vehicle.fromJson(Map<String, dynamic> json) => _$VehicleFromJson(json);
}
