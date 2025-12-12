import 'package:flutter/material.dart';
import 'appointments.dart';
import 'profile.dart';

class EmpleadoHome extends StatefulWidget {
  const EmpleadoHome({super.key});

  @override
  State<EmpleadoHome> createState() => _EmpleadoHomeState();
}

class _EmpleadoHomeState extends State<EmpleadoHome> {
  int index = 0;

  final screens = [
    AppointmentsScreen(), // agenda del empleado
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: screens[index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey,
        onTap: (i) => setState(() => index = i),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.event_available), label: "Agenda"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Perfil"),
        ],
      ),
    );
  }
}
