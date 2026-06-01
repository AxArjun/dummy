// FuelIQ — App Entry Point
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/router/app_router.dart';
import 'shared/theme/app_theme.dart';
import 'features/auth/presentation/providers/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Status bar style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize Hive
  await Hive.initFlutter();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize dotenv
  await dotenv.load(fileName: ".env");

  runApp(
    ClerkAuth(
      config: ClerkAuthConfig(
        publishableKey: dotenv.env['CLERK_PUBLISHABLE_KEY'] ?? '',
      ),
      child: const ProviderScope(
        child: FuelIQApp(),
      ),
    ),
  );
}

class FuelIQApp extends ConsumerStatefulWidget {
  const FuelIQApp({super.key});

  @override
  ConsumerState<FuelIQApp> createState() => _FuelIQAppState();
}

class _FuelIQAppState extends ConsumerState<FuelIQApp> {
  @override
  Widget build(BuildContext context) {
    // Listen to ClerkAuth and sync with Riverpod
    final clerkState = ClerkAuth.of(context);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(authStateProvider.notifier).syncWithClerk(clerkState.user);
      }
    });

    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'FuelIQ',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark, // Default to dark theme — premium automotive feel
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        // Global media query override for consistent text scaling
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1.0),
          ),
          child: child!,
        );
      },
    );
  }
}
