import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/analytics_repository.dart';
import '../domain/analytics_models.dart';

final vehicleAnalyticsProvider = FutureProvider.family<VehicleAnalyticsSummary, String>((ref, vehicleId) async {
  final repository = ref.watch(analyticsRepositoryProvider);
  return repository.getVehicleAnalytics(vehicleId);
});
