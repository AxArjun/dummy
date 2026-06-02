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

  print("STEP 0 - APP START");

  // Lock to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  print("STEP 1 - ORIENTATION SET");

  // Status bar style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  print("STEP 2 - STATUS BAR OK");

  // Initialize Hive
  await Hive.initFlutter();

  print("STEP 3 - HIVE OK");

  // Initialize Firebase
  await Firebase.initializeApp();

  print("STEP 4 - FIREBASE OK");

  // Initialize dotenv
  await dotenv.load(fileName: ".env");

  print("STEP 5 - DOTENV OK");

  print(
    "CLERK KEY: ${dotenv.env['CLERK_PUBLISHABLE_KEY']}",
  );

  print("STEP 6 - RUNAPP");

  runApp(
    ClerkAuth(
      config: ClerkAuthConfig(
        publishableKey:
            dotenv.env['CLERK_PUBLISHABLE_KEY'] ?? '',
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
    print("BUILDING APP");

    final clerkState = ClerkAuth.of(context);

    print("CLERK USER: ${clerkState.user}");

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        print("SYNCING CLERK USER");
        ref
            .read(authStateProvider.notifier)
            .syncWithClerk(clerkState.user);
      }
    });

    print("WATCHING ROUTER");

    final router = ref.watch(appRouterProvider);

    print("ROUTER CREATED");

    return MaterialApp.router(
      title: 'FuelIQ',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
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