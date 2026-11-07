import 'package:flutter/material.dart';
import '../../core/permisos.dart';
import '../../services/economia_repo.dart';
import '../../services/sesion_service.dart';
import '../../widgets/app_bottom_bar.dart';
import '../asistencia/asistencia_screen.dart';
import '../home_screen.dart';
import '../sanciones_screen.dart';
import '../vueltas_screen.dart';
import 'caja_del_dia_screen.dart';
import 'cuota_detalle_screen.dart';
import 'dashboard_cuotas_screen.dart';
import 'informe_economico_screen.dart';
import 'seleccionar_categoria_screen.dart';
import 'widgets/cuota_card.dart';

const _kVerdeOscuro = Color(0xFF02634C);

/// Pantalla Principal del Módulo de Cuotas con diseño corporativo verde.
/// Refleja:
/// - Encabezado curvo verde esmeralda con botón atrás, botón squircle blanco y título grande "Cuotas".
/// - Selector de pestañas / píldoras: [Todas] [En cobro] [Completadas] en verde corporativo.
/// - Tarjetas con fecha destacada, montos y avance de recaudación en verde.
/// - Botón flotante redondeado "+ Nueva cuota" en color verde corporativo.
class CuotasScreen extends StatefulWidget {
  const CuotasScreen({super.key});

  @override
  State<CuotasScreen> createState() => _CuotasScreenState();
}

class _CuotasScreenState extends State<CuotasScreen> {
  List<Map<String, dynamic>> _cuotas = [];
  List<Map<String, dynamic>> _cuotasFiltradas = [];
  bool _isLoading = true;

