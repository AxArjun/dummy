import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../domain/auth_state.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final googleSignInProvider = Provider<GoogleSignIn>((ref) {
  // Pass the Firebase Web Client ID (serverClientId) to GoogleSignIn.
  // This is required on iOS/Web, and highly recommended on Android to reliably
  // receive the idToken needed for Firebase Auth.
  final webClientId = dotenv.env['GOOGLE_WEB_CLIENT_ID'];
  
  return GoogleSignIn(
    serverClientId: webClientId,
  );
});

final firebaseAuthServiceProvider = Provider<FirebaseAuthService>((ref) {
  return FirebaseAuthService(
    ref.watch(firebaseAuthProvider),
    ref.watch(googleSignInProvider),
  );
});

/// Core service for handling all Firebase Authentication operations.
class FirebaseAuthService {
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  FirebaseAuthService(this._auth, this._googleSignIn);

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  /// Determines the current AuthState based on the Firebase User.
  AuthState getAuthState(User? user) {
    if (user == null) {
      return const AuthState.unauthenticated();
    }
    if (!user.emailVerified) {
      return const AuthState.emailNotVerified();
    }
    return const AuthState.authenticated();
  }

  /// Sign up with email and password, then send verification email.
  Future<void> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (credential.user != null && !credential.user!.emailVerified) {
        await credential.user!.sendEmailVerification();
      }
    } on FirebaseAuthException catch (e, st) {
      debugPrint('[FirebaseAuthService] signUp error: ${e.message}\n$st');
      Error.throwWithStackTrace(_handleFirebaseError(e), st);
    } catch (e, st) {
      debugPrint('[FirebaseAuthService] signUp unexpected error: $e\n$st');
      rethrow;
    }
  }

  /// Sign in with email and password.
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e, st) {
      debugPrint('[FirebaseAuthService] signIn error: ${e.message}\n$st');
      Error.throwWithStackTrace(_handleFirebaseError(e), st);
    } catch (e, st) {
      debugPrint('[FirebaseAuthService] signIn unexpected error: $e\n$st');
      rethrow;
    }
  }

  /// Sign in using Google OAuth.
  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // User canceled the sign-in flow
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      if (googleAuth.idToken == null) {
        throw Exception(
          'Missing Google ID Token. Ensure GOOGLE_WEB_CLIENT_ID is set correctly in your .env file.',
        );
      }

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e, st) {
      debugPrint('[FirebaseAuthService] googleSignIn error: ${e.message}\n$st');
      Error.throwWithStackTrace(_handleFirebaseError(e), st);
    } catch (e, st) {
      debugPrint('[FirebaseAuthService] googleSignIn unexpected error: $e\n$st');
      rethrow;
    }
  }

  /// Resend verification email to the current user.
  Future<void> sendVerificationEmail() async {
    try {
      final user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      }
    } on FirebaseAuthException catch (e, st) {
      debugPrint('[FirebaseAuthService] sendVerificationEmail error: ${e.message}\n$st');
      Error.throwWithStackTrace(_handleFirebaseError(e), st);
    } catch (e, st) {
      debugPrint('[FirebaseAuthService] sendVerificationEmail unexpected error: $e\n$st');
      rethrow;
    }
  }

  /// Reload the current user to refresh their state (e.g., check if email was verified).
  Future<void> reloadUser() async {
    try {
      await _auth.currentUser?.reload();
    } on FirebaseAuthException catch (e, st) {
      debugPrint('[FirebaseAuthService] reloadUser error: ${e.message}\n$st');
      Error.throwWithStackTrace(_handleFirebaseError(e), st);
    } catch (e, st) {
      debugPrint('[FirebaseAuthService] reloadUser unexpected error: $e\n$st');
      rethrow;
    }
  }

  /// Send a password reset email.
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e, st) {
      debugPrint('[FirebaseAuthService] resetPassword error: ${e.message}\n$st');
      Error.throwWithStackTrace(_handleFirebaseError(e), st);
    } catch (e, st) {
      debugPrint('[FirebaseAuthService] resetPassword unexpected error: $e\n$st');
      rethrow;
    }
  }

  /// Sign out from both Firebase and Google Sign-In.
  Future<void> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        if (await _googleSignIn.isSignedIn()) _googleSignIn.signOut(),
      ]);
    } catch (e, st) {
      debugPrint('[FirebaseAuthService] signOut error: $e\n$st');
      rethrow;
    }
  }

  /// Maps Firebase exceptions to user-friendly messages.
  Exception _handleFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return Exception('No user found for that email.');
      case 'wrong-password':
        return Exception('Wrong password provided.');
      case 'invalid-email':
        return Exception('The email address is badly formatted.');
      case 'user-disabled':
        return Exception('This user account has been disabled.');
      case 'email-already-in-use':
        return Exception('The account already exists for that email.');
      case 'operation-not-allowed':
        return Exception('This authentication method is not enabled.');
      case 'weak-password':
        return Exception('The password provided is too weak.');
      case 'network-request-failed':
        return Exception('Network error. Please check your connection.');
      default:
        return Exception(e.message ?? 'An unknown authentication error occurred.');
    }
  }
}
