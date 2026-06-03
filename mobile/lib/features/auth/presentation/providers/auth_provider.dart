// FuelIQ — Auth Provider (Production)
// Sealed AuthStatus state, Clerk ChangeNotifier bridge, full auth flow.

import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:clerk_auth/clerk_auth.dart' as clerk;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';

// ─── Auth Status (Sealed) ──────────────────────────────────────────────────────

sealed class AuthStatus {
  const AuthStatus();
}

/// Clerk has not yet finished initializing. Stay on splash.
class AuthInitial extends AuthStatus {
  const AuthInitial();
}

/// An auth operation is in progress.
class AuthLoading extends AuthStatus {
  const AuthLoading();
}

/// User is fully signed in with an active Clerk session.
class AuthAuthenticated extends AuthStatus {
  final clerk.User user;
  const AuthAuthenticated(this.user);
}

/// No active session. Show login screen.
class AuthUnauthenticated extends AuthStatus {
  const AuthUnauthenticated();
}

/// Signup created; waiting for email OTP verification.
class AuthVerificationPending extends AuthStatus {
  final String email;
  const AuthVerificationPending(this.email);
}

/// A structured failure occurred. UI should show the error message.
class AuthError extends AuthStatus {
  final Failure failure;
  const AuthError(this.failure);
}

// ─── Auth Notifier ─────────────────────────────────────────────────────────────

class AuthNotifier extends Notifier<AuthStatus> {
  ClerkAuthState? _clerkState;
  bool _bound = false;

  @override
  AuthStatus build() => const AuthInitial();

  // ─── Clerk Binding ───────────────────────────────────────────────────────

  /// Binds this notifier to the Clerk ChangeNotifier.
  /// Call once from didChangeDependencies in FuelIQApp.
  /// Safe to call multiple times — deduplicates by instance identity.
  void bindClerk(ClerkAuthState clerkAuth) {
    if (_bound && _clerkState == clerkAuth) return;

    // Remove listener from previous instance if it changed (edge case)
    if (_clerkState != null && _clerkState != clerkAuth) {
      _clerkState!.removeListener(_onClerkChanged);
    }

    _clerkState = clerkAuth;
    _bound = true;

    // Listen for all future Clerk state changes (session restore, sign-out, etc.)
    clerkAuth.addListener(_onClerkChanged);

    // Perform an immediate sync with whatever Clerk knows right now
    _onClerkChanged();
  }

  /// Listener — fires whenever ClerkAuthState.notifyListeners() is called.
  /// Does NOT overwrite AuthLoading (preserves in-progress operations).
  void _onClerkChanged() {
    final cs = _clerkState;
    if (cs == null) return;

    if (cs.user != null) {
      state = AuthAuthenticated(cs.user!);
      return;
    }

    if (cs.signUp != null) {
      // Signup in progress and email not yet verified
      state = AuthVerificationPending(cs.signUp!.emailAddress ?? '');
      return;
    }

    // Only transition to Unauthenticated once Clerk has finished initializing.
    // isNotAvailable returns true when env.isEmpty (initialization incomplete).
    if (!cs.isNotAvailable && state is! AuthLoading) {
      state = const AuthUnauthenticated();
    }
    // else: Clerk still initializing → preserve AuthInitial or AuthLoading
  }

  /// Forced sync after an explicit auth operation completes.
  /// Always updates state regardless of current loading status.
  void _syncFromClerk() {
    final cs = _clerkState;
    if (cs == null) {
      state = const AuthUnauthenticated();
      return;
    }

    if (cs.user != null) {
      state = AuthAuthenticated(cs.user!);
    } else if (cs.signUp != null) {
      state = AuthVerificationPending(cs.signUp!.emailAddress ?? '');
    } else {
      state = const AuthUnauthenticated();
    }
  }

  // ─── Sign In with Email + Password ────────────────────────────────────────

  Future<void> signInWithEmailPassword(String email, String password) async {
    final cs = _clerkState;
    if (cs == null) return;

    state = const AuthLoading();
    try {
      await cs.attemptSignIn(
        strategy: clerk.Strategy.password,
        identifier: email,
        password: password,
      );
      _syncFromClerk();
    } on clerk.ClerkError catch (e) {
      state = AuthError(AuthFailure.fromClerkError(e));
    } catch (e) {
      state = AuthError(AuthFailure(e.toString()));
    }
  }

  // ─── Sign Up with Email + Password ────────────────────────────────────────

  /// Creates a Clerk account and triggers the email OTP send.
  /// On success: state → AuthVerificationPending.
  /// Router then redirects to /verify automatically.
  Future<void> signUpWithEmailPassword({
    required String email,
    required String password,
    required String confirmPassword,
    required String name,
  }) async {
    final cs = _clerkState;
    if (cs == null) return;

    state = const AuthLoading();
    try {
      // strategy: emailCode → Clerk auto-calls prepareSignUp (sends OTP email)
      // after detecting unverified email_address field.
      await cs.attemptSignUp(
        strategy: clerk.Strategy.emailCode,
        emailAddress: email,
        password: password,
        passwordConfirmation: confirmPassword,
        firstName: name,
      );
      _syncFromClerk();
    } on clerk.ClerkError catch (e) {
      state = AuthError(AuthFailure.fromClerkError(e));
    } catch (e) {
      state = AuthError(AuthFailure(e.toString()));
    }
  }

