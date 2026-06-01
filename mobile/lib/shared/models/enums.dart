import 'package:json_annotation/json_annotation.dart';

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
