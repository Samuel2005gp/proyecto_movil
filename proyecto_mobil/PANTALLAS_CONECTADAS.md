# Pantallas Conectadas al Backend

## ✅ Completamente Conectadas

### 1. Login (login.dart)
- ✅ Autenticación con backend
- ✅ Decodificación de JWT
- ✅ Almacenamiento de token
- ✅ Redirección por rol
- ✅ Manejo de errores

### 2. Profile (profile.dart)
- ✅ Carga de datos del usuario desde API
- ✅ Muestra información real del perfil
- ✅ Logout con limpieza de sesión
- ✅ Estados de carga y error
- ✅ Refresh manual

### 3. Sales (sales.dart)
- ✅ Lista de ventas desde API (`GET /api/sales`)
- ✅ Cálculo de totales (hoy y mes)
- ✅ Eliminación de ventas (`DELETE /api/sales/:id`)
- ✅ Estados de carga y error
- ✅ Pull-to-refresh
- ✅ Formateo de fechas dinámico
- ✅ Colores de estado dinámicos
- ✅ Sin datos quemados

### 4. Clients (clients.dart)
- ✅ Lista de clientes desde API (`GET /api/clients`)
- ✅ Búsqueda en tiempo real (nombre, correo, teléfono)
- ✅ Eliminación de clientes (`DELETE /api/clients/:id`)
- ✅ Modal con detalles del cliente
- ✅ Estados de carga y error
- ✅ Pull-to-refresh
- ✅ Sin datos quemados

## 🔄 Pendientes de Conectar

### 5. Appointments (appointments.dart)
**Estado**: Usa datos quemados
**Necesita**:
- Conectar a `GET /api/appointments`
- Filtrar por rol (admin/empleado/cliente)
- Implementar `POST /api/appointments` (crear)
- Implementar `PUT /api/appointments/:id` (editar)
- Implementar `DELETE /api/appointments/:id` (eliminar)
- Implementar `PATCH /api/appointments/:id/status` (cambiar estado)

### 6. Dashboard (main.dart - DashboardScreen)
**Estado**: Usa datos quemados
**Necesita**:
- Endpoint para estadísticas del dashboard
- Citas de hoy
- Total de clientes
- Ventas del día/mes
- Próximas citas

## 📊 Funcionalidades Implementadas

### Ventas (Sales)
```dart
// Cargar ventas
GET /api/sales
Response: List<SaleModel>

// Eliminar venta
DELETE /api/sales/:id
Response: { message: "Venta eliminada" }

// Características:
- Cálculo automático de totales por día y mes
- Formateo de fechas (muestra hora si es hoy, fecha completa si no)
- Colores dinámicos según estado (Completada/Pendiente/Cancelada)
- Búsqueda y filtrado (preparado para implementar)
```

### Clientes (Clients)
```dart
// Cargar clientes
GET /api/clients
Response: List<ClientModel>

// Eliminar cliente
DELETE /api/clients/:id
Response: { message: "Cliente eliminado" }

// Características:
- Búsqueda en tiempo real por nombre, correo o teléfono
- Modal con detalles completos del cliente
- Botones de editar y eliminar
- Contador de clientes registrados
```

## 🎨 Características Comunes

Todas las pantallas conectadas incluyen:

1. **Estados de Carga**
   ```dart
   CircularProgressIndicator(color: AppTheme.accent)
   ```

2. **Manejo de Errores**
   ```dart
   - Pantalla de error con botón "Reintentar"
   - SnackBar para errores de operaciones
   ```

3. **Pull-to-Refresh**
   ```dart
   RefreshIndicator(
     onRefresh: _loadData,
     child: ListView(...),
   )
   ```

4. **Confirmación de Eliminación**
   ```dart
   AlertDialog con botones Cancelar/Confirmar
   ```

5. **Feedback Visual**
   ```dart
   - SnackBar verde para éxito
   - SnackBar rojo para errores
   ```

6. **Tema Consistente**
   ```dart
   - Colores de AppTheme
   - Tipografía Google Fonts
   - Bordes redondeados (12px)
   - Sombras suaves
   ```

## 🔧 Próximos Pasos

### 1. Conectar Appointments
Es la funcionalidad más importante. Sigue el patrón de Sales/Clients:

```dart
class AppointmentsScreen extends StatefulWidget {
  // 1. Variables de estado
  List<AppointmentModel> _appointments = [];
  bool _isLoading = true;
  
  // 2. Cargar datos
  Future<void> _loadAppointments() async {
    final response = await ApiService.get(ApiConstants.appointments);
    // parsear y setState
  }
  
  // 3. CRUD operations
  Future<void> _createAppointment(Map<String, dynamic> data) async {
    await ApiService.post(ApiConstants.appointments, data);
  }
  
  Future<void> _updateAppointment(int id, Map<String, dynamic> data) async {
    await ApiService.put(ApiConstants.appointmentDetail(id), data);
  }
  
  Future<void> _deleteAppointment(int id) async {
    await ApiService.delete(ApiConstants.appointmentDetail(id));
  }
  
  Future<void> _changeStatus(int id, String status) async {
    await ApiService.patch(
      ApiConstants.appointmentStatus(id),
      {'estado': status},
    );
  }
}
```

### 2. Conectar Dashboard
Necesita un endpoint específico para estadísticas:

```dart
// Backend debería proveer:
GET /api/dashboard/stats
Response: {
  citasHoy: 12,
  totalClientes: 248,
  ventasHoy: 4200,
  ventasMes: 12500,
  proximasCitas: [...],
  rating: 4.9
}
```

### 3. Implementar Creación/Edición
Crear formularios para:
- Nueva venta (con selector de cita disponible)
- Nuevo cliente
- Nueva cita
- Editar cliente
- Editar cita

## 📝 Notas Importantes

1. **Filtrado por Rol**: Appointments debe filtrar según el usuario:
   ```dart
   final role = await StorageService.getRole();
   final userId = await StorageService.getUserId();
   
   String endpoint = ApiConstants.appointments;
   if (role == 'Cliente') {
     endpoint += '?cliente_id=$userId';
   } else if (role != 'Admin') {
     endpoint += '?empleado_id=$userId';
   }
   ```

2. **Validaciones**: El frontend valida, pero el backend debe validar también.

3. **Permisos**: Respetar los permisos del backend (403 Forbidden).

4. **Tokens**: Si el token expira (401), ApiService redirige automáticamente al login.

## 🚀 Cómo Probar

1. Asegúrate de que el backend esté corriendo
2. Actualiza la URL en `lib/core/constants/api_constants.dart`
3. Ejecuta `flutter run`
4. Inicia sesión con credenciales válidas
5. Navega a Ventas o Clientes para ver los datos reales

## 📊 Progreso

- ✅ Autenticación: 100%
- ✅ Perfil: 100%
- ✅ Ventas: 100%
- ✅ Clientes: 100%
- ⏳ Citas: 0%
- ⏳ Dashboard: 0%
- ⏳ Usuarios (Admin): 0%

**Total: 4/7 pantallas conectadas (57%)**
