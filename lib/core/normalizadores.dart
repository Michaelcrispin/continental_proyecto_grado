/// Funciones utilitarias para la normalización estricta de documentos y placas.
/// Garantizan que búsquedas, comparaciones e índices únicos no fallen por
/// variaciones de formato (puntos, espacios, guiones o extensiones de departamento).
class Normalizadores {
  Normalizadores._();

  /// Extensiones oficiales de cédula de identidad en Bolivia.
  static const List<String> extensionesBolivia = [
    'LP', // La Paz
    'CB', // Cochabamba
    'SC', // Santa Cruz
    'OR', // Oruro
    'PT', // Potosí
    'TJ', // Tarija
    'CH', // Chuquisaca
    'BE', // Beni
    'PA', // Pando
  ];

  static const List<String> departamentosCi = extensionesBolivia;

  /// Grupos reconocidos del sindicato Continental Trufi.
  static const List<String> gruposSindicato = [
    '101', // Grupo Continental 101
    '127', // Grupo Continental 127
  ];

  static const List<String> grupos = gruposSindicato;

  /// Normaliza un CI extrayendo únicamente los dígitos base.
  /// Ejemplos:
  /// - "6.849.201 LP" -> "6849201"
  /// - "6849201-1B"   -> "6849201" (o dígitos principales)
  /// - " 8392012 "    -> "8392012"
  static String normalizarCi(String? raw) {
    if (raw == null) return '';
    var s = raw.trim().toUpperCase();

    // Remover extensiones conocidas al final
    for (final ext in extensionesBolivia) {
      if (s.endsWith(' $ext') || s.endsWith('-$ext') || s.endsWith(ext)) {
        s = s.substring(0, s.lastIndexOf(ext)).trim();
        break;
      }
    }

    // Dejar solo números (y letras de complemento si existen, pero sin puntuación)
    return s.replaceAll(RegExp(r'[^0-9A-Z]'), '');
  }

  /// Normaliza una placa de vehículo eliminando espacios y guiones.
  /// Ejemplos:
  /// - "1234 - ABC" -> "1234ABC"
  /// - "2045abc"    -> "2045ABC"
  static String normalizarPlaca(String? raw) {
    if (raw == null) return '';
    return raw.trim().toUpperCase().replaceAll(RegExp(r'[^0-9A-Z]'), '');
  }

  /// Detecta la extensión de un texto de CI, o retorna 'LP' por defecto.
  static String extraerExtensionCi(String? raw) {
    if (raw == null || raw.trim().isEmpty) return 'LP';
    final s = raw.trim().toUpperCase();
    for (final ext in extensionesBolivia) {
      if (s.endsWith(ext) || s.contains(' $ext') || s.contains('-$ext')) {
        return ext;
      }
    }
    return 'LP';
  }
}
