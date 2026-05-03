import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:intl/intl.dart';
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
import 'presentation/pages/services.dart';
import 'presentation/pages/profile.dart';

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

// Verifica si hay Sesión activa al iniciar la app
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
          color: AppTheme.primary,
        ),
      ),
    );
  }
}

/// ------------------------------------------------
///   CONTROLADOR DE TODA LA NAVEGACIÁ“N INFERIOR
/// ------------------------------------------------
class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator>
    with SingleTickerProviderStateMixin {
  int _index = 0;
  bool _goingRight = true;

  // Controller unico con duracion fija — nunca se recrea
  late final AnimationController _ctrl;
  late final Animation<double> _progress;

  final List<Widget> _screens = [
    const DashboardScreen(),
    AppointmentsScreen(),
    SaleScreen(),
    const ServicesScreen(),
    ClientScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Duracion fija — el spring se simula con la curva, no con SpringSimulation
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _progress = _ctrl;
    // Empieza en 1.0 (pantalla ya visible)
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
    // Reinicia desde 0 y anima hacia 1 con curva elasticOut (spring bounce)
    _ctrl.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _progress,
        builder: (context, child) {
          // Curva elasticOut da el efecto spring/bounce
          final curved = Curves.elasticOut.transform(
            _progress.value.clamp(0.0, 1.0),
          );
          // Slide: va de ±0.25 a 0.0
          final dx = (_goingRight ? 1.0 - curved : curved - 1.0) * 0.25;
          // Fade: de 0 a 1 en la primera mitad
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
      bottomNavigationBar: _AnimatedBottomNav(
        currentIndex: _index,
        onTap: _onTabTapped,
      ),
    );
  }
}

