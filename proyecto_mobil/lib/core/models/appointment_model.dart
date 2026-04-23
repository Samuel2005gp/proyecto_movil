class AppointmentModel {
  final int id;
  final int clienteId;
  final int empleadoId;
  final int servicioId;
  final DateTime fechaHora;
  final String estado;
  final String? notas;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Datos relacionados (si vienen del backend)
  final String? clienteNombre;
  final String? empleadoNombre;
  final String? servicioNombre;
  final double? servicioPrecio;

  AppointmentModel({
    required this.id,
    required this.clienteId,
    required this.empleadoId,
    required this.servicioId,
    required this.fechaHora,
    required this.estado,
    this.notas,
    required this.createdAt,
    required this.updatedAt,
    this.clienteNombre,
    this.empleadoNombre,
    this.servicioNombre,
    this.servicioPrecio,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      id: json['id'] ?? 0,
      clienteId: json['cliente_id'] ?? 0,
      empleadoId: json['empleado_id'] ?? 0,
      servicioId: json['servicio_id'] ?? 0,
      fechaHora: json['fecha_hora'] != null
          ? DateTime.parse(json['fecha_hora'])
          : DateTime.now(),
      estado: json['estado']?.toString() ?? 'Pendiente',
      notas: json['notas']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      clienteNombre: json['cliente_nombre']?.toString(),
      empleadoNombre: json['empleado_nombre']?.toString(),
      servicioNombre: json['servicio_nombre']?.toString(),
      servicioPrecio: json['servicio_precio']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cliente_id': clienteId,
      'empleado_id': empleadoId,
      'servicio_id': servicioId,
      'fecha_hora': fechaHora.toIso8601String(),
      'estado': estado,
      'notas': notas,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