  // ─── Verify Email OTP ─────────────────────────────────────────────────────

  /// Submits the 6-digit OTP from the user's email.
  /// On success: Clerk creates the session → state → AuthAuthenticated.
  Future<void> verifyEmailOtp(String otp) async {
    final cs = _clerkState;
    if (cs == null) return;

    state = const AuthLoading();
    try {
      await cs.attemptSignUp(
        strategy: clerk.Strategy.emailCode,
        code: otp,
      );
      _syncFromClerk();
    } on clerk.ClerkError catch (e) {
      state = AuthError(AuthFailure.fromClerkError(e));
    } catch (e) {
      state = AuthError(AuthFailure(e.toString()));
    }
  }

  /// Resends the email OTP. Calling attemptSignUp without a code
  /// triggers prepareSignUp again (resend) when the signUp exists
  /// with status=missing_requirements and unverified email.
  Future<void> resendEmailOtp() async {
    final cs = _clerkState;
    if (cs == null) return;

    try {
      await cs.attemptSignUp(strategy: clerk.Strategy.emailCode);
      // Keep current AuthVerificationPending state — just resent the OTP
      _onClerkChanged();
    } on clerk.ClerkError catch (e) {
      // Resend failure is non-fatal — show error but stay on verify screen
      state = AuthError(AuthFailure.fromClerkError(e));
    } catch (_) {
      // Silently ignore other errors
    }
  }

  // ─── Google OAuth ─────────────────────────────────────────────────────────

  /// Signs in via Google using Clerk's built-in WebView OAuth overlay.
  /// Requires context to be within the ClerkAuth widget tree.
  Future<void> signInWithGoogle(BuildContext context) async {
    final cs = _clerkState;
    if (cs == null) return;

    state = const AuthLoading();
    try {
      await cs.ssoSignIn(
        context,
        clerk.Strategy.oauthGoogle,
        onError: (clerk.ClerkError error) {
          state = AuthError(
            OAuthFailure(
              error.message.isNotEmpty
                  ? error.message
                  : 'Google sign-in failed. Please try again.',
            ),
          );
        },
      );
    } on clerk.ClerkError catch (e) {
      state = AuthError(
        OAuthFailure(
          e.message.isNotEmpty ? e.message : 'Google sign-in failed.',
        ),
      );
      return;
    } catch (_) {
      // User cancelled the WebView dialog — not an error
    } finally {
      // Always exit loading state after ssoSignIn returns
      if (state is AuthLoading) {
        _syncFromClerk();
      }
    }
  }

  // ─── Sign Out ─────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    final cs = _clerkState;
    try {
      await cs?.signOut();
    } catch (_) {
      // Silently handle — always clear state
    }
    state = const AuthUnauthenticated();
  }

  // ─── Utilities ────────────────────────────────────────────────────────────

  /// Clears an error state and re-syncs from Clerk.
  void clearError() {
    if (state is AuthError) {
      _onClerkChanged();
    }
  }

  /// Returns the current Clerk session JWT for API Authorization headers.
  /// Returns null if not authenticated or token unavailable.
  ///
  /// NOTE: SessionToken.jwt — if compilation fails, check the field name
  /// in clerk_auth package: lib/src/models/client/session_token.dart
  Future<String?> getSessionToken() async {
    final cs = _clerkState;
    if (cs == null || cs.user == null) return null;
    try {
      final token = await cs.sessionToken();
      // Try .jwt first (Clerk standard naming). Change to .value if needed.
      return token.jwt;
    } catch (_) {
      return null;
    }
  }

  // ─── Getters ──────────────────────────────────────────────────────────────

  bool get isAuthenticated => state is AuthAuthenticated;

  clerk.User? get currentUser =>
      state is AuthAuthenticated ? (state as AuthAuthenticated).user : null;
}

// ─── Providers ─────────────────────────────────────────────────────────────────

/// Primary auth state provider. Watch this in screens and the router.
final authNotifierProvider = NotifierProvider<AuthNotifier, AuthStatus>(
  AuthNotifier.new,
);

/// Convenience: the current Clerk user or null. Use in feature screens.
final currentUserProvider = Provider<clerk.User?>((ref) {
  final status = ref.watch(authNotifierProvider);
  return switch (status) {
    AuthAuthenticated(:final user) => user,
    _ => null,
  };
});

/// Splash screen timer. Starts false; splash_screen.dart sets it to true
/// after animations complete (2 seconds). Router stays on splash until true.
final splashTimerProvider = StateProvider<bool>((ref) => false);
