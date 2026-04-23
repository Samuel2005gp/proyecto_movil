class SaleModel {
  final int id;
  final int citaId;
  final double total;
  final String metodoPago;
  final String estado;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Datos relacionados (si vienen del backend)
  final String? clienteNombre;
  final String? servicioNombre;
  final DateTime? citaFecha;

  SaleModel({
    required this.id,
    required this.citaId,
    required this.total,
    required this.metodoPago,
    required this.estado,
    required this.createdAt,
    required this.updatedAt,
    this.clienteNombre,
    this.servicioNombre,
    this.citaFecha,
  });

  factory SaleModel.fromJson(Map<String, dynamic> json) {
    return SaleModel(
      id: json['id'] ?? 0,
      citaId: json['cita_id'] ?? 0,
      total: (json['total'] ?? 0).toDouble(),
      metodoPago: json['metodo_pago']?.toString() ?? '',
      estado: json['estado']?.toString() ?? 'Completada',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      clienteNombre: json['cliente_nombre']?.toString(),
      servicioNombre: json['servicio_nombre']?.toString(),
      citaFecha: json['cita_fecha'] != null
          ? DateTime.parse(json['cita_fecha'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cita_id': citaId,
      'total': total,
      'metodo_pago': metodoPago,
      'estado': estado,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
