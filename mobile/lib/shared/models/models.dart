// FuelIQ — Domain Models
// Plain Dart immutable models (no code generation required)

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

class User {
  const User({
    required this.id,
    required this.clerkId,
    required this.email,
    this.displayName,
    this.avatarUrl,
    this.distanceUnit = DistanceUnit.km,
    this.volumeUnit = VolumeUnit.liters,
    this.currency = 'INR',
    this.timezone = 'Asia/Kolkata',
    required this.createdAt,
  });

  final String id;
  final String clerkId;
  final String email;
  final String? displayName;
  final String? avatarUrl;
  final DistanceUnit distanceUnit;
  final VolumeUnit volumeUnit;
  final String currency;
  final String timezone;
  final DateTime createdAt;

  User copyWith({
    String? id, String? clerkId, String? email, String? displayName,
    String? avatarUrl, DistanceUnit? distanceUnit, VolumeUnit? volumeUnit,
    String? currency, String? timezone, DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id, clerkId: clerkId ?? this.clerkId,
      email: email ?? this.email, displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      distanceUnit: distanceUnit ?? this.distanceUnit,
      volumeUnit: volumeUnit ?? this.volumeUnit,
      currency: currency ?? this.currency, timezone: timezone ?? this.timezone,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'] as String, clerkId: json['clerk_id'] as String,
    email: json['email'] as String,
    displayName: json['display_name'] as String?,
    avatarUrl: json['avatar_url'] as String?,
    createdAt: DateTime.parse(json['created_at'] as String),
  );
}

// ─── Vehicle ──────────────────────────────────────────────────────────────────

class Vehicle {
  const Vehicle({
    required this.id,
    required this.make,
    required this.model,
    required this.year,
    required this.fuelType,
    required this.vehicleType,
    this.licensePlate,
    this.color,
    this.tankCapacityLiters,
    required this.initialOdometer,
    required this.currentOdometer,
    this.photoUrl,
    required this.isPrimary,
    required this.isArchived,
    required this.createdAt,
    this.totalDistanceKm,
    this.totalFuelCost,
    this.avgEfficiencyLper100km,
  });

  final String id;
  final String make;
  final String model;
  final int year;
  final FuelType fuelType;
  final VehicleType vehicleType;
  final String? licensePlate;
  final String? color;
  final double? tankCapacityLiters;
  final double initialOdometer;
  final double currentOdometer;
  final String? photoUrl;
  final bool isPrimary;
  final bool isArchived;
  final DateTime createdAt;
  final double? totalDistanceKm;
  final double? totalFuelCost;
  final double? avgEfficiencyLper100km;

  Vehicle copyWith({
    String? id, String? make, String? model, int? year,
    FuelType? fuelType, VehicleType? vehicleType, String? licensePlate,
    String? color, double? tankCapacityLiters, double? initialOdometer,
    double? currentOdometer, String? photoUrl, bool? isPrimary,
    bool? isArchived, DateTime? createdAt, double? totalDistanceKm,
    double? totalFuelCost, double? avgEfficiencyLper100km,
  }) {
    return Vehicle(
      id: id ?? this.id, make: make ?? this.make, model: model ?? this.model,
      year: year ?? this.year, fuelType: fuelType ?? this.fuelType,
      vehicleType: vehicleType ?? this.vehicleType,
      licensePlate: licensePlate ?? this.licensePlate,
      color: color ?? this.color,
      tankCapacityLiters: tankCapacityLiters ?? this.tankCapacityLiters,
      initialOdometer: initialOdometer ?? this.initialOdometer,
      currentOdometer: currentOdometer ?? this.currentOdometer,
      photoUrl: photoUrl ?? this.photoUrl,
      isPrimary: isPrimary ?? this.isPrimary,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      totalDistanceKm: totalDistanceKm ?? this.totalDistanceKm,
      totalFuelCost: totalFuelCost ?? this.totalFuelCost,
      avgEfficiencyLper100km: avgEfficiencyLper100km ?? this.avgEfficiencyLper100km,
    );
  }

  factory Vehicle.fromJson(Map<String, dynamic> json) => Vehicle(
    id: json['id'] as String, make: json['make'] as String,
    model: json['model'] as String, year: json['year'] as int,
    fuelType: FuelType.petrol, vehicleType: VehicleType.car,
    initialOdometer: (json['initial_odometer'] as num).toDouble(),
    currentOdometer: (json['current_odometer'] as num).toDouble(),
    isPrimary: json['is_primary'] as bool? ?? false,
    isArchived: json['is_archived'] as bool? ?? false,
    createdAt: DateTime.parse(json['created_at'] as String),
  );
}

// ─── Fuel Log ─────────────────────────────────────────────────────────────────

class FuelLog {
  const FuelLog({
    required this.id,
    required this.vehicleId,
    required this.odometerReading,
    required this.volumeLiters,
    required this.pricePerLiter,
    required this.totalCost,
    this.efficiencyLper100km,
    this.efficiencyKmperliter,
    this.distanceSinceLast,
    required this.isFullTank,
    this.stationName,
    this.fuelBrand,
    this.receiptUrl,
    required this.loggedVia,
    this.notes,
    required this.filledAt,
    required this.createdAt,
  });

