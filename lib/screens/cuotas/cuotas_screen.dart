import 'package:flutter/material.dart';
import '../../core/permisos.dart';
import '../../services/economia_repo.dart';
import '../../services/sesion_service.dart';
import '../../widgets/app_background.dart';
import 'caja_del_dia_screen.dart';
import 'cuota_detalle_screen.dart';
import 'informe_economico_screen.dart';
import 'seleccionar_categoria_screen.dart';
import 'widgets/cuota_card.dart';

/// Pantalla Principal del Módulo de Cuotas (Diseño UI Moderno de Tarjetas).
/// Presenta:
/// - Cabecera institucional con logo CONTINENTAL.
/// - Título de sección "Todas las cuotas".
/// - Buscador en cápsula ("Buscar cuota...").
/// - Filtro por estado ('Todas', 'En cobro', 'Pendiente', 'Completada').
/// - Lista de tarjetas con badges y montos.
/// - Botón flotante "+ Nueva cuota" en píldora azul oscuro.
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
  String _filtroEstado = 'todas'; // 'todas' | 'en_cobro' | 'pendiente' | 'completada'
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!Permisos.puedeVer(SesionService.instance.rol, Permisos.moduloControlEconomico)) {
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
        final estado = c['estado_calculado']?.toString().toLowerCase() ?? 'pendiente';

        // Filtro por estado
        if (_filtroEstado != 'todas') {
          if (_filtroEstado == 'en_cobro' && estado != 'en_cobro') return false;
          if (_filtroEstado == 'pendiente' && estado != 'pendiente') return false;
          if (_filtroEstado == 'completada' && estado != 'completada') return false;
        }

        // Filtro por texto (título o descripción)
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
      MaterialPageRoute(
        builder: (_) => const SeleccionarCategoriaScreen(),
      ),
    );
    if (creada == true) {
      _cargarCuotas();
    }
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
            Text('Borrar Todas las Cuotas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: const Text('¿Estás seguro de borrar todas las cuotas de la lista? Quedará limpio desde cero.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Borrar Todo', style: TextStyle(fontWeight: FontWeight.bold)),
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al borrar cuotas: $e')),
          );
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

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F2B5B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Cuotas',
          style: TextStyle(
            color: Color(0xFF0F2B5B),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          // Logo oficial institucional CONTINENTAL en la esquina superior derecha
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Image.asset(
              'assets/images/logo.png',
              height: 38,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.directions_bus_rounded,
                color: Color(0xFF0F2B5B),
                size: 28,
              ),
            ),
          ),
          if (puedeEditar)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Color(0xFF0F2B5B)),
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
                if (val == 'recargar') _cargarCuotas();
                if (val == 'vaciar') _confirmarVaciarTodo();
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: 'crear',
                  child: Row(
                    children: [
                      Icon(Icons.add_circle_outline, color: Color(0xFF0F2B5B), size: 20),
                      SizedBox(width: 8),
                      Text('Nueva Cuota'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'caja_dia',
                  child: Row(
                    children: [
                      Icon(Icons.point_of_sale_outlined, color: Color(0xFF0F2B5B), size: 20),
                      SizedBox(width: 8),
                      Text('Caja del Día (Arqueo)'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'informe_eco',
                  child: Row(
                    children: [
                      Icon(Icons.analytics_outlined, color: Color(0xFF0F2B5B), size: 20),
                      SizedBox(width: 8),
                      Text('Informe Económico General'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'recargar',
                  child: Row(
                    children: [
                      Icon(Icons.refresh, color: Color(0xFF0F2B5B), size: 20),
                      SizedBox(width: 8),
                      Text('Recargar Lista'),
                    ],
                  ),
                ),
                if (_cuotas.isNotEmpty)
                  const PopupMenuItem(
                    value: 'vaciar',
                    child: Row(
                      children: [
                        Icon(Icons.delete_forever, color: Colors.red, size: 20),
                        SizedBox(width: 8),
                        Text('Borrar todas las cuotas', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
              ],
            ),
        ],
      ),
      // Botón flotante estilo píldora azul oscuro "+ Nueva cuota"
      floatingActionButton: puedeEditar
          ? Container(
              margin: const EdgeInsets.only(bottom: 12, right: 4),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F2B5B),
                  foregroundColor: Colors.white,
                  elevation: 6,
                  shadowColor: const Color(0xFF0F2B5B).withOpacity(0.4),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: _abrirCrearCuota,
                icon: const Icon(Icons.add_circle, color: Colors.white, size: 20),
                label: const Text(
                  'Nueva cuota',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            )
          : null,
      body: AppBackground(
        child: RefreshIndicator(
          onRefresh: _cargarCuotas,
          color: const Color(0xFF0F2B5B),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 56), // Espacio para el AppBar transparente

              // Título "Todas las cuotas"
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 10, 20, 14),
                child: Text(
                  'Todas las cuotas',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F2B5B),
                    letterSpacing: -0.3,
                  ),
                ),
              ),

              // Buscador ("Buscar cuota...")
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x060F2B5B),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: _filtrar,
                    style: const TextStyle(fontSize: 14, color: Color(0xFF0F2B5B)),
                    decoration: InputDecoration(
                      hintText: 'Buscar cuota...',
                      hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Color(0xFF0F2B5B),
                        size: 22,
                      ),
                      suffixIcon: _busqueda.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18, color: Color(0xFF94A3B8)),
                              onPressed: () {
                                _searchCtrl.clear();
                                _filtrar('');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // Filtro desplegable ("Todas", "En cobro", "Pendientes", "Completadas")
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x040F2B5B),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _filtroEstado,
                      isDense: true,
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Color(0xFF0F2B5B),
                        size: 22,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      items: const [
                        DropdownMenuItem(
                          value: 'todas',
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.tune_rounded, size: 17, color: Color(0xFF0F2B5B)),
                              SizedBox(width: 8),
                              Text('Todas', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5, color: Color(0xFF0F2B5B))),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'en_cobro',
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.monetization_on_outlined, size: 17, color: Color(0xFF2E7D32)),
                              SizedBox(width: 8),
                              Text('En cobro', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5, color: Color(0xFF2E7D32))),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'pendiente',
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.pending_outlined, size: 17, color: Color(0xFFD97706)),
                              SizedBox(width: 8),
                              Text('Pendientes', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5, color: Color(0xFFD97706))),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'completada',
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle_outline, size: 17, color: Color(0xFF059669)),
                              SizedBox(width: 8),
                              Text('Completadas', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5, color: Color(0xFF059669))),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _filtroEstado = val);
                          _filtrar(_busqueda);
                        }
                      },
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // LISTA DE TARJETAS DE CUOTAS
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Color(0xFF0F2B5B)),
                      )
                    : _cuotasFiltradas.isEmpty
                        ? _buildEstadoVacio(puedeEditar)
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
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
                                      builder: (_) => CuotaDetalleScreen(cuota: cuota),
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
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFDBEAFE), width: 2),
              ),
              child: Icon(
                hayFiltro ? Icons.filter_alt_off_rounded : Icons.receipt_long_rounded,
                size: 54,
                color: const Color(0xFF2563EB),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              hayFiltro ? 'Sin resultados con esos filtros' : 'Aún no hay cuotas creadas',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F2B5B),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              hayFiltro
                  ? 'Prueba cambiando el término de búsqueda o el estado del filtro.'
                  : 'Crea una cuota para asignarla a todos los conductores activos de la empresa.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
              ),
            ),
            if (!hayFiltro && puedeEditar) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F2B5B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
}
