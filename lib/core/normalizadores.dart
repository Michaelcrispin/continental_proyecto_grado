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

  /// Normaliza un nombre completo (sin tildes, en minúsculas y con espacios simples)
  /// para detectar nombres duplicados.
  static String normalizarNombre(String? raw) {
    if (raw == null) return '';
    var s = raw.trim().toLowerCase();
    const conAcento = 'áàäâéèëêíìïîóòöôúùüûñ';
    const sinAcento = 'aaaaeeeeiiiioooouuuun';
    for (int i = 0; i < conAcento.length; i++) {
      s = s.replaceAll(conAcento[i], sinAcento[i]);
    }
    return s.replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Normaliza un número de teléfono/celular boliviano extrayendo los dígitos locales.
  static String normalizarTelefono(String? raw) {
    if (raw == null) return '';
    var s = raw.trim().replaceAll(RegExp(r'[^0-9+]'), '');
    if (s.startsWith('+591')) {
      s = s.substring(4);
    } else if (s.startsWith('591') && s.length > 8) {
      s = s.substring(3);
    }
    return s.replaceAll(RegExp(r'[^0-9]'), '');
  }

  /// Normaliza un código alfanumérico (Licencia, RUAT, SOAT) quitando espacios y guiones.
  static String normalizarCodigo(String? raw) {
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

  /// Extrae el apellido paterno de un nombre completo para el ordenamiento alfabético sindical.
  /// Ejemplos:
  /// - "Pedro Apaza Cruz" -> "Apaza"
  /// - "Juan Carlos Quispe Mamani" -> "Quispe"
  /// - "Miguel Angel Choque" -> "Choque"
  /// - "Carlos Nina Huanca" -> "Nina"
  /// - "Roberto Vargas" -> "Vargas"
  static String extraerApellidoPaterno(String? nombreCompleto) {
    if (nombreCompleto == null) return '';
    final partes = nombreCompleto
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (partes.isEmpty) return '';
    if (partes.length == 1) return partes[0];
    if (partes.length == 2) {
      // "Roberto Vargas" -> Vargas
      return partes[1];
    }

    const compuestos = {
      'juan carlos',
      'miguel angel',
      'jose luis',
      'victor hugo',
      'luis alberto',
      'carlos alberto',
      'juan pablo',
      'jose manuel',
      'marco antonio',
      'edgar javier',
      'pedro luis',
      'julio cesar',
      'maria elena',
      'ana maria',
      'jorge luis',
      'ruben dario',
    };

    final dosPrimeros = '${partes[0]} ${partes[1]}'.toLowerCase();
    if (compuestos.contains(dosPrimeros)) {
      // Si empieza con nombre compuesto (ej: "Miguel Angel Choque" -> Choque)
      // O "Juan Carlos Quispe Mamani" -> Quispe
      if (partes.length == 3) {
        return partes[2];
      }
      return partes[2];
    }

    if (partes.length == 3) {
      // Estándar 3 palabras: [Nombre] [Apellido Paterno] [Apellido Materno]
      // "Pedro Apaza Cruz" -> Apaza
      // "Luis Mamani Condori" -> Mamani
      return partes[1];
    }

    // 4 o más palabras: [Nombre 1] [Nombre 2] [Apellido Paterno] [Apellido Materno]
    // "Carlos Andres Nina Huanca" -> Nina
    return partes[partes.length - 2];
  }
}
