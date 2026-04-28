class SaleModel {
  final int id;
  final int? citaId;
  final double total;
  final double subtotal;
  final double descuento;
  final String metodoPago;
  final String estado;
  final DateTime fecha;

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
    required this.clienteNombre,
    required this.servicioNombre,
    required this.items,
  });

  factory SaleModel.fromJson(Map<String, dynamic> json) {
    DateTime parseFecha(dynamic v) {
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
      citaId: json['citaId'],
      total: (json['Total'] ?? json['total'] ?? 0).toDouble(),
      subtotal: (json['Subtotal'] ?? json['subtotal'] ?? 0).toDouble(),
      descuento: (json['descuento'] ?? 0).toDouble(),
      metodoPago: (json['metodo_pago'] ?? json['metodoPago'] ?? '').toString(),
      estado: (json['Estado'] ?? json['estado'] ?? 'Activo').toString(),
      fecha: parseFecha(json['Fecha'] ?? json['fecha']),
      clienteNombre: (json['Cliente'] ?? json['cliente'] ?? '—').toString(),
      servicioNombre: (json['Servicio'] ?? json['servicio'] ?? '—').toString(),
      items: itemsList,
    );
  }
}
