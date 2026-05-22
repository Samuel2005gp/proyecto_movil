import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'appointments.dart';
import 'profile.dart';

class EmpleadoHomeScreen extends StatefulWidget {
  const EmpleadoHomeScreen({super.key});

  @override
  State<EmpleadoHomeScreen> createState() => _EmpleadoHomeScreenState();
}

class _EmpleadoHomeScreenState extends State<EmpleadoHomeScreen>
    with TickerProviderStateMixin {
  int _index = 0;
  bool _goingRight = true;

  late final AnimationController _ctrl;
  late final Animation<double> _progress;

  final List<Widget> _screens = [
    AppointmentsScreen(),
    const ProfileScreen(),
  ];

  static const _labels = ['Citas', 'Perfil'];
  static const _activeIcons = [
    Icons.calendar_month,
    Icons.person,
  ];
  static const _inactiveIcons = [
    Icons.calendar_month_outlined,
    Icons.person_outline,
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _progress = _ctrl;
    _ctrl.value = 1.0;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTabTapped(int newIndex) {
    if (newIndex == _index) return;
    setState(() {
      _goingRight = newIndex > _index;
      _index = newIndex;
    });
    _ctrl.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _progress,
        builder: (context, child) {
          final curved = Curves.elasticOut.transform(
            _progress.value.clamp(0.0, 1.0),
          );
          final dx = (_goingRight ? 1.0 - curved : curved - 1.0) * 0.25;
          final opacity = (_progress.value * 2.0).clamp(0.0, 1.0);

          return Opacity(
            opacity: opacity,
            child: Transform.translate(
              offset: Offset(MediaQuery.of(context).size.width * dx, 0),
              child: child,
            ),
          );
        },
        child: KeyedSubtree(
          key: ValueKey<int>(_index),
          child: _screens[_index],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.card,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 62,
          child: Row(
            children: List.generate(_labels.length, (i) {
              final selected = i == _index;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _onTabTapped(i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: 7,
                        child: Center(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                            height: 3,
                            width: selected ? 22.0 : 0.0,
                            decoration: BoxDecoration(
                              color: AppTheme.primary,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                      Icon(
                        selected ? _activeIcons[i] : _inactiveIcons[i],
                        size: 22,
                        color: selected ? AppTheme.primary : AppTheme.muted,
                      ),
                      const SizedBox(height: 2),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w400,
                          color: selected ? AppTheme.primary : AppTheme.muted,
                        ),
                        child: Text(_labels[i]),
                      ),
                    ],
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
