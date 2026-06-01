// FuelIQ — Home Screen
// Shell widget with premium bottom navigation bar

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.child});

  final Widget child;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color _bg = Color(0xFF0B0B0B);
  static const Color _surface = Color(0xFF121212);
  static const Color _border = Color(0xFF262626);
  static const Color _gold = Color(0xFFD4AF37);
  static const Color _textSub = Color(0xFF9E9E9E);

  int _selectedIndex = 0;

  static const _tabs = [
    _NavTab(
      label: 'Garage',
      icon: Icons.directions_car_outlined,
      activeIcon: Icons.directions_car_rounded,
      route: AppRoutes.home,
    ),
    _NavTab(
      label: 'Analytics',
      icon: Icons.bar_chart_outlined,
      activeIcon: Icons.bar_chart_rounded,
      route: '/garage/demo/analytics',
    ),
    _NavTab(
      label: 'Alerts',
      icon: Icons.notifications_outlined,
      activeIcon: Icons.notifications_rounded,
      route: AppRoutes.notifications,
    ),
    _NavTab(
      label: 'Profile',
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      route: AppRoutes.profile,
    ),
  ];

  void _onDestinationSelected(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
    context.go(_tabs[index].route);
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _computeIndex(location);
    if (currentIndex != _selectedIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selectedIndex = currentIndex);
      });
    }

    return Scaffold(
      backgroundColor: _bg,
      body: widget.child,
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  int _computeIndex(String location) {
    if (location.startsWith('/notifications')) return 2;
    if (location.startsWith('/profile')) return 3;
    if (location.contains('/analytics')) return 1;
    return 0;
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        border: const Border(
          top: BorderSide(color: _border, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: List.generate(_tabs.length, (index) {
              final tab = _tabs[index];
              final isSelected = _selectedIndex == index;
              return Expanded(
                child: GestureDetector(
                  onTap: () => _onDestinationSelected(index),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 4),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? _gold.withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            isSelected ? tab.activeIcon : tab.icon,
                            key: ValueKey(isSelected),
                            color: isSelected ? _gold : _textSub,
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          tab.label,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: isSelected ? _gold : _textSub,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ).animate(target: isSelected ? 1 : 0).scale(
                        begin: const Offset(0.95, 0.95),
                        end: const Offset(1, 1),
                        curve: Curves.easeOutBack,
                        duration: 200.ms,
                      ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavTab {
  const _NavTab({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.route,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String route;
}
