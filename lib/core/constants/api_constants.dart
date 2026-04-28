// constants/api_constants.dart
import 'package:flutter/foundation.dart';

class ApiConstants {
  // Configuración para diferentes plataformas
  static String get baseUrl {
    if (kIsWeb) {
      // Para Flutter Web (Chrome, Firefox, etc.)
      return 'http://localhost:3001';
    } else {
      // Para móvil - emulador Android
      return 'http://10.0.2.2:3001';
    }
  }

  // Auth endpoints
  static const String login = '/auth/login';

  // Appointments endpoints
  static const String appointments = '/appointments';
  static const String misCitas = '/appointments/mis-citas';
  static const String misCitasEmpleado = '/appointments/mis-citas-empleado';
  static String appointmentDetail(int id) => '/appointments/$id';
  static String appointmentStatus(int id) => '/appointments/$id/status';
  static String appointmentCancel(int id) => '/appointments/$id/cancel';
  static String miCitaDetail(int id) => '/appointments/mis-citas/$id';
  static String miCitaCancel(int id) => '/appointments/mis-citas/$id/cancel';

  // Services endpoints
  static const String services = '/services';

  // Employees endpoints
  static const String employees = '/employees';
  static const String employeesDisponibles = '/employees/disponibles';

  // Clients endpoints
  static const String clients = '/clients';
  static String clientDetail(int id) => '/clients/$id';
  static String clientStatus(int id) => '/clients/$id/status';

  // Sales endpoints
  static const String sales = '/sales';
  static const String salesAppointments = '/sales/appointments';
  static String saleDetail(int id) => '/sales/$id';

  // Users endpoints
  static const String users = '/users';
  static const String userRoles = '/users/roles';
  static String userDetail(int id) => '/users/$id';
  static String userStatus(int id) => '/users/$id/status';

  // Mi perfil (según rol)
  static const String miPerfilCliente = '/clients/mi-perfil';
  static const String miPerfilEmpleado = '/employees/mi-perfil';
  static const String updateMiPerfilEmpleado = '/employees/mi-perfil';
  static String updateClientePerfil(int id) => '/clients/$id';
}
