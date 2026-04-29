import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'appointments.dart';
import 'sales.dart';
import 'services.dart';
import 'profile.dart';

class EmpleadoHomeScreen extends StatefulWidget {
  const EmpleadoHomeScreen({super.key});

  @override
  State<EmpleadoHomeScreen> createState() => _EmpleadoHomeScreenState();
}

class _EmpleadoHomeScreenState extends State<EmpleadoHomeScreen> {
  int _index = 0;

  final List<Widget> _screens = [
    AppointmentsScreen(),
    SaleScreen(),
    const ServicesScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.primary,
        unselectedItemColor: AppTheme.muted,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month), label: 'Citas'),
          BottomNavigationBarItem(
              icon: Icon(Icons.attach_money), label: 'Ventas'),
          BottomNavigationBarItem(
              icon: Icon(Icons.spa_outlined), label: 'Servicios'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}
