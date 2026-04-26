class AppointmentService {
  final int serviceId;
  final String serviceName;
  final int employeeId;
  final String employeeName;
  final int duration;
  final double? price;
  final String startTime;

  AppointmentService({
    required this.serviceId,
    required this.serviceName,
    required this.employeeId,
    required this.employeeName,
    required this.duration,
    this.price,
    required this.startTime,
  });

  factory AppointmentService.fromJson(Map<String, dynamic> json) {
    return AppointmentService(
      serviceId:    int.tryParse(json['serviceId']?.toString() ?? '0') ?? 0,
      serviceName:  json['serviceName']?.toString() ?? '',
      employeeId:   int.tryParse(json['employeeId']?.toString() ?? '0') ?? 0,
      employeeName: json['employeeName']?.toString() ?? '',
      duration:     int.tryParse(json['duration']?.toString() ?? '0') ?? 0,
      price:        json['price'] != null ? double.tryParse(json['price'].toString()) : null,
      startTime:    json['startTime']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'serviceId':  serviceId,
    'employeeId': employeeId,
  };
}

class AppointmentModel {
  final int id;
  final int clienteId;
  final String clienteNombre;
  final String clienteTelefono;
  final String fecha;
  final String horario;
  final String estado;
  final String? notas;
  final List<AppointmentService> servicios;

  AppointmentModel({
    required this.id,
    required this.clienteId,
    required this.clienteNombre,
    required this.clienteTelefono,
    required this.fecha,
    required this.horario,
    required this.estado,
    this.notas,
    required this.servicios,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    final serviciosRaw = json['servicios'] as List<dynamic>? ?? [];
    return AppointmentModel(
      id:              json['PK_id_cita'] ?? json['id'] ?? 0,
      clienteId:       json['cliente_id'] ?? 0,
      clienteNombre:   json['cliente_nombre']?.toString() ?? '',
      clienteTelefono: json['cliente_telefono']?.toString() ?? '',
      fecha:           json['Fecha']?.toString() ?? json['fecha']?.toString() ?? '',
      horario:         json['Horario']?.toString() ?? json['horario']?.toString() ?? '',
      estado:          json['Estado']?.toString() ?? json['estado']?.toString() ?? 'Pendiente',
      notas:           json['Notas']?.toString() ?? json['notas']?.toString(),
      servicios:       serviciosRaw.map((s) => AppointmentService.fromJson(s)).toList(),
    );
  }

  String get servicioNombre => servicios.isNotEmpty ? servicios.first.serviceName : 'Sin servicio';
  String get empleadoNombre => servicios.isNotEmpty ? servicios.first.employeeName : '';

  Map<String, dynamic> toJson() => {
    'cliente_id': clienteId,
    'fecha':      fecha,
    'horario':    horario,
    'notas':      notas,
    'servicios':  servicios.map((s) => s.toJson()).toList(),
  };
}