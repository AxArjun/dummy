import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/auth_state.dart';
import '../../data/firebase_auth_service.dart';
import '../../data/auth_repository.dart';

/// Exposes the FirebaseAuthService for UI components to trigger auth actions.
final authServiceProvider = Provider<FirebaseAuthService>((ref) {
  return ref.watch(firebaseAuthServiceProvider);
});

/// A StreamProvider that listens to Firebase's authStateChanges.
/// It emits the current Firebase User, or null if unauthenticated.
final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthServiceProvider).authStateChanges;
});

/// The core AuthNotifier that translates the raw Firebase User stream into our robust AuthState.
/// GoRouter listens to this provider to handle navigation redirects.
class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    final authService = ref.watch(firebaseAuthServiceProvider);

    // Register a side-effect listener that lives as long as this Notifier.
    // This safely triggers the backend sync exactly once per authenticated session,
    // avoiding side-effects during the build phase itself.
    ref.listen<AsyncValue<User?>>(authStateChangesProvider, (previous, next) {
      final user = next.valueOrNull;
      if (user != null && authService.getAuthState(user) == const AuthState.authenticated()) {
        // Only trigger sync if we transitioned from unauthenticated -> authenticated,
        // or on app launch (where previous is null due to fireImmediately).
        if (previous?.valueOrNull?.uid != user.uid) {
          ref.read(authRepositoryProvider).syncUser(user);
        }
      }
    }, fireImmediately: true);

    // Watch the Firebase auth state stream to drive the UI state.
    final authState = ref.watch(authStateChangesProvider);

    // Map the AsyncValue to our robust AuthState union.
    return authState.when(
      data: (user) => authService.getAuthState(user),
      error: (err, stack) => AuthState.error(err.toString()),
      loading: () => const AuthState.loading(),
    );
  }

  /// Manually force a reload of the Firebase user (e.g., after they click a verification link in their email).
  Future<void> reloadUser() async {
    try {
      state = const AuthState.loading();
      await ref.read(firebaseAuthServiceProvider).reloadUser();
      // The authStateChanges stream does NOT always emit when reload() is called if the uid hasn't changed.
      // So we manually evaluate the state here after reload.
      final user = ref.read(firebaseAuthServiceProvider).currentUser;
      state = ref.read(firebaseAuthServiceProvider).getAuthState(user);
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }

  /// Sign out.
  Future<void> signOut() async {
    state = const AuthState.loading();
    await ref.read(authRepositoryProvider).logout();
    await ref.read(firebaseAuthServiceProvider).signOut();
  }
}

/// The main provider exposed to the rest of the application (GoRouter, etc).
final authNotifierProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});

/// Provider for the current Firebase User, simplifying access without dealing with AsyncValue.
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(firebaseAuthServiceProvider).currentUser;
});
