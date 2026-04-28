class ClientModel {
  final int id;
  final String nombre;
  final String apellido;
  final String correo;
  final String telefono;
  final String? fotoPerfil;
  final String estado;
  final String tipoDocumento;
  final String numeroDocumento;
  final String direccion;
  final DateTime createdAt;
  final DateTime updatedAt;

  ClientModel({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.correo,
    required this.telefono,
    this.fotoPerfil,
    required this.estado,
    required this.tipoDocumento,
    required this.numeroDocumento,
    required this.direccion,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ClientModel.fromJson(Map<String, dynamic> json) {
    return ClientModel(
      id: json['id'] ?? json['PK_id_cliente'] ?? 0,
      nombre: (json['nombre'] ?? json['firstName'] ?? json['name'] ?? '')
          .toString(),
      apellido: (json['apellido'] ?? json['lastName'] ?? '').toString(),
      correo: (json['correo'] ?? json['email'] ?? '').toString(),
      telefono: (json['telefono'] ?? json['phone'] ?? '').toString(),
      fotoPerfil: (json['foto_perfil'] ?? json['photo'] ?? json['fotoPerfil'])
          ?.toString(),
      estado: (json['estado'] ?? json['Estado'] ?? json['status'] ?? 'Activo')
          .toString(),
      tipoDocumento: (json['tipo_documento'] ??
              json['tipoDocumento'] ??
              json['documentType'] ??
              '')
          .toString(),
      numeroDocumento: (json['numero_documento'] ??
              json['numeroDocumento'] ??
              json['documentNumber'] ??
              '')
          .toString(),
      direccion: (json['direccion'] ?? json['address'] ?? '').toString(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'].toString())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'apellido': apellido,
      'correo': correo,
      'telefono': telefono,
      'foto_perfil': fotoPerfil,
      'estado': estado,
      'tipo_documento': tipoDocumento,
      'numero_documento': numeroDocumento,
      'direccion': direccion,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get nombreCompleto => '$nombre $apellido';
}
