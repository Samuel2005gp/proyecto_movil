import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'appointments.dart';
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
    const NovedadesScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        selectedItemColor: AppTheme.accent,
        unselectedItemColor: AppTheme.muted,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: "Mis Citas",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: "Novedades",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Perfil",
          ),
        ],
      ),
    );
  }
}

// Pantalla de novedades (placeholder)
class NovedadesScreen extends StatelessWidget {
  const NovedadesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Novedades'),
      ),
      body: const Center(
        child: Text('Próximamente: Novedades y anuncios'),
      ),
    );
  }
}