  final String id;
  final String vehicleId;
  final double odometerReading;
  final double volumeLiters;
  final double pricePerLiter;
  final double totalCost;
  final double? efficiencyLper100km;
  final double? efficiencyKmperliter;
  final double? distanceSinceLast;
  final bool isFullTank;
  final String? stationName;
  final String? fuelBrand;
  final String? receiptUrl;
  final String loggedVia;
  final String? notes;
  final DateTime filledAt;
  final DateTime createdAt;

  FuelLog copyWith({
    String? id, String? vehicleId, double? odometerReading,
    double? volumeLiters, double? pricePerLiter, double? totalCost,
    double? efficiencyLper100km, double? efficiencyKmperliter,
    double? distanceSinceLast, bool? isFullTank, String? stationName,
    String? fuelBrand, String? receiptUrl, String? loggedVia,
    String? notes, DateTime? filledAt, DateTime? createdAt,
  }) {
    return FuelLog(
      id: id ?? this.id, vehicleId: vehicleId ?? this.vehicleId,
      odometerReading: odometerReading ?? this.odometerReading,
      volumeLiters: volumeLiters ?? this.volumeLiters,
      pricePerLiter: pricePerLiter ?? this.pricePerLiter,
      totalCost: totalCost ?? this.totalCost,
      efficiencyLper100km: efficiencyLper100km ?? this.efficiencyLper100km,
      efficiencyKmperliter: efficiencyKmperliter ?? this.efficiencyKmperliter,
      distanceSinceLast: distanceSinceLast ?? this.distanceSinceLast,
      isFullTank: isFullTank ?? this.isFullTank,
      stationName: stationName ?? this.stationName,
      fuelBrand: fuelBrand ?? this.fuelBrand,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      loggedVia: loggedVia ?? this.loggedVia, notes: notes ?? this.notes,
      filledAt: filledAt ?? this.filledAt, createdAt: createdAt ?? this.createdAt,
    );
  }

  factory FuelLog.fromJson(Map<String, dynamic> json) => FuelLog(
    id: json['id'] as String, vehicleId: json['vehicle_id'] as String,
    odometerReading: (json['odometer_reading'] as num).toDouble(),
    volumeLiters: (json['volume_liters'] as num).toDouble(),
    pricePerLiter: (json['price_per_liter'] as num).toDouble(),
    totalCost: (json['total_cost'] as num).toDouble(),
    isFullTank: json['is_full_tank'] as bool? ?? true,
    loggedVia: json['logged_via'] as String? ?? 'manual',
    filledAt: DateTime.parse(json['filled_at'] as String),
    createdAt: DateTime.parse(json['created_at'] as String),
  );
}

// ─── Expense ──────────────────────────────────────────────────────────────────

class Expense {
  const Expense({
    required this.id,
    required this.vehicleId,
    required this.category,
    required this.amount,
    required this.currency,
    this.description,
    this.vendorName,
    this.odometerReading,
    this.receiptUrl,
    required this.expenseDate,
    required this.createdAt,
  });

  final String id;
  final String vehicleId;
  final ExpenseCategory category;
  final double amount;
  final String currency;
  final String? description;
  final String? vendorName;
  final double? odometerReading;
  final String? receiptUrl;
  final DateTime expenseDate;
  final DateTime createdAt;
}

// ─── Service Record ───────────────────────────────────────────────────────────

class ServiceRecord {
  const ServiceRecord({
    required this.id,
    required this.vehicleId,
    required this.serviceType,
    required this.serviceDate,
    this.odometerReading,
    this.cost,
    required this.currency,
    this.shopName,
    this.description,
    this.partsReplaced,
    this.receiptUrl,
    required this.createdAt,
  });

  final String id;
  final String vehicleId;
  final ServiceType serviceType;
  final DateTime serviceDate;
  final double? odometerReading;
  final double? cost;
  final String currency;
  final String? shopName;
  final String? description;
  final List<Map<String, String>>? partsReplaced;
  final String? receiptUrl;
  final DateTime createdAt;
}

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

// ─── Notification ─────────────────────────────────────────────────────────────

class AppNotification {
  const AppNotification({
    required this.id,
    required this.notificationType,
    required this.title,
    required this.body,
    this.metadata,
    this.actionUrl,
    required this.isRead,
    this.readAt,
    required this.createdAt,
  });

  final String id;
  final NotificationType notificationType;
  final String title;
  final String body;
  final Map<String, dynamic>? metadata;
  final String? actionUrl;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;

  AppNotification copyWith({
    String? id, NotificationType? notificationType, String? title,
    String? body, Map<String, dynamic>? metadata, String? actionUrl,
    bool? isRead, DateTime? readAt, DateTime? createdAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      notificationType: notificationType ?? this.notificationType,
      title: title ?? this.title, body: body ?? this.body,
      metadata: metadata ?? this.metadata,
      actionUrl: actionUrl ?? this.actionUrl,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
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
