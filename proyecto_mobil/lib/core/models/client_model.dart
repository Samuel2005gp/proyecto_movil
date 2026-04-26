class ClientModel {
  final int id;
  final String nombre;
  final String apellido;
  final String correo;
  final String telefono;
  final String? fotoPerfil;
  final String estado;
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
    required this.createdAt,
    required this.updatedAt,
  });

  factory ClientModel.fromJson(Map<String, dynamic> json) {
    return ClientModel(
      id: json['id'] ?? 0,
      nombre: (json['nombre'] ?? json['firstName'] ?? json['name'] ?? '')
          .toString(),
      apellido: (json['apellido'] ?? json['lastName'] ?? '').toString(),
      correo: (json['correo'] ?? json['email'] ?? '').toString(),
      telefono: (json['telefono'] ?? json['phone'] ?? '').toString(),
      fotoPerfil: (json['foto_perfil'] ?? json['photo'] ?? json['fotoPerfil'])
          ?.toString(),
      estado: (json['estado'] ?? json['status'] ?? 'Activo').toString(),
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
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get nombreCompleto => '$nombre $apellido';
}
