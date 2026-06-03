import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/auth/presentation/screens/verify_screen.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/garage/presentation/screens/garage_screen.dart';
import '../../features/garage/presentation/screens/vehicle_detail_screen.dart';
import '../../features/garage/presentation/screens/add_vehicle_screen.dart';
import '../../features/fuel/presentation/screens/add_fuel_screen.dart';
import '../../features/fuel/presentation/screens/fuel_history_screen.dart';
import '../../features/analytics/presentation/screens/analytics_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/profile/presentation/settings_screen.dart';
import '../../shared/screens/home_screen.dart';
import '../../shared/screens/not_found_screen.dart';

part 'app_router.g.dart';

// ─── Routes ────────────────────────────────────────────────────────────────────

class AppRoutes {
  static const splash        = '/';
  static const login         = '/login';
  static const signup        = '/signup';
  static const verify        = '/verify';
  static const home          = '/home';
  static const garage        = '/garage';
  static const addVehicle    = '/garage/add';
  static const notifications = '/notifications';
  static const profile       = '/profile';
  static const settings      = '/settings';
}

// ─── Provider ──────────────────────────────────────────────────────────────────

@riverpod
GoRouter appRouter(AppRouterRef ref) {
  final notifier = _RouterNotifier(ref);
  ref.onDispose(notifier.dispose);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: notifier,
    debugLogDiagnostics: false,
    redirect: notifier.redirect,
    routes: [
      // ── Public / Auth ───────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        pageBuilder: (context, state) => _slideUp(
          key: state.pageKey,
          child: const LoginScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.signup,
        name: 'signup',
        pageBuilder: (context, state) => _slideUp(
          key: state.pageKey,
          child: const SignupScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.verify,
        name: 'verify',
        pageBuilder: (context, state) => _slideUp(
          key: state.pageKey,
          child: const VerifyScreen(),
        ),
      ),

      // ── Authenticated Shell ─────────────────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => HomeScreen(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            name: 'home',
            builder: (context, state) => const GarageScreen(),
          ),
          GoRoute(
            path: AppRoutes.garage,
            name: 'garage',
            builder: (context, state) => const GarageScreen(),
            routes: [
              GoRoute(
                path: 'add',
                name: 'add-vehicle',
                pageBuilder: (context, state) => _slideUp(
                  key: state.pageKey,
                  child: const AddVehicleScreen(),
                ),
              ),
              GoRoute(
                path: ':vehicleId',
                name: 'vehicle-detail',
                builder: (context, state) => VehicleDetailScreen(
                  vehicleId: state.pathParameters['vehicleId']!,
                ),
                routes: [
                  GoRoute(
                    path: 'add-fuel',
                    name: 'add-fuel',
                    pageBuilder: (context, state) => _slideUp(
                      key: state.pageKey,
                      child: AddFuelScreen(
                        vehicleId: state.pathParameters['vehicleId']!,
                      ),
                    ),
                  ),
                  GoRoute(
                    path: 'fuel-history',
                    name: 'fuel-history',
                    builder: (context, state) => FuelHistoryScreen(
                      vehicleId: state.pathParameters['vehicleId']!,
                    ),
                  ),
                  GoRoute(
                    path: 'analytics',
                    name: 'analytics',
                    builder: (context, state) => AnalyticsScreen(
                      vehicleId: state.pathParameters['vehicleId']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.notifications,
            name: 'notifications',
            builder: (context, state) => const NotificationsScreen(),
          ),
          GoRoute(
            path: AppRoutes.profile,
            name: 'profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: AppRoutes.settings,
            name: 'settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => const NotFoundScreen(),
  );
}

// ─── Router Notifier ───────────────────────────────────────────────────────────

class _RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  _RouterNotifier(this._ref) {
    _ref.listen<AuthStatus>(authNotifierProvider, (_, __) => notifyListeners());
    _ref.listen<bool>(splashTimerProvider, (_, __) => notifyListeners());
  }

  String? redirect(BuildContext context, GoRouterState state) {
    final auth = _ref.read(authNotifierProvider);
    final splashDone = _ref.read(splashTimerProvider);
    final path = state.matchedLocation;

    // Still initialising — keep on splash until Clerk resolves
    if (auth is AuthInitial || auth is AuthLoading) {
      return path == AppRoutes.splash ? null : AppRoutes.splash;
    }

    // Authenticated — kick out of all auth screens
    if (auth is AuthAuthenticated) {
      if (path == AppRoutes.splash) {
        return splashDone ? AppRoutes.home : null;
      }
      if (path == AppRoutes.login ||
          path == AppRoutes.signup ||
          path == AppRoutes.verify) {
        return AppRoutes.home;
      }
      return null;
    }

    // Email OTP pending — must verify first
    if (auth is AuthVerificationPending) {
      return path == AppRoutes.verify ? null : AppRoutes.verify;
    }

    // Unauthenticated or Error — allow auth screens, block everything else
    if (path == AppRoutes.splash) {
      return splashDone ? AppRoutes.login : null;
    }
    if (path == AppRoutes.login || path == AppRoutes.signup) {
      return null;
    }
    return AppRoutes.login;
  }
}

// ─── Page Transition ───────────────────────────────────────────────────────────

CustomTransitionPage<T> _slideUp<T>({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: key,
    child: child,
    transitionDuration: const Duration(milliseconds: 350),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return SlideTransition(
        position: Tween(
          begin: const Offset(0.0, 1.0),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeOutCubic)).animate(animation),
        child: child,
      );
    },
  );
}
