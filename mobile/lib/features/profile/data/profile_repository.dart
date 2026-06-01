import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsState {
  const SettingsState({
    this.darkMode = true,
    this.notifications = true,
    this.serviceAlerts = true,
    this.weeklyReports = true,
    this.distanceUnit = 'km',
    this.volumeUnit = 'L',
    this.currency = 'INR',
  });

  final bool darkMode;
  final bool notifications;
  final bool serviceAlerts;
  final bool weeklyReports;
  final String distanceUnit;
  final String volumeUnit;
  final String currency;

  SettingsState copyWith({
    bool? darkMode,
    bool? notifications,
    bool? serviceAlerts,
    bool? weeklyReports,
    String? distanceUnit,
    String? volumeUnit,
    String? currency,
  }) {
    return SettingsState(
      darkMode: darkMode ?? this.darkMode,
      notifications: notifications ?? this.notifications,
      serviceAlerts: serviceAlerts ?? this.serviceAlerts,
      weeklyReports: weeklyReports ?? this.weeklyReports,
      distanceUnit: distanceUnit ?? this.distanceUnit,
      volumeUnit: volumeUnit ?? this.volumeUnit,
      currency: currency ?? this.currency,
    );
  }
}

final profileRepositoryProvider = Provider((ref) => ProfileRepository());

class ProfileRepository {
  Future<SettingsState> getSettings() async {
    await Future.delayed(const Duration(milliseconds: 600));
    return const SettingsState();
  }

  Future<void> updateSettings(SettingsState settings) async {
    await Future.delayed(const Duration(milliseconds: 300));
    // Simulate updating backend
  }
}
