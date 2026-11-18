import 'package:intl/intl.dart';

/// Utilidad para el formateo de montos monetarios en Bolivianos (Bs.)
/// 
/// Reglas aplicadas en toda la interfaz de Cuotas:
/// 1. Cero decimales cuando es número entero o redondo (ej: Bs. 3,000, Bs. 30,000, Bs. 50).
/// 2. Muestra decimales (.xx) ÚNICAMENTE si existen centavos reales (ej: Bs. 12.50, Bs. 30,000.25).
/// 3. Separador de miles con comas (ej: 30,000 / 1,250,000).
class FormatoMoneda {
  FormatoMoneda._();

  static final NumberFormat _sinDecimales = NumberFormat('#,##0', 'en_US');
  static final NumberFormat _conDecimales = NumberFormat('#,##0.00', 'en_US');

  /// Formatea un valor monetario agregando el prefijo "Bs. ".
  /// Ejemplos:
  /// - 30000   -> "Bs. 30,000"
  /// - 3000    -> "Bs. 3,000"
  /// - 50      -> "Bs. 50"
  /// - 50.5    -> "Bs. 50.50"
  /// - 0       -> "Bs. 0"
  /// - null    -> "Bs. 0"
  /// - -150    -> "-Bs. 150"
  static String bs(num? valor, {bool conEspacio = true}) {
    final s = numero(valor);
    if (s.startsWith('-')) {
      final sub = s.substring(1);
      return conEspacio ? '-Bs. $sub' : '-Bs.$sub';
    }
    return conEspacio ? 'Bs. $s' : 'Bs.$s';
  }

  /// Retorna solo el número formateado con comas de miles y centavos solo si existen.
  /// Ejemplos:
  /// - 30000   -> "30,000"
  /// - 3000.75 -> "3,000.75"
  /// - 50      -> "50"
  /// - 0       -> "0"
  /// - null    -> "0"
  static String numero(num? valor) {
    if (valor == null) return '0';
    final absVal = valor.abs();
    final tieneCentavos = ((absVal * 100).round() % 100) != 0;
    if (tieneCentavos) {
      return _conDecimales.format(valor);
    } else {
      return _sinDecimales.format(valor.round());
    }
  }
}

/// Función auxiliar de acceso rápido para "Bs. X,XXX"
String formatearBs(num? valor) => FormatoMoneda.bs(valor);

/// Función auxiliar de acceso rápido para "X,XXX"
String formatearNumero(num? valor) => FormatoMoneda.numero(valor);

