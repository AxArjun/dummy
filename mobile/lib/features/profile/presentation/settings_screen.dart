// FuelIQ — Settings Screen
// App configuration and preferences

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/router/app_router.dart';

// ─── Settings Provider ────────────────────────────────────────────────────────

class SettingsState {
  const SettingsState({
    this.darkMode = true,
    this.notifications = true,
    this.serviceAlerts = true,
    this.weeklyReports = true,
    this.distanceUnit = 'km',
    this.volumeUnit = 'L',
    this.currency = 'INR',
  });

  final bool darkMode;
  final bool notifications;
  final bool serviceAlerts;
  final bool weeklyReports;
  final String distanceUnit;
  final String volumeUnit;
  final String currency;

  SettingsState copyWith({
    bool? darkMode,
    bool? notifications,
    bool? serviceAlerts,
    bool? weeklyReports,
    String? distanceUnit,
    String? volumeUnit,
    String? currency,
  }) {
    return SettingsState(
      darkMode: darkMode ?? this.darkMode,
      notifications: notifications ?? this.notifications,
      serviceAlerts: serviceAlerts ?? this.serviceAlerts,
      weeklyReports: weeklyReports ?? this.weeklyReports,
      distanceUnit: distanceUnit ?? this.distanceUnit,
      volumeUnit: volumeUnit ?? this.volumeUnit,
      currency: currency ?? this.currency,
    );
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(const SettingsState());

  void toggle(String key) {
    switch (key) {
      case 'darkMode':
        state = state.copyWith(darkMode: !state.darkMode);
        break;
      case 'notifications':
        state = state.copyWith(notifications: !state.notifications);
        break;
      case 'serviceAlerts':
        state = state.copyWith(serviceAlerts: !state.serviceAlerts);
        break;
      case 'weeklyReports':
        state = state.copyWith(weeklyReports: !state.weeklyReports);
        break;
    }
  }

  void setDistanceUnit(String unit) =>
      state = state.copyWith(distanceUnit: unit);
  void setVolumeUnit(String unit) =>
      state = state.copyWith(volumeUnit: unit);
  void setCurrency(String currency) =>
      state = state.copyWith(currency: currency);
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const Color _bg = Color(0xFF0B0B0B);
  static const Color _card = Color(0xFF1A1A1A);
  static const Color _border = Color(0xFF262626);
  static const Color _gold = Color(0xFFD4AF37);
  static const Color _textPrimary = Color(0xFFF5F5F5);
  static const Color _textSub = Color(0xFF9E9E9E);
  static const Color _danger = Color(0xFFF44336);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _border),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: _textPrimary, size: 16),
          ),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: _textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Appearance ─────────────────────────────────────────
            _buildSectionHeader('Appearance'),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _border),
              ),
              child: _SettingsToggle(
                icon: Icons.dark_mode_rounded,
                title: 'Dark Mode',
                subtitle: 'Premium dark automotive theme',
                value: settings.darkMode,
                onChanged: (_) =>
                    ref.read(settingsProvider.notifier).toggle('darkMode'),
              ),
            ).animate().fadeIn(duration: 400.ms),

            const SizedBox(height: 20),

            // ── Notifications ──────────────────────────────────────
            _buildSectionHeader('Notifications'),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _border),
              ),
              child: Column(
                children: [
                  _SettingsToggle(
                    icon: Icons.notifications_outlined,
                    title: 'Push Notifications',
                    subtitle: 'Receive alerts and reminders',
                    value: settings.notifications,
                    onChanged: (_) => ref
                        .read(settingsProvider.notifier)
                        .toggle('notifications'),
                  ),
                  const Divider(color: _border, height: 1),
                  _SettingsToggle(
                    icon: Icons.build_outlined,
                    title: 'Service Alerts',
                    subtitle: 'Oil change, tyre rotation reminders',
                    value: settings.serviceAlerts,
                    onChanged: settings.notifications
                        ? (_) => ref
                            .read(settingsProvider.notifier)
                            .toggle('serviceAlerts')
                        : null,
                  ),
                  const Divider(color: _border, height: 1),
                  _SettingsToggle(
                    icon: Icons.bar_chart_outlined,
                    title: 'Weekly Reports',
                    subtitle: 'Summary of your fuel activity',
                    value: settings.weeklyReports,
                    onChanged: settings.notifications
                        ? (_) => ref
                            .read(settingsProvider.notifier)
                            .toggle('weeklyReports')
                        : null,
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 100.ms, duration: 400.ms),

            const SizedBox(height: 20),

            // ── Units ──────────────────────────────────────────────
            _buildSectionHeader('Units & Region'),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _border),
              ),
              child: Column(
                children: [
                  _SettingsDropdown(
                    icon: Icons.straighten_rounded,
                    title: 'Distance Unit',
                    subtitle: settings.distanceUnit,
                    options: const ['km', 'miles'],
                    value: settings.distanceUnit,
                    onChanged: (v) => ref
                        .read(settingsProvider.notifier)
                        .setDistanceUnit(v!),
                  ),
                  const Divider(color: _border, height: 1),
                  _SettingsDropdown(
                    icon: Icons.local_gas_station_outlined,
                    title: 'Volume Unit',
                    subtitle: settings.volumeUnit,
                    options: const ['L', 'gal'],
                    value: settings.volumeUnit,
                    onChanged: (v) => ref
                        .read(settingsProvider.notifier)
                        .setVolumeUnit(v!),
                  ),
                  const Divider(color: _border, height: 1),
                  _SettingsDropdown(
                    icon: Icons.currency_exchange_rounded,
                    title: 'Currency',
                    subtitle: settings.currency,
                    options: const ['INR', 'USD', 'EUR', 'GBP'],
                    value: settings.currency,
                    onChanged: (v) =>
                        ref.read(settingsProvider.notifier).setCurrency(v!),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

            const SizedBox(height: 20),

            // ── Privacy ────────────────────────────────────────────
            _buildSectionHeader('Privacy & Security'),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _border),
              ),
              child: Column(
                children: [
                  _SettingsTile(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacy Policy',
                    onTap: () {},
                  ),
                  const Divider(color: _border, height: 1),
                  _SettingsTile(
                    icon: Icons.article_outlined,
                    title: 'Terms of Service',
                    onTap: () {},
                  ),
                  const Divider(color: _border, height: 1),
                  _SettingsTile(
                    icon: Icons.delete_outline_rounded,
                    title: 'Delete Account',
                    titleColor: _danger,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text(
                              'Contact support to delete your account'),
                          backgroundColor: _card,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 300.ms, duration: 400.ms),

            const SizedBox(height: 20),

            // ── About ──────────────────────────────────────────────
            _buildSectionHeader('About'),
            const SizedBox(height: 12),
            FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (context, snapshot) {
                final version = snapshot.data?.version ?? '1.0.0';
                final build = snapshot.data?.buildNumber ?? '1';
                return Container(
                  decoration: BoxDecoration(
                    color: _card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _border),
                  ),
                  child: Column(
                    children: [
                      _SettingsTile(
                        icon: Icons.info_outline_rounded,
                        title: 'Version',
                        trailing: Text(
                          '$version ($build)',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            color: _textSub,
                          ),
                        ),
                        onTap: () {},
                      ),
                      const Divider(color: _border, height: 1),
                      _SettingsTile(
                        icon: Icons.star_outline_rounded,
                        title: 'Rate FuelIQ',
                        onTap: () {},
                      ),
                      const Divider(color: _border, height: 1),
                      _SettingsTile(
                        icon: Icons.help_outline_rounded,
                        title: 'Help & Support',
                        onTap: () {},
                      ),
                    ],
                  ),
                );
              },
            ).animate().fadeIn(delay: 400.ms, duration: 400.ms),

            const SizedBox(height: 60),
          ],
        ),
      ),
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
}

