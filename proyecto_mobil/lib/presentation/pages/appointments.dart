import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../core/services/api_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/constants/api_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/appointment_model.dart';
import 'create_appointment.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});
  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<AppointmentModel> _allAppointments = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final role = await StorageService.getRole();
      String endpoint;
      if (role == 'Cliente') {
        endpoint = ApiConstants.misCitas;
      } else if (role != 'Admin') {
        endpoint = ApiConstants.misCitasEmpleado;
      } else {
        endpoint = ApiConstants.appointments;
      }

      final response = await ApiService.get(endpoint);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _allAppointments = data.map((json) => AppointmentModel.fromJson(json)).toList();
          _isLoading = false;
        });
      } else {
        throw Exception('Error al cargar citas');
      }
    } catch (e) {
      setState(() { _errorMessage = e.toString(); _isLoading = false; });
    }
  }

  // Filtra citas por dia usando el campo "Fecha" (yyyy-MM-dd)
  List<AppointmentModel> _getAppointmentsOfDay(DateTime day) {
    final dayStr = DateFormat('yyyy-MM-dd').format(day);
    return _allAppointments.where((a) => a.fecha == dayStr).toList();
  }

  Future<void> _deleteAppointment(int id) async {
    final confirm = await _showConfirmDialog('Eliminar esta cita?');
    if (!confirm) return;
    try {
      final response = await ApiService.delete(ApiConstants.appointmentDetail(id));
      if (response.statusCode == 200) {
        _showSuccess('Cita eliminada');
        _loadAppointments();
      } else {
        throw Exception('Error al eliminar');
      }
    } catch (e) { _showError(e.toString()); }
  }

  Future<void> _changeStatus(int id, String newStatus) async {
    try {
      final response = await ApiService.patch(ApiConstants.appointmentStatus(id), {'estado': newStatus});
      if (response.statusCode == 200) {
        _showSuccess('Estado actualizado');
        _loadAppointments();
      } else {
        throw Exception('Error al cambiar estado');
      }
    } catch (e) { _showError(e.toString()); }
  }

  void _showSuccess(String msg) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppTheme.colorSuccess));
  void _showError(String msg) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppTheme.destructive));

  Future<bool> _showConfirmDialog(String message) async {
    final result = await showDialog<bool>(context: context,
      builder: (ctx) => AlertDialog(title: const Text('Confirmar'), content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirmar')),
        ]));
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppTheme.primary)));
    if (_errorMessage != null) {
      return Scaffold(body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.error_outline, size: 60, color: AppTheme.destructive),
        const SizedBox(height: 16), Text(_errorMessage!), const SizedBox(height: 16),
        ElevatedButton(onPressed: _loadAppointments, child: const Text('Reintentar')),
      ])));
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final created = await Navigator.push<bool>(context,
              MaterialPageRoute(builder: (_) => const CreateAppointmentScreen()));
          if (created == true) _loadAppointments();
        },
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadAppointments,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildCalendarCard(),
              const SizedBox(height: 32),
              _buildDayAppointments(),
              const SizedBox(height: 80),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Citas', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      const SizedBox(height: 5),
      Text(DateFormat('dd/MM/yyyy').format(_selectedDay!),
          style: const TextStyle(fontSize: 14, color: AppTheme.muted)),
    ]);
  }

  Widget _buildCalendarCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: AppTheme.card, borderRadius: BorderRadius.circular(18)),
        child: TableCalendar(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) =>
              day.year == _selectedDay!.year && day.month == _selectedDay!.month && day.day == _selectedDay!.day,
          availableCalendarFormats: const {CalendarFormat.month: 'Mes'},
          eventLoader: _getAppointmentsOfDay,
          calendarStyle: const CalendarStyle(
            markersMaxCount: 3,
            markerDecoration: BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
          ),
          calendarBuilders: CalendarBuilders(
            selectedBuilder: (context, date, _) => Center(child: Container(
              width: 28, height: 28,
              decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Text('${date.day}', style: const TextStyle(color: Colors.white, fontSize: 14)))),
            todayBuilder: (context, date, _) => Center(child: Container(
              width: 26, height: 26,
              decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.3), shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Text('${date.day}', style: const TextStyle(color: AppTheme.foreground, fontSize: 13)))),
          ),
          onDaySelected: (selected, focused) {
            setState(() { _selectedDay = selected; _focusedDay = focused; });
          },
        ),
      ),
    );
  }

  Widget _buildDayAppointments() {
    final appointments = _getAppointmentsOfDay(_selectedDay!);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Citas - ${DateFormat('dd/MM/yyyy').format(_selectedDay!)}',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
      const SizedBox(height: 10),
      if (appointments.isEmpty)
        const Center(child: Padding(padding: EdgeInsets.all(32),
            child: Text('No hay citas para este dia', style: TextStyle(color: AppTheme.muted))))
      else
        ...appointments.map((a) => _buildAppointmentCard(a)),
    ]);
  }

  Widget _buildAppointmentCard(AppointmentModel appointment) {
    final statusColor = _getStatusColor(appointment.estado);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.card, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 3))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(25)),
              child: Icon(Icons.access_time, color: statusColor)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(appointment.clienteNombre.isNotEmpty ? appointment.clienteNombre : 'Cliente',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(appointment.servicioNombre, style: const TextStyle(fontSize: 13, color: AppTheme.muted)),
            if (appointment.empleadoNombre.isNotEmpty)
              Text(appointment.empleadoNombre, style: const TextStyle(fontSize: 12, color: AppTheme.muted)),
          ])),
          Text(appointment.horario,
              style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 15)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: statusColor.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
              child: Text(appointment.estado,
                  style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold))),
          const Spacer(),
          if (appointment.estado == 'Pendiente') ...[
            IconButton(icon: const Icon(Icons.check_circle, color: AppTheme.colorSuccess),
                onPressed: () => _changeStatus(appointment.id, 'Completada'), tooltip: 'Completar'),
            IconButton(icon: const Icon(Icons.cancel, color: AppTheme.colorEdit),
                onPressed: () => _changeStatus(appointment.id, 'Cancelada'), tooltip: 'Cancelar'),
          ],
          IconButton(icon: const Icon(Icons.delete_outline, color: AppTheme.destructive),
              onPressed: () => _deleteAppointment(appointment.id), tooltip: 'Eliminar'),
        ]),
        if (appointment.notas != null && appointment.notas!.isNotEmpty) ...[
          const Divider(),
          Text('Notas: ${appointment.notas}', style: const TextStyle(fontSize: 12, color: AppTheme.muted)),
        ],
      ]),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completada': return AppTheme.colorSuccess;
      case 'pendiente':  return AppTheme.colorEdit;
      case 'cancelada':  return AppTheme.destructive;
      default:           return AppTheme.muted;
    }
  }
}