class ApiConstants {
  // Cambia esta IP por la de tu servidor local
  // Si usas emulador Android: http://10.0.2.2:3001/api
  // Si usas dispositivo físico en la misma red: http://TU_IP_LOCAL:3001/api
  static const String baseUrl = 'http://localhost:3001/api';
  
  // Auth endpoints
  static const String login = '/auth/login';
  
  // Appointments endpoints
  static const String appointments = '/appointments';
  static String appointmentDetail(int id) => '/appointments/$id';
  static String appointmentStatus(int id) => '/appointments/$id/status';
  static String appointmentCancel(int id) => '/appointments/$id/cancel';
  
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
}
