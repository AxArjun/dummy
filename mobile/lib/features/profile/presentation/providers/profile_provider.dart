import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/profile_repository.dart';

final profileProvider = AsyncNotifierProvider<ProfileNotifier, SettingsState>(() {
  return ProfileNotifier();
});

class ProfileNotifier extends AsyncNotifier<SettingsState> {
  @override
  Future<SettingsState> build() async {
    return ref.read(profileRepositoryProvider).getSettings();
  }

  Future<void> _updateState(SettingsState newState) async {
    if (!state.hasValue) return;
    final previousState = state.valueOrNull!;
    
    // Optimistic update
    state = AsyncData(newState);
    
    try {
      await ref.read(profileRepositoryProvider).updateSettings(newState);
    } catch (e, st) {
      debugPrint('[ProfileProvider] Failed to update state: $e\n$st');
      // Rollback to previous valid state but preserve the error for UI surfacing
      state = AsyncError<SettingsState>(e, st).copyWithPrevious(AsyncData(previousState));
    }
  }

  void toggle(String key) {
    if (!state.hasValue) return;
    final currentState = state.valueOrNull!;
    
    switch (key) {
      case 'darkMode':
        _updateState(currentState.copyWith(darkMode: !currentState.darkMode));
        break;
      case 'notifications':
        _updateState(currentState.copyWith(notifications: !currentState.notifications));
        break;
      case 'serviceAlerts':
        _updateState(currentState.copyWith(serviceAlerts: !currentState.serviceAlerts));
        break;
      case 'weeklyReports':
        _updateState(currentState.copyWith(weeklyReports: !currentState.weeklyReports));
        break;
    }
  }

  void setDistanceUnit(String unit) {
    if (!state.hasValue) return;
    _updateState(state.valueOrNull!.copyWith(distanceUnit: unit));
  }

  void setVolumeUnit(String unit) {
    if (!state.hasValue) return;
    _updateState(state.valueOrNull!.copyWith(volumeUnit: unit));
  }

  void setCurrency(String currency) {
    if (!state.hasValue) return;
    _updateState(state.valueOrNull!.copyWith(currency: currency));
  }
}
