import 'package:flutter/material.dart';

class AppColors {
  // Fondos principales
  static const Color background = Color(0xFFF7F9FC); // Fondo base claro con tono azulado
  static const Color cardBackground = Colors.white;  // Fondo de tarjetas y contenedores
  
  // Colores primarios (Textos, botones, identidad)
  static const Color primaryDark = Color(0xFF0F2B5B); // Textos principales, logo oscuro
  static const Color primaryBlue = Color(0xFF2563EB); // Botones principales, acentos fuertes
  static const Color secondaryBlue = Color(0xFF3B82F6); // Detalles secundarios
  
  // Textos y descriptivos
  static const Color textGray = Color(0xFF475569); // Textos secundarios, descripciones
  static const Color textLight = Color(0xFF64748B); // Textos muy tenues
  
  // Elementos de UI (Bordes, separadores, fondos de íconos)
  static const Color dividerColor = Color(0xFFF1F5F9); // Líneas sutiles
  static const Color iconBgBlue = Color(0xFFEFF6FF); // Fondo de íconos azules
  static const Color iconBgGray = Color(0xFFF1F5F9); // Fondo de íconos grises
  static const Color iconBgGreen = Color(0xFFD1FAE5); // Fondo de íconos de éxito
  
  // Estados (Éxito, Error, Advertencia)
  static const Color success = Color(0xFF10B981); // Checkmark, Estado "Activo"
  static const Color danger = Color(0xFFEF4444);  // Cerrar sesión, Alertas
  static const Color dangerBg = Color(0xFFFECACA); // Fondo de alertas o bordes rojos
  
  // Olas del fondo decorativo (Glassmorphism / BackgroundPainter)
  static const Color waveLight = Color(0xFFE2EAF4); // Ola superior e inferior base
  static const Color waveMid = Color(0xFF3B82F6);   // Ola intermedia inferior
  static const Color waveDark = Color(0xFF1E3A8A);  // Esquina final oscura
}
