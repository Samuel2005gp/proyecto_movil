import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/services/api_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/constants/api_constants.dart';
import '../../core/theme/app_theme.dart';

class CreateAppointmentScreen extends StatefulWidget {
  const CreateAppointmentScreen({super.key});
  @override
  State<CreateAppointmentScreen> createState() => _CreateAppointmentScreenState();
}

class _CreateAppointmentScreenState extends State<CreateAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notasCtrl = TextEditingController();

  int? _selectedClienteId;
  DateTime _selectedDate = DateTime.now();
  String? _selectedHora;
  bool _isSaving = false;
  String? _userRole;

  List<Map<String, dynamic>> _clientes = [];
  List<Map<String, dynamic>> _servicios = [];
  List<Map<String, dynamic>> _empleados = [];
  bool _isLoadingData = true;

  final List<Map<String, dynamic>> _serviciosAgregados = [];
  int? _servicioSeleccionado;
  int? _empleadoSeleccionado;

  final List<String> _horas = [
    '08:00','08:30','09:00','09:30','10:00','10:30',
    '11:00','11:30','12:00','12:30','13:00','13:30',
    '14:00','14:30','15:00','15:30','16:00','16:30',
    '17:00','17:30','18:00',
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _notasCtrl.dispose();
    super.dispose();
  }

  int _toInt(dynamic v) => int.tryParse(v?.toString() ?? '0') ?? 0;
  double _toDouble(dynamic v) => double.tryParse(v?.toString() ?? '0') ?? 0.0;

  Future<void> _loadInitialData() async {
    setState(() => _isLoadingData = true);
    _userRole = await StorageService.getRole();

    try {
      final futures = <Future>[
        ApiService.get(ApiConstants.services),
        ApiService.get(ApiConstants.employees),
      ];
      if (_userRole == 'Admin') {
        futures.add(ApiService.get(ApiConstants.clients));
      }

      final results = await Future.wait(futures);

      if (results[0].statusCode == 200) {
        final data = jsonDecode(results[0].body) as List;
        _servicios = data.map((s) => {
          'id':       _toInt(s['id']),
          'name':     s['name']?.toString() ?? s['nombre']?.toString() ?? '',
          'price':    _toDouble(s['price'] ?? s['precio']),
          'duration': _toInt(s['duration'] ?? s['duracion']),
        }).toList();
      }

      if (results[1].statusCode == 200) {
        final data = jsonDecode(results[1].body) as List;
        _empleados = data.map((e) => {
          'id':   _toInt(e['id']),
          'name': '${e['firstName'] ?? e['nombre'] ?? ''} ${e['lastName'] ?? e['apellido'] ?? ''}'.trim(),
        }).toList();
      }

      if (_userRole == 'Admin' && results.length > 2 && results[2].statusCode == 200) {
        final data = jsonDecode(results[2].body) as List;
        _clientes = data.map((c) => {
          'id':   _toInt(c['id']),
          'name': '${c['nombre'] ?? c['firstName'] ?? ''} ${c['apellido'] ?? c['lastName'] ?? ''}'.trim(),
        }).toList();
      }
    } catch (e) {
      _showError('Error cargando datos: $e');
    }

    setState(() => _isLoadingData = false);
  }

  void _agregarServicio() {
    if (_servicioSeleccionado == null) { _showError('Selecciona un servicio'); return; }
    if (_empleadoSeleccionado == null) { _showError('Selecciona un empleado'); return; }

    final servicio = _servicios.firstWhere((s) => s['id'] == _servicioSeleccionado);
    final empleado = _empleados.firstWhere((e) => e['id'] == _empleadoSeleccionado);

    setState(() {
      _serviciosAgregados.add({
        'serviceId':    _servicioSeleccionado,
        'serviceName':  servicio['name'],
        'employeeId':   _empleadoSeleccionado,
        'employeeName': empleado['name'],
      });
      _servicioSeleccionado = null;
      _empleadoSeleccionado = null;
    });
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppTheme.primary)),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_userRole == 'Admin' && _selectedClienteId == null) { _showError('Selecciona un cliente'); return; }
    if (_selectedHora == null) { _showError('Selecciona una hora'); return; }
    if (_serviciosAgregados.isEmpty) { _showError('Agrega al menos un servicio'); return; }

    setState(() => _isSaving = true);
    try {
      final fechaStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final endpoint = _userRole == 'Admin'
          ? ApiConstants.appointments
          : _userRole == 'Cliente'
              ? ApiConstants.misCitas
              : ApiConstants.misCitasEmpleado;

      final body = {
        'fecha':    fechaStr,
        'horario':  _selectedHora,
        'notas':    _notasCtrl.text.trim(),
        'servicios': _serviciosAgregados.map((s) => {
          'serviceId':  s['serviceId'],
          'employeeId': s['employeeId'],
        }).toList(),
        if (_userRole == 'Admin' && _selectedClienteId != null)
          'cliente_id': _selectedClienteId,
      };

      final response = await ApiService.post(endpoint, body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Cita creada exitosamente'),
            backgroundColor: AppTheme.colorSuccess));
        Navigator.pop(context, true);
      } else {
        String errorMsg = 'Error ${response.statusCode}';
        try {
          final error = jsonDecode(response.body);
          errorMsg = error['message']?.toString() ?? error['error']?.toString() ?? errorMsg;
        } catch (_) {}
        _showError(errorMsg);
      }
    } catch (e) {
      _showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showError(String msg) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppTheme.destructive,
          duration: const Duration(seconds: 4)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva Cita')),
      body: _isLoadingData
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                            color: AppTheme.colorPurple.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.calendar_month, color: AppTheme.colorPurple),
                      ),
                      const SizedBox(width: 12),
                      const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Nueva Cita', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                        Text('Programa una nueva cita', style: TextStyle(fontSize: 13, color: AppTheme.muted)),
                      ]),
                    ]),
                    const SizedBox(height: 28),

                    // Cliente (solo admin)
                    if (_userRole == 'Admin') ...[
                      const Text('Cliente *', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        value: _selectedClienteId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                            hintText: 'Selecciona un cliente',
                            prefixIcon: Icon(Icons.person_outline)),
                        items: _clientes.map((c) => DropdownMenuItem<int>(
                            value: c['id'] as int,
                            child: Text(c['name'], overflow: TextOverflow.ellipsis))).toList(),
                        onChanged: (v) => setState(() => _selectedClienteId = v),
                        validator: (v) => v == null ? 'Selecciona un cliente' : null,
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Fecha
                    const Text('Fecha *', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _selectDate,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                            color: AppTheme.inputBg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.border)),
                        child: Row(children: [
                          Expanded(child: Text(
                              DateFormat('dd/MM/yyyy').format(_selectedDate),
                              style: const TextStyle(fontSize: 14))),
                          const Icon(Icons.calendar_today, size: 18, color: AppTheme.muted),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Hora
                    const Text('Hora de Inicio *', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedHora,
                      isExpanded: true,
                      decoration: const InputDecoration(hintText: 'Selecciona hora'),
                      items: _horas.map((h) => DropdownMenuItem(value: h, child: Text(h))).toList(),
                      onChanged: (v) => setState(() => _selectedHora = v),
                      validator: (v) => v == null ? 'Selecciona una hora' : null,
                    ),
                    const SizedBox(height: 24),

                    // Agregar Servicios
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                          color: AppTheme.card,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.border)),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('Agregar Servicios',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 16),

                        // Servicio
                        const Text('Servicio', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<int>(
                          value: _servicioSeleccionado,
                          isExpanded: true,
                          decoration: const InputDecoration(hintText: 'Selecciona servicio'),
                          items: _servicios.map((s) => DropdownMenuItem<int>(
                              value: s['id'] as int,
                              child: Text(s['name'], overflow: TextOverflow.ellipsis))).toList(),
                          onChanged: (v) => setState(() => _servicioSeleccionado = v),
                        ),
                        const SizedBox(height: 12),

                        // Empleado
                        const Text('Empleado', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<int>(
                          value: _empleadoSeleccionado,
                          isExpanded: true,
                          decoration: const InputDecoration(hintText: 'Selecciona empleado'),
                          items: _empleados.map((e) => DropdownMenuItem<int>(
                              value: e['id'] as int,
                              child: Text(e['name'], overflow: TextOverflow.ellipsis))).toList(),
                          onChanged: (v) => setState(() => _empleadoSeleccionado = v),
                        ),
                        const SizedBox(height: 12),

                        // Servicios agregados
                        ..._serviciosAgregados.asMap().entries.map((entry) {
                          final i = entry.key;
                          final s = entry.value;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                                color: AppTheme.primary.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppTheme.primary.withOpacity(0.2))),
                            child: Row(children: [
                              const Icon(Icons.check_circle, size: 16, color: AppTheme.colorSuccess),
                              const SizedBox(width: 8),
                              Expanded(child: Text(
                                  '${s['serviceName']} - ${s['employeeName']}',
                                  style: const TextStyle(fontSize: 13),
                                  overflow: TextOverflow.ellipsis)),
                              GestureDetector(
                                onTap: () => setState(() => _serviciosAgregados.removeAt(i)),
                                child: const Icon(Icons.close, size: 16, color: AppTheme.destructive),
                              ),
                            ]),
                          );
                        }),

                        if (_serviciosAgregados.isNotEmpty) const SizedBox(height: 8),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _agregarServicio,
                            icon: const Icon(Icons.add),
                            label: const Text('Agregar Servicio'),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primary.withOpacity(0.7),
                                padding: const EdgeInsets.symmetric(vertical: 14)),
                          ),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 20),

                    // Notas
                    const Text('Notas (opcional)',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _notasCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                          hintText: 'Preferencias del cliente, alergias, etc.'),
                    ),
                    const SizedBox(height: 32),

                    // Botones
                    Row(children: [
                      Expanded(child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancelar'))),
                      const SizedBox(width: 12),
                      Expanded(child: ElevatedButton(
                        onPressed: _isSaving ? null : _save,
                        child: _isSaving
                            ? const SizedBox(height: 20, width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Crear Cita'),
                      )),
                    ]),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }
}