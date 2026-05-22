import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/api_service.dart';
import '../../core/constants/api_constants.dart';
import '../../core/utils/responsive_utils.dart';

class ResponsiveDashboard extends StatefulWidget {
  const ResponsiveDashboard({super.key});

  @override
  State<ResponsiveDashboard> createState() => _ResponsiveDashboardState();
}

class _ResponsiveDashboardState extends State<ResponsiveDashboard> {
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
      final userName = await StorageService.getUserName();
      final role = await StorageService.getRole();
      _userName = userName ?? 'Usuario';
      _userRole = role ?? '';

      await Future.wait([
        _loadAppointmentsToday(),
        _loadClientsCount(),
        _loadSalesToday(),
      ]);

      setState(() => _isLoading = false);
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
                padding:
                    EdgeInsets.symmetric(horizontal: context.horizontalPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: context.spacing(20)),
                    _buildPromoCard(),
                    SizedBox(height: context.spacing(20)),
                    _buildStatsGrid(),
                    SizedBox(height: context.spacing(25)),
                    Text(
                      "Próximas Citas",
                      style: TextStyle(
                        fontSize: context.fontSize(17),
                        color: AppTheme.foreground,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: context.spacing(10)),
                    if (_proximasCitas.isEmpty)
                      Center(
                        child: Padding(
                          padding: EdgeInsets.all(context.spacing(32)),
                          child: Text(
                            'No hay citas próximas',
                            style: TextStyle(
                                fontSize: context.fontSize(14),
                                color: AppTheme.muted),
                          ),
                        ),
                      )
                    else
                      ..._proximasCitas.map((cita) => Padding(
                            padding:
                                EdgeInsets.only(bottom: context.spacing(12)),
                            child: _buildAppointmentItem(
                              cita['name']!,
                              cita['service']!,
                              cita['time']!,
                            ),
                          )),
                    SizedBox(height: context.spacing(60)),
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

    final parts =
        _userName.trim().split(' ').where((p) => p.isNotEmpty).toList();
    final initials = parts.length >= 2
        ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
        : parts.isNotEmpty
            ? parts[0][0].toUpperCase()
            : 'U';

    final rolLabel = _userRole == 'Admin'
        ? 'Administrador'
        : _userRole == 'Cliente'
            ? 'Cliente'
            : _userRole.isNotEmpty
                ? _userRole
                : 'Usuario';

    final topPadding = MediaQuery.of(context).padding.top;
    final isSmall = context.isSmallMobile;

    return Container(
      padding: EdgeInsets.fromLTRB(
        context.horizontalPadding,
        topPadding + context.verticalPadding,
        context.horizontalPadding,
        context.spacing(28),
      ),
      decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(context.borderRadius(24)),
          bottomRight: Radius.circular(context.borderRadius(24)),
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
                  style: TextStyle(
                    fontSize: context.fontSize(13),
                    color: Colors.white70,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                SizedBox(height: context.spacing(4)),
                Text(
                  parts.isNotEmpty ? parts[0] : 'Usuario',
                  style: TextStyle(
                    fontSize: context.fontSize(isSmall ? 18 : 22),
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                SizedBox(height: context.spacing(6)),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.spacing(10),
                    vertical: context.spacing(3),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius:
                        BorderRadius.circular(context.borderRadius(20)),
                  ),
                  child: Text(
                    rolLabel,
                    style: TextStyle(
                      fontSize: context.fontSize(12),
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: context.spacing(12)),
          Container(
            width: context.scale(50),
            height: context.scale(50),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
              border:
                  Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
            ),
            child: Center(
              child: Text(
                initials,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: context.fontSize(18),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoCard() {
    return Container(
      padding: EdgeInsets.all(context.spacing(18)),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(context.borderRadius(18)),
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
            padding: EdgeInsets.all(context.spacing(10)),
            decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                shape: BoxShape.circle),
            child: Icon(Icons.trending_up,
                color: AppTheme.primary, size: context.iconSize(24)),
          ),
          SizedBox(width: context.spacing(15)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Bienvenido al Dashboard",
                    style: TextStyle(
                        fontSize: context.fontSize(16),
                        fontWeight: FontWeight.w600)),
                SizedBox(height: context.spacing(4)),
                Text(
                  "Gestiona tu negocio desde aquí",
                  style: TextStyle(
                      fontSize: context.fontSize(13), color: AppTheme.muted),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    final columns =
        ResponsiveUtils.gridColumns(context, mobile: 2, tablet: 4, desktop: 4);

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: columns,
      mainAxisSpacing: context.spacing(12),
      crossAxisSpacing: context.spacing(12),
      childAspectRatio: context.cardAspectRatio,
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
      padding: EdgeInsets.all(context.spacing(16)),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(context.borderRadius(16)),
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
            padding: EdgeInsets.all(context.spacing(10)),
            decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                shape: BoxShape.circle),
            child:
                Icon(icon, size: context.iconSize(22), color: AppTheme.primary),
          ),
          SizedBox(width: context.spacing(14)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(value,
                    style: TextStyle(
                        fontSize: context.fontSize(18),
                        fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text(label,
                    style: TextStyle(
                        fontSize: context.fontSize(13), color: AppTheme.muted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildAppointmentItem(String name, String service, String hour) {
    return Container(
      padding: EdgeInsets.all(context.spacing(16)),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(context.borderRadius(16)),
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
            padding: EdgeInsets.all(context.spacing(12)),
            decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                shape: BoxShape.circle),
            child: Icon(Icons.access_time_filled,
                size: context.iconSize(24), color: AppTheme.primary),
          ),
          SizedBox(width: context.spacing(14)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: TextStyle(
                        fontSize: context.fontSize(15),
                        fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text(service,
                    style: TextStyle(
                        fontSize: context.fontSize(13), color: AppTheme.muted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Text(hour,
              style: TextStyle(
                  fontSize: context.fontSize(15),
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary)),
        ],
      ),
    );
  }
}
