class UserModel {
  final int id;
  final String nombre;
  final String apellido;
  final String correo;
  final String telefono;
  final String? fotoPerfil;
  final String rol;
  final int? rolId;
  final String estado;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.correo,
    required this.telefono,
    this.fotoPerfil,
    required this.rol,
    this.rolId,
    required this.estado,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 0,
      // Soporta tanto 'firstName'/'lastName' como 'nombre'/'apellido'
      nombre: json['firstName']?.toString() ??
              json['nombre']?.toString() ??
              (json['name']?.toString().split(' ').first ?? ''),
      apellido: json['lastName']?.toString() ??
                json['apellido']?.toString() ??
                (json['name']?.toString().contains(' ') == true
                    ? json['name'].toString().split(' ').skip(1).join(' ')
                    : ''),
      correo: json['email']?.toString() ??
              json['correo']?.toString() ?? '',
      telefono: json['phone']?.toString() ??
                json['telefono']?.toString() ?? '',
      fotoPerfil: json['photo']?.toString() ??
                  json['foto_perfil']?.toString(),
      rol: json['role']?.toString() ??
           json['rol']?.toString() ?? '',
      rolId: json['rolId'],
      estado: json['estado']?.toString() ?? 'Activo',
      isActive: json['isActive'] ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'firstName': nombre,
      'lastName': apellido,
      'email': correo,
      'phone': telefono,
      'photo': fotoPerfil,
      'role': rol,
    };
  }

  String get nombreCompleto =>
      apellido.isNotEmpty ? '$nombre $apellido' : nombre;
}
