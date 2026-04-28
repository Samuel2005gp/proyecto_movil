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
  final String documentType;
  final String document;

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
    this.documentType = '',
    this.document = '',
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // El backend devuelve 'name' como nombre completo cuando no hay perfil (ej: Admin)
    // y 'firstName'/'lastName' cuando sí hay perfil de empleado/cliente
    final firstName = json['firstName']?.toString() ?? '';
    final lastName = json['lastName']?.toString() ?? '';
    final fullName = json['name']?.toString() ?? '';

    String nombre = firstName;
    String apellido = lastName;

    // Si firstName está vacío pero hay 'name', descomponerlo
    if (nombre.isEmpty &&
        fullName.isNotEmpty &&
        fullName != (json['email'] ?? json['correo'] ?? '')) {
      final parts = fullName.trim().split(' ');
      nombre = parts.first;
      apellido = parts.length > 1 ? parts.skip(1).join(' ') : '';
    }

    return UserModel(
      id: json['id'] ?? 0,
      nombre: nombre,
      apellido: apellido,
      correo: json['email']?.toString() ?? json['correo']?.toString() ?? '',
      telefono: json['phone']?.toString() ?? json['telefono']?.toString() ?? '',
      fotoPerfil: json['photo']?.toString() ?? json['foto_perfil']?.toString(),
      rol: json['role']?.toString() ?? json['rol']?.toString() ?? '',
      rolId: json['rolId'],
      estado: json['estado']?.toString() ?? 'Activo',
      isActive: json['isActive'] ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      documentType: json['documentType']?.toString() ?? '',
      document: json['document']?.toString() ?? '',
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
