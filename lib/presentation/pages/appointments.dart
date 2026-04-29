import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../core/services/api_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/constants/api_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/snackbar_helper.dart';
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
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final role = await StorageService.getRole();
      setState(() => _userRole = role);
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
          _allAppointments =
              data.map((j) => AppointmentModel.fromJson(j)).toList();
          _isLoading = false;
        });
      } else {
        throw Exception('Error al cargar citas');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  List<AppointmentModel> _getAppointmentsOfDay(DateTime day) {
    final dayStr = DateFormat('yyyy-MM-dd').format(day);
    return _allAppointments.where((a) => a.fecha == dayStr).toList();
  }

  Future<void> _deleteAppointment(AppointmentModel appointment) async {
    if (appointment.estado == 'Completada') {
      _showError('No se puede eliminar una cita completada');
      return;
    }
    if (appointment.estado == 'Cancelada') {
      _showError('No se puede eliminar una cita ya cancelada');
      return;
    }
    final confirm = await _showConfirmDialog(
      '¿Eliminar la cita de ${appointment.clienteNombre.isNotEmpty ? appointment.clienteNombre : "este cliente"}?\n\nEsta acción no se puede deshacer.',
    );
    if (!confirm) return;
    try {
      final response = await ApiService.delete(
          ApiConstants.appointmentDetail(appointment.id));
      if (response.statusCode == 200) {
        _showSuccess('Cita eliminada correctamente');
        _loadAppointments();
      } else {
        final error = jsonDecode(response.body);
        _showError(error['error']?.toString() ?? 'Error al eliminar');
      }
    } catch (e) {
      _showError(
          'Error de conexión: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }

  Future<void> _changeStatus(
      AppointmentModel appointment, String newStatus) async {
    if (appointment.estado == 'Completada') {
      _showError('Esta cita ya está completada y no puede modificarse');
      return;
    }
    if (appointment.estado == 'Cancelada') {
      _showError('Esta cita ya está cancelada y no puede modificarse');
      return;
    }
    if (appointment.estado == newStatus) {
      _showError('La cita ya tiene el estado "$newStatus"');
      return;
    }
    if (newStatus == 'Completada') {
      final fechaHora =
          DateTime.tryParse('${appointment.fecha} ${appointment.horario}');
      if (fechaHora != null && fechaHora.isAfter(DateTime.now())) {
        final confirm = await _showConfirmDialog(
            'La cita es futura. ¿Deseas marcarla como completada de todas formas?');
        if (!confirm) return;
      }
    }
    final accion = newStatus == 'Completada' ? 'completar' : 'cancelar';
    final confirm = await _showConfirmDialog('¿Deseas $accion esta cita?');
    if (!confirm) return;
    try {
      final statusMap = {
        'Completada': 'completed',
        'Cancelada': 'cancelled',
        'Pendiente': 'pending'
      };
      final statusEn = statusMap[newStatus] ?? newStatus.toLowerCase();
      final response = await ApiService.patch(
        ApiConstants.appointmentStatus(appointment.id),
        {'status': statusEn},
      );
      if (response.statusCode == 200) {
        _showSuccess('Cita marcada como $newStatus');
        _loadAppointments();
      } else {
        final error = jsonDecode(response.body);
        _showError(error['error']?.toString() ?? 'Error al cambiar estado');
      }
    } catch (e) {
      _showError(
          'Error de conexión: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }

  void _viewAppointment(AppointmentModel appointment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detalles de la Cita'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow(
                  'Cliente:',
                  appointment.clienteNombre.isNotEmpty
                      ? appointment.clienteNombre
                      : 'Sin cliente'),
              _buildDetailRow('Servicio:', appointment.servicioNombre),
              if (appointment.empleadoNombre.isNotEmpty)
                _buildDetailRow('Empleado:', appointment.empleadoNombre),
              _buildDetailRow('Fecha:', appointment.fecha),
              _buildDetailRow('Hora:', appointment.horario),
              _buildDetailRow('Estado:', appointment.estado),
              if (appointment.notas != null && appointment.notas!.isNotEmpty)
                _buildDetailRow('Notas:', appointment.notas!),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.muted,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _editAppointment(AppointmentModel appointment) {
    Navigator.push<bool>(
      context,
      MaterialPageRoute(
          builder: (_) => EditAppointmentScreen(appointment: appointment)),
    ).then((updated) {
      if (updated == true) _loadAppointments();
    });
  }

  void _showSuccess(String msg) => SnackBarHelper.showSuccess(context, msg);
  void _showError(String msg) => SnackBarHelper.showError(context, msg);

  Future<bool> _showConfirmDialog(String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar'),
        content: Text(message),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Confirmar')),
        ],
      ),
    );
    return result ?? false;
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completada':
        return const Color(0xFF1D4ED8); // azul
      case 'pendiente':
        return const Color(0xFFD97706); // amarillo
      case 'cancelada':
        return const Color(0xFFDC2626); // rojo
      default:
        return AppTheme.muted;
    }
  }

  Color _getStatusBgColor(String status) {
    switch (status.toLowerCase()) {
      case 'completada':
        return const Color(0xFFDBEAFE); // azul claro
      case 'pendiente':
        return const Color(0xFFFEF9C3); // amarillo claro
      case 'cancelada':
        return const Color(0xFFFCE7F3); // rojo claro
      default:
        return const Color(0xFFF3F4F6);
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completada':
        return Icons.check_circle_rounded;
      case 'pendiente':
        return Icons.schedule_rounded;
      case 'cancelada':
        return Icons.cancel_rounded;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
          body: Center(
              child: CircularProgressIndicator(color: AppTheme.primary)));
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
                onPressed: _loadAppointments, child: const Text('Reintentar')),
          ])));
    }

    final dayAppointments = _getAppointmentsOfDay(_selectedDay!);

    return Scaffold(
      backgroundColor: AppTheme.background,
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final created = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                  builder: (_) => const CreateAppointmentScreen()));
          if (created == true) _loadAppointments();
        },
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          _buildHeader(dayAppointments.length),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadAppointments,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCalendarCard(),
                      const SizedBox(height: 8),
                      _buildLegend(),
                      const SizedBox(height: 28),
                      _buildDayAppointments(dayAppointments),
                    ]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(int count) {
    final isToday = _selectedDay!.year == DateTime.now().year &&
        _selectedDay!.month == DateTime.now().month &&
        _selectedDay!.day == DateTime.now().day;
    final topPadding = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, topPadding + 16, 20, 24),
      decoration: const BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(children: [
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Citas',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const SizedBox(height: 4),
            Text(
              isToday
                  ? 'Hoy, ${DateFormat('dd/MM/yyyy').format(_selectedDay!)}'
                  : DateFormat('dd/MM/yyyy').format(_selectedDay!),
              style: const TextStyle(fontSize: 13, color: Colors.white70),
            ),
          ]),
        ),
        if (count > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$count ${count == 1 ? 'cita' : 'citas'}',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13),
            ),
          ),
      ]),
    );
  }

  Widget _buildCalendarCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
        border: Border.all(
            color: AppTheme.primary.withValues(alpha: 0.15), width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: TableCalendar(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) =>
              day.year == _selectedDay!.year &&
              day.month == _selectedDay!.month &&
              day.day == _selectedDay!.day,
          availableCalendarFormats: const {CalendarFormat.month: 'Mes'},
          eventLoader: _getAppointmentsOfDay,
          headerStyle: HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            titleTextStyle:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            leftChevronIcon:
                Icon(Icons.chevron_left_rounded, color: AppTheme.primary),
            rightChevronIcon:
                Icon(Icons.chevron_right_rounded, color: AppTheme.primary),
            headerPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
          daysOfWeekStyle: const DaysOfWeekStyle(
            weekdayStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.muted),
            weekendStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.muted),
          ),
          calendarStyle: const CalendarStyle(
            markersMaxCount: 3,
            outsideDaysVisible: true,
            outsideTextStyle: TextStyle(color: AppTheme.muted, fontSize: 13),
            defaultTextStyle: TextStyle(fontSize: 13),
            weekendTextStyle: TextStyle(fontSize: 13),
          ),
          calendarBuilders: CalendarBuilders(
            markerBuilder: (context, date, events) {
              if (events.isEmpty) return const SizedBox.shrink();
              final appointments = events.cast<AppointmentModel>();
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: appointments.take(3).map((a) {
                    final color = _getStatusColor(a.estado);
                    return Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 1.5),
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                              color: color.withValues(alpha: 0.5),
                              blurRadius: 3,
                              spreadRadius: 0.5)
                        ],
                      ),
                    );
                  }).toList(),
                ),
              );
            },
            selectedBuilder: (context, date, _) => Center(
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2))
                  ],
                ),
                alignment: Alignment.center,
                child: Text('${date.day}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold)),
              ),
            ),
            todayBuilder: (context, date, _) => Center(
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: AppTheme.primary.withValues(alpha: 0.4),
                      width: 1.5),
                ),
                alignment: Alignment.center,
                child: Text('${date.day}',
                    style: const TextStyle(
                        color: AppTheme.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          ),
          onDaySelected: (selected, focused) {
            setState(() {
              _selectedDay = selected;
              _focusedDay = focused;
            });
          },
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      _legendItem(AppTheme.colorEdit, 'Pendiente'),
      const SizedBox(width: 16),
      _legendItem(AppTheme.colorSuccess, 'Completada'),
      const SizedBox(width: 16),
      _legendItem(AppTheme.destructive, 'Cancelada'),
    ]);
  }

  Widget _legendItem(Color color, String label) {
    return Row(children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 3)
          ],
        ),
      ),
      const SizedBox(width: 5),
      Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.muted)),
    ]);
  }

  Widget _buildDayAppointments(List<AppointmentModel> appointments) {
    final isToday = _selectedDay!.year == DateTime.now().year &&
        _selectedDay!.month == DateTime.now().month &&
        _selectedDay!.day == DateTime.now().day;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(
          isToday ? 'Hoy' : DateFormat('dd/MM/yyyy').format(_selectedDay!),
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        if (appointments.isNotEmpty) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('${appointments.length}',
                style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.primary,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ]),
      const SizedBox(height: 12),
      if (appointments.isEmpty)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppTheme.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(children: [
            Icon(Icons.calendar_today_outlined,
                size: 40, color: AppTheme.muted.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            const Text('Sin citas para este día',
                style: TextStyle(color: AppTheme.muted, fontSize: 14)),
          ]),
        )
      else
        ...appointments.map((a) => _buildAppointmentCard(a)),
    ]);
  }

  Widget _buildAppointmentCard(AppointmentModel appointment) {
    final statusColor = _getStatusColor(appointment.estado);
    final statusBg = _getStatusBgColor(appointment.estado);
    final statusIcon = _getStatusIcon(appointment.estado);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: statusBg,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: statusColor, width: 4)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            // Hora destacada
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(appointment.horario,
                  style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
            ),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(
                    appointment.clienteNombre.isNotEmpty
                        ? appointment.clienteNombre
                        : 'Cliente',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(appointment.servicioNombre,
                      style:
                          const TextStyle(fontSize: 12, color: AppTheme.muted),
                      overflow: TextOverflow.ellipsis),
                ])),
            // Badge de estado
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(statusIcon, size: 12, color: statusColor),
                const SizedBox(width: 4),
                Text(appointment.estado,
                    style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ]),
            ),
          ]),
          if (appointment.empleadoNombre.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.person_outline, size: 13, color: AppTheme.muted),
              const SizedBox(width: 4),
              Text(appointment.empleadoNombre,
                  style: const TextStyle(fontSize: 12, color: AppTheme.muted)),
            ]),
          ],
          if (appointment.notas != null && appointment.notas!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.notes_rounded, size: 13, color: AppTheme.muted),
              const SizedBox(width: 4),
              Expanded(
                  child: Text(appointment.notas!,
                      style:
                          const TextStyle(fontSize: 12, color: AppTheme.muted),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis)),
            ]),
          ],
          if (appointment.estado == 'Pendiente' || _userRole == 'Admin') ...[
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 6),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              if (appointment.estado == 'Pendiente') ...[
                _actionBtn(Icons.remove_red_eye_outlined, 'Ver',
                    AppTheme.primary, () => _viewAppointment(appointment)),
                _actionBtn(Icons.edit_outlined, 'Editar', AppTheme.primary,
                    () => _editAppointment(appointment)),
              ],
              if (_userRole == 'Admin')
                _actionBtn(
                    Icons.delete_outline,
                    'Eliminar',
                    AppTheme.destructive,
                    () => _deleteAppointment(appointment)),
            ]),
          ],
        ]),
      ),
    );
  }

  Widget _actionBtn(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16, color: color),
      label: Text(label, style: TextStyle(color: color, fontSize: 12)),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

