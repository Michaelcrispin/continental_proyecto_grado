class Usuario {
  final String id;
  final String nombre;
  final String rol;
  final String? gmail;
  final String? ci;
  final String? numeroTrufi;
  final String estado;

  Usuario({
    required this.id,
    required this.nombre,
    required this.rol,
    this.gmail,
    this.ci,
    this.numeroTrufi,
    required this.estado,
  });

  /// Usuario actualmente autenticado en la sesión.
  /// Se inicializa como null hasta que inicie sesión con la base de datos SQLite.
  static Usuario? currentUser;

  factory Usuario.fromMap(Map<String, dynamic> map) {
    return Usuario(
      id: map['id_usuario']?.toString() ?? '',
      nombre: map['nombre']?.toString() ?? '',
      rol: map['rol']?.toString() ?? 'conductor',
      gmail: map['gmail']?.toString(),
      ci: map['ci']?.toString(),
      numeroTrufi: map['placa']?.toString() ?? map['numeroTrufi']?.toString(),
      estado: map['estado']?.toString() ?? 'activo',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_usuario': id,
      'nombre': nombre,
      'rol': rol,
      'gmail': gmail,
      'estado': estado,
    };
  }
}
