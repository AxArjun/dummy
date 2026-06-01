// FuelIQ — Fuel Provider
// Mock Riverpod providers for fuel log data

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/models.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/models.dart';
import '../data/fuel_repository.dart';

// ─── Fuel Notifier ────────────────────────────────────────────────────────────

class FuelNotifier extends AutoDisposeFamilyAsyncNotifier<List<FuelLog>, String> {
  @override
  Future<List<FuelLog>> build(String arg) async {
    return ref.read(fuelRepositoryProvider).getLogs(arg);
  }

  Future<void> addLog(FuelLog log) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(fuelRepositoryProvider);
      await repo.addLog(log);
      return repo.getLogs(arg);
    });
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(fuelRepositoryProvider).getLogs(arg));
  }
}

final fuelNotifierProvider = AutoDisposeAsyncNotifierProviderFamily<FuelNotifier, List<FuelLog>, String>(() {
  return FuelNotifier();
});

// ─── Convenience provider ─────────────────────────────────────────────────────

final fuelLogsProvider = AutoDisposeProviderFamily<List<FuelLog>, String>((ref, vehicleId) {
  final asyncValue = ref.watch(fuelNotifierProvider(vehicleId));
  return asyncValue.valueOrNull ?? [];
});
