import 'package:flutter/material.dart';
import '../../core/formato_moneda.dart';
import '../../core/permisos.dart';
import '../../services/database_helper.dart';
import '../../services/economia_repo.dart';
import '../../services/sesion_service.dart';
import '../../widgets/app_bottom_bar.dart';
import '../../widgets/avatar_conductor.dart';
import '../asistencia/asistencia_screen.dart';
import '../home_screen.dart';
import '../sanciones_screen.dart';
import '../vueltas_screen.dart';
import 'caja_del_dia_screen.dart';
import 'cuota_conductor_detalle_screen.dart';
import 'cuota_detalle_screen.dart';
import 'dashboard_cuotas_screen.dart';
import 'informe_economico_screen.dart';
import 'seleccionar_categoria_screen.dart';
import '../pasanaco_screen.dart';
import 'widgets/cuota_card.dart';

const _kVerdeOscuro = Color(0xFF02634C);
const _kMintBg = Color(0xFFE6F4F0);

/// Pantalla Principal del Módulo de Cuotas adaptativa según el ROL:
/// 
/// 1. CONDUCTOR ("Mis cuotas"):
///    - Vista puramente informativa (no cobra).
///    - Tarjeta "Debes en total" con monto, cuotas pendientes y vencidas.
///    - Filtros: [Todas] [Debo] [Al día].
///    - Lista de cuotas agrupadas por concepto con saldo, avance y alertas.
///    - Al tocar una cuota -> Detalle con Cronograma y Mis Pagos.
///    - Aviso al pie: "Para pagar, acércate a la Secretaría de Hacienda."
///
/// 2. SUPERVISOR ("Cuotas" con dos pestañas):
///    - [Mis cuotas]: Misma vista informativa del conductor para sus propias cuotas.
///    - [Choferes]: Resumen general de choferes con deuda (solo lectura).
///      Al tocar un chofer -> Detalle de cuotas de ese chofer en solo lectura.
///
/// 3. HACIENDA (Superadmin / Admin / Tesorero):
///    - Vista de gestión institucional completa:
///      Acceso a Dashboard global, botón "+ Nueva cuota", listado de cuotas con
///      avance general de recaudación y gestión de cobros.
class CuotasScreen extends StatefulWidget {
  const CuotasScreen({super.key});

  @override
  State<CuotasScreen> createState() => _CuotasScreenState();
}

class _CuotasScreenState extends State<CuotasScreen> {
  bool _isLoading = true;

  // Roles
  String get _rol => (SesionService.instance.rol ?? '').toLowerCase().trim();
  bool get _esConductor => _rol == 'conductor';
  bool get _esSupervisor => _rol == 'supervisor';
  bool get _esHacienda => !_esConductor && !_esSupervisor;

  // ---------------------------------------------------------------------------
  // ESTADO PARA HACIENDA (ADMIN / SUPERADMIN / TESORERO)
  // ---------------------------------------------------------------------------
  List<Map<String, dynamic>> _cuotasHacienda = [];
  List<Map<String, dynamic>> _cuotasHaciendaFiltradas = [];
  String _filtroEstadoHacienda = 'todas'; // 'todas' | 'en_cobro' | 'completada'
  bool _mostrarBuscadorHacienda = false;
  final TextEditingController _searchHaciendaCtrl = TextEditingController();

  // ---------------------------------------------------------------------------
  // ESTADO PARA CONDUCTOR ("MIS CUOTAS")
  // ---------------------------------------------------------------------------
  String? _idConductor;
  Map<String, dynamic> _resumenConductor = {
    'debe_total': 0.0,
    'cuotas_pendientes': 0,
    'vencidas': 0,
  };
  List<Map<String, dynamic>> _cuotasConductor = [];
  List<Map<String, dynamic>> _cuotasConductorFiltradas = [];
  String _filtroConductor = 'todas'; // 'todas' | 'debo' | 'al_dia'

