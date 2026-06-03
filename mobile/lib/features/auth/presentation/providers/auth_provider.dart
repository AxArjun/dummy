import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:clerk_auth/clerk_auth.dart' as clerk;

typedef AuthState = AsyncValue<clerk.User?>;

extension AuthStateX on AuthState {
  bool get isAuthenticated => hasValue && value != null;
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() => const AsyncData(null);

  void syncWithClerk(clerk.User? user) {
    state = AsyncData(user);
  }

  Future<void> signInWithEmailPassword(
    BuildContext context,
    String email,
    String password,
  ) async {
    final authState = ClerkAuth.of(context, listen: false);

    await authState.attemptSignIn(
      strategy: clerk.Strategy.password,
      identifier: email,
      password: password,
    );

    state = AsyncData(authState.user);
  }

Future<clerk.SignUp?> signUpWithEmailPassword(
  BuildContext context,
  String email,
  String password,
  String confirmPassword,
  String name,
) async {
  try {
    final authState = ClerkAuth.of(context, listen: false);

    final result = await authState.attemptSignUp(
      strategy: clerk.Strategy.password,
      emailAddress: email,
      password: password,
      passwordConfirmation: confirmPassword,
      firstName: name,
    );

    debugPrint("========== CLERK SIGNUP ==========");
    debugPrint("SIGNUP RESULT = $result");
    debugPrint("SIGNUP OBJECT = ${authState.signUp}");
    debugPrint("CURRENT USER = ${authState.user}");

    state = AsyncData(authState.user);

    return authState.signUp;
  } catch (e, s) {
    debugPrint("========== SIGNUP ERROR ==========");
    debugPrint(e.toString());
    debugPrint(s.toString());

    state = AsyncError(e, s);

    rethrow;
  }
}

  Future<void> signOut(BuildContext context) async {
    final authState = ClerkAuth.of(context, listen: false);

    await authState.signOut();

    state = const AsyncData(null);
  }
}

final authStateProvider =
    NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

final splashTimerProvider =
    StateProvider<bool>((ref) => true);

