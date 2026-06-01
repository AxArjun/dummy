// FuelIQ — Fuel Provider
// Mock Riverpod providers for fuel log data

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../shared/models/models.dart';

part 'fuel_provider.g.dart';

// ─── Mock fuel log data ───────────────────────────────────────────────────────

final _mockFuelLogs = {
  'v001': <FuelLog>[
    FuelLog(
      id: 'fl001',
      vehicleId: 'v001',
      odometerReading: 24850,
      volumeLiters: 45.5,
      pricePerLiter: 106.5,
      totalCost: 4845.75,
      efficiencyLper100km: 8.9,
      efficiencyKmperliter: 11.2,
      distanceSinceLast: 512,
      isFullTank: true,
      stationName: 'HP Petrol Pump, Bandra',
      loggedVia: 'manual',
      filledAt: DateTime(2026, 5, 28),
      createdAt: DateTime(2026, 5, 28),
    ),
    FuelLog(
      id: 'fl002',
      vehicleId: 'v001',
      odometerReading: 24338,
      volumeLiters: 40.0,
      pricePerLiter: 105.8,
      totalCost: 4232.0,
      efficiencyLper100km: 9.1,
      efficiencyKmperliter: 11.0,
      distanceSinceLast: 440,
      isFullTank: true,
      stationName: 'Indian Oil, Andheri',
      loggedVia: 'manual',
      filledAt: DateTime(2026, 5, 12),
      createdAt: DateTime(2026, 5, 12),
    ),
    FuelLog(
      id: 'fl003',
      vehicleId: 'v001',
      odometerReading: 23898,
      volumeLiters: 38.2,
      pricePerLiter: 104.9,
      totalCost: 4007.18,
      efficiencyLper100km: 9.4,
      efficiencyKmperliter: 10.6,
      distanceSinceLast: 402,
      isFullTank: true,
      stationName: 'BPCL, Juhu',
      loggedVia: 'manual',
      filledAt: DateTime(2026, 4, 25),
      createdAt: DateTime(2026, 4, 25),
    ),
    FuelLog(
      id: 'fl004',
      vehicleId: 'v001',
      odometerReading: 23496,
      volumeLiters: 42.1,
      pricePerLiter: 105.2,
      totalCost: 4428.92,
      efficiencyLper100km: 8.7,
      efficiencyKmperliter: 11.5,
      distanceSinceLast: 485,
      isFullTank: true,
      stationName: 'HP Petrol Pump, Bandra',
      loggedVia: 'receipt',
      filledAt: DateTime(2026, 4, 8),
      createdAt: DateTime(2026, 4, 8),
    ),
    FuelLog(
      id: 'fl005',
      vehicleId: 'v001',
      odometerReading: 23011,
      volumeLiters: 50.0,
      pricePerLiter: 104.5,
      totalCost: 5225.0,
      efficiencyLper100km: 9.2,
      efficiencyKmperliter: 10.9,
      distanceSinceLast: 544,
      isFullTank: true,
      stationName: 'Shell, Worli',
      loggedVia: 'manual',
      filledAt: DateTime(2026, 3, 22),
      createdAt: DateTime(2026, 3, 22),
    ),
    FuelLog(
      id: 'fl006',
      vehicleId: 'v001',
      odometerReading: 22467,
      volumeLiters: 47.8,
      pricePerLiter: 103.9,
      totalCost: 4966.42,
      efficiencyLper100km: 8.9,
      efficiencyKmperliter: 11.2,
      distanceSinceLast: 530,
      isFullTank: true,
      stationName: 'Indian Oil, Bandra',
      loggedVia: 'manual',
      filledAt: DateTime(2026, 3, 5),
      createdAt: DateTime(2026, 3, 5),
    ),
  ],
  'v002': <FuelLog>[
    FuelLog(
      id: 'fl007',
      vehicleId: 'v002',
      odometerReading: 8420,
      volumeLiters: 8.5,
      pricePerLiter: 106.5,
      totalCost: 905.25,
      efficiencyLper100km: 3.9,
      efficiencyKmperliter: 25.6,
      distanceSinceLast: 218,
      isFullTank: true,
      stationName: 'HP Petrol Pump',
      loggedVia: 'manual',
      filledAt: DateTime(2026, 5, 25),
      createdAt: DateTime(2026, 5, 25),
    ),
    FuelLog(
      id: 'fl008',
      vehicleId: 'v002',
      odometerReading: 8202,
      volumeLiters: 7.8,
      pricePerLiter: 105.8,
      totalCost: 825.24,
      efficiencyLper100km: 4.1,
      efficiencyKmperliter: 24.4,
      distanceSinceLast: 190,
      isFullTank: true,
      stationName: 'Indian Oil',
      loggedVia: 'manual',
      filledAt: DateTime(2026, 5, 10),
      createdAt: DateTime(2026, 5, 10),
    ),
  ],
};

// ─── Fuel Logs State ──────────────────────────────────────────────────────────

class FuelState {
  const FuelState({
    this.logs = const [],
    this.isLoading = false,
    this.error,
  });

  final List<FuelLog> logs;
  final bool isLoading;
  final String? error;

  FuelState copyWith({
    List<FuelLog>? logs,
    bool? isLoading,
    String? error,
  }) {
    return FuelState(
      logs: logs ?? this.logs,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// ─── Fuel Notifier ────────────────────────────────────────────────────────────

@riverpod
class FuelNotifier extends _$FuelNotifier {
  late String vehicleId;

  @override
  FuelState build(String vehicleId) {
    this.vehicleId = vehicleId;
    _loadLogs();
    return const FuelState(isLoading: true);
  }

  Future<void> _loadLogs() async {
    await Future.delayed(const Duration(milliseconds: 600));
    final logs = _mockFuelLogs[vehicleId] ?? [];
    state = FuelState(logs: logs);
  }

  Future<void> addLog(FuelLog log) async {
    final updated = [log, ...state.logs];
    state = state.copyWith(logs: updated);
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);
    await Future.delayed(const Duration(milliseconds: 600));
    final logs = _mockFuelLogs[vehicleId] ?? [];
    state = FuelState(logs: logs);
  }
}

// ─── Convenience provider ─────────────────────────────────────────────────────

@riverpod
List<FuelLog> fuelLogs(FuelLogsRef ref, String vehicleId) {
  return ref.watch(fuelNotifierProvider(vehicleId)).logs;
}
