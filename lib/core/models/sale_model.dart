class SaleModel {
  final int id;
  final int citaId;
  final double total;
  final double subtotal;
  final double descuento;
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
    required this.subtotal,
    required this.descuento,
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
      citaId: json['cita_id'] ?? json['citaId'] ?? json['appointmentId'] ?? 0,
      total: (json['total'] ?? json['Total'] ?? json['amount'] ?? 0).toDouble(),
      subtotal: (json['subtotal'] ?? json['Subtotal'] ?? 0).toDouble(),
      descuento: (json['descuento'] ?? json['discount'] ?? 0).toDouble(),
      metodoPago: (json['metodo_pago'] ??
              json['metodoPago'] ??
              json['paymentMethod'] ??
              '')
          .toString(),
      estado:
          (json['estado'] ?? json['Estado'] ?? json['status'] ?? 'Completada')
              .toString(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : json['Fecha'] != null
              ? DateTime.parse(json['Fecha'].toString())
              : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'].toString())
          : json['Fecha'] != null
              ? DateTime.parse(json['Fecha'].toString())
              : DateTime.now(),
      // Prueba múltiples nombres de campo para el cliente
      clienteNombre: (json['cliente_nombre'] ??
              json['clienteNombre'] ??
              json['client_name'] ??
              json['clientName'] ??
              json['cliente'] ??
              json['Cliente'] ??
              json['client'])
          ?.toString(),
      // Prueba múltiples nombres de campo para el servicio
      servicioNombre: (json['servicio_nombre'] ??
              json['servicioNombre'] ??
              json['service_name'] ??
              json['serviceName'] ??
              json['servicio'] ??
              json['Servicio'] ??
              json['service'])
          ?.toString(),
      citaFecha: (json['cita_fecha'] ??
                  json['citaFecha'] ??
                  json['appointment_date'] ??
                  json['Fecha']) !=
              null
          ? DateTime.parse((json['cita_fecha'] ??
                  json['citaFecha'] ??
                  json['appointment_date'] ??
                  json['Fecha'])
              .toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cita_id': citaId,
      'total': total,
      'subtotal': subtotal,
      'descuento': descuento,
      'metodo_pago': metodoPago,
      'estado': estado,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