// ─── Settings Widgets ─────────────────────────────────────────────────────────

class _SettingsToggle extends StatelessWidget {
  const _SettingsToggle({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  static const Color _gold = Color(0xFFD4AF37);
  static const Color _textPrimary = Color(0xFFF5F5F5);
  static const Color _textSub = Color(0xFF9E9E9E);

  @override
  Widget build(BuildContext context) {
    return ListTile(
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
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: onChanged != null ? _textPrimary : _textSub,
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
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: _gold,
        activeTrackColor: _gold.withOpacity(0.3),
        inactiveTrackColor: const Color(0xFF262626),
        inactiveThumbColor: const Color(0xFF9E9E9E),
      ),
    );
  }
}

class _SettingsDropdown extends StatelessWidget {
  const _SettingsDropdown({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<String> options;
  final String value;
  final ValueChanged<String?>? onChanged;

  static const Color _gold = Color(0xFFD4AF37);
  static const Color _textPrimary = Color(0xFFF5F5F5);
  static const Color _textSub = Color(0xFF9E9E9E);

  @override
  Widget build(BuildContext context) {
    return ListTile(
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
      trailing: DropdownButton<String>(
        value: value,
        dropdownColor: const Color(0xFF1A1A1A),
        underline: const SizedBox.shrink(),
        icon: const Icon(Icons.expand_more_rounded,
            color: _textSub, size: 18),
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 13,
          color: _gold,
          fontWeight: FontWeight.w600,
        ),
        items: options
            .map((o) => DropdownMenuItem(value: o, child: Text(o)))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.trailing,
    this.titleColor,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Widget? trailing;
  final Color? titleColor;

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
        child: Icon(icon, color: titleColor ?? _gold, size: 18),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: titleColor ?? _textPrimary,
        ),
      ),
      trailing: trailing ??
          const Icon(Icons.chevron_right_rounded,
              color: _textSub, size: 20),
    );
  }
}
