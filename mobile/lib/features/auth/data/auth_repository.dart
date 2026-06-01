import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/models.dart';

class AuthRepository {
  Future<User> login(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1));
    if (email.isEmpty || password.isEmpty) {
      throw Exception('Invalid credentials');
    }
    return User(
      id: 'usr_mock_123',
      clerkId: 'clerk_123',
      email: 'mock@fueliq.com',
      displayName: 'Alex Carter',
      createdAt: DateTime.now(),
    );
  }

  Future<User> register(String name, String email, String password) async {
    await Future.delayed(const Duration(seconds: 1));
    return User(
      id: 'usr_mock_123',
      clerkId: 'clerk_123',
      email: email,
      displayName: name,
      createdAt: DateTime.now(),
    );
  }

  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Future<User?> checkAuth() async {
    await Future.delayed(const Duration(milliseconds: 800));
    // Simulate already logged in for mock
    return User(
      id: 'usr_mock_123',
      clerkId: 'clerk_123',
      email: 'mock@fueliq.com',
      displayName: 'Alex Carter',
      createdAt: DateTime.now(),
    );
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});
