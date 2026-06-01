// FuelIQ — Freezed Domain Models
// Immutable data models with JSON serialization

import 'package:freezed_annotation/freezed_annotation.dart';

part 'models.freezed.dart';
part 'models.g.dart';

// ─── Enums ────────────────────────────────────────────────────────────────────

enum FuelType {
  petrol, diesel, cng, electric, hybrid, lpg
}

enum VehicleType {
  car, motorcycle, scooter, truck, van, bus, other
}

enum ExpenseCategory {
  fuel, maintenance, insurance, tax, toll, parking, accessories, repair, cleaning, other
}

enum ServiceType {
  oilChange, tireRotation, brakeService, airFilter, fuelFilter,
  sparkPlugs, battery, coolant, transmission, generalInspection,
  acService, wheelAlignment, other
}

enum ReminderType { dateBased, odometerBased }
enum ReminderStatus { pending, notified, completed, dismissed, overdue }
enum NotificationType {
  serviceReminder, serviceOverdue, weeklySummary, monthlyReport, anomalyAlert, system
}
enum DistanceUnit { km, miles }
enum VolumeUnit { liters, gallons }

// ─── User ─────────────────────────────────────────────────────────────────────

@freezed
class User with _$User {
  const factory User({
    required String id,
    required String clerkId,
    required String email,
    String? displayName,
    String? avatarUrl,
    @Default(DistanceUnit.km) DistanceUnit distanceUnit,
    @Default(VolumeUnit.liters) VolumeUnit volumeUnit,
    @Default('INR') String currency,
    @Default('Asia/Kolkata') String timezone,
    required DateTime createdAt,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}

// ─── Vehicle ──────────────────────────────────────────────────────────────────

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
    // Analytics (from materialized view)
    double? totalDistanceKm,
    double? totalFuelCost,
    double? avgEfficiencyLper100km,
  }) = _Vehicle;

  factory Vehicle.fromJson(Map<String, dynamic> json) => _$VehicleFromJson(json);
}

// ─── Fuel Log ─────────────────────────────────────────────────────────────────

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

// ─── Expense ──────────────────────────────────────────────────────────────────

@freezed
class Expense with _$Expense {
  const factory Expense({
    required String id,
    required String vehicleId,
    required ExpenseCategory category,
    required double amount,
    required String currency,
    String? description,
    String? vendorName,
    double? odometerReading,
    String? receiptUrl,
    required DateTime expenseDate,
    required DateTime createdAt,
  }) = _Expense;

  factory Expense.fromJson(Map<String, dynamic> json) => _$ExpenseFromJson(json);
}

// ─── Service Record ───────────────────────────────────────────────────────────

@freezed
class ServiceRecord with _$ServiceRecord {
  const factory ServiceRecord({
    required String id,
    required String vehicleId,
    required ServiceType serviceType,
    required DateTime serviceDate,
    double? odometerReading,
    double? cost,
    required String currency,
    String? shopName,
    String? description,
    List<Map<String, String>>? partsReplaced,
    String? receiptUrl,
    required DateTime createdAt,
  }) = _ServiceRecord;

  factory ServiceRecord.fromJson(Map<String, dynamic> json) => _$ServiceRecordFromJson(json);
}

// ─── Reminder ─────────────────────────────────────────────────────────────────

@freezed
class Reminder with _$Reminder {
  const factory Reminder({
    required String id,
    required String vehicleId,
    required String title,
    String? description,
    ServiceType? serviceType,
    required ReminderType reminderType,
    DateTime? remindAt,
    double? remindAtOdometer,
    required ReminderStatus status,
    required bool isRecurring,
    int? recurrenceIntervalDays,
    DateTime? completedAt,
    required DateTime createdAt,
  }) = _Reminder;

  factory Reminder.fromJson(Map<String, dynamic> json) => _$ReminderFromJson(json);
}

// ─── Notification ─────────────────────────────────────────────────────────────

@freezed
class AppNotification with _$AppNotification {
  const factory AppNotification({
    required String id,
    required NotificationType notificationType,
    required String title,
    required String body,
    Map<String, dynamic>? metadata,
    String? actionUrl,
    required bool isRead,
    DateTime? readAt,
    required DateTime createdAt,
  }) = _AppNotification;

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      _$AppNotificationFromJson(json);
}

// ─── Analytics ────────────────────────────────────────────────────────────────

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
    required ExpenseCategory category,
    required double totalAmount,
    required int transactionCount,
    required double percentage,
  }) = _ExpenseBreakdown;

  factory ExpenseBreakdown.fromJson(Map<String, dynamic> json) =>
      _$ExpenseBreakdownFromJson(json);
}

@freezed
class VehicleAnalytics with _$VehicleAnalytics {
  const factory VehicleAnalytics({
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
  }) = _VehicleAnalytics;

  factory VehicleAnalytics.fromJson(Map<String, dynamic> json) =>
      _$VehicleAnalyticsFromJson(json);
}

// ─── OCR ──────────────────────────────────────────────────────────────────────

@freezed
class ParsedReceiptData with _$ParsedReceiptData {
  const factory ParsedReceiptData({
    double? volumeLiters,
    double? pricePerLiter,
    double? totalAmount,
    DateTime? date,
    String? stationName,
    @Default(0.0) double volumeConfidence,
    @Default(0.0) double priceConfidence,
    @Default(0.0) double totalConfidence,
    @Default(0.0) double dateConfidence,
  }) = _ParsedReceiptData;

  factory ParsedReceiptData.fromJson(Map<String, dynamic> json) =>
      _$ParsedReceiptDataFromJson(json);
}

// ─── Paginated Response ───────────────────────────────────────────────────────

@freezed
class PaginatedResult<T> with _$PaginatedResult<T> {
  const factory PaginatedResult({
    required List<T> items,
    required int total,
    required int page,
    required int pageSize,
    required int totalPages,
  }) = _PaginatedResult;
}
