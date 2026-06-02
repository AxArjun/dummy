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

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  await Hive.initFlutter();
  await Firebase.initializeApp();
  await dotenv.load(fileName: ".env");

  runApp(
    ProviderScope(
      child: ClerkAuth(
        config: ClerkAuthConfig(
          publishableKey: dotenv.env['CLERK_PUBLISHABLE_KEY'] ?? '',
        ),
        child: const FuelIQApp(),
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
  bool _synced = false;

  @override
  Widget build(BuildContext context) {
    final clerkState = ClerkAuth.of(context);

    if (!_synced) {
      _synced = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref
              .read(authStateProvider.notifier)
              .syncWithClerk(clerkState.user);

          debugPrint(
            "CLERK SYNCED -> ${clerkState.user?.id}",
          );
        }
      });
    }

    final router = ref.watch(appRouterProvider);

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