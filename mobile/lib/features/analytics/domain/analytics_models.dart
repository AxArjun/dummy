import 'package:freezed_annotation/freezed_annotation.dart';

part 'analytics_models.freezed.dart';
part 'analytics_models.g.dart';

@freezed
class MonthlyFuelStat with _$MonthlyFuelStat {
  const factory MonthlyFuelStat({
    required DateTime month,
    required double totalCost,
    required double totalLiters,
    double? avgEfficiencyLper100km,
    required int fillCount,
  }) = _MonthlyFuelStat;

  factory MonthlyFuelStat.fromJson(Map<String, dynamic> json) =>
      _$MonthlyFuelStatFromJson(json);
}

@freezed
class EfficiencyTrendPoint with _$EfficiencyTrendPoint {
  const factory EfficiencyTrendPoint({
    required DateTime filledAt,
    required double efficiencyLper100km,
    required double efficiencyKmperliter,
    required double odometerReading,
  }) = _EfficiencyTrendPoint;

  factory EfficiencyTrendPoint.fromJson(Map<String, dynamic> json) =>
      _$EfficiencyTrendPointFromJson(json);
}

@freezed
class ExpenseBreakdown with _$ExpenseBreakdown {
  const factory ExpenseBreakdown({
    required String category,
    required double totalAmount,
    required int transactionCount,
    required double percentage,
  }) = _ExpenseBreakdown;

  factory ExpenseBreakdown.fromJson(Map<String, dynamic> json) =>
      _$ExpenseBreakdownFromJson(json);
}

@freezed
class VehicleAnalyticsSummary with _$VehicleAnalyticsSummary {
  const factory VehicleAnalyticsSummary({
    required String vehicleId,
    required double totalDistanceKm,
    required double totalFuelCost,
    required double totalOtherExpenses,
    required double totalServiceCost,
    required double totalCostOfOwnership,
    double? avgEfficiencyLper100km,
    double? costPerKm,
    required int totalFills,
    required List<MonthlyFuelStat> monthlyStats,
    required List<EfficiencyTrendPoint> efficiencyTrend,
    required List<ExpenseBreakdown> expenseBreakdown,
  }) = _VehicleAnalyticsSummary;

  factory VehicleAnalyticsSummary.fromJson(Map<String, dynamic> json) =>
      _$VehicleAnalyticsSummaryFromJson(json);
}