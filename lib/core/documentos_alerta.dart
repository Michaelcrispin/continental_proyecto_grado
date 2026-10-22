import 'package:flutter/material.dart';

/// Utilidad para cálculo de vigencia y alertas de vencimiento de documentos
/// (Licencia de Conducir y SOAT).
class DocumentosAlerta {
  /// Devuelve: 'Vencida', 'Por vencer', 'Vigente' o 'No registrado'
  static String estado(String? fechaVence) {
    if (fechaVence == null || fechaVence.trim().isEmpty) return 'No registrado';
    try {
      final fecha = DateTime.parse(fechaVence.trim());
      final hoy = DateTime.now();
      final fechaFinDia = DateTime(fecha.year, fecha.month, fecha.day, 23, 59, 59);
      final dias = fechaFinDia.difference(hoy).inDays;
      if (dias < 0) return 'Vencida';
      if (dias <= 30) return 'Por vencer';
      return 'Vigente';
    } catch (_) {
      return 'No registrado';
    }
  }

  static Color color(String estado) {
    switch (estado) {
      case 'Vencida':
        return const Color(0xFFEF4444); // Rojo
      case 'Por vencer':
        return const Color(0xFFF59E0B); // Ámbar / Naranja
      case 'Vigente':
        return const Color(0xFF10B981); // Verde
      default:
        return const Color(0xFF94A3B8); // Gris
    }
  }

  static Color colorFondo(String estado) {
    switch (estado) {
      case 'Vencida':
        return const Color(0xFFFEF2F2);
      case 'Por vencer':
        return const Color(0xFFFFFBEB);
      case 'Vigente':
        return const Color(0xFFECFDF5);
      default:
        return const Color(0xFFF1F5F9);
    }
  }

  static int? diasRestantes(String? fechaVence) {
    if (fechaVence == null || fechaVence.trim().isEmpty) return null;
    try {
      final fecha = DateTime.parse(fechaVence.trim());
      final hoy = DateTime.now();
      final fechaFinDia = DateTime(fecha.year, fecha.month, fecha.day, 23, 59, 59);
      return fechaFinDia.difference(hoy).inDays;
    } catch (_) {
      return null;
    }
  }
}
