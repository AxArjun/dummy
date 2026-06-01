// FuelIQ — Auth Provider
// Manages authentication state via Clerk

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:clerk_auth/clerk_auth.dart' as clerk;

// ─── Extension for Router Contract ────────────────────────────────────────────

typedef AuthState = AsyncValue<clerk.User?>;

extension AuthStateX on AuthState {
  bool get isAuthenticated => hasValue && value != null;
}

// ─── Auth Notifier ────────────────────────────────────────────────────────────

class AuthNotifier extends AsyncNotifier<clerk.User?> {
  @override
  Future<clerk.User?> build() async {
    // Initial state is null. Clerk updates this via UI sync.
    return null;
  }

  void syncWithClerk(clerk.User? user) {
    if (state.value?.id != user?.id) {
      state = AsyncData(user);
    }
  }

  Future<void> signInWithEmailPassword(BuildContext context, String email, String password) async {
    state = const AsyncLoading();
    try {
      final authState = ClerkAuth.of(context, listen: false);
      await authState.attemptSignIn(
        strategy: clerk.Strategy.password,
        identifier: email,
        password: password,
      );
      if (authState.client.signIn?.status != clerk.Status.complete) {
        throw Exception("Sign in requires further steps (MFA, etc).");
      }
      state = AsyncData(authState.user);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> signUpWithEmailPassword(BuildContext context, String email, String password, String name) async {
    state = const AsyncLoading();
    try {
      final authState = ClerkAuth.of(context, listen: false);
      await authState.attemptSignUp(
        strategy: clerk.Strategy.password,
        emailAddress: email,
        password: password,
        firstName: name,
      );
      
      // Usually sign up requires email verification.
      if (authState.client.signUp?.status == clerk.Status.complete) {
        state = AsyncData(authState.user);
      } else {
        // We'll mock immediate completion for now or throw if unverified
        state = AsyncData(authState.user);
      }
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> signOut(BuildContext context) async {
    state = const AsyncLoading();
    try {
      final authState = ClerkAuth.of(context, listen: false);
      await authState.signOut();
      state = const AsyncData(null);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }
}

// ─── Convenience Provider ─────────────────────────────────────────────────────

final authStateProvider = AsyncNotifierProvider<AuthNotifier, clerk.User?>(() {
  return AuthNotifier();
});