// ── Bottom nav con indicador spring ───────────────────────────────────────
class _AnimatedBottomNav extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _AnimatedBottomNav({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<_AnimatedBottomNav> createState() => _AnimatedBottomNavState();
}

class _AnimatedBottomNavState extends State<_AnimatedBottomNav>
    with TickerProviderStateMixin {

  static const _labels = ['Inicio', 'Citas', 'Ventas', 'Servicios', 'Clientes', 'Perfil'];
  static const _activeIcons = [
    Icons.home_rounded, Icons.calendar_month, Icons.attach_money,
    Icons.spa, Icons.groups, Icons.person,
  ];
  static const _inactiveIcons = [
    Icons.home_outlined, Icons.calendar_month_outlined, Icons.money_outlined,
    Icons.spa_outlined, Icons.groups_outlined, Icons.person_outline,
  ];

  // Un controller por tab para el bounce del icono
  late List<AnimationController> _bounceControllers;
  late List<Animation<double>> _scaleAnims;

  @override
  void initState() {
    super.initState();
    _bounceControllers = List.generate(_labels.length, (i) {
      return AnimationController(vsync: this);
    });
    _scaleAnims = _bounceControllers.map((ctrl) {
      return ctrl.drive(Tween<double>(begin: 1.0, end: 1.0));
    }).toList();
  }

  @override
  void didUpdateWidget(_AnimatedBottomNav old) {
    super.didUpdateWidget(old);
    if (old.currentIndex != widget.currentIndex) {
      _triggerBounce(widget.currentIndex);
    }
  }

  void _triggerBounce(int i) {
    final ctrl = _bounceControllers[i];
    ctrl.dispose();
    _bounceControllers[i] = AnimationController(vsync: this);

    // Spring bounce en el icono seleccionado
    final spring = SpringSimulation(
      const SpringDescription(mass: 1.0, stiffness: 400.0, damping: 14.0),
      1.3,   // empieza grande (overshoot)
      1.0,   // vuelve a tamanio normal
      -8.0,  // velocidad inicial negativa = rebote hacia abajo primero
    );

    _bounceControllers[i].animateWith(spring);

    _scaleAnims[i] = _bounceControllers[i].drive(
      Tween<double>(begin: 1.3, end: 1.0),
    );

    setState(() {});
  }

  @override
  void dispose() {
    for (final c in _bounceControllers) { c.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              final selected = i == widget.currentIndex;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => widget.onTap(i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Indicador superior en SizedBox fijo para no causar overflow
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
                      // Icono con spring bounce
                      AnimatedBuilder(
                        animation: _bounceControllers[i],
                        builder: (_, __) {
                          final scale = selected
                              ? _scaleAnims[i].value
                              : 1.0;
                          return Transform.scale(
                            scale: scale,
                            child: Icon(
                              selected ? _activeIcons[i] : _inactiveIcons[i],
                              size: 22,
                              color: selected ? AppTheme.primary : AppTheme.muted,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 2),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
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
  String _userRole = '';
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
      // Cargar nombre y rol del usuario
      final userName = await StorageService.getUserName();
      final role = await StorageService.getRole();
      _userName = userName ?? 'Usuario';
      _userRole = role ?? '';

      // Cargar estadísticas en paralelo
      await Future.wait([
        _loadAppointmentsToday(),
        _loadClientsCount(),
        _loadSalesToday(),
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
        final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
        _citasHoy = data.where((a) {
          final fecha = a['Fecha']?.toString() ?? a['fecha']?.toString() ?? '';
          return fecha == todayStr;
        }).length;

        // Próximas citas: pendientes de hoy en adelante
        final now = DateTime.now();
        final upcoming = data.where((a) {
          final fecha = a['Fecha']?.toString() ?? a['fecha']?.toString() ?? '';
          final estado =
              a['Estado']?.toString() ?? a['estado']?.toString() ?? '';
          if (fecha.isEmpty) return false;
          try {
            final d = DateTime.parse(fecha);
            return estado == 'Pendiente' &&
                (d.isAfter(now) || fecha == todayStr);
          } catch (_) {
            return false;
          }
        }).toList();

        upcoming.sort((a, b) {
          final fa = a['Fecha']?.toString() ?? a['fecha']?.toString() ?? '';
          final fb = b['Fecha']?.toString() ?? b['fecha']?.toString() ?? '';
          final ha = a['Horario']?.toString() ?? a['horario']?.toString() ?? '';
          final hb = b['Horario']?.toString() ?? b['horario']?.toString() ?? '';
          return '$fa $ha'.compareTo('$fb $hb');
        });

        _proximasCitas = upcoming.take(3).map<Map<String, String>>((a) {
          final servicios = a['servicios'] as List<dynamic>? ?? [];
          final servicio = servicios.isNotEmpty
              ? (servicios[0]['serviceName']?.toString() ?? 'Servicio')
              : 'Servicio';
          return {
            'name': (a['cliente_nombre']?.toString() ?? 'Cliente'),
            'service': servicio,
            'time':
                a['Horario']?.toString() ?? a['horario']?.toString() ?? '--:--',
          };
        }).toList();
      }
    } catch (_) {}
  }

  Future<void> _loadClientsCount() async {
    try {
      final response = await ApiService.get(ApiConstants.clients);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _totalClientes = data.length;
      }
    } catch (_) {}
  }

  Future<void> _loadSalesToday() async {
    try {
      final response = await ApiService.get(ApiConstants.sales);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
        _ventasHoy = data.where((sale) {
          final fecha =
              sale['Fecha']?.toString() ?? sale['fecha']?.toString() ?? '';
          return fecha == todayStr;
        }).fold(
            0.0,
            (sum, sale) =>
                sum +
                ((sale['Total'] ?? sale['total'] ?? 0) as num).toDouble());
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
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
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Buenos días'
        : hour < 18
            ? 'Buenas tardes'
            : 'Buenas noches';

    // Iniciales del nombre completo
    final parts =
        _userName.trim().split(' ').where((p) => p.isNotEmpty).toList();
    final initials = parts.length >= 2
        ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
        : parts.isNotEmpty
            ? parts[0][0].toUpperCase()
            : 'U';

    // Etiqueta del rol
    final rolLabel = _userRole == 'Admin'
        ? 'Administrador'
        : _userRole == 'Cliente'
            ? 'Cliente'
            : _userRole.isNotEmpty
                ? _userRole
                : 'Usuario';

    return Builder(
      builder: (context) {
        final topPadding = MediaQuery.of(context).padding.top;
        return Container(
          padding: EdgeInsets.fromLTRB(20, topPadding + 16, 20, 28),
          decoration: const BoxDecoration(
            color: AppTheme.primary,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$greeting,',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _userName.isNotEmpty ? _userName : 'Usuario',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        rolLabel,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Colors.white.withOpacity(0.4), width: 1.5),
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
                color: AppTheme.primary.withOpacity(0.1),
                shape: BoxShape.circle),
            child: const Icon(Icons.trending_up,
                color: AppTheme.primary, size: 24),
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
                color: AppTheme.primary.withOpacity(0.1),
                shape: BoxShape.circle),
            child: Icon(icon, size: 22, color: AppTheme.primary),
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildQuickBtn(context, Icons.calendar_month, "Citas", 1),
              const SizedBox(width: 16),
              _buildQuickBtn(context, Icons.attach_money, "Ventas", 2),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildQuickBtn(context, Icons.spa_outlined, "Servicios", 3),
              const SizedBox(width: 16),
              _buildQuickBtn(context, Icons.groups, "Clientes", 4),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickBtn(
      BuildContext context, IconData icon, String label, int index) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          final nav = context.findAncestorStateOfType<_MainNavigatorState>();
          nav?.setState(() => nav._index = index);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.primary.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: AppTheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.foreground,
                  ),
                ),
              ),
            ],
          ),
        ),
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
                color: AppTheme.primary.withOpacity(0.1),
                shape: BoxShape.circle),
            child: const Icon(Icons.access_time_filled,
                size: 24, color: AppTheme.primary),
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
                  color: AppTheme.primary)),
        ],
      ),
    );
  }
}
