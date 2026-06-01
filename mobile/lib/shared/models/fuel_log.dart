import 'package:freezed_annotation/freezed_annotation.dart';

part 'fuel_log.freezed.dart';
part 'fuel_log.g.dart';

@freezed
class FuelLog with _$FuelLog {
  const factory FuelLog({
    required String id,
    required String vehicleId,
    required double odometerReading,
    required double volumeLiters,
    required double pricePerLiter,
    required double totalCost,
    double? efficiencyLper100km,
    double? efficiencyKmperliter,
    double? distanceSinceLast,
    required bool isFullTank,
    String? stationName,
    String? fuelBrand,
    String? receiptUrl,
    required String loggedVia,
    String? notes,
    required DateTime filledAt,
    required DateTime createdAt,
  }) = _FuelLog;

  factory FuelLog.fromJson(Map<String, dynamic> json) => _$FuelLogFromJson(json);
}
