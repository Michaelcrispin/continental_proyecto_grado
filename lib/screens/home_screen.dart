import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/permisos.dart';
import '../models/usuario_model.dart';
import '../services/database_helper.dart';
import '../services/sesion_service.dart';
import '../widgets/app_background.dart';
import '../widgets/glass_card.dart';

import 'asistencia_screen.dart';
import 'vueltas_screen.dart';
import 'sanciones_screen.dart';
import 'conductores_screen.dart';
import 'control_economico_screen.dart';
import 'informes_screen.dart';
import 'gps_screen.dart';
import 'perfil_screen.dart';
import 'panel_tecnico_screen.dart';
import 'usuarios_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final int _currentIndex = 0;
  bool _isLoading = true;
  Map<String, num> _resumen = {
    'conductores_activos': 0,
    'asistencias_hoy': 0,
    'sanciones_pendientes': 0,
    'cuotas_pendientes_monto': 0,
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
        final resumenCond = await DatabaseHelper.instance.resumenConductor(idConductor);
        if (mounted) {
          setState(() {
            _resumen = resumenCond;
            _isLoading = false;
          });
        }
      } else {
        final hoy = DateTime.now().toIso8601String().substring(0, 10);
        final resumenGlobal = await DatabaseHelper.instance.resumenHome();
        final vueltas = await DatabaseHelper.instance.vueltasDetalle(fecha: hoy);

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
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
    ];
    return 'Hoy, ${now.day} de ${meses[now.month - 1]} de ${now.year}';
  }

  Color _colorPorRol(String? rol) {
    switch (rol?.toLowerCase().trim()) {
      case 'superadmin':
        return const Color(0xFF8B5CF6);
      case 'admin':
        return AppColors.primaryBlue;
      case 'supervisor':
        return const Color(0xFFF59E0B);
      case 'conductor':
        return const Color(0xFF10B981);
      default:
        return AppColors.textGray;
    }
  }

  String _etiquetaRol(String? rol) {
    switch (rol?.toLowerCase().trim()) {
      case 'superadmin':
        return 'SUPERADMIN';
      case 'admin':
        return 'ADMINISTRADOR';
      case 'supervisor':
        return 'SUPERVISOR';
      case 'conductor':
        return 'CONDUCTOR';
      default:
        return (rol ?? 'USUARIO').toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final nombreUsuario = SesionService.instance.nombre ??
        Usuario.currentUser?.nombre ??
        'Encargado';
    final rol = SesionService.instance.rol ?? Usuario.currentUser?.rol;
    final esConductor = SesionService.instance.esConductor;
    final esSupervisor = SesionService.instance.esSupervisor;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.refresh, color: AppColors.primaryDark),
          tooltip: 'Actualizar datos',
          onPressed: _cargarDatos,
        ),
        title: Center(
          child: Image.asset(
            'assets/images/logo.png',
            height: 40,
            errorBuilder: (c, e, s) => const Text(
              'Continental',
              style: TextStyle(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: AppColors.primaryDark),
            onPressed: () {},
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PerfilScreen()),
                ).then((_) => _cargarDatos());
              },
              child: const CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.iconBgBlue,
                child: Icon(Icons.person, color: AppColors.primaryBlue, size: 20),
              ),
            ),
          ),
        ],
      ),
      body: AppBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hola, $nombreUsuario',
                          style: const TextStyle(
                            color: AppColors.primaryDark,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Grupo Continental Trufi 101 - 127',
                          style: TextStyle(color: AppColors.textGray, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _colorPorRol(rol).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _colorPorRol(rol).withOpacity(0.35)),
                    ),
                    child: Text(
                      _etiquetaRol(rol),
                      style: TextStyle(
                        color: _colorPorRol(rol),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Widget de Fecha Dinámica
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      _formatearFecha(),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Tarjetas de Estadísticas Reales según Rol
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (esConductor) ...[
                // Estadísticas personalizadas para el Conductor
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        Icons.how_to_reg,
                        _resumen['asistio_hoy'] == 1 ? AppColors.success : const Color(0xFFF59E0B),
                        'Mi Asistencia',
                        _resumen['asistio_hoy'] == 1 ? 'Presente' : 'Pendiente',
                        'estado de hoy',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        Icons.route,
                        AppColors.primaryBlue,
                        'Mis Vueltas',
                        '${_resumen['vueltas_hoy'] ?? 0}',
                        'completadas hoy',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        Icons.warning_amber_rounded,
                        AppColors.danger,
                        'Mis Sanciones',
                        '${_resumen['sanciones_pendientes'] ?? 0}',
                        'pendientes',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        Icons.account_balance_wallet,
                        const Color(0xFF8B5CF6),
                        'Mis Cuotas',
                        'Bs. ${_resumen['cuotas_pendientes_monto'] ?? 0}',
                        'saldo pendiente',
                      ),
                    ),
                  ],
                ),
              ] else if (esSupervisor) ...[
                // Estadísticas para Supervisor (operativo)
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        Icons.person,
                        AppColors.success,
                        'Asistencia',
                        '${_resumen['asistencias_hoy'] ?? 0} / ${_resumen['conductores_activos'] ?? 0}',
                        'conductores hoy',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        Icons.route,
                        AppColors.primaryBlue,
                        'Vueltas',
                        '$_vueltasHoy',
                        'registradas hoy',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        Icons.warning_amber_rounded,
                        AppColors.danger,
                        'Sanciones',
                        '${_resumen['sanciones_pendientes'] ?? 0}',
                        'pendientes',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        Icons.groups_outlined,
                        const Color(0xFF0EA5E9),
                        'Conductores',
                        '${_resumen['conductores_activos'] ?? 0}',
                        'activos en línea',
                      ),
                    ),
                  ],
                ),
              ] else ...[
                // Estadísticas globales para Admin y Superadmin
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        Icons.person,
                        AppColors.success,
                        'Asistencia',
                        '${_resumen['asistencias_hoy'] ?? 0} / ${_resumen['conductores_activos'] ?? 0}',
                        'conductores',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        Icons.route,
                        AppColors.primaryBlue,
                        'Vueltas',
                        '$_vueltasHoy',
                        'registradas hoy',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        Icons.warning_amber_rounded,
                        AppColors.danger,
                        'Sanciones',
                        '${_resumen['sanciones_pendientes'] ?? 0}',
                        'pendientes',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        Icons.account_balance_wallet,
                        const Color(0xFF8B5CF6),
                        'Cuotas',
                        'Bs. ${_resumen['cuotas_pendientes_monto'] ?? 0}',
                        'pendientes',
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 30),

              const Text(
                'Accesos rápidos',
                style: TextStyle(
                  color: AppColors.primaryDark,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Grid de Accesos Rápidos filtrado dinámicamente por Permisos RBAC
              _buildQuickAccessGrid(rol, esConductor),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            final puedeVerUsuarios = Permisos.puedeVer(rol, Permisos.moduloUsuarios);
            if (puedeVerUsuarios) {
              if (index == 1) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const UsuariosScreen()),
                ).then((_) => _cargarDatos());
              } else if (index == 2) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AsistenciaScreen()),
                ).then((_) => _cargarDatos());
              } else if (index == 3) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const VueltasScreen()),
                ).then((_) => _cargarDatos());
              } else if (index == 4) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PerfilScreen()),
                ).then((_) => _cargarDatos());
              }
            } else {
              if (index == 1) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AsistenciaScreen()),
                ).then((_) => _cargarDatos());
              } else if (index == 2) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const VueltasScreen()),
                ).then((_) => _cargarDatos());
              } else if (index == 3) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const GpsScreen()),
                ).then((_) => _cargarDatos());
              } else if (index == 4) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PerfilScreen()),
                ).then((_) => _cargarDatos());
              }
            }
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.primaryBlue,
          unselectedItemColor: const Color(0xFF94A3B8),
          showUnselectedLabels: true,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 10),
          items: Permisos.puedeVer(rol, Permisos.moduloUsuarios)
              ? const [
                  BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
                  BottomNavigationBarItem(icon: Icon(Icons.manage_accounts), label: 'Usuarios'),
                  BottomNavigationBarItem(icon: Icon(Icons.groups), label: 'Asistencia'),
                  BottomNavigationBarItem(icon: Icon(Icons.route), label: 'Vueltas'),
                  BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: 'Más'),
                ]
              : const [
                  BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
                  BottomNavigationBarItem(icon: Icon(Icons.groups), label: 'Asistencia'),
                  BottomNavigationBarItem(icon: Icon(Icons.route), label: 'Vueltas'),
                  BottomNavigationBarItem(icon: Icon(Icons.gps_fixed), label: 'GPS'),
                  BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: 'Más'),
                ],
        ),
      ),
    );
  }

  Widget _buildQuickAccessGrid(String? rol, bool esConductor) {
    final List<Widget> items = [];

    // 1. Panel Técnico (exclusivo para superadmin)
    if (Permisos.puedeVer(rol, Permisos.moduloPanelTecnico)) {
      items.add(_buildQuickAccess(
        Icons.admin_panel_settings,
        'Panel Técnico',
        const PanelTecnicoScreen(),
        colorIcono: const Color(0xFF8B5CF6),
      ));
    }

    // 2. Gestión de Usuarios (superadmin y admin)
    if (Permisos.puedeVer(rol, Permisos.moduloUsuarios)) {
      items.add(_buildQuickAccess(
        Icons.manage_accounts,
        'Usuarios',
        const UsuariosScreen(),
        colorIcono: const Color(0xFF0284C7),
      ));
    }

    // 3. Conductores (superadmin y admin)
    if (Permisos.puedeVer(rol, Permisos.moduloConductores)) {
      items.add(_buildQuickAccess(
        Icons.person,
        'Conductores',
        const ConductoresScreen(),
      ));
    }

    // 3. Asistencia (todos)
    if (Permisos.puedeVer(rol, Permisos.moduloAsistencia)) {
      items.add(_buildQuickAccess(
        Icons.groups,
        esConductor ? 'Mi Asistencia' : 'Asistencia',
        const AsistenciaScreen(),
      ));
    }

    // 4. Vueltas (todos)
    if (Permisos.puedeVer(rol, Permisos.moduloVueltas)) {
      items.add(_buildQuickAccess(
        Icons.route,
        esConductor ? 'Mis Vueltas' : 'Vueltas',
        const VueltasScreen(),
      ));
    }

    // 5. Sanciones (todos)
    if (Permisos.puedeVer(rol, Permisos.moduloSanciones)) {
      items.add(_buildQuickAccess(
        Icons.warning_amber_rounded,
        esConductor ? 'Mis Sanciones' : 'Sanciones',
        const SancionesScreen(),
      ));
    }

    // 6. Control Económico / Cuotas (superadmin, admin y conductor)
    if (Permisos.puedeVer(rol, Permisos.moduloControlEconomico)) {
      items.add(_buildQuickAccess(
        Icons.account_balance_wallet,
        esConductor ? 'Mis Cuotas' : 'Económico',
        const ControlEconomicoScreen(),
      ));
    }

    // 7. Informes (superadmin y admin)
    if (Permisos.puedeVer(rol, Permisos.moduloInformes)) {
      items.add(_buildQuickAccess(
        Icons.description,
        'Informes',
        const InformesScreen(),
      ));
    }

    // 8. GPS / Monitoreo (todos)
    if (Permisos.puedeVer(rol, Permisos.moduloGps)) {
      items.add(_buildQuickAccess(
        Icons.gps_fixed,
        'GPS',
        const GpsScreen(),
      ));
    }

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.05,
      children: items,
    );
  }

  Widget _buildStatCard(
    IconData icon,
    Color iconColor,
    String title,
    String value,
    String subtitle,
  ) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const Spacer(),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textGray,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              color: iconColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(color: AppColors.textLight, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccess(
    IconData icon,
    String label,
    Widget targetScreen, {
    Color? colorIcono,
  }) {
    final c = colorIcono ?? AppColors.primaryBlue;
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => targetScreen),
        ).then((_) => _cargarDatos());
      },
      child: GlassCard(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: c.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: c, size: 22),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.primaryDark,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
