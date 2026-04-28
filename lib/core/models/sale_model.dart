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

    // El backend devuelve: Cliente, Servicio, Total, Subtotal, Fecha, Estado,
    // metodo_pago, descuento — con mayúsculas/minúsculas mixtas
    return SaleModel(
      id: json['id'] ?? json['PK_id_venta_encabezado'] ?? 0,
      citaId: json['citaId'] ?? json['FK_id_cita'] ?? json['cita_id'],
      total: (json['Total'] ?? json['total'] ?? json['amount'] ?? 0).toDouble(),
      subtotal: (json['Subtotal'] ??
              json['subtotal'] ??
              json['Total'] ??
              json['total'] ??
              0)
          .toDouble(),
      descuento:
          (json['descuento'] ?? json['Descuento'] ?? json['discount'] ?? 0)
              .toDouble(),
      metodoPago: (json['metodo_pago'] ??
              json['metodoPago'] ??
              json['MetodoPago'] ??
              json['paymentMethod'] ??
              '')
          .toString(),
      estado: (json['Estado'] ?? json['estado'] ?? json['status'] ?? 'Activo')
          .toString(),
      fecha: parseDate(
          json['Fecha'] ?? json['fecha'] ?? json['created_at'] ?? json['date']),
      citaFecha: (json['cita_fecha'] ??
                  json['citaFecha'] ??
                  json['appointment_date']) !=
              null
          ? parseDate(json['cita_fecha'] ??
              json['citaFecha'] ??
              json['appointment_date'])
          : null,
      // El backend devuelve "Cliente" como string con nombre completo
      clienteNombre: (json['Cliente'] ??
              json['cliente_nombre'] ??
              json['clienteNombre'] ??
              json['client_name'] ??
              json['clientName'] ??
              json['cliente'] ??
              'Sin cliente')
          .toString(),
      // El backend devuelve "Servicio" como string con nombre(s) del servicio
      servicioNombre: (json['Servicio'] ??
              json['servicio_nombre'] ??
              json['servicioNombre'] ??
              json['service_name'] ??
              json['serviceName'] ??
              json['servicio'] ??
              'Sin servicio')
          .toString(),
      items: itemsList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cita_id': citaId,
      'Total': total,
      'Subtotal': subtotal,
      'descuento': descuento,
      'metodo_pago': metodoPago,
      'Estado': estado,
      'Fecha': fecha.toIso8601String(),
    };
  }
}
