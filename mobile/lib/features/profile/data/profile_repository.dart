import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/network/dio_client.dart';

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

final profileRepositoryProvider = Provider((ref) => ProfileRepository(ref.watch(dioProvider)));

class ProfileRepository {
  final Dio _dio;

  ProfileRepository(this._dio);

  Future<SettingsState> getSettings() async {
    try {
      final response = await _dio.get('/users/me');
      if (response.statusCode == 200) {
        final data = response.data['data'];
        return SettingsState(
          distanceUnit: data['distance_unit'] ?? 'km',
          volumeUnit: data['volume_unit'] ?? 'L',
          currency: data['currency'] ?? 'INR',
        );
      }
      return const SettingsState();
    } on DioException catch (e) {
      debugPrint('[ProfileRepository] getSettings error: ${e.message}');
      throw Exception(e.response?.data['message'] ?? 'Failed to fetch settings');
    }
  }

  Future<void> updateSettings(SettingsState settings) async {
    try {
      final response = await _dio.patch(
        '/users/me',
        data: {
          'preferences': {
            'distance_unit': settings.distanceUnit,
            'volume_unit': settings.volumeUnit,
            'currency': settings.currency,
            'timezone': 'Asia/Kolkata',
          }
        },
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to update settings');
      }
    } on DioException catch (e) {
      debugPrint('[ProfileRepository] updateSettings error: ${e.message}');
      throw Exception(e.response?.data['message'] ?? 'Failed to update settings');
    }
  }
}