// ── EDITAR CITA ───────────────────────────────────────────────────────────────
class EditAppointmentScreen extends StatefulWidget {
  final AppointmentModel appointment;
  const EditAppointmentScreen({super.key, required this.appointment});
  @override
  State<EditAppointmentScreen> createState() => _EditAppointmentScreenState();
}

class _EditAppointmentScreenState extends State<EditAppointmentScreen> {
  bool _isLoading = true;
  bool _isSaving = false;

  // Datos cargados
  List<Map<String, dynamic>> _clientes = [];
  List<Map<String, dynamic>> _servicios = [];
  List<Map<String, dynamic>> _empleados = [];

  // Selecciones
  int? _clienteSeleccionado;
  DateTime _fecha = DateTime.now();
  String _hora = '08:00';
  final TextEditingController _notasCtrl = TextEditingController();

  // Servicios agregados: [{servicio, empleado_usuario, nombre, empleadoNombre}]
  final List<Map<String, dynamic>> _serviciosAgregados = [];

  // Para agregar nuevo servicio
  int? _servicioTemp;
  int? _empleadoTemp;

  // Horas disponibles
  final List<String> _horas = List.generate(
    28,
    (i) {
      final h = 7 + i ~/ 2;
      final m = (i % 2) * 30;
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
    },
  );