  // ---------------------------------------------------------------------------
  // ESTADO PARA SUPERVISOR ("CHOFERES")
  // ---------------------------------------------------------------------------
  int _tabSupervisor = 0; // 0: Mis cuotas, 1: Choferes
  List<Map<String, dynamic>> _choferesSupervisor = [];
  List<Map<String, dynamic>> _choferesSupervisorFiltrados = [];
  String _filtroChoferes = 'todos'; // 'todos' | 'deben' | 'al_dia'
  final TextEditingController _searchChoferesCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!Permisos.puedeVer(
        SesionService.instance.rol,
        Permisos.moduloControlEconomico,
      )) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No tienes acceso al módulo de Cuotas.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    });
    _cargarDatos();
  }

  @override
  void dispose() {
    _searchHaciendaCtrl.dispose();
    _searchChoferesCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);
    try {
      if (_esConductor) {
        await _cargarDatosConductor();
      } else if (_esSupervisor) {
        await Future.wait([
          _cargarDatosConductor(),
          _cargarDatosSupervisor(),
        ]);
      } else {
        await _cargarDatosHacienda();
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Carga para Conductor ("Mis cuotas")
  Future<void> _cargarDatosConductor() async {
    String? idCond = SesionService.instance.idConductor;
    if ((idCond == null || idCond.isEmpty) &&
        SesionService.instance.idUsuario != null) {
      final cond = await DatabaseHelper.instance.conductorDeUsuario(
        SesionService.instance.idUsuario!,
      );
      if (cond != null) {
        idCond = cond['id_conductor']?.toString();
      }
    }
    _idConductor = idCond;

    if (idCond != null && idCond.isNotEmpty) {
      final res = await EconomiaRepo.instance.resumenDeudaConductor(idCond);
      final lista =
          await EconomiaRepo.instance.cuotasAgrupadasConductor(idCond);
      _resumenConductor = res;
      _cuotasConductor = lista;
      _filtrarCuotasConductor(_filtroConductor);
    }
  }

  // Carga para Supervisor ("Choferes")
  Future<void> _cargarDatosSupervisor() async {
    final choferes =
        await EconomiaRepo.instance.resumenChoferesSupervisor();
    _choferesSupervisor = choferes;
    _filtrarChoferes();
  }

  // Carga para Hacienda (Mesa directiva)
  Future<void> _cargarDatosHacienda() async {
    final lista = await EconomiaRepo.instance.listarCuotasConResumen();
    _cuotasHacienda = lista;
    _filtrarHacienda(_searchHaciendaCtrl.text);
  }

  // ---------------------------------------------------------------------------
  // FILTRADOS
  // ---------------------------------------------------------------------------
  void _filtrarCuotasConductor(String filtro) {
    _filtroConductor = filtro;
    setState(() {
      _cuotasConductorFiltradas = _cuotasConductor.where((c) {
        final saldo = (c['saldo'] as num?)?.toDouble() ?? 0.0;
        if (filtro == 'debo') return saldo > 0.001;
        if (filtro == 'al_dia') return saldo <= 0.001;
        return true;
      }).toList();
    });
  }

  void _filtrarChoferes() {
    final q = _searchChoferesCtrl.text.trim().toLowerCase();
    setState(() {
      _choferesSupervisorFiltrados = _choferesSupervisor.where((c) {
        final debe = (c['debe'] as num?)?.toDouble() ?? 0.0;
        if (_filtroChoferes == 'deben' && debe <= 0.001) return false;
        if (_filtroChoferes == 'al_dia' && debe > 0.001) return false;
        if (q.isNotEmpty) {
          final nombre = (c['nombre'] ?? '').toString().toLowerCase();
          final ci = (c['ci'] ?? '').toString().toLowerCase();
          final interno = (c['numero_interno'] ?? '').toString();
          if (!nombre.contains(q) && !ci.contains(q) && !interno.contains(q)) {
            return false;
          }
        }
        return true;
      }).toList();
    });
  }

  void _filtrarHacienda(String query) {
    final q = query.toLowerCase().trim();
    setState(() {
      _cuotasHaciendaFiltradas = _cuotasHacienda.where((c) {
        final estado =
            c['estado_calculado']?.toString().toLowerCase() ?? 'pendiente';

        if (_filtroEstadoHacienda != 'todas') {
          if (_filtroEstadoHacienda == 'en_cobro' &&
              (estado != 'en_cobro' && estado != 'pendiente')) {
            return false;
          }
          if (_filtroEstadoHacienda == 'completada' && estado != 'completada') {
            return false;
          }
        }

        if (q.isNotEmpty) {
          final nombre = (c['nombre'] ?? '').toString().toLowerCase();
          final desc = (c['descripcion'] ?? '').toString().toLowerCase();
          if (!nombre.contains(q) && !desc.contains(q)) return false;
        }

        return true;
      }).toList();
    });
  }

  // ---------------------------------------------------------------------------
  // NAVEGACIÓN Y ACCIONES HACIENDA
  // ---------------------------------------------------------------------------
  Future<void> _abrirCrearCuota() async {
    final creada = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const SeleccionarCategoriaScreen()),
    );
    if (creada == true) {
      _cargarDatos();
    }
  }

  Future<void> _abrirDashboard() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DashboardCuotasScreen()),
    );
    if (mounted) _cargarDatos();
  }

  Future<void> _confirmarVaciarTodo() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text(
              'Borrar Todas las Cuotas',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        content: const Text(
          '¿Estás seguro de borrar todas las cuotas de la lista? Quedará limpio desde cero.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sí, borrar todo'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        final db = await DatabaseHelper.instance.database;
        await db.delete('pago');
        await db.delete('cuota');
        await db.delete('ronda_pasanaco');
        await db.delete('participante_pasanaco');
        await db.delete('pasanaco');
        await db.delete('tipo_cuota');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Se borraron todas las cuotas correctamente.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al borrar: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) _cargarDatos();
      }
    }
  }

  IconData _iconoCategoria(String? categoria, String nombre) {
    final cat = (categoria ?? '').toLowerCase();
    final nom = nombre.toLowerCase();
    if (cat == 'multa' || nom.contains('multa')) {
      return Icons.gavel_rounded;
    }
    if (cat == 'solidaria' ||
        nom.contains('apoyo') ||
        nom.contains('solidar')) {
      return Icons.volunteer_activism_rounded;
    }
    if (cat == 'pasanaco' ||
        nom.contains('pasanac') ||
        nom.contains('pasanak')) {
      return Icons.savings_rounded;
    }
    if (cat == 'ahorro' ||
        nom.contains('canast') ||
        nom.contains('ahorro') ||
        nom.contains('navid')) {
      return Icons.card_giftcard_rounded;
    }
    return Icons.payments_rounded;
  }

  // ---------------------------------------------------------------------------
  // BUILD PRINCIPAL
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      bottomNavigationBar: AppBottomBar(
        currentTab: AppBottomTab.cuotas,
        onTabSelected: (tab) {
          if (tab == AppBottomTab.cuotas) {
            _cargarDatos();
          } else if (tab == AppBottomTab.inicio) {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const HomeScreen()),
              );
            }
          } else if (tab == AppBottomTab.asistencias) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const AsistenciaScreen()),
            );
          } else if (tab == AppBottomTab.vueltas) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const VueltasScreen()),
            );
          } else if (tab == AppBottomTab.sanciones) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const SancionesScreen()),
            );
          }
        },
      ),
      floatingActionButton: _esHacienda
          ? FloatingActionButton.extended(
              onPressed: _abrirCrearCuota,
              backgroundColor: _kVerdeOscuro,
              foregroundColor: Colors.white,
              elevation: 4,
              icon: const Icon(
                Icons.add_rounded,
                size: 22,
                color: Colors.white,
              ),
              label: const Text(
                'Nueva cuota',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14.5,
                  letterSpacing: 0.2,
                ),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: _cargarDatos,
        color: _kVerdeOscuro,
        child: Column(
          children: [
            // 1. ENCABEZADO CURVO VERDE CORPORATIVO
            _buildEncabezado(topPadding),

            // 2. CUERPO SEGÚN ROL
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: _kVerdeOscuro),
                    )
                  : _buildCuerpoSegunRol(),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 1. ENCABEZADO CURVO VERDE
  // ===========================================================================
  Widget _buildEncabezado(double topPadding) {
    String tituloHeader = 'Cuotas';
    if (_esConductor) {
      tituloHeader = 'Mis cuotas';
    }

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: _kVerdeOscuro,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      padding: EdgeInsets.fromLTRB(16, topPadding + 8, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
              Row(
                children: [
                  if (_esHacienda) ...[
                    IconButton(
                      icon: const Icon(
                        Icons.insights_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                      tooltip: 'Dashboard Resumen de Cuotas',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: _abrirDashboard,
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      icon: Icon(
                        _mostrarBuscadorHacienda ? Icons.close : Icons.search,
                        color: Colors.white,
                        size: 22,
                      ),
                      tooltip: _mostrarBuscadorHacienda
                          ? 'Cerrar búsqueda'
                          : 'Buscar cuota',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        setState(() {
                          _mostrarBuscadorHacienda = !_mostrarBuscadorHacienda;
                          if (!_mostrarBuscadorHacienda) {
                            _searchHaciendaCtrl.clear();
                            _filtrarHacienda('');
                          }
                        });
                      },
                    ),
                    const SizedBox(width: 10),
                  ],

                  // Avatar / Squircle del usuario
                  _buildSquircleUsuario(),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // TÍTULO GRANDE
          Text(
            tituloHeader,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),

          // PESTAÑAS PARA EL SUPERVISOR: [Mis cuotas] [Choferes]
          if (_esSupervisor) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildTabSupervisorItem(
                      index: 0,
                      titulo: 'Mis cuotas',
                      icono: Icons.person_rounded,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _buildTabSupervisorItem(
                      index: 1,
                      titulo: 'Choferes',
                      icono: Icons.people_alt_rounded,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSquircleUsuario() {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: PopupMenuButton<String>(
        icon: const Icon(
          Icons.person_rounded,
          color: _kVerdeOscuro,
          size: 24,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        onSelected: (val) {
          if (val == 'crear') _abrirCrearCuota();
          if (val == 'caja_dia') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CajaDelDiaScreen()),
            );
          }
          if (val == 'informe_eco') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const InformeEconomicoScreen()),
            );
          }
          if (val == 'dashboard') _abrirDashboard();
          if (val == 'recargar') _cargarDatos();
          if (val == 'vaciar') _confirmarVaciarTodo();
        },
        itemBuilder: (ctx) {
          if (_esHacienda) {
            return [
              const PopupMenuItem(
                value: 'crear',
                child: Row(
                  children: [
                    Icon(Icons.add_circle_outline, color: _kVerdeOscuro, size: 20),
                    SizedBox(width: 8),
                    Text('Nueva Cuota'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'caja_dia',
                child: Row(
                  children: [
                    Icon(Icons.point_of_sale_outlined, color: _kVerdeOscuro, size: 20),
                    SizedBox(width: 8),
                    Text('Caja del Día (Arqueo)'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'informe_eco',
                child: Row(
                  children: [
                    Icon(Icons.analytics_outlined, color: _kVerdeOscuro, size: 20),
                    SizedBox(width: 8),
                    Text('Informe Económico General'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'dashboard',
                child: Row(
                  children: [
                    Icon(Icons.insights_rounded, color: _kVerdeOscuro, size: 20),
                    SizedBox(width: 8),
                    Text('Dashboard Resumen de Cuotas'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'recargar',
                child: Row(
                  children: [
                    Icon(Icons.refresh, color: _kVerdeOscuro, size: 20),
                    SizedBox(width: 8),
                    Text('Recargar Lista'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'vaciar',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep_outlined, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Text('Borrar Todas las Cuotas', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ];
          } else {
            return [
              PopupMenuItem(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      SesionService.instance.nombre ?? 'Usuario',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    Text(
                      'Rol: ${_rol.toUpperCase()}',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'recargar',
                child: Row(
                  children: [
                    Icon(Icons.refresh, color: _kVerdeOscuro, size: 20),
                    SizedBox(width: 8),
                    Text('Recargar Datos'),
                  ],
                ),
              ),
            ];
          }
        },
      ),
    );
  }

  Widget _buildTabSupervisorItem({
    required int index,
    required String titulo,
    required IconData icono,
  }) {
    final seleccionado = _tabSupervisor == index;
    return GestureDetector(
      onTap: () => setState(() => _tabSupervisor = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: seleccionado ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: seleccionado
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icono,
              size: 16,
              color: seleccionado ? _kVerdeOscuro : Colors.white70,
            ),
            const SizedBox(width: 6),
            Text(
              titulo,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: seleccionado ? _kVerdeOscuro : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 2. DISPATCHER DE CUERPO SEGÚN ROL
  // ===========================================================================
  Widget _buildCuerpoSegunRol() {
    if (_esConductor) {
      return _buildVistaConductor();
    }
    if (_esSupervisor) {
      return _tabSupervisor == 0
          ? _buildVistaConductor()
          : _buildVistaSupervisorChoferes();
    }
    return _buildVistaHacienda();
  }

  // ===========================================================================
  // VISTA 1: CONDUCTOR ("MIS CUOTAS")
  // ===========================================================================
  Widget _buildVistaConductor() {
    if (_idConductor == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.badge_outlined, size: 54, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              const Text(
                'Sin Ficha de Conductor Vinculada',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 6),
              const Text(
                'Tu cuenta actual no tiene una ficha de conductor asignada para consultar cuotas individuales.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // 1. TARJETA "DEBES EN TOTAL"
        _buildCardDebesEnTotal(),

        const SizedBox(height: 6),

        // 2. PÍLDORAS FILTRO: [Todas] [Debo] [Al día]
        _buildFiltrosConductor(),

        const SizedBox(height: 10),

        // 3. LISTADO DE CUOTAS
        if (_cuotasConductorFiltradas.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.check_circle_outline_rounded,
                    size: 48,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _filtroConductor == 'debo'
                        ? '¡No tienes ninguna cuota pendiente!'
                        : 'No se encontraron cuotas para este filtro.',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ..._cuotasConductorFiltradas
              .map((c) => _buildCardCuotaConductor(c)),

        // 4. AVISO INFORMATIVO DE HACIENDA AL PIE
        _buildAvisoHacienda(),
      ],
    );
  }

  Widget _buildCardDebesEnTotal() {
    final debe =
        (_resumenConductor['debe_total'] as num?)?.toDouble() ?? 0.0;
    final pendientes =
        (_resumenConductor['cuotas_pendientes'] as num?)?.toInt() ?? 0;
    final vencidas =
        (_resumenConductor['vencidas'] as num?)?.toInt() ?? 0;
    final alDia = debe <= 0.001;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: alDia
              ? [const Color(0xFF02634C), const Color(0xFF047857)]
              : (vencidas > 0
                  ? [const Color(0xFF991B1B), const Color(0xFFB91C1C)]
                  : [const Color(0xFF02634C), const Color(0xFF065F46)]),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Debes en total',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              Icon(
                alDia
                    ? Icons.check_circle_outline_rounded
                    : Icons.info_outline_rounded,
                color: Colors.white.withOpacity(0.85),
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            formatearBs(debe),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  alDia
                      ? 'Al día con todas las cuotas'
                      : '$pendientes cuota(s) pendiente(s)',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (vencidas > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          size: 14, color: Color(0xFFDC2626)),
                      const SizedBox(width: 4),
                      Text(
                        '$vencidas vencida(s)',
                        style: const TextStyle(
                          color: Color(0xFFDC2626),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFiltrosConductor() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildPildoraFiltroConductor('todas', 'Todas'),
          const SizedBox(width: 8),
          _buildPildoraFiltroConductor('debo', 'Debo'),
          const SizedBox(width: 8),
          _buildPildoraFiltroConductor('al_dia', 'Al día'),
        ],
      ),
    );
  }

  Widget _buildPildoraFiltroConductor(String key, String etiqueta) {
    final sel = _filtroConductor == key;
    return GestureDetector(
      onTap: () => _filtrarCuotasConductor(key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: sel ? _kVerdeOscuro : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: sel ? _kVerdeOscuro : const Color(0xFFE2E8F0),
            width: 1.2,
          ),
        ),
        child: Text(
          etiqueta,
          style: TextStyle(
            color: sel ? Colors.white : const Color(0xFF64748B),
            fontSize: 12.5,
            fontWeight: sel ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildCardCuotaConductor(Map<String, dynamic> c) {
    final nombre = c['nombre']?.toString() ?? 'Cuota';
    final categoria = c['categoria']?.toString();
    final total = (c['total'] as num?)?.toDouble() ?? 0.0;
    final pagado = (c['pagado'] as num?)?.toDouble() ?? 0.0;
    final saldo = (c['saldo'] as num?)?.toDouble() ?? 0.0;
    final vencidas = (c['vencidas'] as num?)?.toInt() ?? 0;
    final porcentaje = total > 0 ? (pagado / total).clamp(0.0, 1.0) : 1.0;
    final alDia = saldo <= 0.001;

    final icono = _iconoCategoria(categoria, nombre);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: vencidas > 0
              ? const Color(0xFFFECACA)
              : const Color(0xFFE2E8F0),
          width: vencidas > 0 ? 1.4 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            if (_idConductor != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CuotaConductorDetalleScreen(
                    idConductor: _idConductor!,
                    idTipoCuota: c['id_tipo_cuota'].toString(),
                    nombreCuota: nombre,
                    categoria: categoria,
                  ),
                ),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: alDia
                            ? _kMintBg
                            : (vencidas > 0
                                ? const Color(0xFFFEF2F2)
                                : _kMintBg),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icono,
                        color: alDia
                            ? _kVerdeOscuro
                            : (vencidas > 0
                                ? const Color(0xFFDC2626)
                                : _kVerdeOscuro),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nombre,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            alDia
                                ? '${formatearBs(total)} - PAGADO'
                                : 'Debes: ${formatearBs(saldo)}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: alDia
                                  ? const Color(0xFF059669)
                                  : const Color(0xFFDC2626),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: Color(0xFFCBD5E1),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: porcentaje,
                    minHeight: 5,
                    backgroundColor: const Color(0xFFF1F5F9),
                    color: alDia ? const Color(0xFF059669) : _kVerdeOscuro,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Pagado ${formatearBs(pagado)} de ${formatearBs(total)}',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (vencidas > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              size: 13,
                              color: Color(0xFFDC2626),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$vencidas vencida(s)',
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFDC2626),
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (!alDia)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'PENDIENTE',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFB45309),
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _kMintBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'AL DÍA',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: _kVerdeOscuro,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvisoHacienda() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline_rounded,
              size: 18, color: Color(0xFF475569)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Para pagar o regularizar tus cuotas, acércate a la Secretaría de Hacienda.',
              style: TextStyle(
                fontSize: 11.5,
                color: Color(0xFF475569),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // VISTA 2: SUPERVISOR ("CHOFERES")
  // ===========================================================================
  Widget _buildVistaSupervisorChoferes() {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // 1. TARJETA RESUMEN: CHOFERES CON DEUDA
        _buildCardResumenSupervisor(),

        // 2. BUSCADOR DE CHOFERES
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: TextField(
            controller: _searchChoferesCtrl,
            onChanged: (_) => _filtrarChoferes(),
            decoration: InputDecoration(
              hintText: 'Buscar chofer por nombre, CI o interno...',
              prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF64748B)),
              suffixIcon: _searchChoferesCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchChoferesCtrl.clear();
                        _filtrarChoferes();
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _kVerdeOscuro, width: 1.5),
              ),
            ),
          ),
        ),

        // 3. PÍLDORAS FILTRO: [Todos] [Deben] [Al día]
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              _buildPildoraFiltroChoferes('todos', 'Todos'),
              const SizedBox(width: 8),
              _buildPildoraFiltroChoferes('deben', 'Deben'),
              const SizedBox(width: 8),
              _buildPildoraFiltroChoferes('al_dia', 'Al día'),
            ],
          ),
        ),

        const SizedBox(height: 6),

        // 4. LISTADO DE CHOFERES
        if (_choferesSupervisorFiltrados.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text(
                _searchChoferesCtrl.text.isNotEmpty
                    ? 'No se encontraron choferes con esa búsqueda.'
                    : 'No hay choferes en esta categoría.',
                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
            ),
          )
        else
          ..._choferesSupervisorFiltrados
              .map((c) => _buildItemChoferSupervisor(c)),

        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildCardResumenSupervisor() {
    final totalChoferes = _choferesSupervisor.length;
    final conDeuda = _choferesSupervisor
        .where((c) => ((c['debe'] as num?)?.toDouble() ?? 0.0) > 0.001)
        .length;
    double sumaDeuda = 0.0;
    int sumaVencidas = 0;
    for (final c in _choferesSupervisor) {
      sumaDeuda += (c['debe'] as num?)?.toDouble() ?? 0.0;
      sumaVencidas += (c['vencidas'] as num?)?.toInt() ?? 0;
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.people_alt_rounded,
                  size: 18, color: _kVerdeOscuro),
              const SizedBox(width: 6),
              const Text(
                'Choferes con deuda',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$conDeuda de $totalChoferes choferes',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              Text(
                formatearBs(sumaDeuda),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFDC2626),
                ),
              ),
            ],
          ),
          if (sumaVencidas > 0) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    size: 14, color: Color(0xFFDC2626)),
                const SizedBox(width: 4),
                Text(
                  '$sumaVencidas con cuotas vencidas',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFDC2626),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPildoraFiltroChoferes(String key, String etiqueta) {
    final sel = _filtroChoferes == key;
    return GestureDetector(
      onTap: () {
        setState(() => _filtroChoferes = key);
        _filtrarChoferes();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: sel ? _kVerdeOscuro : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: sel ? _kVerdeOscuro : const Color(0xFFE2E8F0),
            width: 1.2,
          ),
        ),
        child: Text(
          etiqueta,
          style: TextStyle(
            color: sel ? Colors.white : const Color(0xFF64748B),
            fontSize: 12.5,
            fontWeight: sel ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildItemChoferSupervisor(Map<String, dynamic> c) {
    final nombre = c['nombre']?.toString() ?? 'Conductor';
    final interno = c['numero_interno']?.toString() ?? '--';
    final ci = c['ci']?.toString() ?? '';
    final debe = (c['debe'] as num?)?.toDouble() ?? 0.0;
    final vencidas = (c['vencidas'] as num?)?.toInt() ?? 0;
    final alDia = debe <= 0.001;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: vencidas > 0
              ? const Color(0xFFFECACA)
              : const Color(0xFFE2E8F0),
          width: vencidas > 0 ? 1.3 : 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _mostrarCuotasChoferParaSupervisor(c),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                AvatarConductor(
                  nombre: nombre,
                  foto: c['foto']?.toString(),
                  radio: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nombre,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Interno #$interno${ci.isNotEmpty ? ' · CI: $ci' : ''}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      alDia ? 'Al día' : 'Debe ${formatearBs(debe)}',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: alDia
                            ? const Color(0xFF059669)
                            : const Color(0xFFDC2626),
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (vencidas > 0)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            size: 13,
                            color: Color(0xFFDC2626),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '$vencidas vencida(s)',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFDC2626),
                            ),
                          ),
                        ],
                      )
                    else if (!alDia)
                      const Text(
                        'Pendiente',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFFD97706),
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    else
                      const Icon(
                        Icons.check_circle_outline_rounded,
                        size: 16,
                        color: Color(0xFF059669),
                      ),
                  ],
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: Color(0xFF94A3B8),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _mostrarCuotasChoferParaSupervisor(Map<String, dynamic> chofer) {
    final idCond = chofer['id_conductor'].toString();
    final nombre = chofer['nombre']?.toString() ?? 'Chofer';
    final interno = chofer['numero_interno']?.toString() ?? '--';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.82,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (sheetCtx, scrollCtrl) {
          return Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: EconomiaRepo.instance.cuotasAgrupadasConductor(idCond),
              builder: (fCtx, snap) {
                return Column(
                  children: [
                    // Barra superior drag handle
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: 10, bottom: 8),
                        width: 42,
                        height: 4.5,
                        decoration: BoxDecoration(
                          color: const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 4, 18, 12),
                      child: Row(
                        children: [
                          AvatarConductor(
                            nombre: nombre,
                            foto: chofer['foto']?.toString(),
                            radio: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  nombre,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                Text(
                                  'Interno #$interno · Modo Solo Lectura (Supervisor)',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(sheetCtx),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFFE2E8F0)),
                    Expanded(
                      child: snap.connectionState == ConnectionState.waiting
                          ? const Center(
                              child: CircularProgressIndicator(color: _kVerdeOscuro),
                            )
                          : (snap.data == null || snap.data!.isEmpty)
                              ? const Center(
                                  child: Text(
                                    'Este chofer no tiene cuotas registradas.',
                                    style: TextStyle(color: Color(0xFF64748B)),
                                  ),
                                )
                              : ListView.builder(
                                  controller: scrollCtrl,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  itemCount: snap.data!.length,
                                  itemBuilder: (bCtx, idx) {
                                    final item = snap.data![idx];
                                    final cNombre = item['nombre']?.toString() ?? 'Cuota';
                                    final saldo = (item['saldo'] as num?)?.toDouble() ?? 0.0;
                                    final total = (item['total'] as num?)?.toDouble() ?? 0.0;
                                    final pagado = (item['pagado'] as num?)?.toDouble() ?? 0.0;
                                    final vencidas = (item['vencidas'] as num?)?.toInt() ?? 0;
                                    final alDia = saldo <= 0.001;

                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 10),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: vencidas > 0
                                              ? const Color(0xFFFECACA)
                                              : const Color(0xFFE2E8F0),
                                        ),
                                      ),
                                      child: ListTile(
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 6,
                                        ),
                                        leading: CircleAvatar(
                                          backgroundColor: alDia ? _kMintBg : const Color(0xFFFEF2F2),
                                          child: Icon(
                                            _iconoCategoria(item['categoria']?.toString(), cNombre),
                                            color: alDia ? _kVerdeOscuro : const Color(0xFFDC2626),
                                            size: 20,
                                          ),
                                        ),
                                        title: Text(
                                          cNombre,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14.5,
                                          ),
                                        ),
                                        subtitle: Text(
                                          'Pagado: ${formatearBs(pagado)} de ${formatearBs(total)}',
                                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                        ),
                                        trailing: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              alDia ? 'Al día' : 'Debe ${formatearBs(saldo)}',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                                color: alDia ? const Color(0xFF059669) : const Color(0xFFDC2626),
                                              ),
                                            ),
                                            if (vencidas > 0)
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(
                                                    Icons.warning_amber_rounded,
                                                    size: 12,
                                                    color: Color(0xFFDC2626),
                                                  ),
                                                  const SizedBox(width: 3),
                                                  Text(
                                                    '$vencidas vencida(s)',
                                                    style: const TextStyle(
                                                      fontSize: 10.5,
                                                      fontWeight: FontWeight.bold,
                                                      color: Color(0xFFDC2626),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                          ],
                                        ),
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => CuotaConductorDetalleScreen(
                                                idConductor: idCond,
                                                idTipoCuota: item['id_tipo_cuota'].toString(),
                                                nombreCuota: cNombre,
                                                categoria: item['categoria']?.toString(),
                                                nombreConductor: nombre,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    );
                                  },
                                ),
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  // ===========================================================================
  // VISTA 3: HACIENDA (ADMIN / SUPERADMIN / TESORERO)
  // ===========================================================================
  Widget _buildVistaHacienda() {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // 1. BANNER DASHBOARD RESUMEN DE TODAS LAS CUOTAS
        Container(
          margin: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: [_kVerdeOscuro, Color(0xFF007A5A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: _kVerdeOscuro.withOpacity(0.28),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: _abrirDashboard,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.auto_graph_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Text(
                        'Dashboard Resumen de todas las Cuotas',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // BUSCADOR SI ESTÁ ACTIVO
        if (_mostrarBuscadorHacienda)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: TextField(
              controller: _searchHaciendaCtrl,
              autofocus: true,
              onChanged: _filtrarHacienda,
              decoration: InputDecoration(
                hintText: 'Buscar por título o descripción...',
                prefixIcon: const Icon(Icons.search, size: 20, color: _kVerdeOscuro),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    _searchHaciendaCtrl.clear();
                    _filtrarHacienda('');
                  },
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
            ),
          ),

        // 2. PÍLDORAS FILTRO: [Todas] [En cobro] [Completadas]
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              _buildPildoraFiltroHacienda('todas', 'Todas'),
              const SizedBox(width: 8),
              _buildPildoraFiltroHacienda('en_cobro', 'En cobro'),
              const SizedBox(width: 8),
              _buildPildoraFiltroHacienda('completada', 'Completadas'),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // 3. LISTADO DE CUOTAS INSTITUCIONALES
        if (_cuotasHaciendaFiltradas.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.inventory_2_outlined, size: 50, color: Colors.grey.shade300),
                  const SizedBox(height: 10),
                  const Text(
                    'No hay cuotas registradas en este estado.',
                    style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
          )
        else
          ..._cuotasHaciendaFiltradas.asMap().entries.map((entry) {
            final idx = entry.key;
            final cuota = entry.value;
            return CuotaCard(
              cuota: cuota,
              index: idx,
              onTap: () async {
                final cat =
                    (cuota['categoria'] ?? '').toString().toLowerCase().trim();
                final idTipo = cuota['id_tipo_cuota']?.toString() ?? '';
                if (cat == 'pasanaco' && idTipo.isNotEmpty) {
                  final pas = await EconomiaRepo.instance
                      .obtenerPasanacoPorTipoCuota(idTipo);
                  if (!mounted) return;
                  if (pas != null) {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PasanacoDetalleScreen(
                          idPasanaco: pas['id_pasanaco'].toString(),
                          puedeEditar: true,
                        ),
                      ),
                    );
                    if (mounted) _cargarDatos();
                    return;
                  }
                }
                if (!mounted) return;
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CuotaDetalleScreen(cuota: cuota),
                  ),
                );
                if (mounted) _cargarDatos();
              },
            );
          }),

        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildPildoraFiltroHacienda(String key, String etiqueta) {
    final sel = _filtroEstadoHacienda == key;
    return GestureDetector(
      onTap: () {
        setState(() => _filtroEstadoHacienda = key);
        _filtrarHacienda(_searchHaciendaCtrl.text);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: sel ? _kVerdeOscuro : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: sel ? _kVerdeOscuro : const Color(0xFFE2E8F0),
            width: 1.2,
          ),
        ),
        child: Text(
          etiqueta,
          style: TextStyle(
            color: sel ? Colors.white : const Color(0xFF64748B),
            fontSize: 12.5,
            fontWeight: sel ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
