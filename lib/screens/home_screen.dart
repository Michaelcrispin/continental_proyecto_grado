import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/permisos.dart';
import '../models/usuario_model.dart';
import '../services/database_helper.dart';
import '../services/sesion_service.dart';
import '../widgets/app_bottom_bar.dart';

import 'asistencia/asistencia_screen.dart';
import 'asistencia/puntos_control_screen.dart';
import 'vueltas_screen.dart';
import 'sanciones_screen.dart';
import 'cuotas/cuotas_screen.dart';
import 'conductores/grupos_conductores_screen.dart';
import 'informes_screen.dart';
import 'gps/gps_en_vivo_screen.dart';
import 'gps/ruta_oficial_screen.dart';
import 'perfil_screen.dart';
// DESACTIVADO: Panel Técnico oculto del menú y la pantalla principal.
// import 'panel_tecnico_screen.dart';
import 'usuarios_screen.dart';
import 'reuniones_screen.dart';

const _kVerdeOscuro = Color(
  0xFF02634C,
); // Exacto al diseño de la imagen (#02634C)
const _kVerdeSuave = Color(0xFF0D7C66);

class _ModuloItem {
  final String titulo;
  final IconData icono;
  final Widget destino;
  final Color color;
  final String? badge;

  const _ModuloItem({
    required this.titulo,
    required this.icono,
    required this.destino,
    required this.color,
    this.badge,
  });
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedModuloIndex = 0;
  bool _isLoading = true;
  Map<String, dynamic> _resumen = {
    'conductores_activos': 0,
    'asistencias_hoy': 0,
    'sanciones_pendientes': 0,
    'cuotas_pendientes_monto': 0,
    'cuotas_creadas': 0,
    'asistio_hoy': 0,
    'vueltas_hoy': 0,
  };
  int _vueltasHoy = 0;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);
    try {
      final esConductor = SesionService.instance.esConductor;
      final idConductor = SesionService.instance.idConductor;

      if (esConductor && idConductor != null) {
        final resumenCond = await DatabaseHelper.instance.resumenConductor(
          idConductor,
        );
        if (mounted) {
          setState(() {
            _resumen = resumenCond;
            _isLoading = false;
          });
        }
      } else {
        final hoy = DateTime.now().toIso8601String().substring(0, 10);
        final resumenGlobal = await DatabaseHelper.instance.resumenHome();
        final vueltas = await DatabaseHelper.instance.vueltasDetalle(
          fecha: hoy,
        );

        if (mounted) {
          setState(() {
            _resumen = resumenGlobal;
            _vueltasHoy = vueltas.length;
            _isLoading = false;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatearFecha() {
    final now = DateTime.now();
    const meses = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];
    return 'Hoy, ${now.day} de ${meses[now.month - 1]} de ${now.year}';
  }

  String _etiquetaRol(String? rol) {
    switch (rol?.toLowerCase().trim()) {
      case 'superadmin':
        return 'SUPERADMIN';
      case 'admin':
        return 'ADMINISTRADOR';
      case 'supervisor':
        return 'SUPERVISOR';
      case 'tesorero':
        return 'SECRETARIO DE HACIENDA';
      case 'conductor':
        return 'CONDUCTOR';
      default:
        return (rol ?? 'USUARIO').toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final nombreUsuario =
        SesionService.instance.nombre ??
        Usuario.currentUser?.nombre ??
        'Encargado';
    final rol = SesionService.instance.rol ?? Usuario.currentUser?.rol;
    final esConductor = SesionService.instance.esConductor;
    final esSupervisor = SesionService.instance.esSupervisor;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: _buildDrawer(context, nombreUsuario, rol),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Encabezado Verde (Diseño moderno con Fecha en lugar de Buscador)
            _buildGreenHeader(context, nombreUsuario, rol),

            const SizedBox(height: 18),

            // 2. Contenido Principal (Resumen del día primero)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Fila de título: "Resumen del día" + "Ver todo" (estilo Our Services de la referencia)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Resumen del día',
                        style: TextStyle(
                          color: Color(0xFF1E293B),
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.3,
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const InformesScreen(),
                            ),
                          ).then((_) => _cargarDatos());
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 4,
                          ),
                          child: Row(
                            children: [
                              Text(
                                'Ver todo',
                                style: TextStyle(
                                  color: _kVerdeOscuro,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(width: 3),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: _kVerdeOscuro,
                                size: 11,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Tarjetas de Estadísticas Reales según Rol
                  if (_isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (esConductor) ...[
                    // Par de tarjetas destacadas superiores (Asistencia y Sanciones / Vueltas de castigo)
                    Builder(
                      builder: (context) {
                        final estadoSancion = _resumen['estado_sancion']?.toString() ?? 'sin_sancion';
                        final asig = (_resumen['vueltas_castigo_asignadas'] as num?)?.toInt() ?? 0;
                        final cump = (_resumen['vueltas_castigo_cumplidas'] as num?)?.toInt() ?? 0;

                        final String valorSancion;
                        final String subtituloSancion;
                        final Color colorSancion;
                        final IconData iconoSancion;

                        if (estadoSancion == 'pendiente' && asig > 0) {
                          valorSancion = '$cump/$asig';
                          subtituloSancion = 'Vueltas por cumplir';
                          colorSancion = cump > 0 ? const Color(0xFFF59E0B) : const Color(0xFFEF4444);
                          iconoSancion = Icons.warning_amber_rounded;
                        } else if (estadoSancion == 'cumplida' && asig > 0) {
                          valorSancion = '$cump/$asig';
                          subtituloSancion = 'Vueltas cumplidas';
                          colorSancion = const Color(0xFF10B981);
                          iconoSancion = Icons.verified_rounded;
                        } else {
                          valorSancion = '0';
                          subtituloSancion = 'Sin vueltas por cumplir';
                          colorSancion = const Color(0xFF02634C);
                          iconoSancion = Icons.check_circle_outline_rounded;
                        }

                        final asistioHoy =
                            ((_resumen['asistio_hoy'] as num?)?.toInt() ?? 0) >= 1;

                        return _buildHeroPairCards(
                          title1: 'Mi Asistencia',
                          value1: asistioHoy
                              ? 'Asistió'
                              : 'Pendiente',
                          subtitle1: asistioHoy
                              ? 'Asistencia registrada hoy'
                              : 'Marcación de hoy',
                          icon1: Icons.how_to_reg_rounded,
                          color1: asistioHoy
                              ? AppColors.success
                              : const Color(0xFFF59E0B),
                          onTap1: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const GpsEnVivoScreen(),
                              ),
                            ).then((_) => _cargarDatos());
                          },
                          title2: 'Mis Sanciones',
                          value2: valorSancion,
                          subtitle2: subtituloSancion,
                          icon2: iconoSancion,
                          color2: colorSancion,
                          onTap2: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SancionesScreen(),
                              ),
                            ).then((_) => _cargarDatos());
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildStatCard(
                      Icons.route_rounded,
                      const Color(0xFF3B82F6),
                      'Mis Vueltas',
                      '${_resumen['vueltas_hoy'] ?? 0}',
                      'Vueltas completadas hoy',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const VueltasScreen(),
                          ),
                        ).then((_) => _cargarDatos());
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildStatCard(
                      Icons.account_balance_wallet_rounded,
                      const Color(0xFF8B5CF6),
                      'Mis Cuotas',
                      'Bs. ${_resumen['cuotas_pendientes_monto'] ?? 0}',
                      'Saldo pendiente de pago',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CuotasScreen(),
                          ),
                        ).then((_) => _cargarDatos());
                      },
                    ),
                  ] else if (esSupervisor) ...[
                    // Supervisor: Par de tarjetas destacadas
                    _buildHeroPairCards(
                      title1: 'Asistencias',
                      value1:
                          '${_resumen['asistencias_hoy'] ?? 0} / ${_resumen['conductores_activos'] ?? 0}',
                      subtitle1: 'Conductores presentes',
                      icon1: Icons.groups_rounded,
                      color1: AppColors.success,
                      onTap1: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AsistenciaScreen(),
                          ),
                        ).then((_) => _cargarDatos());
                      },
                      title2: 'Vueltas',
                      value2: '$_vueltasHoy',
                      subtitle2: 'Recorridos hoy',
                      icon2: Icons.route_rounded,
                      color2: const Color(0xFF3B82F6),
                      onTap2: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const VueltasScreen(),
                          ),
                        ).then((_) => _cargarDatos());
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildStatCard(
                      Icons.warning_amber_rounded,
                      const Color(0xFFEF4444),
                      'Sanciones Pendientes',
                      '${_resumen['sanciones_pendientes'] ?? 0}',
                      'Sanciones registradas hoy',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SancionesScreen(),
                          ),
                        ).then((_) => _cargarDatos());
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildStatCard(
                      Icons.local_taxi_rounded,
                      const Color(0xFF0EA5E9),
                      'Conductores en Línea',
                      '${_resumen['conductores_activos'] ?? 0}',
                      'Unidades habilitadas activas',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const GruposConductoresScreen(),
                          ),
                        ).then((_) => _cargarDatos());
                      },
                    ),
                  ] else ...[
                    // Admin / Superadmin: Par de tarjetas destacadas
                    _buildHeroPairCards(
                      title1: 'Asistencia',
                      value1:
                          '${_resumen['asistencias_hoy'] ?? 0} / ${_resumen['conductores_activos'] ?? 0}',
                      subtitle1: 'Conductores marcados',
                      icon1: Icons.groups_rounded,
                      color1: AppColors.success,
                      onTap1: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AsistenciaScreen(),
                          ),
                        ).then((_) => _cargarDatos());
                      },
                      title2: 'Vueltas',
                      value2: '$_vueltasHoy',
                      subtitle2: 'Vueltas registradas',
                      icon2: Icons.route_rounded,
                      color2: const Color(0xFF3B82F6),
                      onTap2: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const VueltasScreen(),
                          ),
                        ).then((_) => _cargarDatos());
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildStatCard(
                      Icons.warning_amber_rounded,
                      const Color(0xFFEF4444),
                      'Sanciones',
                      '${_resumen['sanciones_pendientes'] ?? 0}',
                      'Sanciones pendientes de cobro',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SancionesScreen(),
                          ),
                        ).then((_) => _cargarDatos());
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildStatCard(
                      Icons.account_balance_wallet_rounded,
                      const Color(0xFF8B5CF6),
                      'Cuotas',
                      '${_resumen['cuotas_creadas'] ?? 0}',
                      'Cuotas institucionales creadas',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CuotasScreen(),
                          ),
                        ).then((_) => _cargarDatos());
                      },
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Título de la sección de accesos directos
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Accesos directos',
                style: TextStyle(
                  color: Color(0xFF1E293B),
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.3,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // 3. Cuadrícula de módulos (3 botones por fila)
            _buildGridModulos(context, rol, esConductor),

            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomBar(
        currentTab: AppBottomTab.inicio,
        onTabSelected: (tab) {
          if (tab == AppBottomTab.inicio) {
            _cargarDatos();
          } else if (tab == AppBottomTab.asistencias) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AsistenciaScreen()),
            ).then((_) => _cargarDatos());
          } else if (tab == AppBottomTab.vueltas) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const VueltasScreen()),
            ).then((_) => _cargarDatos());
          } else if (tab == AppBottomTab.cuotas) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CuotasScreen()),
            ).then((_) => _cargarDatos());
          } else if (tab == AppBottomTab.sanciones) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SancionesScreen()),
            ).then((_) => _cargarDatos());
          }
        },
      ),
    );
  }

  /// Encabezado verde corporativo con tarjeta de avatar y widget de fecha
  Widget _buildGreenHeader(
    BuildContext context,
    String nombreUsuario,
    String? rol,
  ) {
    final padding = MediaQuery.of(context).padding;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: _kVerdeOscuro,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, padding.top + 8, 20, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Barra de acciones superiores: Menú (Drawer), Refrescar y Notificaciones
            Row(
              children: [
                Builder(
                  builder: (ctx) => IconButton(
                    icon: const Icon(
                      Icons.menu_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                    tooltip: 'Menú principal',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Scaffold.of(ctx).openDrawer(),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(
                    Icons.refresh_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                  tooltip: 'Actualizar datos',
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  constraints: const BoxConstraints(),
                  onPressed: _cargarDatos,
                ),
                const SizedBox(width: 6),
                IconButton(
                  icon: const Icon(
                    Icons.notifications_none_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {},
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Fila: "Hola, Super Administrador" + Tarjeta Blanca con Avatar
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hola, $nombreUsuario',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.3,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Grupo Continental Trufi 101 - 127',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      if (rol != null && !SesionService.instance.esConductor) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _etiquetaRol(rol),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 14),

                // Tarjeta Blanca con ícono de persona verde (idéntico a la imagen de referencia)
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PerfilScreen(),
                      ),
                    ).then((_) => _cargarDatos());
                  },
                  child: Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      color: _kVerdeOscuro,
                      size: 30,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Barra blanca (donde estaba el buscador, ahora con la FECHA como pidió el usuario)
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today_rounded,
                    color: _kVerdeSuave,
                    size: 19,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _formatearFecha(),
                      style: const TextStyle(
                        color: Color(0xFF334155),
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Cuadrícula de módulos: 3 botones por fila, sin carrusel ni scroll horizontal.
  Widget _buildGridModulos(
    BuildContext context,
    String? rol,
    bool esConductor,
  ) {
    final modulos = _obtenerModulos(rol, esConductor);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: modulos.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.86,
        ),
        itemBuilder: (context, index) {
          final m = modulos[index];
          final esSeleccionado = index == _selectedModuloIndex;

          return GestureDetector(
            onTap: () {
              setState(() => _selectedModuloIndex = index);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => m.destino),
              ).then((_) => _cargarDatos());
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              decoration: BoxDecoration(
                color: esSeleccionado ? _kVerdeOscuro : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: esSeleccionado
                      ? _kVerdeOscuro
                      : const Color(0xFFE2E8F0),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: esSeleccionado
                        ? _kVerdeOscuro.withOpacity(0.32)
                        : Colors.black.withOpacity(0.02),
                    blurRadius: esSeleccionado ? 10 : 4,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 8,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            m.icono,
                            color: esSeleccionado ? Colors.white : m.color,
                            size: 29,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            m.titulo,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: esSeleccionado
                                  ? Colors.white
                                  : const Color(0xFF334155),
                              fontSize: 11.5,
                              fontWeight: esSeleccionado
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                              height: 1.15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (m.badge != null && m.badge!.isNotEmpty)
                    Positioned(
                      top: 7,
                      right: 7,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: esSeleccionado ? Colors.white : m.color,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          m.badge!,
                          style: TextStyle(
                            color: esSeleccionado
                                ? _kVerdeOscuro
                                : Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<_ModuloItem> _obtenerModulos(String? rol, bool esConductor) {
    final list = <_ModuloItem>[];

    // 1. Asistencia - Coral cálido (como en la Imagen 1)
    if (Permisos.puedeVer(rol, Permisos.moduloAsistencia)) {
      list.add(
        _ModuloItem(
          titulo: esConductor ? 'Mi Asistencia' : 'Asistencia',
          icono: Icons.how_to_reg_rounded,
          destino: const AsistenciaScreen(),
          color: const Color(0xFFFF7A59),
          badge: esConductor
              ? (_resumen['asistio_hoy'] == 1 ? 'OK' : null)
              : '${_resumen['asistencias_hoy'] ?? 0}',
        ),
      );
    }

    // 2. Vueltas - Azul vibrante
    if (Permisos.puedeVer(rol, Permisos.moduloVueltas)) {
      list.add(
        _ModuloItem(
          titulo: esConductor ? 'Mis Vueltas' : 'Vueltas',
          icono: Icons.route_rounded,
          destino: const VueltasScreen(),
          color: const Color(0xFF3B82F6),
          badge: '$_vueltasHoy',
        ),
      );
    }

    // 3. Ruta Oficial (Fija Geo Tracker) - Verde Corporativo
    list.add(
      const _ModuloItem(
        titulo: 'Ruta',
        icono: Icons.map_rounded,
        destino: RutaOficialScreen(),
        color: Color(0xFF02634C),
      ),
    );

    // 4. Sanciones - Rojo / Carmín
    if (Permisos.puedeVer(rol, Permisos.moduloSanciones)) {
      final sanc = _resumen['sanciones_pendientes'] ?? 0;
      list.add(
        _ModuloItem(
          titulo: esConductor ? 'Mis Sanciones' : 'Sanciones',
          icono: Icons.warning_amber_rounded,
          destino: const SancionesScreen(),
          color: const Color(0xFFEF4444),
          badge: sanc > 0 ? '$sanc' : null,
        ),
      );
    }

    // 4. Cuotas / Económico - Púrpura / Violeta
    if (Permisos.puedeVer(rol, Permisos.moduloControlEconomico)) {
      list.add(
        _ModuloItem(
          titulo: esConductor ? 'Mis Cuotas' : 'Cuotas',
          icono: Icons.account_balance_wallet_rounded,
          destino: const CuotasScreen(),
          color: const Color(0xFF8B5CF6),
        ),
      );
    }

    // 5. GPS en Vivo - Verde azulado / Teal
    if (Permisos.puedeVer(rol, Permisos.moduloGps)) {
      list.add(
        const _ModuloItem(
          titulo: 'GPS en Vivo',
          icono: Icons.gps_fixed_rounded,
          destino: GpsEnVivoScreen(),
          color: Color(0xFF0D9488),
        ),
      );
    }

    // 6. Puntos A y B - Ámbar / Naranja dorado
    if (Permisos.puedeVer(rol, Permisos.moduloPuntosParada)) {
      list.add(
        const _ModuloItem(
          titulo: 'Puntos A y B',
          icono: Icons.edit_location_alt_rounded,
          destino: PuntosControlScreen(),
          color: Color(0xFFF59E0B),
        ),
      );
    }

    // 7. Conductores - Verde Esmeralda
    if (Permisos.puedeVer(rol, Permisos.moduloConductores)) {
      list.add(
        const _ModuloItem(
          titulo: 'Conductores',
          icono: Icons.local_taxi_rounded,
          destino: GruposConductoresScreen(),
          color: Color(0xFF10B981),
        ),
      );
    }

    // 8. Informes - Rosa Frambuesa
    if (Permisos.puedeVer(rol, Permisos.moduloInformes)) {
      list.add(
        const _ModuloItem(
          titulo: 'Informes',
          icono: Icons.description_rounded,
          destino: InformesScreen(),
          color: Color(0xFFEC4899),
        ),
      );
    }

    // 9. Directorio - Índigo
    if (Permisos.puedeVer(rol, Permisos.moduloUsuarios)) {
      list.add(
        const _ModuloItem(
          titulo: 'Directorio',
          icono: Icons.manage_accounts_rounded,
          destino: UsuariosScreen(),
          color: Color(0xFF6366F1),
        ),
      );
    }

    // 10. Panel Técnico - Azul Océano / Cian
    // DESACTIVADO: se oculta del menú de módulos de la pantalla principal.
    // if (Permisos.puedeVer(rol, Permisos.moduloPanelTecnico)) {
    //   list.add(
    //     const _ModuloItem(
    //       titulo: 'Panel Técnico',
    //       icono: Icons.admin_panel_settings_rounded,
    //       destino: PanelTecnicoScreen(),
    //       color: Color(0xFF0284C7),
    //     ),
    //   );
    // }

    return list;
  }

  Widget _buildStatCard(
    IconData icon,
    Color iconColor,
    String title,
    String value,
    String subtitle, {
    VoidCallback? onTap,
  }) {
    final card = Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Ícono circular destacado y más grande
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(width: 16),

          // Título y subtítulo descriptivo
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF1E293B),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Métrica / Valor numérico grande y destacado
          Text(
            value,
            style: TextStyle(
              color: iconColor,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 6),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF94A3B8),
              size: 22,
            ),
          ],
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: card);
    }
    return card;
  }

  Widget _buildHeroPairCards({
    required String title1,
    required String value1,
    required String subtitle1,
    required IconData icon1,
    required Color color1,
    required VoidCallback onTap1,
    required String title2,
    required String value2,
    required String subtitle2,
    required IconData icon2,
    required Color color2,
    required VoidCallback onTap2,
  }) {
    return Row(
      children: [
        Expanded(
          child: _buildHeroCard(
            title: title1,
            value: value1,
            subtitle: subtitle1,
            icon: icon1,
            color: color1,
            onTap: onTap1,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _buildHeroCard(
            title: title2,
            value: value2,
            subtitle: subtitle2,
            icon: icon2,
            color: color2,
            onTap: onTap2,
          ),
        ),
      ],
    );
  }

  Widget _buildHeroCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 154,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Banner superior con color suave (estilo Washer Service de referencia)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(19),
                ),
              ),
              child: Row(
                children: [
                  Icon(icon, color: color, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: color,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        value,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1E293B),
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, String nombreUsuario, String? rol) {
    final correo = SesionService.instance.gmail;
    final ci = SesionService.instance.ci;
    final identificador = (correo != null && correo.isNotEmpty)
        ? correo
        : ((ci != null && ci.isNotEmpty) ? 'CI: ' : 'Línea 101 - 127');

    final etiquetaRol = _etiquetaRolDrawer(rol);

    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // Encabezado verde corporativo Continental con curva inferior
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              18,
              MediaQuery.of(context).padding.top + 14,
              18,
              22,
            ),
            decoration: const BoxDecoration(
              color: Color(0xFF02634C),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar circular grande en blanco con silueta
                Container(
                  width: 58,
                  height: 58,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.person,
                      size: 38,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Información del usuario al lado del avatar
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Pill de rol con borde sutil translúcido (solo para roles administrativos/supervisión)
                      if (!SesionService.instance.esConductor) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 2.5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.55),
                              width: 1.0,
                            ),
                          ),
                          child: Text(
                            etiquetaRol,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                      ],

                      // Nombre del usuario en negrita
                      Text(
                        nombreUsuario,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),

                      // Correo electrónico o identificador
                      Text(
                        identificador,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.88),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),

                      // Grupo Continental Trufi 101 - 127
                      Row(
                        children: [
                          Icon(
                            Icons.groups_rounded,
                            size: 15,
                            color: Colors.white.withOpacity(0.9),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Grupo Continental Trufi 101 - 127',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.92),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Lista de opciones del menú
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                // Sección Administración según permisos (arriba de Operaciones).
                // DESACTIVADO: el Panel Técnico ya no cuenta para mostrar la sección.
                if (Permisos.puedeVer(rol, Permisos.moduloUsuarios) ||
                    Permisos.puedeVer(rol, Permisos.moduloConductores) ||
                    Permisos.puedeVer(rol, Permisos.moduloInformes) ||
                    Permisos.puedeVer(rol, Permisos.moduloPuntosParada)) ...[
                  _buildDrawerSectionHeader('ADMINISTRACIÓN'),
                  if (Permisos.puedeVer(rol, Permisos.moduloUsuarios))
                    _buildDrawerItem(
                      icon: Icons.folder_outlined,
                      title: 'Directorio',
                      onTap: () =>
                          _navegarDesdeDrawer(context, const UsuariosScreen()),
                    ),
                  if (Permisos.puedeVer(rol, Permisos.moduloConductores))
                    _buildDrawerItem(
                      icon: Icons.directions_car_outlined,
                      title: 'Conductores',
                      onTap: () => _navegarDesdeDrawer(
                        context,
                        const GruposConductoresScreen(),
                      ),
                    ),
                  if (Permisos.puedeVer(rol, Permisos.moduloInformes))
                    _buildDrawerItem(
                      icon: Icons.bar_chart_rounded,
                      title: 'Informes y Estadísticas',
                      onTap: () =>
                          _navegarDesdeDrawer(context, const InformesScreen()),
                    ),
                  if (Permisos.puedeVer(rol, Permisos.moduloPuntosParada))
                    _buildDrawerItem(
                      icon: Icons.verified_user_outlined,
                      title: 'Puntos de Parada (A y B)',
                      onTap: () => _navegarDesdeDrawer(
                        context,
                        const PuntosControlScreen(),
                      ),
                    ),
                  // DESACTIVADO: acceso al Panel Técnico desde el menú lateral.
                  // if (Permisos.puedeVer(rol, Permisos.moduloPanelTecnico))
                  //   _buildDrawerItem(
                  //     icon: Icons.settings_outlined,
                  //     title: 'Panel Técnico (Superadmin)',
                  //     onTap: () => _navegarDesdeDrawer(
                  //       context,
                  //       const PanelTecnicoScreen(),
                  //     ),
                  //   ),
                  const Divider(
                    height: 20,
                    thickness: 1,
                    color: Color(0xFFF1F5F9),
                    indent: 16,
                    endIndent: 16,
                  ),
                ],

                _buildDrawerSectionHeader('OPERACIONES'),
                _buildDrawerItem(
                  icon: Icons.groups_rounded,
                  title: 'Reuniones y Asambleas',
                  onTap: () =>
                      _navegarDesdeDrawer(context, const ReunionesScreen()),
                ),
                _buildDrawerItem(
                  icon: Icons.warning_amber_rounded,
                  title: 'Sanciones',
                  onTap: () =>
                      _navegarDesdeDrawer(context, const SancionesScreen()),
                ),
                _buildDrawerItem(
                  icon: Icons.my_location_rounded,
                  title: 'Monitoreo GPS en Vivo',
                  onTap: () =>
                      _navegarDesdeDrawer(context, const GpsEnVivoScreen()),
                ),

                const Divider(
                  height: 20,
                  thickness: 1,
                  color: Color(0xFFF1F5F9),
                  indent: 16,
                  endIndent: 16,
                ),
                _buildDrawerSectionHeader('MI CUENTA'),
                _buildDrawerItem(
                  icon: Icons.person_outline_rounded,
                  title: 'Mi Perfil',
                  onTap: () =>
                      _navegarDesdeDrawer(context, const PerfilScreen()),
                ),
                _buildDrawerItem(
                  icon: Icons.logout_rounded,
                  title: 'Cerrar Sesión',
                  colorIcono: const Color(0xFFEF4444),
                  colorTexto: const Color(0xFFEF4444),
                  onTap: () {
                    Navigator.pop(context); // Cierra drawer
                    SesionService.instance.cerrarSesion(context);
                  },
                ),
              ],
            ),
          ),

          // Pie del Drawer
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/logo.png',
                  height: 20,
                  errorBuilder: (c, e, s) => const Icon(
                    Icons.local_taxi_rounded,
                    color: Color(0xFF02634C),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Continental Trufi 101 – 127',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _etiquetaRolDrawer(String? rol) {
    switch (rol?.toLowerCase().trim()) {
      case 'superadmin':
        return 'Super Administrador';
      case 'admin':
        return 'Administrador';
      case 'supervisor':
        return 'Supervisor';
      case 'tesorero':
        return 'Secretario de Hacienda';
      case 'conductor':
        return 'Conductor';
      default:
        return rol ?? 'Usuario';
    }
  }

  void _navegarDesdeDrawer(BuildContext context, Widget screen) {
    Navigator.pop(context); // Cierra el Drawer
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    ).then((_) => _cargarDatos());
  }

  Widget _buildDrawerSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF475569),
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? colorIcono,
    Color? colorTexto,
    bool isSelected = false,
  }) {
    const verdeCorporativo = Color(0xFF02634C);
    final iconColor = isSelected
        ? verdeCorporativo
        : (colorIcono ?? verdeCorporativo);
    final textColor = isSelected
        ? verdeCorporativo
        : (colorTexto ?? const Color(0xFF1E293B));

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFE8F5EF) : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Icon(icon, color: iconColor, size: 22),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w600,
                      fontSize: 13.5,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: isSelected
                      ? verdeCorporativo
                      : const Color(0xFF94A3B8),
                  size: 19,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
