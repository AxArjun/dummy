// FuelIQ — Auth Provider
// Manages authentication state via Clerk

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_provider.g.dart';

// ─── Auth State ───────────────────────────────────────────────────────────────

class AuthState {
  const AuthState({
    this.isAuthenticated = false,
    this.isLoading = true,
    this.userId,
    this.email,
    this.displayName,
    this.avatarUrl,
    this.error,
  });

  final bool isAuthenticated;
  final bool isLoading;
  final String? userId;
  final String? email;
  final String? displayName;
  final String? avatarUrl;
  final String? error;

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    String? userId,
    String? email,
    String? displayName,
    String? avatarUrl,
    String? error,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      userId: userId ?? this.userId,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      error: error,
    );
  }
}

// ─── Secure Storage Provider ──────────────────────────────────────────────────

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
});

// ─── Auth Notifier ────────────────────────────────────────────────────────────

@riverpod
class AuthStateNotifier extends _$AuthStateNotifier {
  static const _tokenKey = 'clerk_session_token';
  static const _userIdKey = 'user_id';
  static const _emailKey = 'user_email';
  static const _nameKey = 'user_name';

  @override
  AuthState build() {
    _initializeAuth();
    return const AuthState(isLoading: true);
  }

  Future<void> _initializeAuth() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    final storage = ref.read(secureStorageProvider);
    final token = await storage.read(key: _tokenKey);

    if (token != null) {
      final userId = await storage.read(key: _userIdKey);
      final email = await storage.read(key: _emailKey);
      final name = await storage.read(key: _nameKey);
      state = AuthState(
        isAuthenticated: true,
        isLoading: false,
        userId: userId,
        email: email,
        displayName: name,
      );
    } else {
      state = const AuthState(isAuthenticated: false, isLoading: false);
    }
  }

  Future<void> signInWithEmailPassword(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await Future.delayed(const Duration(seconds: 1));
      final storage = ref.read(secureStorageProvider);
      const mockToken = 'mock_clerk_session_token';
      const mockUserId = 'user_mock_001';
      await storage.write(key: _tokenKey, value: mockToken);
      await storage.write(key: _userIdKey, value: mockUserId);
      await storage.write(key: _emailKey, value: email);
      await storage.write(key: _nameKey, value: email.split('@').first);

      state = AuthState(
        isAuthenticated: true,
        isLoading: false,
        userId: mockUserId,
        email: email,
        displayName: email.split('@').first,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Sign in failed. Please check your credentials.',
      );
    }
  }

  Future<void> signUpWithEmailPassword(
      String email, String password, String name) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await Future.delayed(const Duration(seconds: 1));
      final storage = ref.read(secureStorageProvider);
      const mockToken = 'mock_clerk_session_token';
      const mockUserId = 'user_mock_002';
      await storage.write(key: _tokenKey, value: mockToken);
      await storage.write(key: _userIdKey, value: mockUserId);
      await storage.write(key: _emailKey, value: email);
      await storage.write(key: _nameKey, value: name);

      state = AuthState(
        isAuthenticated: true,
        isLoading: false,
        userId: mockUserId,
        email: email,
        displayName: name,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Sign up failed. Please try again.',
      );
    }
  }

  Future<void> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await Future.delayed(const Duration(seconds: 1));
      final storage = ref.read(secureStorageProvider);
      const mockToken = 'mock_google_clerk_token';
      const mockUserId = 'user_google_001';
      await storage.write(key: _tokenKey, value: mockToken);
      await storage.write(key: _userIdKey, value: mockUserId);
      await storage.write(key: _emailKey, value: 'user@gmail.com');
      await storage.write(key: _nameKey, value: 'Google User');

      state = const AuthState(
        isAuthenticated: true,
        isLoading: false,
        userId: mockUserId,
        email: 'user@gmail.com',
        displayName: 'Google User',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Google sign in failed.',
      );
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    final storage = ref.read(secureStorageProvider);
    await storage.deleteAll();
    state = const AuthState(isAuthenticated: false, isLoading: false);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// ─── Convenience Provider ─────────────────────────────────────────────────────

final authStateProvider = authStateNotifierProvider;
