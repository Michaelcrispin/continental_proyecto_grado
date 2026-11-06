import 'package:flutter/material.dart';

import '../core/permisos.dart';
import '../models/usuario_model.dart';
import '../services/sesion_service.dart';
import 'cuotas/cuotas_screen.dart';
import 'home_screen.dart';
import 'usuarios_screen.dart';

// ---------- Paleta Corporativa Sindicato Continental ----------
const _kVerdeContinental = Color(0xFF02634C);
const _kVerdeOscuro = Color(0xFF014D3B);
const _kVerdeClaro = Color(0xFFE6F4F0);
const _kVerdeBorde = Color(0xFFA7F3D0);
const _kVerdeActivo = Color(0xFF10B981);
const _kFondo = Color(0xFFF8FAFC);
const _kTexto = Color(0xFF0F172A);
const _kSlate = Color(0xFF64748B);
const _kBorde = Color(0xFFE2E8F0);
const _kRojo = Color(0xFFDC2626);
const _kRojoClaro = Color(0xFFFEF2F2);
const _kRojoBorde = Color(0xFFFECACA);

/// Pantalla de Perfil de Usuario con la identidad corporativa verde Continental.
///
/// Refleja:
/// - Encabezado curvo verde esmeralda (#02634C) con logo oficial de Continental y botón volver.
/// - Tarjeta principal con avatar, nombre completo y badge de rol en verde corporativo.
/// - Bloque de información con iconos circulares verdes (correo, CI, móvil y estado activo).
/// - Accesos del sistema actualizados (Historial de cuotas, Gestión de usuarios y Configuración).
/// - Historial de asistencia e historial de sanciones removidos según requerimiento.
/// - Botón estilizado de cerrar sesión con diálogo de confirmación.
class PerfilScreen extends StatelessWidget {
  const PerfilScreen({super.key});

