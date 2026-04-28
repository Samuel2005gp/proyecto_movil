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
    // Por ahora mostrar un mensaje, luego se puede implementar la edición completa
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Cita'),
        content: const Text(
            'Funcionalidad de edición en desarrollo.\n\nPor ahora puedes cancelar la cita y crear una nueva.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendido'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _changeStatus(appointment, 'Cancelada');
            },
            child: const Text('Cancelar Cita'),
          ),
        ],
      ),
    );
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
                if (_userRole != 'Cliente')
                  _actionBtn(
                      Icons.check_circle_outline,
                      'Completar',
                      AppTheme.colorSuccess,
                      () => _changeStatus(appointment, 'Completada')),
                _actionBtn(
                    Icons.cancel_outlined,
                    'Cancelar',
                    AppTheme.colorEdit,
                    () => _changeStatus(appointment, 'Cancelada')),
              ],
              if (_userRole == 'Admin')
                _actionBtn(Icons.close, 'Eliminar', AppTheme.destructive,
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
