# Ejemplo: Cómo Conectar una Pantalla al Backend

Este documento muestra paso a paso cómo conectar una pantalla al backend usando el ejemplo de Appointments.

## Estructura Básica

```dart
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';
import '../../core/constants/api_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/appointment_model.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  // 1. Variables de estado
  List<AppointmentModel> _appointments = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  // 2. Cargar datos del backend
  Future<void> _loadAppointments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.get(ApiConstants.appointments);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _appointments = data.map((json) => AppointmentModel.fromJson(json)).toList();
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

  // 3. Crear nueva cita
  Future<void> _createAppointment(Map<String, dynamic> data) async {
    try {
      final response = await ApiService.post(
        ApiConstants.appointments,
        data,
      );

      if (response.statusCode == 201) {
        _showSuccess('Cita creada exitosamente');
        _loadAppointments(); // Recargar lista
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Error al crear cita');
      }
    } catch (e) {
      _showError(e.toString());
    }
  }

  // 4. Actualizar cita
  Future<void> _updateAppointment(int id, Map<String, dynamic> data) async {
    try {
      final response = await ApiService.put(
        ApiConstants.appointmentDetail(id),
        data,
      );

      if (response.statusCode == 200) {
        _showSuccess('Cita actualizada exitosamente');
        _loadAppointments();
      } else {
        throw Exception('Error al actualizar cita');
      }
    } catch (e) {
      _showError(e.toString());
    }
  }

  // 5. Eliminar cita
  Future<void> _deleteAppointment(int id) async {
    final confirm = await _showConfirmDialog('¿Eliminar esta cita?');
    if (!confirm) return;

    try {
      final response = await ApiService.delete(
        ApiConstants.appointmentDetail(id),
      );

      if (response.statusCode == 200) {
        _showSuccess('Cita eliminada exitosamente');
        _loadAppointments();
      } else {
        throw Exception('Error al eliminar cita');
      }
    } catch (e) {
      _showError(e.toString());
    }
  }

  // 6. Cambiar estado de cita
  Future<void> _changeStatus(int id, String newStatus) async {
    try {
      final response = await ApiService.patch(
        ApiConstants.appointmentStatus(id),
        {'estado': newStatus},
      );

      if (response.statusCode == 200) {
        _showSuccess('Estado actualizado');
        _loadAppointments();
      } else {
        throw Exception('Error al cambiar estado');
      }
    } catch (e) {
      _showError(e.toString());
    }
  }

  // 7. Helpers para mostrar mensajes
  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.colorSuccess,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.destructive,
      ),
    );
  }

  Future<bool> _showConfirmDialog(String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    // 8. Mostrar loading
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.accent),
        ),
      );
    }

    // 9. Mostrar error
    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 60, color: AppTheme.destructive),
              const SizedBox(height: 16),
              Text(_errorMessage!),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadAppointments,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    // 10. Mostrar lista con RefreshIndicator
    return Scaffold(
      appBar: AppBar(
        title: const Text('Citas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showCreateDialog,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadAppointments,
        child: _appointments.isEmpty
            ? const Center(child: Text('No hay citas'))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _appointments.length,
                itemBuilder: (context, index) {
                  final appointment = _appointments[index];
                  return _buildAppointmentCard(appointment);
                },
              ),
      ),
    );
  }

  Widget _buildAppointmentCard(AppointmentModel appointment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.accent,
          child: const Icon(Icons.calendar_today, color: Colors.white),
        ),
        title: Text(appointment.clienteNombre ?? 'Cliente'),
        subtitle: Text(
          '${appointment.servicioNombre ?? 'Servicio'} - ${appointment.estado}',
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Text('Editar'),
            ),
            const PopupMenuItem(
              value: 'complete',
              child: Text('Completar'),
            ),
            const PopupMenuItem(
              value: 'cancel',
              child: Text('Cancelar'),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Text('Eliminar'),
            ),
          ],
          onSelected: (value) {
            switch (value) {
              case 'edit':
                _showEditDialog(appointment);
                break;
              case 'complete':
                _changeStatus(appointment.id, 'Completada');
                break;
              case 'cancel':
                _changeStatus(appointment.id, 'Cancelada');
                break;
              case 'delete':
                _deleteAppointment(appointment.id);
                break;
            }
          },
        ),
      ),
    );
  }

  void _showCreateDialog() {
    // TODO: Implementar formulario de creación
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nueva Cita'),
        content: const Text('Formulario de creación aquí'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              // Ejemplo de datos
              _createAppointment({
                'cliente_id': 1,
                'empleado_id': 2,
                'servicio_id': 3,
                'fecha_hora': DateTime.now().toIso8601String(),
                'notas': 'Nota de ejemplo',
              });
              Navigator.pop(context);
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(AppointmentModel appointment) {
    // TODO: Implementar formulario de edición
  }
}
```

## Patrón de Uso

### 1. GET - Listar datos
```dart
final response = await ApiService.get(ApiConstants.appointments);
if (response.statusCode == 200) {
  final List<dynamic> data = jsonDecode(response.body);
  final items = data.map((json) => Model.fromJson(json)).toList();
}
```

### 2. POST - Crear
```dart
final response = await ApiService.post(
  ApiConstants.appointments,
  {
    'campo1': 'valor1',
    'campo2': 'valor2',
  },
);
if (response.statusCode == 201) {
  // Éxito
}
```

### 3. PUT - Actualizar
```dart
final response = await ApiService.put(
  ApiConstants.appointmentDetail(id),
  {
    'campo1': 'nuevo_valor',
  },
);
```

### 4. PATCH - Actualizar parcial
```dart
final response = await ApiService.patch(
  ApiConstants.appointmentStatus(id),
  {'estado': 'Completada'},
);
```

### 5. DELETE - Eliminar
```dart
final response = await ApiService.delete(
  ApiConstants.appointmentDetail(id),
);
```

## Manejo de Errores

```dart
try {
  final response = await ApiService.get(endpoint);
  
  if (response.statusCode == 200) {
    // Éxito
  } else if (response.statusCode == 404) {
    throw Exception('No encontrado');
  } else if (response.statusCode == 403) {
    throw Exception('No tienes permisos');
  } else {
    final error = jsonDecode(response.body);
    throw Exception(error['message'] ?? 'Error desconocido');
  }
} on UnauthorizedException catch (e) {
  // El ApiService ya redirige al login
  print('Sesión expirada');
} catch (e) {
  // Otros errores
  _showError(e.toString());
}
```

## Filtrado por Rol

```dart
Future<void> _loadAppointments() async {
  final role = await StorageService.getRole();
  final userId = await StorageService.getUserId();
  
  String endpoint = ApiConstants.appointments;
  
  // Filtrar según el rol
  if (role == 'Cliente') {
    endpoint += '?cliente_id=$userId';
  } else if (role != 'Admin') {
    // Empleados ven solo sus citas
    endpoint += '?empleado_id=$userId';
  }
  
  final response = await ApiService.get(endpoint);
  // ...
}
```

## Tips Importantes

1. **Siempre usa try-catch** para manejar errores de red
2. **Muestra loading** mientras cargas datos
3. **Implementa RefreshIndicator** para recargar datos
4. **Valida respuestas** del servidor antes de parsear
5. **Maneja estados vacíos** (sin datos)
6. **Confirma acciones destructivas** (eliminar)
7. **Muestra feedback** al usuario (SnackBar)
8. **Recarga la lista** después de crear/editar/eliminar

## Siguiente Paso

Aplica este patrón a las demás pantallas:
- Clients
- Sales
- Dashboard (para estadísticas)
