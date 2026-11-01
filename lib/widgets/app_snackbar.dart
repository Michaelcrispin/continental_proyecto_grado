import 'package:flutter/material.dart';

/// Tipos de alertas visuales para SnackBar según el sistema de diseño oficial.
enum AppSnackBarTipo {
  exito,
  error,
  advertencia,
  informacion,
  neutro,
}

/// SnackBar flotante reutilizable con soporte para los 5 estados:
/// Éxito, Error, Advertencia, Información y Neutro.
/// Especificaciones:
/// - Altura mínima 48px
/// - Radio de borde 12px
/// - Duración 4 a 6 segundos (por defecto 4s)
/// - Icono temático sobre círculo blanco / forma blanca
/// - Botón cerrar (X) interactivo
class AppSnackBar {
  static void mostrar(
    BuildContext context, {
    required String mensaje,
    AppSnackBarTipo tipo = AppSnackBarTipo.exito,
    Duration duracion = const Duration(seconds: 4),
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    final config = _getConfig(tipo);

    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        elevation: 4,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        duration: duracion,
        backgroundColor: config.colorFondo,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        content: Row(
          children: [
            // Icono ilustrado
            _buildIcono(tipo, config),
            const SizedBox(width: 12),

            // Mensaje
            Expanded(
              child: Text(
                mensaje,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Botón cerrar (X)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Métodos de acceso rápido
  static void exito(BuildContext context, String mensaje, {Duration? duracion}) {
    mostrar(
      context,
      mensaje: mensaje,
      tipo: AppSnackBarTipo.exito,
      duracion: duracion ?? const Duration(seconds: 4),
    );
  }

  static void error(BuildContext context, String mensaje, {Duration? duracion}) {
    mostrar(
      context,
      mensaje: mensaje,
      tipo: AppSnackBarTipo.error,
      duracion: duracion ?? const Duration(seconds: 5),
    );
  }

  static void advertencia(BuildContext context, String mensaje, {Duration? duracion}) {
    mostrar(
      context,
      mensaje: mensaje,
      tipo: AppSnackBarTipo.advertencia,
      duracion: duracion ?? const Duration(seconds: 4),
    );
  }

  static void info(BuildContext context, String mensaje, {Duration? duracion}) {
    mostrar(
      context,
      mensaje: mensaje,
      tipo: AppSnackBarTipo.informacion,
      duracion: duracion ?? const Duration(seconds: 4),
    );
  }

  static void neutro(BuildContext context, String mensaje, {Duration? duracion}) {
    mostrar(
      context,
      mensaje: mensaje,
      tipo: AppSnackBarTipo.neutro,
      duracion: duracion ?? const Duration(seconds: 4),
    );
  }

  static Widget _buildIcono(AppSnackBarTipo tipo, _SnackBarConfig config) {
    if (tipo == AppSnackBarTipo.advertencia) {
      return const Icon(
        Icons.warning_rounded,
        color: Colors.white,
        size: 24,
      );
    }

    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: Icon(
        config.icono,
        color: config.colorFondo,
        size: config.tamanoIcono,
      ),
    );
  }

  static _SnackBarConfig _getConfig(AppSnackBarTipo tipo) {
    switch (tipo) {
      case AppSnackBarTipo.exito:
        return const _SnackBarConfig(
          colorFondo: Color(0xFF16A34A),
          icono: Icons.check_rounded,
          tamanoIcono: 16,
        );
      case AppSnackBarTipo.error:
        return const _SnackBarConfig(
          colorFondo: Color(0xFFDC2626),
          icono: Icons.close_rounded,
          tamanoIcono: 15,
        );
      case AppSnackBarTipo.advertencia:
        return const _SnackBarConfig(
          colorFondo: Color(0xFFF59E0B),
          icono: Icons.warning_rounded,
          tamanoIcono: 16,
        );
      case AppSnackBarTipo.informacion:
        return const _SnackBarConfig(
          colorFondo: Color(0xFF1E6BF2),
          icono: Icons.info_rounded,
          tamanoIcono: 16,
        );
      case AppSnackBarTipo.neutro:
        return const _SnackBarConfig(
          colorFondo: Color(0xFF1E293B),
          icono: Icons.info_rounded,
          tamanoIcono: 16,
        );
    }
  }
}

class _SnackBarConfig {
  final Color colorFondo;
  final IconData icono;
  final double tamanoIcono;

  const _SnackBarConfig({
    required this.colorFondo,
    required this.icono,
    required this.tamanoIcono,
  });
}

