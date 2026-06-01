// FuelIQ — Splash Screen
// Animated brand intro with auth state redirect

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../../../../core/router/app_router.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  static const Color _bg = Color(0xFF0B0B0B);
  static const Color _gold = Color(0xFFD4AF37);
  static const Color _textPrimary = Color(0xFFF5F5F5);
  static const Color _textSub = Color(0xFF9E9E9E);

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authStateProvider, (previous, next) {
      if (!next.isLoading && mounted) {
        if (next.isAuthenticated) {
          context.go(AppRoutes.home);
        } else {
          context.go(AppRoutes.login);
        }
      }
    });

    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          // ── Background radial glow ──────────────────────────────────────
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 0.8,
                  colors: [
                    Color(0x22D4AF37),
                    Color(0x00000000),
                  ],
                ),
              ),
            ),
          ),

          // ── Content ─────────────────────────────────────────────────────
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                _buildLogo(),
                const SizedBox(height: 32),

                // Brand name
                Text(
                  'FuelIQ',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 48,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary,
                    letterSpacing: -1.0,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 400.ms, duration: 700.ms)
                    .slideY(begin: 0.3, end: 0),

                const SizedBox(height: 12),

                Text(
                  'Vehicle Intelligence Platform',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: _textSub,
                    letterSpacing: 2.0,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 700.ms, duration: 600.ms),

                const SizedBox(height: 72),

                // Loading indicator
                _buildLoadingDots(),
              ],
            ),
          ),

          // ── Version tag ─────────────────────────────────────────────────
          Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: Text(
              'v1.0.0',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: Color(0xFF4A4A4A),
                letterSpacing: 1.5,
              ),
            ).animate().fadeIn(delay: 1200.ms),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + (_pulseController.value * 0.04),
          child: child,
        );
      },
      child: Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const RadialGradient(
            colors: [Color(0xFFD4AF37), Color(0xFF8B6914)],
          ),
          boxShadow: [
            BoxShadow(
              color: _gold.withOpacity(0.35),
              blurRadius: 32,
              spreadRadius: 8,
            ),
          ],
        ),
        child: const Icon(
          Icons.local_gas_station_rounded,
          color: Color(0xFF0B0B0B),
          size: 44,
        ),
      )
          .animate()
          .fadeIn(duration: 600.ms)
          .scale(begin: const Offset(0.5, 0.5), end: const Offset(1, 1)),
    );
  }

  Widget _buildLoadingDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: _gold,
            shape: BoxShape.circle,
          ),
        )
            .animate(onPlay: (c) => c.repeat())
            .fadeIn(delay: Duration(milliseconds: index * 200), duration: 400.ms)
            .then()
            .fadeOut(duration: 400.ms);
      }),
    );
  }
}
