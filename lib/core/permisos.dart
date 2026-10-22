import 'package:flutter/material.dart';

/// Helper centralizado de control de acceso basado en roles (RBAC).
///
/// Roles reconocidos en el sistema:
/// - 'superadmin'
/// - 'admin'
/// - 'supervisor'
/// - 'conductor'
class Permisos {
  // Constantes de identificación de módulos
  static const String moduloPanelTecnico = 'panel_tecnico';
  static const String moduloUsuarios = 'usuarios';
  static const String moduloConductores = 'conductores';
  static const String moduloSanciones = 'sanciones';
  static const String moduloControlEconomico = 'control_economico';
  static const String moduloAsistencia = 'asistencia';
  static const String moduloVueltas = 'vueltas';
  static const String moduloInformes = 'informes';
  static const String moduloGps = 'gps';
  static const String moduloPerfil = 'perfil';

  /// Determina si un [rol] tiene permiso para VISUALIZAR un [modulo].
  ///
  /// Reglas de negocio:
  /// - superadmin: Todo, incluyendo 'panel_tecnico' y 'usuarios'.
  /// - admin: Usuarios, conductores, sanciones, económico, asistencia, vueltas, informes, gps, perfil.
  /// - supervisor: Asistencia, vueltas, sanciones, gps, perfil (SIN control económico y SIN conductores ni informes).
  /// - conductor: Asistencia, vueltas, sanciones, cuotas (filtradas), gps, perfil (SIN conductores, informes ni panel técnico).
  static bool puedeVer(String? rol, String modulo) {
    if (rol == null) return false;
    final r = rol.toLowerCase().trim();

    switch (modulo) {
      case moduloPanelTecnico:
        return r == 'superadmin';

      case moduloUsuarios:
        return r == 'superadmin' || r == 'admin';

      case moduloConductores:
        return r == 'superadmin' || r == 'admin' || r == 'tesorero';

      case moduloControlEconomico:
        // Conductor ve sus cuotas; tesorero/admin/superadmin gestionan caja; supervisor visualiza.
        return r == 'superadmin' || r == 'admin' || r == 'conductor' || r == 'supervisor' || r == 'tesorero';

      case moduloInformes:
        return r == 'superadmin' || r == 'admin' || r == 'tesorero';

      case moduloAsistencia:
      case moduloVueltas:
      case moduloSanciones:
      case moduloGps:
      case moduloPerfil:
        return true;

      default:
        return false;
    }
  }

  /// Determina si un [rol] tiene autorización para CREAR / EDITAR / GESTIONAR en un [modulo].
  static bool puedeEditar(String? rol, String modulo) {
    if (rol == null) return false;
    final r = rol.toLowerCase().trim();

    switch (modulo) {
      case moduloPanelTecnico:
        return r == 'superadmin';

      case moduloUsuarios:
      case moduloConductores:
        return r == 'superadmin' || r == 'admin';

      case moduloControlEconomico:
        return r == 'superadmin' || r == 'admin' || r == 'tesorero';

      case moduloInformes:
        return r == 'superadmin' || r == 'admin';

      case moduloSanciones:
        // Supervisor puede crear/proponer; admin y superadmin gestión completa.
        return r == 'superadmin' || r == 'admin' || r == 'supervisor';

      case moduloAsistencia:
      case moduloVueltas:
        // Supervisor, admin y superadmin registran vueltas y asistencia.
        // El conductor solo puede marcar su propia asistencia.
        if (modulo == moduloAsistencia && r == 'conductor') return true;
        return r == 'superadmin' || r == 'admin' || r == 'supervisor';

      case moduloPerfil:
        return true;

      default:
        return false;
    }
  }

  /// Protege una pantalla verificando que el rol tenga permiso de entrada.
  /// Si no tiene permiso, muestra un mensaje de advertencia y saca al usuario de la pantalla.
  static bool verificarAcceso(BuildContext context, String? rol, String modulo) {
    if (!puedeVer(rol, modulo)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Acceso restringido: El rol "$rol" no tiene permiso para este módulo.'),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.of(context).maybePop();
        }
      });
      return false;
    }
    return true;
  }
}