  @override
  void initState() {
    super.initState();
    _initFromAppointment();
    _loadData();
  }

  void _initFromAppointment() {
    final a = widget.appointment;
    _clienteSeleccionado = a.clienteId > 0 ? a.clienteId : null;
    _notasCtrl.text = a.notas ?? '';
    // Fecha
    try {
      _fecha = DateTime.parse(a.fecha);
    } catch (_) {
      _fecha = DateTime.now();
    }
    // Hora
    _hora = a.horario.length >= 5 ? a.horario.substring(0, 5) : '08:00';
    // Servicios existentes
    for (final s in a.servicios) {
      _serviciosAgregados.add({
        'servicio': s.serviceId,
        'empleado_usuario': s.employeeId,
        'nombre': s.serviceName,
        'empleadoNombre': s.employeeName,
        'duracion': s.duration,
      });
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        ApiService.get(ApiConstants.clients),
        ApiService.get(ApiConstants.services),
        ApiService.get(ApiConstants.employees),
      ]);
      if (results[0].statusCode == 200) {
        final data = jsonDecode(results[0].body) as List;
        _clientes = data
            .map((c) => {
                  'id': c['id'] ?? c['PK_id_cliente'],
                  'name':
                      '${c['nombre'] ?? c['firstName'] ?? ''} ${c['apellido'] ?? c['lastName'] ?? ''}'
                          .trim(),
                })
            .toList();
      }
      if (results[1].statusCode == 200) {
        final data = jsonDecode(results[1].body) as List;
        _servicios = data
            .map((s) => {
                  'id': s['id'],
                  'name': s['name'] ?? s['nombre'] ?? '',
                  'duracion': s['duration'] ?? s['duracion'] ?? 60,
                  'precio': (s['price'] ?? s['precio'] ?? 0).toDouble(),
                })
            .toList();
      }
      if (results[2].statusCode == 200) {
        final data = jsonDecode(results[2].body) as List;
        _empleados = data
            .map((e) => {
                  'id': int.tryParse(e['id']?.toString() ?? '0') ?? 0,
                  'name': e['name'] ??
                      '${e['nombre'] ?? ''} ${e['apellido'] ?? ''}'.trim(),
                })
            .toList();
      }
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _notasCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('es'),
    );
    if (picked != null) setState(() => _fecha = picked);
  }

  void _agregarServicio() {
    if (_servicioTemp == null) {
      SnackBarHelper.showError(context, 'Selecciona un servicio');
      return;
    }
    final s = _servicios.firstWhere((x) => x['id'] == _servicioTemp);
    final e = _empleadoTemp != null
        ? _empleados.firstWhere((x) => x['id'] == _empleadoTemp,
            orElse: () => {'id': 0, 'name': ''})
        : null;
    setState(() {
      _serviciosAgregados.add({
        'servicio': _servicioTemp,
        'empleado_usuario': _empleadoTemp ?? 0,
        'nombre': s['name'],
        'empleadoNombre': e?['name'] ?? '',
        'duracion': s['duracion'],
      });
      _servicioTemp = null;
      _empleadoTemp = null;
    });
  }

  int get _duracionTotal => _serviciosAgregados.fold(
      0, (sum, s) => sum + ((s['duracion'] as int?) ?? 60));

  String get _horaFin {
    if (_serviciosAgregados.isEmpty) return _hora;
    final parts = _hora.split(':');
    final mins =
        int.parse(parts[0]) * 60 + int.parse(parts[1]) + _duracionTotal;
    return '${(mins ~/ 60).toString().padLeft(2, '0')}:${(mins % 60).toString().padLeft(2, '0')}';
  }

  Future<void> _save() async {
    if (_serviciosAgregados.isEmpty) {
      SnackBarHelper.showError(context, 'Agrega al menos un servicio');
      return;
    }
    setState(() => _isSaving = true);
    try {
      final body = {
        'cliente': _clienteSeleccionado,
        'fecha': DateFormat('yyyy-MM-dd').format(_fecha),
        'hora': _hora,
        'notas': _notasCtrl.text.trim(),
        'servicios': _serviciosAgregados
            .map((s) => {
                  'servicio': s['servicio'],
                  'empleado_usuario': s['empleado_usuario'],
                  'precio': null,
                })
            .toList(),
      };
      final response = await ApiService.put(
          ApiConstants.appointmentDetail(widget.appointment.id), body);
      if (response.statusCode == 200) {
        if (!mounted) return;
        SnackBarHelper.showSuccess(context, 'Cita actualizada correctamente');
        Navigator.pop(context, true);
      } else {
        String errorMsg = 'Error ${response.statusCode}';
        try {
          final err = jsonDecode(response.body);
          errorMsg = err['error']?.toString() ?? errorMsg;
        } catch (_) {}
        if (!mounted) return;
        SnackBarHelper.showError(context, errorMsg);
      }
    } catch (e) {
      if (!mounted) return;
      SnackBarHelper.showError(
          context, e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar Cita')),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cliente
                  const Text('Cliente',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    value: _clienteSeleccionado,
                    isExpanded: true,
                    decoration: const InputDecoration(
                        hintText: 'Selecciona un cliente'),
                    items: _clientes
                        .map((c) => DropdownMenuItem<int>(
                              value: c['id'] as int,
                              child: Text(c['name'],
                                  overflow: TextOverflow.ellipsis),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _clienteSeleccionado = v),
                  ),
                  const SizedBox(height: 16),

                  // Fecha y Hora
                  Row(children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Fecha *',
                              style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: _pickDate,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: AppTheme.inputBg,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppTheme.border),
                              ),
                              child: Row(children: [
                                const Icon(Icons.calendar_today_outlined,
                                    size: 18, color: AppTheme.muted),
                                const SizedBox(width: 8),
                                Text(DateFormat('dd/MM/yyyy').format(_fecha),
                                    style: const TextStyle(fontSize: 14)),
                              ]),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Hora *',
                              style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value:
                                _horas.contains(_hora) ? _hora : _horas.first,
                            isExpanded: true,
                            decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.access_time)),
                            items: _horas
                                .map((h) =>
                                    DropdownMenuItem(value: h, child: Text(h)))
                                .toList(),
                            onChanged: (v) => setState(() => _hora = v!),
                          ),
                        ],
                      ),
                    ),
                  ]),
                  const SizedBox(height: 20),

                  // Sección servicios
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Agregar Servicios',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),

                        // Servicio dropdown
                        const Text('Servicio',
                            style:
                                TextStyle(fontSize: 13, color: AppTheme.muted)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<int>(
                          value: _servicioTemp,
                          isExpanded: true,
                          decoration: const InputDecoration(
                              hintText: 'Selecciona servicio'),
                          items: _servicios
                              .map((s) => DropdownMenuItem<int>(
                                    value: s['id'] as int,
                                    child: Text(s['name'],
                                        overflow: TextOverflow.ellipsis),
                                  ))
                              .toList(),
                          onChanged: (v) => setState(() => _servicioTemp = v),
                        ),
                        const SizedBox(height: 10),

                        // Empleado dropdown
                        const Text('Empleado',
                            style:
                                TextStyle(fontSize: 13, color: AppTheme.muted)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<int>(
                          value: _empleadoTemp,
                          isExpanded: true,
                          decoration: const InputDecoration(
                              hintText: 'Selecciona empleado'),
                          items: _empleados
                              .map((e) => DropdownMenuItem<int>(
                                    value: e['id'] as int,
                                    child: Text(e['name'],
                                        overflow: TextOverflow.ellipsis),
                                  ))
                              .toList(),
                          onChanged: (v) => setState(() => _empleadoTemp = v),
                        ),
                        const SizedBox(height: 12),

                        // Botón agregar
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _agregarServicio,
                            icon: const Icon(Icons.add),
                            label: const Text('Agregar Servicio'),
                          ),
                        ),

                        // Lista de servicios agregados
                        if (_serviciosAgregados.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          const Text('Servicios agregados:',
                              style: TextStyle(
                                  fontSize: 12, color: AppTheme.muted)),
                          const SizedBox(height: 6),
                          ..._serviciosAgregados.asMap().entries.map((e) {
                            final s = e.value;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppTheme.background,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppTheme.border),
                              ),
                              child: Row(children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(s['nombre'],
                                          style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600)),
                                      if ((s['empleadoNombre'] as String)
                                          .isNotEmpty)
                                        Row(children: [
                                          const Icon(Icons.person_outline,
                                              size: 12, color: AppTheme.muted),
                                          const SizedBox(width: 3),
                                          Text(s['empleadoNombre'],
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color: AppTheme.muted)),
                                        ]),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close,
                                      size: 16, color: AppTheme.destructive),
                                  onPressed: () => setState(() =>
                                      _serviciosAgregados.removeAt(e.key)),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ]),
                            );
                          }),

                          // Resumen duración
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Duración total: $_duracionTotal min  •  Finaliza: $_horaFin',
                              style: const TextStyle(
                                  fontSize: 12, color: AppTheme.primary),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Notas
                  const Text('Notas (opcional)',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _notasCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                        hintText: 'Agrega notas sobre la cita...'),
                  ),
                  const SizedBox(height: 32),

                  // Botones
                  Row(children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _save,
                        child: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Text('Actualizar Cita'),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}
