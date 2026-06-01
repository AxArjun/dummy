// FuelIQ — Profile Screen
// User profile with stats and account management

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/presentation/providers/auth_provider.dart';
import '../../garage/presentation/providers/vehicle_provider.dart';
import '../../fuel/presentation/providers/fuel_provider.dart';
import '../../../../core/router/app_router.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  static const Color _bg = Color(0xFF0B0B0B);
  static const Color _card = Color(0xFF1A1A1A);
  static const Color _border = Color(0xFF262626);
  static const Color _gold = Color(0xFFD4AF37);
  static const Color _silver = Color(0xFFC0C0C0);
  static const Color _textPrimary = Color(0xFFF5F5F5);
  static const Color _textSub = Color(0xFF9E9E9E);
  static const Color _danger = Color(0xFFF44336);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final garageState = ref.watch(garageScreenStateProvider);
    final vehicleIds = garageState.vehiclesState.valueOrNull?.map((v) => v.id).toList() ?? [];

    final totalLogs = vehicleIds.fold<int>(0, (sum, id) {
      final logs = ref.watch(fuelLogsProvider(id));
      return sum + logs.length;
    });

    final displayName = authState.value?.name ?? 'User';
    final email = authState.value?.email ?? 'user@example.com';
    final initials = displayName.isNotEmpty
        ? displayName.split(' ').map((p) => p.isNotEmpty ? p[0] : '').take(2).join().toUpperCase()
        : 'U';

    return Scaffold(
      backgroundColor: _bg,
      body: CustomScrollView(
        slivers: [
          // ── Header ─────────────────────────────────────────────────
          SliverAppBar(
            backgroundColor: _bg,
            expandedHeight: 260,
            pinned: true,
            title: const Text(
              'Profile',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: _textPrimary,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_outlined, color: _gold),
                onPressed: () => context.go(AppRoutes.settings),
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _buildProfileHero(
                  initials, displayName, email, vehicleIds.length,
                  totalLogs),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),

                  // ── Stats ─────────────────────────────────────────
                  _buildStatsRow(vehicleIds.length, totalLogs)
                      .animate()
                      .fadeIn(delay: 150.ms, duration: 500.ms),

                  const SizedBox(height: 24),

                  // ── Account section ───────────────────────────────
                  _buildSectionHeader('Account'),
                  const SizedBox(height: 12),
                  _buildAccountSection(context, email)
                      .animate()
                      .fadeIn(delay: 250.ms, duration: 500.ms),

                  const SizedBox(height: 24),

                  // ── Vehicles ──────────────────────────────────────
                  _buildSectionHeader('Vehicles'),
                  const SizedBox(height: 12),
                  _buildVehiclesSection(
                      context, vehicleIds.length, totalLogs)
                      .animate()
                      .fadeIn(delay: 350.ms, duration: 500.ms),

                  const SizedBox(height: 24),

                  // ── Logout ────────────────────────────────────────
                  _buildLogoutButton(context, ref)
                      .animate()
                      .fadeIn(delay: 450.ms, duration: 500.ms),

                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHero(String initials, String displayName, String email,
      int vehicleCount, int logCount) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1C1600), Color(0xFF0B0B0B)],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 100, bottom: 16, left: 24, right: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Avatar
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFD4AF37), Color(0xFF8B6914)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: _gold.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  initials,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0B0B0B),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              displayName,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              email,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: _textSub,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(int vehicleCount, int totalLogs) {
    return Row(
      children: [
        _ProfileStat(
          value: '$vehicleCount',
          label: 'Vehicles',
          icon: Icons.directions_car_rounded,
          color: _gold,
        ),
        const SizedBox(width: 12),
        _ProfileStat(
          value: '$totalLogs',
          label: 'Fuel Logs',
          icon: Icons.local_gas_station_rounded,
          color: _silver,
        ),
        const SizedBox(width: 12),
        _ProfileStat(
          value: 'PRO',
          label: 'Plan',
          icon: Icons.workspace_premium_rounded,
          color: const Color(0xFF4CAF50),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: _textSub,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildAccountSection(BuildContext context, String? email) {
    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          _ProfileListTile(
            icon: Icons.person_outline_rounded,
            title: 'Edit Profile',
            subtitle: 'Update your name and details',
            onTap: () {},
          ),
          const Divider(color: _border, height: 1),
          _ProfileListTile(
            icon: Icons.mail_outline_rounded,
            title: 'Email',
            subtitle: email ?? 'Not set',
            onTap: () {},
          ),
          const Divider(color: _border, height: 1),
          _ProfileListTile(
            icon: Icons.lock_outline_rounded,
            title: 'Change Password',
            subtitle: 'Update your password via Clerk',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildVehiclesSection(
      BuildContext context, int vehicleCount, int totalLogs) {
    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          _ProfileListTile(
            icon: Icons.garage_outlined,
            title: 'My Garage',
            subtitle: '$vehicleCount vehicle${vehicleCount != 1 ? 's' : ''}',
            trailing: Text(
              '$vehicleCount',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _gold,
              ),
            ),
            onTap: () => context.go(AppRoutes.garage),
          ),
          const Divider(color: _border, height: 1),
          _ProfileListTile(
            icon: Icons.history_rounded,
            title: 'Total Fuel Logs',
            subtitle: 'Across all vehicles',
            trailing: Text(
              '$totalLogs',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _silver,
              ),
            ),
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: () async {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: const Color(0xFF1A1A1A),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: const Text(
                'Sign Out',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                  color: _textPrimary,
                ),
              ),
              content: const Text(
                'Are you sure you want to sign out of FuelIQ?',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: _textSub,
                  fontSize: 14,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel',
                      style: TextStyle(
                          fontFamily: 'Inter',
                          color: _textSub,
                          fontWeight: FontWeight.w600)),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    ref.read(authStateProvider.notifier).signOut(context);
                    if (context.mounted) context.go(AppRoutes.login);
                  },
                  child: const Text(
                    'Sign Out',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: _danger,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        icon: const Icon(Icons.logout_rounded, size: 18, color: _danger),
        label: const Text(
          'Sign Out',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: _danger,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: _danger, width: 1),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}

// ─── Supporting Widgets ───────────────────────────────────────────────────────

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color color;

  static const Color _card = Color(0xFF1A1A1A);
  static const Color _border = Color(0xFF262626);
  static const Color _textPrimary = Color(0xFFF5F5F5);
  static const Color _textSub = Color(0xFF9E9E9E);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _border),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _textPrimary,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                color: _textSub,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileListTile extends StatelessWidget {
  const _ProfileListTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;

  static const Color _gold = Color(0xFFD4AF37);
  static const Color _textPrimary = Color(0xFFF5F5F5);
  static const Color _textSub = Color(0xFF9E9E9E);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: _gold.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: _gold, size: 18),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: _textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          color: _textSub,
        ),
      ),
      trailing: trailing ??
          const Icon(Icons.chevron_right_rounded,
              color: _textSub, size: 20),
    );
  }
}
