import 'enums.dart';

// ─── Reminder ─────────────────────────────────────────────────────────────────

class Reminder {
  const Reminder({
    required this.id,
    required this.vehicleId,
    required this.title,
    this.description,
    this.serviceType,
    required this.reminderType,
    this.remindAt,
    this.remindAtOdometer,
    required this.status,
    required this.isRecurring,
    this.recurrenceIntervalDays,
    this.completedAt,
    required this.createdAt,
  });

  final String id;
  final String vehicleId;
  final String title;
  final String? description;
  final ServiceType? serviceType;
  final ReminderType reminderType;
  final DateTime? remindAt;
  final double? remindAtOdometer;
  final ReminderStatus status;
  final bool isRecurring;
  final int? recurrenceIntervalDays;
  final DateTime? completedAt;
  final DateTime createdAt;
}

// ─── Analytics ────────────────────────────────────────────────────────────────

class MonthlyFuelStat {
  const MonthlyFuelStat({
    required this.month,
    required this.totalCost,
    required this.totalLiters,
    this.avgEfficiencyLper100km,
    required this.fillCount,
  });

  final DateTime month;
  final double totalCost;
  final double totalLiters;
  final double? avgEfficiencyLper100km;
  final int fillCount;
}

class EfficiencyTrendPoint {
  const EfficiencyTrendPoint({
    required this.filledAt,
    required this.efficiencyLper100km,
    required this.efficiencyKmperliter,
    required this.odometerReading,
  });

  final DateTime filledAt;
  final double efficiencyLper100km;
  final double efficiencyKmperliter;
  final double odometerReading;
}

class ExpenseBreakdown {
  const ExpenseBreakdown({
    required this.category,
    required this.totalAmount,
    required this.transactionCount,
    required this.percentage,
  });

  final ExpenseCategory category;
  final double totalAmount;
  final int transactionCount;
  final double percentage;
}

class VehicleAnalytics {
  const VehicleAnalytics({
    required this.vehicleId,
    required this.totalDistanceKm,
    required this.totalFuelCost,
    required this.totalOtherExpenses,
    required this.totalServiceCost,
    required this.totalCostOfOwnership,
    this.avgEfficiencyLper100km,
    this.costPerKm,
    required this.totalFills,
    required this.monthlyStats,
    required this.efficiencyTrend,
    required this.expenseBreakdown,
  });

  final String vehicleId;
  final double totalDistanceKm;
  final double totalFuelCost;
  final double totalOtherExpenses;
  final double totalServiceCost;
  final double totalCostOfOwnership;
  final double? avgEfficiencyLper100km;
  final double? costPerKm;
  final int totalFills;
  final List<MonthlyFuelStat> monthlyStats;
  final List<EfficiencyTrendPoint> efficiencyTrend;
  final List<ExpenseBreakdown> expenseBreakdown;
}

// ─── OCR ──────────────────────────────────────────────────────────────────────

class ParsedReceiptData {
  const ParsedReceiptData({
    this.volumeLiters,
    this.pricePerLiter,
    this.totalAmount,
    this.date,
    this.stationName,
    this.volumeConfidence = 0.0,
    this.priceConfidence = 0.0,
    this.totalConfidence = 0.0,
    this.dateConfidence = 0.0,
  });

  final double? volumeLiters;
  final double? pricePerLiter;
  final double? totalAmount;
  final DateTime? date;
  final String? stationName;
  final double volumeConfidence;
  final double priceConfidence;
  final double totalConfidence;
  final double dateConfidence;
}

// ─── Paginated Response ───────────────────────────────────────────────────────

class PaginatedResult<T> {
  const PaginatedResult({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.totalPages,
  });

  final List<T> items;
  final int total;
  final int page;
  final int pageSize;
  final int totalPages;
}
