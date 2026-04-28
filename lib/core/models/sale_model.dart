class SaleModel {
  final int id;
  final int? citaId;
  final double total;
  final double subtotal;
  final double descuento;
  final String metodoPago;
  final String estado;
  final DateTime fecha;
  final DateTime? citaFecha;
  final String clienteNombre;
  final String servicioNombre;
  final List<Map<String, dynamic>> items;

  SaleModel({
    required this.id,
    this.citaId,
    required this.total,
    required this.subtotal,
    required this.descuento,
    required this.metodoPago,
    required this.estado,
    required this.fecha,
    this.citaFecha,
    required this.clienteNombre,
    required this.servicioNombre,
    required this.items,
  });

  factory SaleModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic v) {
      if (v == null) return DateTime.now();
      try {
        return DateTime.parse(v.toString());
      } catch (_) {
        return DateTime.now();
      }
    }

    final rawItems = json['items'];
    final List<Map<String, dynamic>> itemsList = rawItems is List
        ? rawItems.map((e) => Map<String, dynamic>.from(e as Map)).toList()
        : [];

    return SaleModel(
      id: json['id'] ?? 0,
      citaId: json['cita_id'] ?? json['citaId'] ?? json['appointmentId'],
      total: (json['total'] ?? json['amount'] ?? 0).toDouble(),
      subtotal:
          (json['subtotal'] ?? json['total'] ?? json['amount'] ?? 0).toDouble(),
      descuento: (json['descuento'] ?? json['discount'] ?? 0).toDouble(),
      metodoPago: (json['metodo_pago'] ??
              json['metodoPago'] ??
              json['paymentMethod'] ??
              '')
          .toString(),
      estado: (json['estado'] ?? json['status'] ?? 'Completada').toString(),
      fecha: parseDate(
        json['created_at'] ?? json['fecha'] ?? json['date'],
      ),
      citaFecha: (json['cita_fecha'] ??
                  json['citaFecha'] ??
                  json['appointment_date']) !=
              null
          ? parseDate(json['cita_fecha'] ??
              json['citaFecha'] ??
              json['appointment_date'])
          : null,
      clienteNombre: (json['cliente_nombre'] ??
              json['clienteNombre'] ??
              json['client_name'] ??
              json['clientName'] ??
              json['cliente'] ??
              json['client'] ??
              'Sin cliente')
          .toString(),
      servicioNombre: (json['servicio_nombre'] ??
              json['servicioNombre'] ??
              json['service_name'] ??
              json['serviceName'] ??
              json['servicio'] ??
              json['service'] ??
              'Sin servicio')
          .toString(),
      items: itemsList,
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
      'fecha': fecha.toIso8601String(),
    };
  }
}
