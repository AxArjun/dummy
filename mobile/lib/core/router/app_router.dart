import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/auth_state.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/auth/presentation/screens/verify_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../shared/screens/home_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';

// Import Garage & Profile screens (Assuming these exist based on the prompt context)
import '../../features/garage/presentation/screens/garage_screen.dart';
import '../../features/garage/presentation/screens/vehicle_detail_screen.dart';
import '../../features/analytics/presentation/screens/analytics_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/profile/presentation/settings_screen.dart';

// ─── Route Constants ──────────────────────────────────────────────────────────

class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const signup = '/signup';
  static const verify = '/verify';
  static const forgotPassword = '/forgot-password';
  static const home = '/home';
  static const garage = '/garage';
  static const addVehicle = '/garage/add';
  static const notifications = '/notifications';
  static const profile = '/profile';
  static const settings = '/settings';
}

// ─── Router Provider ──────────────────────────────────────────────────────────

final routerProvider = Provider<GoRouter>((ref) {
  final routerNotifier = _RouterNotifier(ref);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: routerNotifier,
    redirect: routerNotifier.redirect,
    debugLogDiagnostics: true,
    routes: [
      // ─── Splash ───
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),

      // ─── Auth ───
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.signup,
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: AppRoutes.verify,
        builder: (context, state) => const VerifyScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      // ─── Main App ───
      ShellRoute(
        builder: (context, state, child) => HomeScreen(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            builder: (context, state) => const GarageScreen(), // Typically the dashboard
          ),
          GoRoute(
            path: AppRoutes.garage,
            builder: (context, state) => const GarageScreen(),
          ),
          GoRoute(
            path: '/garage/:vehicleId/analytics',
            builder: (context, state) {
              final vehicleId = state.pathParameters['vehicleId']!;
              return AnalyticsScreen(vehicleId: vehicleId);
            },
          ),
          GoRoute(
            path: AppRoutes.addVehicle,
            builder: (context, state) => const Scaffold(body: Center(child: Text("Add Vehicle Screen"))), // Placeholder if doesn't exist
          ),
          GoRoute(
            path: AppRoutes.notifications,
            builder: (context, state) => const NotificationsScreen(),
          ),
          GoRoute(
            path: AppRoutes.profile,
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: AppRoutes.settings,
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );
});

// ─── Router Notifier (Redirect Logic) ─────────────────────────────────────────

class _RouterNotifier extends ChangeNotifier {
  final Ref _ref;
  AuthState _authState = const AuthState.loading();

  _RouterNotifier(this._ref) {
    _ref.listen<AuthState>(authNotifierProvider, (_, next) {
      _authState = next;
      notifyListeners();
    });
  }

  String? redirect(BuildContext context, GoRouterState state) {
    final isGoingToLogin = state.matchedLocation == AppRoutes.login;
    final isGoingToSignup = state.matchedLocation == AppRoutes.signup;
    final isGoingToVerify = state.matchedLocation == AppRoutes.verify;
    final isGoingToForgotPass = state.matchedLocation == AppRoutes.forgotPassword;

    // Helper boolean
    final isAuthRoute = isGoingToLogin || isGoingToSignup || isGoingToForgotPass;

    return _authState.when(
      loading: () => AppRoutes.splash, // Keep at splash while loading
      error: (_) => AppRoutes.login, // Drop to login on fatal auth error
      unauthenticated: () {
        if (!isAuthRoute) return AppRoutes.login;
        return null; // Let them proceed to login/signup/forgot password
      },
      emailNotVerified: () {
        // If they are not verified, restrict them to the verify screen.
        if (isGoingToVerify) return null;
        return AppRoutes.verify;
      },
      authenticated: () {
        // If fully authenticated and trying to access an auth screen or splash, send to home.
        if (isAuthRoute || isGoingToVerify || state.matchedLocation == AppRoutes.splash) {
          return AppRoutes.home;
        }
        return null; // Allow access to any other authenticated route
      },
    );
  }
}
