import 'package:flutter/material.dart';
import 'presentation/pages/appointments.dart';
import 'presentation/pages/clients.dart';
import 'presentation/pages/profile.dart';
import 'presentation/pages/sales.dart';
import 'presentation/pages/login.dart';
//import 'package:icons_launcher/utils/icon.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Dashboard App',
      home: const LoginScreen(),
    );
  }
}

/// ------------------------------------------------
///   CONTROLADOR DE TODA LA NAVEGACIÓN INFERIOR
/// ------------------------------------------------
class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  int _index = 0;

  final List<Widget> _screens = [
    DashboardScreen(),
    AppointmentsScreen(),
    ClientScreen(),
    SaleScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month), label: 'Citas'),
          BottomNavigationBarItem(icon: Icon(Icons.groups), label: 'Clientes'),
          BottomNavigationBarItem(
              icon: Icon(Icons.attach_money), label: 'Ventas'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}

//
// ---------------------------------------------------------------
//                      DASHBOARD SCREEN
// ---------------------------------------------------------------
//

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF3F6F6),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _header(),
              const SizedBox(height: 20),
              _promoCard(),
              const SizedBox(height: 20),
              _statsGrid(),
              const SizedBox(height: 25),
              Text(
                "Accesos Rápidos",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              _quickActions(context),
              const SizedBox(height: 25),
              Text(
                "Próximas Citas",
                style: TextStyle(
                  fontSize: 17,
                  color: Colors.grey.shade800,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              _appointmentItem("Ana Martínez", "Masaje Relajante", "10:00 AM"),
              const SizedBox(height: 12),
              _appointmentItem("Carlos López", "Facial Hidratante", "11:30 AM"),
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  // --- HEADER ---
  Widget _header() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xffA1E5C1), Color(0xff77D9B6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomRight: Radius.circular(40),
          bottomLeft: Radius.circular(40),
        ),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Hola,",
                    style: TextStyle(fontSize: 18, color: Colors.white)),
                SizedBox(height: 2),
                Text(
                  "María García",
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Color(0xD9FFFFFF),
              shape: BoxShape.circle,
            ),
            child:
                const Icon(Icons.directions_run, size: 26, color: Colors.teal),
          ),
        ],
      ),
    );
  }

  Widget _promoCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3))
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: Colors.teal.shade50, shape: BoxShape.circle),
            child: const Icon(Icons.trending_up, color: Colors.teal, size: 24),
          ),
          const SizedBox(width: 15),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Promoción Especial",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              SizedBox(height: 4),
              Text(
                "20% descuento en masajes – Esta semana",
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _statsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.7,
      children: [
        _statCard(Icons.calendar_today, "12", "Citas Hoy"),
        _statCard(Icons.people, "248", "Clientes"),
        _statCard(Icons.attach_money, "\$4.2k", "Ventas"),
        _statCard(Icons.star, "4.9", "Rating"),
      ],
    );
  }

  Widget _statCard(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: Colors.teal.shade50, shape: BoxShape.circle),
            child: Icon(icon, size: 22, color: Colors.teal),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              Text(label,
                  style: const TextStyle(fontSize: 13, color: Colors.grey)),
            ],
          )
        ],
      ),
    );
  }

  // ---- ACCESOS RÁPIDOS ----
  Widget _quickActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _quickBtn(context, Icons.person, "Perfil", 4),
        _quickBtn(context, Icons.calendar_month, "Citas", 1),
        _quickBtn(context, Icons.groups, "Clientes", 2),
        _quickBtn(context, Icons.attach_money, "Ventas", 3),
      ],
    );
  }

  Widget _quickBtn(
      BuildContext context, IconData icon, String label, int index) {
    return GestureDetector(
      onTap: () {
        // Cambia la pestaña del BottomNavigationBar
        final nav = context.findAncestorStateOfType<_MainNavigatorState>();
        nav!.setState(() => nav._index = index);
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(
                    color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
              ],
            ),
            child: Icon(icon, size: 28, color: Colors.teal),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }

  // ---- CITAS ----
  Widget _appointmentItem(String name, String service, String hour) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: Colors.teal.shade50, shape: BoxShape.circle),
            child: Icon(Icons.access_time_filled,
                size: 24, color: Colors.teal.shade600),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold)),
                Text(service,
                    style: const TextStyle(fontSize: 13, color: Colors.grey)),
              ],
            ),
          ),
          Text(hour,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal)),
        ],
      ),
    );
  }
}
