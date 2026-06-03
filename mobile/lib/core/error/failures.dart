// FuelIQ — Structured Failure Hierarchy
// Production error modeling for auth, session, network, and OAuth layers.

import 'package:firebase_auth/firebase_auth.dart';

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

  factory AuthFailure.fromFirebaseError(FirebaseAuthException error) {
    return AuthFailure(_mapFirebaseError(error));
  }

  static String _mapFirebaseError(FirebaseAuthException error) {
    final code = error.code.toLowerCase();

    if (code == 'user-not-found') {
      return 'No user found for that email.';
    }
    if (code == 'wrong-password' || code == 'invalid-credential') {
      return 'Invalid email or password. Please check your details.';
    }
    if (code == 'email-already-in-use') {
      return 'An account with this email already exists.';
    }
    if (code == 'too-many-requests') {
      return 'Too many attempts. Please wait a moment and try again.';
    }
    if (code == 'weak-password') {
      return 'Password is too weak. Use at least 6 characters.';
    }
    if (code == 'invalid-verification-code') {
      return 'Incorrect verification code. Please try again.';
    }
    if (code == 'expired-action-code') {
      return 'Verification code expired. Please request a new one.';
    }
    if (error.message != null && error.message!.isNotEmpty) {
      return error.message!;
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