  void _confirmarCerrarSesion(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: _kRojo, size: 24),
            SizedBox(width: 10),
            Text(
              'Cerrar sesión',
              style: TextStyle(
                color: _kTexto,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: const Text(
          '¿Estás seguro de que deseas cerrar tu sesión actual?',
          style: TextStyle(color: _kSlate, fontSize: 14),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: _kSlate, fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              SesionService.instance.cerrarSesion(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _kRojo,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Text('Sí, cerrar sesión'),
          ),
        ],
      ),
    );
  }

  void _mostrarConfiguracion(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Row(
              children: [
                Icon(Icons.tune_rounded, color: _kVerdeContinental, size: 22),
                SizedBox(width: 10),
                Text(
                  'Configuración y Parámetros',
                  style: TextStyle(
                    color: _kTexto,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Parámetros oficiales configurados en el Sindicato Continental',
              style: TextStyle(color: _kSlate, fontSize: 12.5),
            ),
            const SizedBox(height: 16),
            _parametroFila(
              'Horario oficial de entrada',
              '07:30 AM',
              Icons.schedule_rounded,
            ),
            _parametroFila(
              'Tolerancia máxima (límite)',
              '08:00 AM (30 min)',
              Icons.alarm_on_rounded,
            ),
            _parametroFila(
              'Sanción por atraso (> 08:00 AM)',
              '+2 vueltas de castigo',
              Icons.gavel_rounded,
            ),
            _parametroFila(
              'Horario de cumplimiento de castigo',
              'Desde las 21:00 PM',
              Icons.nightlight_round,
            ),
            _parametroFila(
              'Versión del sistema',
              'Continental App v2.0 (La Paz - El Alto)',
              Icons.verified_rounded,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kVerdeContinental,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: const Text('Entendido'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _parametroFila(String label, String valor, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _kVerdeClaro,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: _kVerdeContinental, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: _kSlate, fontSize: 11.5, fontWeight: FontWeight.w500),
                ),
                Text(
                  valor,
                  style: const TextStyle(color: _kTexto, fontSize: 13.5, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final usuario = Usuario.currentUser;
    final nombre = usuario?.nombre ?? SesionService.instance.nombre ?? 'Sin sesión activa';
    final rol = usuario?.rol ?? SesionService.instance.rol ?? 'Invitado';
    final correo = usuario?.gmail ?? SesionService.instance.gmail;
    final ci = usuario?.ci ?? SesionService.instance.ci;
    final trufi = usuario?.numeroTrufi;
    final estado = usuario?.estado ?? 'Activo';

    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: _kFondo,
      body: Column(
        children: [
          // 1. Encabezado Curvo Verde Continental
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_kVerdeContinental, _kVerdeOscuro],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
              boxShadow: [
                BoxShadow(
                  color: Color(0x3302634C),
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, topPadding + 10, 16, 22),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    tooltip: 'Volver',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      } else {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const HomeScreen()),
                        );
                      }
                    },
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Mi Perfil',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Sindicato Continental • Cuenta activa',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                    ),
                    child: Image.asset(
                      'assets/images/logo.png',
                      height: 28,
                      errorBuilder: (c, e, s) => const Icon(Icons.public, color: Colors.white, size: 24),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. Contenido Scrolleable
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tarjeta Principal de Perfil (Avatar + Nombre + Rol)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: _kBorde),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: _kVerdeClaro,
                            shape: BoxShape.circle,
                            border: Border.all(color: _kVerdeBorde, width: 2),
                          ),
                          child: const CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.white,
                            child: Icon(
                              Icons.person_rounded,
                              color: _kVerdeContinental,
                              size: 34,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                nombre,
                                style: const TextStyle(
                                  color: _kTexto,
                                  fontSize: 17.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _kVerdeClaro,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: _kVerdeBorde),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.shield_outlined,
                                      size: 13,
                                      color: _kVerdeContinental,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      rol.toUpperCase(),
                                      style: const TextStyle(
                                        color: _kVerdeContinental,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Bloque de Información Personal
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: _kBorde),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        if (correo != null && correo.isNotEmpty) ...[
                          _datoPersonalFila(
                            icon: Icons.mail_outline_rounded,
                            label: 'Correo electrónico',
                            value: correo,
                          ),
                          const Divider(height: 20, color: _kBorde),
                        ],
                        if (ci != null && ci.isNotEmpty) ...[
                          _datoPersonalFila(
                            icon: Icons.badge_outlined,
                            label: 'Carnet de Identidad (CI)',
                            value: ci,
                          ),
                          const Divider(height: 20, color: _kBorde),
                        ],
                        if (trufi != null && trufi.isNotEmpty) ...[
                          _datoPersonalFila(
                            icon: Icons.directions_car_filled_rounded,
                            label: 'Móvil / Placa asignada',
                            value: trufi,
                          ),
                          const Divider(height: 20, color: _kBorde),
                        ],
                        // Estado de la cuenta
                        Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: _kVerdeClaro,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.check_circle_outline_rounded,
                                color: _kVerdeContinental,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Estado de cuenta',
                                    style: TextStyle(
                                      color: _kSlate,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Container(
                                        width: 7,
                                        height: 7,
                                        decoration: BoxDecoration(
                                          color: estado.toLowerCase() == 'activo'
                                              ? _kVerdeActivo
                                              : _kRojo,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        estado.toUpperCase(),
                                        style: TextStyle(
                                          color: estado.toLowerCase() == 'activo'
                                              ? const Color(0xFF065F46)
                                              : _kRojo,
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: Text(
                      'Accesos y Opciones',
                      style: TextStyle(
                        color: _kTexto,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Bloque de Menú / Opciones (Sin historial de asistencia ni de sanciones)
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: _kBorde),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _opcionMenuTile(
                          context: context,
                          icon: Icons.account_balance_wallet_rounded,
                          title: 'Historial de cuotas',
                          subtitle: 'Aportes, pagos y estado económico',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const CuotasScreen()),
                            );
                          },
                        ),
                        if (Permisos.puedeVer(rol, Permisos.moduloUsuarios)) ...[
                          const Divider(height: 1, color: _kBorde, indent: 64, endIndent: 16),
                          _opcionMenuTile(
                            context: context,
                            icon: Icons.manage_accounts_rounded,
                            title: 'Gestión de usuarios',
                            subtitle: 'Control de accesos y personal',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const UsuariosScreen()),
                              );
                            },
                          ),
                        ],
                        const Divider(height: 1, color: _kBorde, indent: 64, endIndent: 16),
                        _opcionMenuTile(
                          context: context,
                          icon: Icons.tune_rounded,
                          title: 'Configuración y Parámetros',
                          subtitle: 'Horarios oficiales, tolerancia y sistema',
                          onTap: () => _mostrarConfiguracion(context),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Botón Cerrar Sesión
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: _kRojoClaro,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _kRojoBorde, width: 1.2),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => _confirmarCerrarSesion(context),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.logout_rounded, color: _kRojo, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Cerrar sesión',
                                style: TextStyle(
                                  color: _kRojo,
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _datoPersonalFila({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: _kVerdeClaro,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: _kVerdeContinental, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: _kSlate,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: _kTexto,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _opcionMenuTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _kVerdeClaro,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: _kVerdeContinental, size: 21),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: _kTexto,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: _kSlate,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Color(0xFF94A3B8),
                size: 15,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
