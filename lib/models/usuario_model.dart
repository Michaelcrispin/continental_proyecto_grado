class Usuario {
  final String id;
  final String nombre;
  final String rol;
  final String ci;
  final String numeroTrufi;
  final String estado;

  Usuario({
    required this.id,
    required this.nombre,
    required this.rol,
    required this.ci,
    required this.numeroTrufi,
    required this.estado,
  });

  // Simulando datos de ejemplo (Mock Data)
  // Cuando conectemos a tu DB, este método se reemplazará por fromJson()
  static Usuario get currentUser => Usuario(
        id: 'U001',
        nombre: 'Michael Crispin Mamani',
        rol: 'Encargado',
        ci: '12345678',
        numeroTrufi: '115',
        estado: 'Activo',
      );
}
