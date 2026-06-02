// FuelIQ — Go Router Configuration
// Feature-first routing with auth guards and shell routes

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
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

/// Route names — type-safe constants
class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const signup = '/signup';
  static const home = '/home';
  static const garage = '/garage';
  static const addVehicle = '/garage/add';
  static const vehicleDetail = '/garage/:vehicleId';
  static const addFuel = '/garage/:vehicleId/add-fuel';
  static const fuelHistory = '/garage/:vehicleId/fuel-history';
  static const analytics = '/garage/:vehicleId/analytics';
  static const notifications = '/notifications';
  static const profile = '/profile';
  static const settings = '/settings';
}

@riverpod
GoRouter appRouter(AppRouterRef ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,
    redirect: (context, state) {

  print("========== ROUTER ==========");
  print("LOCATION: ${state.matchedLocation}");
  print("AUTH LOADING: ${authState.isLoading}");
  print("AUTH VALUE: ${authState.value}");

  final isAuthenticated = authState.isAuthenticated;
  final isAuthRoute =
      state.matchedLocation == AppRoutes.login ||
      state.matchedLocation == AppRoutes.signup ||
      state.matchedLocation == AppRoutes.splash;

  print("IS AUTHENTICATED: $isAuthenticated");
  print("IS AUTH ROUTE: $isAuthRoute");

  if (authState.isLoading) {
    print("AUTH STILL LOADING");
    return null;
  }

  if (!isAuthenticated && !isAuthRoute) {
    print("REDIRECT -> LOGIN");
    return AppRoutes.login;
  }

  if (isAuthenticated &&
      state.matchedLocation == AppRoutes.login) {
    print("REDIRECT -> HOME");
    return AppRoutes.home;
  }

  if (isAuthenticated &&
      state.matchedLocation == AppRoutes.splash) {
    print("REDIRECT -> HOME");
    return AppRoutes.home;
  }

  print("NO REDIRECT");
  return null;
},
      final isAuthenticated = authState.isAuthenticated;
      final isAuthRoute = state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.signup ||
          state.matchedLocation == AppRoutes.splash;

      // Loading state — stay on splash
      if (authState.isLoading) return null;

      // Not authenticated — redirect to login
      if (!isAuthenticated && !isAuthRoute) {
        return AppRoutes.login;
      }

      // Authenticated — skip auth screens
      if (isAuthenticated && state.matchedLocation == AppRoutes.login) {
        return AppRoutes.home;
      }
      if (isAuthenticated && state.matchedLocation == AppRoutes.splash) {
        return AppRoutes.home;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        pageBuilder: (context, state) => _slideFromBottom(
          key: state.pageKey,
          child: const LoginScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.signup,
        name: 'signup',
        pageBuilder: (context, state) => _slideFromBottom(
          key: state.pageKey,
          child: const SignupScreen(),
        ),
      ),

      // ── Main Shell ─────────────────────────────────────────────────────────
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
                pageBuilder: (context, state) => _slideFromBottom(
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
                    pageBuilder: (context, state) => _slideFromBottom(
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

CustomTransitionPage<T> _slideFromBottom<T>({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: key,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(0.0, 1.0);
      const end = Offset.zero;
      const curve = Curves.easeOutCubic;
      final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
      return SlideTransition(position: animation.drive(tween), child: child);
    },
    transitionDuration: const Duration(milliseconds: 350),
  );
}
