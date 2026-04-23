import 'dart:convert';
import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'core/services/storage_service.dart';
import 'core/services/api_service.dart';
import 'core/constants/api_constants.dart';
import 'presentation/pages/login.dart';
import 'presentation/pages/admin_home.dart';
import 'presentation/pages/empleado_home.dart';
import 'presentation/pages/Cliente_home.dart';
import 'presentation/pages/appointments.dart';
import 'presentation/pages/clients.dart';
import 'presentation/pages/sales.dart';
import 'presentation/pages/profile.dart';
import 'presentation/pages/users.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Spa & Salón',
      theme: AppTheme.theme,
      home: const AuthChecker(),
    );
  }
}

// Verifica si hay sesión activa al iniciar la app
class AuthChecker extends StatefulWidget {
  const AuthChecker({super.key});

  @override
  State<AuthChecker> createState() => _AuthCheckerState();
}

class _AuthCheckerState extends State<AuthChecker> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final hasSession = await StorageService.hasActiveSession();

    if (!mounted) return;

    if (hasSession) {
      final role = await StorageService.getRole();
      _navigateToHome(role);
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  void _navigateToHome(String? role) {
    Widget homeScreen;

    if (role == 'Admin') {
      homeScreen = const AdminHomeScreen();
    } else if (role == 'Cliente') {
      homeScreen = const ClienteHomeScreen();
    } else {
      // Manicurista, Estilista, Barbero, Masajista, Cosmetóloga
      homeScreen = const EmpleadoHomeScreen();
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => homeScreen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(
          color: AppTheme.accent,
        ),
      ),
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
    const DashboardScreen(),
    AppointmentsScreen(),
    ClientScreen(),
    SaleScreen(),
    UsersScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.accent,
        unselectedItemColor: AppTheme.muted,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month), label: 'Citas'),
          BottomNavigationBarItem(icon: Icon(Icons.groups), label: 'Clientes'),
          BottomNavigationBarItem(
              icon: Icon(Icons.attach_money), label: 'Ventas'),
          BottomNavigationBarItem(
              icon: Icon(Icons.manage_accounts), label: 'Usuarios'),
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

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  String _userName = '';
  int _citasHoy = 0;
  int _totalClientes = 0;
  double _ventasHoy = 0;
  List<Map<String, String>> _proximasCitas = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Cargar nombre del usuario
      final userName = await StorageService.getUserName();
      _userName = userName ?? 'Usuario';

      // Cargar estadísticas en paralelo
      await Future.wait([
        _loadAppointmentsToday(),
        _loadClientsCount(),
        _loadSalesToday(),
        _loadUpcomingAppointments(),
      ]);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadAppointmentsToday() async {
    try {
      final response = await ApiService.get(ApiConstants.appointments);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final today = DateTime.now();

        _citasHoy = data.where((appointment) {
          final fechaHora = DateTime.parse(appointment['fecha_hora']);
          return fechaHora.year == today.year &&
              fechaHora.month == today.month &&
              fechaHora.day == today.day;
        }).length;
      }
    } catch (e) {
      print('Error loading appointments: $e');
    }
  }

  Future<void> _loadClientsCount() async {
    try {
      final response = await ApiService.get(ApiConstants.clients);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _totalClientes = data.length;
      }
    } catch (e) {
      print('Error loading clients: $e');
    }
  }

  Future<void> _loadSalesToday() async {
    try {
      final response = await ApiService.get(ApiConstants.sales);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final today = DateTime.now();

        _ventasHoy = data.where((sale) {
          final createdAt = DateTime.parse(sale['created_at']);
          return createdAt.year == today.year &&
              createdAt.month == today.month &&
              createdAt.day == today.day;
        }).fold(0.0, (sum, sale) => sum + (sale['total'] ?? 0).toDouble());
      }
    } catch (e) {
      print('Error loading sales: $e');
    }
  }

  Future<void> _loadUpcomingAppointments() async {
    try {
      final response = await ApiService.get(ApiConstants.appointments);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final now = DateTime.now();

        // Filtrar citas futuras y ordenar por fecha
        final upcoming = data.where((appointment) {
          final fechaHora = DateTime.parse(appointment['fecha_hora']);
          return fechaHora.isAfter(now) && appointment['estado'] == 'Pendiente';
        }).toList()
          ..sort((a, b) {
            final dateA = DateTime.parse(a['fecha_hora']);
            final dateB = DateTime.parse(b['fecha_hora']);
            return dateA.compareTo(dateB);
          });

        // Tomar las primeras 3
        _proximasCitas =
            upcoming.take(3).map<Map<String, String>>((appointment) {
          final fechaHora = DateTime.parse(appointment['fecha_hora']);
          return {
            'name': (appointment['cliente_nombre'] ?? 'Cliente').toString(),
            'service':
                (appointment['servicio_nombre'] ?? 'Servicio').toString(),
            'time':
                '${fechaHora.hour.toString().padLeft(2, '0')}:${fechaHora.minute.toString().padLeft(2, '0')}',
          };
        }).toList();
      }
    } catch (e) {
      print('Error loading upcoming appointments: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.accent),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  size: 60, color: AppTheme.destructive),
              const SizedBox(height: 16),
              Text(_errorMessage!),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadDashboardData,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadDashboardData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 20),
                _buildPromoCard(),
                const SizedBox(height: 20),
                _buildStatsGrid(),
                const SizedBox(height: 25),
                const Text(
                  "Accesos Rápidos",
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                _buildQuickActions(context),
                const SizedBox(height: 25),
                const Text(
                  "Próximas Citas",
                  style: TextStyle(
                    fontSize: 17,
                    color: AppTheme.foreground,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                if (_proximasCitas.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text(
                        'No hay citas próximas',
                        style: TextStyle(color: AppTheme.muted),
                      ),
                    ),
                  )
                else
                  ..._proximasCitas.map((cita) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildAppointmentItem(
                          cita['name']!,
                          cita['service']!,
                          cita['time']!,
                        ),
                      )),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.accent, AppTheme.primary],
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Hola,",
                    style: TextStyle(fontSize: 18, color: Colors.white)),
                const SizedBox(height: 2),
                Text(
                  _userName,
                  style: const TextStyle(
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
            child: const Icon(Icons.spa, size: 26, color: AppTheme.accent),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 3))
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: AppTheme.accent.withOpacity(0.1),
                shape: BoxShape.circle),
            child:
                const Icon(Icons.trending_up, color: AppTheme.accent, size: 24),
          ),
          const SizedBox(width: 15),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Bienvenido al Dashboard",
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                SizedBox(height: 4),
                Text(
                  "Gestiona tu negocio desde aquí",
                  style: TextStyle(fontSize: 13, color: AppTheme.muted),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.7,
      children: [
        _buildStatCard(Icons.calendar_today, "$_citasHoy", "Citas Hoy"),
        _buildStatCard(Icons.people, "$_totalClientes", "Clientes"),
        _buildStatCard(Icons.attach_money, "\$${_ventasHoy.toStringAsFixed(0)}",
            "Ventas Hoy"),
        _buildStatCard(Icons.star, "4.9", "Rating"),
      ],
    );
  }

  Widget _buildStatCard(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 6,
              offset: const Offset(0, 3))
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: AppTheme.accent.withOpacity(0.1),
                shape: BoxShape.circle),
            child: Icon(icon, size: 22, color: AppTheme.accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(value,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                Text(label,
                    style:
                        const TextStyle(fontSize: 13, color: AppTheme.muted)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildQuickBtn(context, Icons.calendar_month, "Citas", 1),
        _buildQuickBtn(context, Icons.groups, "Clientes", 2),
        _buildQuickBtn(context, Icons.attach_money, "Ventas", 3),
        _buildQuickBtn(context, Icons.manage_accounts, "Usuarios", 4),
      ],
    );
  }

  Widget _buildQuickBtn(
      BuildContext context, IconData icon, String label, int index) {
    return GestureDetector(
      onTap: () {
        final nav = context.findAncestorStateOfType<_MainNavigatorState>();
        nav?.setState(() => nav._index = index);
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.card,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 3)),
              ],
            ),
            child: Icon(icon, size: 28, color: AppTheme.accent),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildAppointmentItem(String name, String service, String hour) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 6,
              offset: const Offset(0, 3))
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: AppTheme.accent.withOpacity(0.1),
                shape: BoxShape.circle),
            child: const Icon(Icons.access_time_filled,
                size: 24, color: AppTheme.accent),
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
                    style:
                        const TextStyle(fontSize: 13, color: AppTheme.muted)),
              ],
            ),
          ),
          Text(hour,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.accent)),
        ],
      ),
    );
  }
}
