import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AvatarConductor extends StatelessWidget {
  final String? foto;
  final String nombre;
  final double radio;
  final bool mostrarBotonCamara;
  final VoidCallback? onTap;
  final VoidCallback? onTapCamara;
  final double? fontSize;

  const AvatarConductor({
    super.key,
    required this.foto,
    required this.nombre,
    this.radio = 40,
    this.mostrarBotonCamara = false,
    this.onTap,
    this.onTapCamara,
    this.fontSize,
  });

  /// Extrae las iniciales del nombre (ej: "Michael Crispin" -> "MC")
  static String obtenerIniciales(String nombre) {
    final partes = nombre.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (partes.isEmpty) return 'C';
    if (partes.length == 1) {
      return partes[0].substring(0, partes[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return (partes[0].substring(0, 1) + partes[1].substring(0, 1)).toUpperCase();
  }

  /// Genera un gradiente moderno y consistente según el nombre del conductor
  static List<Color> obtenerGradiente(String nombre) {
    final hash = nombre.hashCode;
    const paletas = [
      [Color(0xFF2563EB), Color(0xFF1D4ED8)], // Azul real
      [Color(0xFF059669), Color(0xFF047857)], // Esmeralda
      [Color(0xFF7C3AED), Color(0xFF5B21B6)], // Violeta
      [Color(0xFFD97706), Color(0xFFB45309)], // Ámbar
      [Color(0xFF0891B2), Color(0xFF0E7490)], // Cian
      [Color(0xFFE11D48), Color(0xFFBE123C)], // Carmesí
      [Color(0xFF4F46E5), Color(0xFF3730A3)], // Índigo
    ];
    return paletas[hash.abs() % paletas.length];
  }

  /// Muestra un modal elegante para elegir foto desde Cámara, Galería o Quitar Foto.
  /// Retorna la ruta del archivo (String), '' para indicar eliminación, o null si canceló.
  static Future<String?> mostrarSelectorOrigen(
    BuildContext context, {
    bool puedeEliminar = false,
  }) async {
    final picker = ImagePicker();

    return showModalBottomSheet<String?>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Foto de Perfil del Conductor',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Selecciona el origen de la imagen',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildOpcionOrigen(
                  icono: Icons.camera_alt_rounded,
                  color: const Color(0xFF10B981),
                  bgColor: const Color(0xFFECFDF5),
                  label: 'Cámara',
                  onTap: () async {
                    try {
                      final XFile? foto = await picker.pickImage(
                        source: ImageSource.camera,
                        imageQuality: 85,
                        maxWidth: 1024,
                      );
                      if (foto != null && ctx.mounted) {
                        Navigator.pop(ctx, foto.path);
                      }
                    } catch (_) {}
                  },
                ),
                _buildOpcionOrigen(
                  icono: Icons.photo_library_rounded,
                  color: const Color(0xFF2563EB),
                  bgColor: const Color(0xFFEFF6FF),
                  label: 'Galería',
                  onTap: () async {
                    try {
                      final XFile? foto = await picker.pickImage(
                        source: ImageSource.gallery,
                        imageQuality: 85,
                        maxWidth: 1024,
                      );
                      if (foto != null && ctx.mounted) {
                        Navigator.pop(ctx, foto.path);
                      }
                    } catch (_) {}
                  },
                ),
                if (puedeEliminar)
                  _buildOpcionOrigen(
                    icono: Icons.delete_outline_rounded,
                    color: const Color(0xFFEF4444),
                    bgColor: const Color(0xFFFEF2F2),
                    label: 'Quitar',
                    onTap: () async {
                      if (ctx.mounted) {
                        Navigator.pop(ctx, '');
                      }
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildOpcionOrigen({
    required IconData icono,
    required Color color,
    required Color bgColor,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icono, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final diametro = radio * 2;
    final iniciales = obtenerIniciales(nombre);
    final gradiente = obtenerGradiente(nombre);

    Widget imagenContent;
    final fotoLimpia = foto?.trim();

    if (fotoLimpia != null && fotoLimpia.isNotEmpty) {
      if (fotoLimpia.startsWith('assets/')) {
        imagenContent = Image.asset(
          fotoLimpia,
          width: diametro,
          height: diametro,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _buildFallback(iniciales, gradiente),
        );
      } else {
        final file = File(fotoLimpia);
        if (file.existsSync()) {
          imagenContent = Image.file(
            file,
            width: diametro,
            height: diametro,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _buildFallback(iniciales, gradiente),
          );
        } else {
          imagenContent = _buildFallback(iniciales, gradiente);
        }
      }
    } else {
      imagenContent = _buildFallback(iniciales, gradiente);
    }

    Widget avatarWidget = Container(
      width: diametro,
      height: diametro,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: radio > 30 ? 3 : 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipOval(child: imagenContent),
    );

    if (onTap != null) {
      avatarWidget = GestureDetector(
        onTap: onTap,
        child: avatarWidget,
      );
    }

    if (!mostrarBotonCamara) {
      return avatarWidget;
    }

    final tamBoton = (radio * 0.65).clamp(26.0, 34.0);

    return Stack(
      children: [
        avatarWidget,
        Positioned(
          right: 0,
          bottom: 0,
          child: GestureDetector(
            onTap: onTapCamara ?? onTap,
            child: Container(
              width: tamBoton,
              height: tamBoton,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.camera_alt,
                color: const Color(0xFF1E3A8A),
                size: tamBoton * 0.55,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFallback(String iniciales, List<Color> gradiente) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradiente,
        ),
      ),
      child: Center(
        child: Text(
          iniciales,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: fontSize ?? (radio * 0.7).clamp(11.0, 28.0),
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