  String _busqueda = '';
  String _filtroEstado = 'todas'; // 'todas' | 'en_cobro' | 'completada'
  bool _mostrarBuscador = false;
  final TextEditingController _searchCtrl = TextEditingController();

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
    _cargarCuotas();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarCuotas() async {
    setState(() => _isLoading = true);
    try {
      final lista = await EconomiaRepo.instance.listarCuotasConResumen();
      if (mounted) {
        setState(() {
          _cuotas = lista;
          _filtrar(_busqueda);
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filtrar(String query) {
    _busqueda = query;
    final q = query.toLowerCase().trim();
    setState(() {
      _cuotasFiltradas = _cuotas.where((c) {
        final estado =
            c['estado_calculado']?.toString().toLowerCase() ?? 'pendiente';

        // Filtro por píldoras ('todas', 'en_cobro', 'completada')
        if (_filtroEstado != 'todas') {
          if (_filtroEstado == 'en_cobro' &&
              (estado != 'en_cobro' && estado != 'pendiente')) {
            return false;
          }
          if (_filtroEstado == 'completada' && estado != 'completada') {
            return false;
          }
        }

        // Filtro por texto si el buscador está activo
        if (q.isNotEmpty) {
          final nombre = (c['nombre'] ?? '').toString().toLowerCase();
          final desc = (c['descripcion'] ?? '').toString().toLowerCase();
          if (!nombre.contains(q) && !desc.contains(q)) return false;
        }

        return true;
      }).toList();
    });
  }

  Future<void> _abrirCrearCuota() async {
    final creada = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const SeleccionarCategoriaScreen()),
    );
    if (creada == true) {
      _cargarCuotas();
    }
  }

  Future<void> _abrirDashboard() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DashboardCuotasScreen()),
    );
    if (mounted) _cargarCuotas();
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
            child: const Text(
              'Borrar Todo',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await EconomiaRepo.instance.vaciarTodasLasCuotas();
        _cargarCuotas();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Se borraron todas las cuotas.')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error al borrar cuotas: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final puedeEditar = Permisos.puedeEditar(
      SesionService.instance.rol,
      Permisos.moduloControlEconomico,
    );
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      bottomNavigationBar: AppBottomBar(
        currentTab: AppBottomTab.cuotas,
        onTabSelected: (tab) {
          if (tab == AppBottomTab.cuotas) {
            _cargarCuotas();
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
      floatingActionButton: puedeEditar
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
        onRefresh: _cargarCuotas,
        color: _kVerdeOscuro,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. ENCABEZADO CURVO VERDE CORPORATIVO
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: _kVerdeOscuro,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(32),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, topPadding + 8, 16, 20),
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
                            size: 22,
                          ),
                          tooltip: 'Volver',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.insights_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                              tooltip: 'Dashboard de recaudación',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: _abrirDashboard,
                            ),
                            const SizedBox(width: 10),
                            IconButton(
                              icon: Icon(
                                _mostrarBuscador ? Icons.close : Icons.search,
                                color: Colors.white,
                                size: 22,
                              ),
                              tooltip: _mostrarBuscador
                                  ? 'Cerrar búsqueda'
                                  : 'Buscar cuota',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                setState(() {
                                  _mostrarBuscador = !_mostrarBuscador;
                                  if (!_mostrarBuscador) {
                                    _searchCtrl.clear();
                                    _filtrar('');
                                  }
                                });
                              },
                            ),
                            const SizedBox(width: 10),
                            // Botón blanco squircle con icono
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: PopupMenuButton<String>(
                                icon: const Icon(
                                  Icons.person_rounded,
                                  color: _kVerdeOscuro,
                                  size: 26,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                onSelected: (val) {
                                  if (val == 'crear') _abrirCrearCuota();
                                  if (val == 'caja_dia') {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const CajaDelDiaScreen(),
                                      ),
                                    );
                                  }
                                  if (val == 'informe_eco') {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const InformeEconomicoScreen(),
                                      ),
                                    );
                                  }
                                  if (val == 'dashboard') _abrirDashboard();
                                  if (val == 'recargar') _cargarCuotas();
                                  if (val == 'vaciar') _confirmarVaciarTodo();
                                },
                                itemBuilder: (ctx) => [
                                  const PopupMenuItem(
                                    value: 'crear',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.add_circle_outline,
                                          color: _kVerdeOscuro,
                                          size: 20,
                                        ),
                                        SizedBox(width: 8),
                                        Text('Nueva Cuota'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'caja_dia',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.point_of_sale_outlined,
                                          color: _kVerdeOscuro,
                                          size: 20,
                                        ),
                                        SizedBox(width: 8),
                                        Text('Caja del Día (Arqueo)'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'informe_eco',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.analytics_outlined,
                                          color: _kVerdeOscuro,
                                          size: 20,
                                        ),
                                        SizedBox(width: 8),
                                        Text('Informe Económico General'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'dashboard',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.insights_rounded,
                                          color: _kVerdeOscuro,
                                          size: 20,
                                        ),
                                        SizedBox(width: 8),
                                        Text('Dashboard de Recaudación'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'recargar',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.refresh,
                                          color: _kVerdeOscuro,
                                          size: 20,
                                        ),
                                        SizedBox(width: 8),
                                        Text('Recargar Lista'),
                                      ],
                                    ),
                                  ),
                                  if (_cuotas.isNotEmpty && puedeEditar)
                                    const PopupMenuItem(
                                      value: 'vaciar',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.delete_forever,
                                            color: Colors.red,
                                            size: 20,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'Borrar todas las cuotas',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // Título grande "Cuotas" como en la imagen
                    const Text(
                      'Cuotas',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.4,
                      ),
                    ),
                    if (_mostrarBuscador) ...[
                      const SizedBox(height: 12),
                      Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: TextField(
                          controller: _searchCtrl,
                          autofocus: true,
                          onChanged: _filtrar,
                          style: const TextStyle(
                            fontSize: 14,
                            color: _kVerdeOscuro,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Buscar cuota o motivo...',
                            hintStyle: const TextStyle(
                              fontSize: 13.5,
                              color: Color(0xFF94A3B8),
                            ),
                            prefixIcon: const Icon(
                              Icons.search,
                              color: _kVerdeOscuro,
                              size: 20,
                            ),
                            suffixIcon: _busqueda.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(
                                      Icons.clear,
                                      size: 18,
                                      color: Color(0xFF94A3B8),
                                    ),
                                    onPressed: () {
                                      _searchCtrl.clear();
                                      _filtrar('');
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 10,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // 1.b Acceso rápido al dashboard de recaudación
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: InkWell(
                onTap: _abrirDashboard,
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF064E3B), Color(0xFF0D9488)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: _kVerdeOscuro.withValues(alpha: 0.18),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.insights_rounded,
                          color: Colors.white,
                          size: 21,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Dashboard de recaudación',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              'Recaudado, pendiente, métodos de pago y deudores',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.white,
                        size: 15,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 2. Píldoras de filtrado: [Todas] [En cobro] [Completadas]
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              child: Row(
                children: [
                  _buildFilterPill('todas', 'Todas'),
                  const SizedBox(width: 8),
                  _buildFilterPill('en_cobro', 'En cobro'),
                  const SizedBox(width: 8),
                  _buildFilterPill('completada', 'Completadas'),
                ],
              ),
            ),

            // 3. Lista de tarjetas de cuotas
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: _kVerdeOscuro),
                    )
                  : _cuotasFiltradas.isEmpty
                  ? _buildEstadoVacio(puedeEditar)
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 85),
                      itemCount: _cuotasFiltradas.length,
                      itemBuilder: (context, index) {
                        final cuota = _cuotasFiltradas[index];
                        return CuotaCard(
                          cuota: cuota,
                          index: index,
                          onTap: () async {
                            final recargar = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    CuotaDetalleScreen(cuota: cuota),
                              ),
                            );
                            if (recargar == true || mounted) {
                              _cargarCuotas();
                            }
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterPill(String key, String label) {
    final isSelected = _filtroEstado == key;
    return GestureDetector(
      onTap: () {
        setState(() => _filtroEstado = key);
        _filtrar(_busqueda);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? _kVerdeOscuro : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? _kVerdeOscuro : const Color(0xFFE2E8F0),
            width: 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _kVerdeOscuro.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  Widget _buildEstadoVacio(bool puedeEditar) {
    final hayFiltro = _busqueda.isNotEmpty || _filtroEstado != 'todas';

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFE6F4F0),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFBBF7D0), width: 2),
              ),
              child: Icon(
                hayFiltro
                    ? Icons.filter_alt_off_rounded
                    : Icons.receipt_long_rounded,
                size: 48,
                color: _kVerdeOscuro,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Aún no hay cuotas creadas',
              style: TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.bold,
                color: _kVerdeOscuro,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              hayFiltro
                  ? 'Prueba cambiando el término de búsqueda o seleccionando "Todas".'
                  : 'Crea una cuota para asignarla a todos los conductores activos del sindicato.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            if (!hayFiltro && puedeEditar) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kVerdeOscuro,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed: _abrirCrearCuota,
                icon: const Icon(Icons.add, size: 20),
                label: const Text(
                  'Crear Primera Cuota',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Barra inferior fija idéntica a la pantalla principal, con "Cuotas" seleccionada
}
