// FuelIQ — Auth Provider
// Manages authentication state via Clerk

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/models.dart';
import '../data/auth_repository.dart';

// ─── Extension for Router Contract ────────────────────────────────────────────

extension AuthStateX on AsyncValue<User?> {
  bool get isAuthenticated => hasValue && value != null;
}

// ─── Auth Notifier ────────────────────────────────────────────────────────────

class AuthNotifier extends AsyncNotifier<User?> {
  @override
  Future<User?> build() async {
    return ref.read(authRepositoryProvider).checkAuth();
  }

  Future<void> signInWithEmailPassword(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      return ref.read(authRepositoryProvider).login(email, password);
    });
  }

  Future<void> signUpWithEmailPassword(
      String email, String password, String name) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      return ref.read(authRepositoryProvider).register(name, email, password);
    });
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncData(null);
  }
}

// ─── Convenience Provider ─────────────────────────────────────────────────────

final authStateProvider = AsyncNotifierProvider<AuthNotifier, User?>(() {
  return AuthNotifier();
});
