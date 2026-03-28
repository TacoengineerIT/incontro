import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'screens/chat_screen.dart';
import 'screens/map_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/swipe_screen.dart';

class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key, this.initialIndex = 0});

  final int initialIndex;

  // ignore: library_private_types_in_public_api
  static _MainNavigatorState? maybeOf(BuildContext context) =>
      context.findAncestorStateOfType<_MainNavigatorState>();

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  late int _index = widget.initialIndex.clamp(0, 3);

  void setTab(int index) => setState(() => _index = index.clamp(0, 3));

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    const barHeight = 74.0;

    return Scaffold(
      backgroundColor: const Color(0xFF131313),
      extendBody: true,
      body: SafeArea(
        top: false,
        bottom: false,
        child: IndexedStack(
          index: _index,
          children: const [
            SwipeScreen(),
            MapScreen(),
            ChatScreen(),
            ProfileScreen(),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 10 + bottomInset * 0.2),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              height: barHeight,
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E).withValues(alpha: 0.88),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  _NavItem(
                    label: 'Scopri',
                    icon: Icons.local_fire_department_rounded,
                    selected: _index == 0,
                    onTap: () => setTab(0),
                  ),
                  _NavItem(
                    label: 'Mappa',
                    icon: Icons.map_rounded,
                    selected: _index == 1,
                    onTap: () => setTab(1),
                  ),
                  _NavItem(
                    label: 'Chat',
                    icon: Icons.chat_bubble_rounded,
                    selected: _index == 2,
                    onTap: () => setTab(2),
                  ),
                  _NavItem(
                    label: 'Profilo',
                    icon: Icons.person_rounded,
                    selected: _index == 3,
                    onTap: () => setTab(3),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final active = const Color(0xFF8781FF);
    final inactive = Colors.white38;
    final color = selected ? active : inactive;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        splashColor: active.withValues(alpha: 0.18),
        highlightColor: active.withValues(alpha: 0.08),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(icon, color: color, size: 24),
                  Positioned(
                    bottom: -10,
                    left: 0,
                    right: 0,
                    child: AnimatedOpacity(
                      opacity: selected ? 1 : 0,
                      duration: 180.ms,
                      curve: Curves.easeOut,
                      child: Center(
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: active,
                            borderRadius: BorderRadius.circular(99),
                            boxShadow: [
                              BoxShadow(
                                color: active.withValues(alpha: 0.55),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                        )
                            .animate(target: selected ? 1 : 0)
                            .scaleXY(
                              begin: 0.6,
                              end: 1,
                              curve: Curves.elasticOut,
                              duration: 380.ms,
                            ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AppNav {
  static final rootNavigatorKey = GlobalKey<NavigatorState>();
}

