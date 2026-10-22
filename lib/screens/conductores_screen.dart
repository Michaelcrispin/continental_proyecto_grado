import 'package:flutter/material.dart';
import '../core/permisos.dart';
import '../services/database_helper.dart';
import '../services/sesion_service.dart';
import '../widgets/app_background.dart';
import '../core/documentos_alerta.dart';
import 'conductor_detalle_screen.dart';
import 'conductor_form_screen.dart';
import '../widgets/avatar_conductor.dart';

class ConductoresScreen extends StatefulWidget {
  const ConductoresScreen({super.key});

  @override
  State<ConductoresScreen> createState() => _ConductoresScreenState();
}

class _ConductoresScreenState extends State<ConductoresScreen> {
  List<Map<String, dynamic>> _conductores = [];
  List<Map<String, dynamic>> _conductoresFiltrados = [];
  bool _isLoading = true;
  String _busqueda = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!Permisos.verificarAcceso(
          context, SesionService.instance.rol, Permisos.moduloConductores)) {
        return;
      }
    });
    _cargarConductores();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargarConductores() async {
    setState(() => _isLoading = true);
    try {
      final lista = await DatabaseHelper.instance.conductoresConAuto();
      if (mounted) {
        setState(() {
          _conductores = lista;
          _filtrar(_busqueda);
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _filtrar(String query) {
    _busqueda = query;
    final q = query.toLowerCase().trim();
    setState(() {
      if (q.isEmpty) {
        _conductoresFiltrados = _conductores;
      } else {
        _conductoresFiltrados = _conductores.where((c) {
          final nombre = (c['nombre'] ?? '').toString().toLowerCase();
          final ci = (c['ci'] ?? '').toString().toLowerCase();
          final placa = (c['placa'] ?? '').toString().toLowerCase();
          return nombre.contains(q) || ci.contains(q) || placa.contains(q);
        }).toList();
      }
    });
  }

  // ---------------------------------------------------------------------------
  // NAVEGACIÓN A PANTALLA COMPLETA DE REGISTRO / EDICIÓN
  // ---------------------------------------------------------------------------
  void _abrirFormularioConductor({Map<String, dynamic>? conductorExistente}) async {
    final modificado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ConductorFormScreen(conductor: conductorExistente),
      ),
    );
    if (modificado == true) {
      _cargarConductores();
    }
  }

  void _mostrarFichaDetalleConductor(Map<String, dynamic> c) async {
    final modificado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ConductorDetalleScreen(conductor: c),
      ),
    );
    if (modificado == true) {
      _cargarConductores();
    }
  }

  void _confirmarEliminarConductor(Map<String, dynamic> c) {
    final idUsuario = c['id_usuario']?.toString();
    final nombre = c['nombre'] ?? 'este conductor';

    if (idUsuario == null) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Confirmar baja'),
          ],
        ),
        content: Text('¿Estás seguro de que deseas eliminar a "$nombre" del padrón de conductores?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await DatabaseHelper.instance.eliminarUsuarioCompleto(idUsuario);
                _cargarConductores();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Conductor "$nombre" eliminado.')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // CONSTRUCCIÓN PRINCIPAL (UI TIPO CUADRADOS)
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final cantConductores = _conductoresFiltrados.length;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E3A8A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Conductores ($cantConductores)',
          style: const TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF1E3A8A)),
            tooltip: 'Recargar',
            onPressed: _cargarConductores,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Image.asset(
              'assets/images/logo.png',
              height: 32,
              errorBuilder: (c, e, s) => const Icon(Icons.public, color: Color(0xFF1E3A8A)),
            ),
          ),
        ],
      ),
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Buscador superior
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar por nombre, CI o placa...',
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF10B981)),
                    suffixIcon: _busqueda.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              _searchController.clear();
                              _filtrar('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                  onChanged: _filtrar,
                ),
              ),

              // GRIDVIEW TIPO CUADRADOS (2 COLUMNAS)
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _conductoresFiltrados.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.directions_bus_outlined, size: 64, color: Colors.grey.shade300),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'No hay conductores registrados',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Toca "+ Nuevo Conductor" para registrar choferes y unidades.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _cargarConductores,
                            child: GridView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                              itemCount: _conductoresFiltrados.length,
                              physics: const BouncingScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 0.78,
                              ),
                              itemBuilder: (context, index) {
                                final c = _conductoresFiltrados[index];
                                final nombre = c['nombre'] ?? 'Sin nombre';
                                final ci = c['ci'] ?? 'S/CI';
                                final placa = c['placa']?.toString();
                                final estado = c['estado']?.toString() ?? 'activo';
                                final esActivo = estado.toLowerCase() == 'activo';
                                final estadoLic = DocumentosAlerta.estado(c['licencia_vencimiento']?.toString());
                                final estadoSoat = DocumentosAlerta.estado(c['fecha_vencimiento_soat']?.toString());
                                final tieneAlerta = estadoLic == 'Vencida' ||
                                    estadoLic == 'Por vencer' ||
                                    estadoSoat == 'Vencida';

                                return GestureDetector(
                                  onTap: () => _mostrarFichaDetalleConductor(c),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(22),
                                      border: tieneAlerta
                                          ? Border.all(
                                              color: (estadoLic == 'Vencida' || estadoSoat == 'Vencida')
                                                  ? const Color(0xFFEF4444).withValues(alpha: 0.4)
                                                  : const Color(0xFFF59E0B).withValues(alpha: 0.4),
                                              width: 1.2,
                                            )
                                          : null,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.04),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Fila superior: Avatar circular de trufi + Badges
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            AvatarConductor(
                                              foto: c['foto']?.toString(),
                                              nombre: nombre,
                                              radio: 21,
                                              fontSize: 11,
                                            ),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFECFDF5),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: const Text(
                                                    'CONDUCTOR',
                                                    style: TextStyle(
                                                      color: Color(0xFF059669),
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 8.5,
                                                      letterSpacing: 0.2,
                                                    ),
                                                  ),
                                                ),
                                                if (tieneAlerta) ...[
                                                  const SizedBox(height: 3),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: DocumentosAlerta.colorFondo(estadoLic == 'Vencida' ? 'Vencida' : estadoLic == 'Por vencer' ? 'Por vencer' : 'Vencida'),
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Text(
                                                      estadoLic == 'Vencida'
                                                          ? 'Lic. Vencida'
                                                          : estadoLic == 'Por vencer'
                                                              ? 'Lic. vence pronto'
                                                              : 'SOAT Vencido',
                                                      style: TextStyle(
                                                        color: DocumentosAlerta.color(estadoLic == 'Vencida' ? 'Vencida' : estadoLic == 'Por vencer' ? 'Por vencer' : 'Vencida'),
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 8,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),

                                      // Nombre del Conductor
                                      Text(
                                        nombre,
                                        style: const TextStyle(
                                          color: Color(0xFF1E3A8A),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),

                                      // CI
                                      Row(
                                        children: [
                                          const Icon(Icons.badge_outlined, size: 13, color: Color(0xFF64748B)),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              'CI: $ci',
                                              style: const TextStyle(
                                                color: Color(0xFF64748B),
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),

                                      // Placa / Auto
                                      Row(
                                        children: [
                                          const Icon(Icons.directions_car_outlined, size: 13, color: Color(0xFF2563EB)),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              (placa != null && placa.isNotEmpty) ? placa : 'Sin unidad',
                                              style: const TextStyle(
                                                color: Color(0xFF2563EB),
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),

                                      // Estado
                                      Row(
                                        children: [
                                          Container(
                                            width: 7,
                                            height: 7,
                                            decoration: BoxDecoration(
                                              color: esActivo ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 5),
                                          Text(
                                            esActivo ? 'Estado: Habilitado' : 'Estado: Inhabilitado',
                                            style: TextStyle(
                                              color: esActivo ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),

                                      const Spacer(),

                                      // Botones de acción: Ver información (Ojito), Editar y Eliminar
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          Container(
                                            width: 32,
                                            height: 32,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF1F5F9),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: IconButton(
                                              padding: EdgeInsets.zero,
                                              icon: const Icon(Icons.visibility_outlined, size: 16, color: Color(0xFF475569)),
                                              tooltip: 'Ver información',
                                              onPressed: () => _mostrarFichaDetalleConductor(c),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Container(
                                            width: 32,
                                            height: 32,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFEFF6FF),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: IconButton(
                                              padding: EdgeInsets.zero,
                                              icon: const Icon(Icons.edit, size: 15, color: Color(0xFF3B82F6)),
                                              tooltip: 'Editar',
                                              onPressed: () => _abrirFormularioConductor(conductorExistente: c),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Container(
                                            width: 32,
                                            height: 32,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFEF2F2),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: IconButton(
                                              padding: EdgeInsets.zero,
                                              icon: const Icon(Icons.delete_outline, size: 15, color: Color(0xFFEF4444)),
                                              tooltip: 'Eliminar',
                                              onPressed: () => _confirmarEliminarConductor(c),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  ),
                                );
                              },
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text(
          'Nuevo Conductor',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        onPressed: () => _abrirFormularioConductor(),
      ),
    );
  }
}
