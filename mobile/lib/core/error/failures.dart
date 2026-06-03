// FuelIQ — Structured Failure Hierarchy
// Production error modeling for auth, session, network, and OAuth layers.

import 'package:clerk_auth/clerk_auth.dart' as clerk;

// ─── Base ─────────────────────────────────────────────────────────────────────

sealed class Failure {
  final String userMessage;
  const Failure(this.userMessage);

  @override
  String toString() => '$runtimeType: $userMessage';
}

// ─── Auth Failures ─────────────────────────────────────────────────────────────

class AuthFailure extends Failure {
  const AuthFailure(super.userMessage);

  factory AuthFailure.fromClerkError(clerk.ClerkError error) {
    return AuthFailure(_mapClerkError(error));
  }

  static String _mapClerkError(clerk.ClerkError error) {
    final code = error.code.toString().toLowerCase();
    final msg = error.message.toLowerCase();

    if (code.contains('password_match') || msg.contains('match')) {
      return 'Passwords do not match. Please try again.';
    }
    if (code.contains('invalid_credentials') ||
        msg.contains('invalid credentials') ||
        msg.contains('is incorrect')) {
      return 'Invalid email or password. Please check your details.';
    }
    if (code.contains('identifier_exists') ||
        msg.contains('already exists') ||
        msg.contains('taken')) {
      return 'An account with this email already exists.';
    }
    if (code.contains('too_many_requests') || msg.contains('too many')) {
      return 'Too many attempts. Please wait a moment and try again.';
    }
    if (code.contains('password_strength') ||
        (msg.contains('password') && msg.contains('weak'))) {
      return 'Password is too weak. Use at least 8 characters.';
    }
    if (code.contains('incorrect_code') ||
        (msg.contains('incorrect') && msg.contains('code'))) {
      return 'Incorrect verification code. Please try again.';
    }
    if (code.contains('expired') || msg.contains('expired')) {
      return 'Verification code expired. Please request a new one.';
    }
    if (code.contains('not_found') || msg.contains('not found')) {
      return 'Account not found. Please sign up first.';
    }
    if (error.message.isNotEmpty) {
      return error.message;
    }
    return 'Authentication failed. Please try again.';
  }
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.userMessage);
}

// ─── Network Failures ──────────────────────────────────────────────────────────

class NetworkFailure extends Failure {
  const NetworkFailure(super.userMessage);

  static const offline = NetworkFailure(
    'No internet connection. Please check your network.',
  );
  static const timeout = NetworkFailure(
    'Request timed out. Please try again.',
  );
  static const serverError = NetworkFailure(
    'Server error. Please try again later.',
  );
}

// ─── Session Failures ──────────────────────────────────────────────────────────

class SessionFailure extends Failure {
  const SessionFailure(super.userMessage);

  static const expired = SessionFailure(
    'Your session has expired. Please sign in again.',
  );
  static const notFound = SessionFailure(
    'No active session found. Please sign in.',
  );
}

// ─── OAuth Failures ────────────────────────────────────────────────────────────

class OAuthFailure extends Failure {
  const OAuthFailure(super.userMessage);

  static const cancelled = OAuthFailure('Sign-in was cancelled.');
  static const failed = OAuthFailure(
    'Google sign-in failed. Please try again.',
  );
}
