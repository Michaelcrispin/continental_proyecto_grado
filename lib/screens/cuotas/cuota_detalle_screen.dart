import 'package:flutter/material.dart';
import '../../core/permisos.dart';
import '../../services/economia_repo.dart';
import '../../services/recibo_pdf_service.dart';
import '../../services/sesion_service.dart';
import '../../widgets/app_background.dart';
import '../../widgets/avatar_conductor.dart';
import 'widgets/detalle_conductor_cuotas_sheet.dart';
import 'widgets/dialogo_nueva_cuota.dart';

/// Pantalla de Detalle de una Cuota específica.
/// Muestra los indicadores clave (recaudado vs falta), resumen de la cuota,
/// opciones de informe PDF, edición y la lista de todos los choferes con su estado de pago.
class CuotaDetalleScreen extends StatefulWidget {
  final Map<String, dynamic> cuota;

  const CuotaDetalleScreen({super.key, required this.cuota});

  @override
  State<CuotaDetalleScreen> createState() => _CuotaDetalleScreenState();
}

class _CuotaDetalleScreenState extends State<CuotaDetalleScreen> {
  late Map<String, dynamic> _cuotaActual;
  List<Map<String, dynamic>> _conductores = [];
  List<Map<String, dynamic>> _conductoresFiltrados = [];
  bool _isLoading = true;

  String _busqueda = '';
  String _filtroEstado = 'todos'; // 'todos' | 'pagados' | 'deben'
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cuotaActual = Map<String, dynamic>.from(widget.cuota);
    _cargarConductores();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarConductores() async {
    setState(() => _isLoading = true);
    try {
      final idTipo = _cuotaActual['id_tipo_cuota'].toString();
      final lista = await EconomiaRepo.instance.estadoConductoresPorCuota(idTipo);

      // Actualizar también los datos actuales de la cuota desde la BD
      final tipos = await EconomiaRepo.instance.listarCuotasConResumen();
      final actualizada = tipos.firstWhere(
        (t) => t['id_tipo_cuota'].toString() == idTipo,
        orElse: () => _cuotaActual,
      );

      if (mounted) {
        setState(() {
          _cuotaActual = Map<String, dynamic>.from(actualizada);
          _conductores = lista;
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
      _conductoresFiltrados = _conductores.where((c) {
        final falta = (c['monto_falta'] as num?)?.toDouble() ?? 0.0;
        final alDia = falta <= 0.001;

        if (_filtroEstado == 'pagados' && !alDia) return false;
        if (_filtroEstado == 'deben' && alDia) return false;

        if (q.isNotEmpty) {
          final nombre = (c['conductor_nombre'] ?? '').toString().toLowerCase();
          final ci = (c['conductor_ci'] ?? '').toString().toLowerCase();
          if (!nombre.contains(q) && !ci.contains(q)) return false;
        }

        return true;
      }).toList();
    });
  }

  void _cambiarFiltro(String nuevoFiltro) {
    setState(() => _filtroEstado = nuevoFiltro);
    _filtrar(_busqueda);
  }

  Future<void> _editarCuota() async {
    final cambiado = await DialogoNuevaCuota.mostrar(
      context,
      cuotaAEditar: _cuotaActual,
    );
    if (cambiado == true) {
      _cargarConductores();
    }
  }

  Future<void> _eliminarCuota() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Eliminar Cuota', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          ],
        ),
        content: Text(
          '¿Estás seguro de eliminar la cuota "${_cuotaActual['nombre']}"? Se borrarán los registros asociados.',
          style: const TextStyle(fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await EconomiaRepo.instance.eliminarTipoCuota(_cuotaActual['id_tipo_cuota'].toString());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cuota eliminada correctamente.')),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al eliminar cuota: $e')),
          );
        }
      }
    }
  }

  void _generarInformePdf() {
    if (_conductores.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay datos suficientes para generar el informe.')),
      );
      return;
    }

    final nombreCuota = _cuotaActual['nombre']?.toString() ?? 'Cuota General';
    final montoSugerido = (_cuotaActual['monto_sugerido'] as num?)?.toDouble() ?? 0.0;

    int cantPagados = 0;
    int cantDeben = 0;
    double totalRecaudado = 0;
    double totalFalta = 0;
    for (final c in _conductores) {
      final pagado = (c['monto_pagado'] as num?)?.toDouble() ?? 0.0;
      final falta = (c['monto_falta'] as num?)?.toDouble() ?? 0.0;
      totalRecaudado += pagado;
      totalFalta += falta;
      if (falta <= 0.001) {
        cantPagados++;
      } else {
        cantDeben++;
      }
    }

    ReciboPdfService.mostrarVistaPreviaInformeCuotas(
      context,
      tituloCuota: nombreCuota,
      motivoCuota: _cuotaActual['descripcion']?.toString(),
      montoSugerido: montoSugerido,
      conductores: _conductores,
      totalRecaudado: totalRecaudado,
      totalFalta: totalFalta,
      totalConductores: _conductores.length,
      cantPagados: cantPagados,
      cantDeben: cantDeben,
    );
  }

  Future<void> _abrirDetalleConductor(Map<String, dynamic> c) async {
    await DetalleConductorCuotasSheet.mostrar(
      context,
      conductor: c,
      cuota: _cuotaActual,
      onActualizado: _cargarConductores,
    );
  }

  String _formatearFechaCorta(dynamic fecha) {
    if (fecha == null || fecha.toString().trim().isEmpty) return '';
    try {
      final f = DateTime.parse(fecha.toString().trim());
      const meses = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
      return '${f.day.toString().padLeft(2, '0')} ${meses[f.month - 1]} ${f.year}';
    } catch (_) {
      return fecha.toString();
    }
  }


  @override
  Widget build(BuildContext context) {
    final puedeEditar = Permisos.puedeEditar(
      SesionService.instance.rol,
      Permisos.moduloControlEconomico,
    );

    final nombre = _cuotaActual['nombre']?.toString() ?? 'Detalle de Cuota';
    final descripcion = _cuotaActual['descripcion']?.toString();
    final montoSugerido = (_cuotaActual['monto_sugerido'] as num?)?.toDouble() ?? 0.0;
    final categoria = _cuotaActual['categoria']?.toString().toLowerCase();

    int cantPagados = 0;
    int cantDeben = 0;
    double totalRecaudado = 0;
    double totalFalta = 0;
    for (final c in _conductores) {
      final pagado = (c['monto_pagado'] as num?)?.toDouble() ?? 0.0;
      final falta = (c['monto_falta'] as num?)?.toDouble() ?? 0.0;
      totalRecaudado += pagado;
      totalFalta += falta;
      if (falta <= 0.001) {
        cantPagados++;
      } else {
        cantDeben++;
      }
    }
    final totalMeta = totalRecaudado + totalFalta;
    final porcentaje = totalMeta > 0 ? (totalRecaudado / totalMeta).clamp(0.0, 1.0) : 0.0;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E3A8A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          nombre,
          style: const TextStyle(
            color: Color(0xFF0F2B5B),
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (_conductores.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _generarInformePdf,
                icon: const Icon(Icons.picture_as_pdf, size: 14, color: Colors.white),
                label: const Text('Informe', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ),
          if (puedeEditar)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Color(0xFF1E3A8A)),
              onSelected: (val) {
                if (val == 'editar') _editarCuota();
                if (val == 'eliminar') _eliminarCuota();
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: 'editar',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, color: Color(0xFF1E3A8A), size: 20),
                      SizedBox(width: 8),
                      Text('Editar Cuota'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'eliminar',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Text('Eliminar Cuota', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: AppBackground(
        child: RefreshIndicator(
          onRefresh: _cargarConductores,
          color: const Color(0xFF1E3A8A),
          child: Column(
            children: [
              const SizedBox(height: 56), // Espacio para el AppBar transparente

              // CABECERA CON RESUMEN FINANCIERO DE LA CUOTA
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x080F2B5B),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  nombre,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 17,
                                    color: Color(0xFF0F2B5B),
                                  ),
                                ),
                                if (categoria == 'multa' || nombre.toLowerCase().contains('multa') || (descripcion ?? '').contains('Multas por falta')) ...[
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEF2F2),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: const Color(0xFFFECACA)),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.gavel_rounded, size: 12, color: Color(0xFFDC2626)),
                                        SizedBox(width: 4),
                                        Text(
                                          'Multa por Asamblea',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFFDC2626),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                if (descripcion != null && descripcion.trim().isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  if (descripcion.contains('Modalidad:')) ...[
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 4,
                                      children: [
                                        if (descripcion.contains('Modalidad: Obligatoria'))
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFEFF6FF),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: const Color(0xFFBFDBFE)),
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.verified_user_rounded, size: 12, color: Color(0xFF2563EB)),
                                                SizedBox(width: 4),
                                                Text(
                                                  'Cuota Obligatoria',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF2563EB),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                        else if (descripcion.contains('Modalidad: Voluntaria'))
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFECFDF5),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: const Color(0xFFA7F3D0)),
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.volunteer_activism_rounded, size: 12, color: Color(0xFF059669)),
                                                SizedBox(width: 4),
                                                Text(
                                                  'Aporte Voluntario',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF059669),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                  ],
                                  Text(
                                    descripcion.trim(),
                                    style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Bs. ${montoSugerido.toStringAsFixed(0)} / chofer',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12.5,
                                color: Color(0xFF2563EB),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Barra de progreso
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: porcentaje,
                          minHeight: 7,
                          backgroundColor: const Color(0xFFF1F5F9),
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 3 Mini-Estadísticas
                      Row(
                        children: [
                          Expanded(
                            child: _buildMiniStat(
                              'Recaudado',
                              'Bs. ${totalRecaudado.toStringAsFixed(0)}',
                              const Color(0xFF059669),
                            ),
                          ),
                          Container(width: 1, height: 28, color: const Color(0xFFF1F5F9)),
                          Expanded(
                            child: _buildMiniStat(
                              'Por cobrar',
                              'Bs. ${totalFalta.toStringAsFixed(0)}',
                              const Color(0xFFDC2626),
                            ),
                          ),
                          Container(width: 1, height: 28, color: const Color(0xFFF1F5F9)),
                          Expanded(
                            child: _buildMiniStat(
                              'Al día',
                              '$cantPagados de ${_conductores.length}',
                              const Color(0xFF2563EB),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // BUSCADOR Y FILTROS RÁPIDOS
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: _filtrar,
                        decoration: const InputDecoration(
                          hintText: 'Buscar conductor por nombre o CI...',
                          hintStyle: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                          prefixIcon: Icon(Icons.search, size: 20, color: Color(0xFF1E3A8A)),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Chips de filtro (Todos, Pagados, Deben)
                    Row(
                      children: [
                        _buildFilterChip('todos', 'Todos (${_conductores.length})'),
                        const SizedBox(width: 8),
                        _buildFilterChip('pagados', 'Al día ($cantPagados)'),
                        const SizedBox(width: 8),
                        _buildFilterChip('deben', 'Deben ($cantDeben)'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // LISTA DE CONDUCTORES
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF1E3A8A)))
                    : _conductoresFiltrados.isEmpty
                        ? const Center(
                            child: Text(
                              'No se encontraron conductores con el filtro actual.',
                              style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                            itemCount: _conductoresFiltrados.length,
                            itemBuilder: (context, i) {
                              final c = _conductoresFiltrados[i];
                              final nombreChofer = c['conductor_nombre']?.toString() ?? 'Conductor';
                              final ciChofer = c['conductor_ci']?.toString() ?? 'S/CI';
                              final foto = c['conductor_foto']?.toString();
                              final pagado = (c['monto_pagado'] as num?)?.toDouble() ?? 0.0;
                              final falta = (c['monto_falta'] as num?)?.toDouble() ?? 0.0;
                              final alDia = falta <= 0.001;

                              final proxFecha = c['proxima_fecha_pago']?.toString();
                              final cuotasPendientes = (c['cuotas_pendientes'] as num?)?.toInt() ?? 0;

                              return Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () => _abrirDetalleConductor(c),
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: alDia ? const Color(0xFFD1FAE5) : const Color(0xFFF1F5F9),
                                      ),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Color(0x060F2B5B),
                                          blurRadius: 8,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        AvatarConductor(
                                          foto: foto,
                                          nombre: nombreChofer,
                                          radio: 20,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                nombreChofer,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                  color: Color(0xFF0F2B5B),
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                'CI: $ciChofer',
                                                style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                                              ),
                                              const SizedBox(height: 4),
                                              Wrap(
                                                crossAxisAlignment: WrapCrossAlignment.center,
                                                spacing: 4,
                                                children: [
                                                  Text(
                                                    'Pagó: Bs. ${pagado.toStringAsFixed(0)}',
                                                    style: const TextStyle(
                                                      fontSize: 11.5,
                                                      color: Color(0xFF059669),
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                  if (!alDia) ...[
                                                    const Text('•', style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 11)),
                                                    Text(
                                                      'Falta: Bs. ${falta.toStringAsFixed(0)}',
                                                      style: const TextStyle(
                                                        fontSize: 11.5,
                                                        color: Color(0xFFDC2626),
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                              if (!alDia && proxFecha != null && proxFecha.isNotEmpty) ...[
                                                const SizedBox(height: 3),
                                                Text(
                                                  'Próx. pago: ${_formatearFechaCorta(proxFecha)}',
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color: Color(0xFF2563EB),
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),

                                        // Badge de Estado: "Al día" o "Pendiente"
                                        if (alDia)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFD1FAE5),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 14),
                                                SizedBox(width: 4),
                                                Text(
                                                  'Al día',
                                                  style: TextStyle(
                                                    color: Color(0xFF065F46),
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                        else
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFEF3C7),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.schedule_rounded, color: Color(0xFFD97706), size: 14),
                                                const SizedBox(width: 4),
                                                Text(
                                                  cuotasPendientes > 1 ? 'Pendiente ($cuotasPendientes)' : 'Pendiente',
                                                  style: const TextStyle(
                                                    color: Color(0xFF92400E),
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),

                                        const SizedBox(width: 4),
                                        const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 18),
                                      ],
                                    ),
                                  ),
                                ),
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

  Widget _buildMiniStat(String label, String valor, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
        const SizedBox(height: 2),
        Text(
          valor,
          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String filtro, String texto) {
    final activo = _filtroEstado == filtro;
    return GestureDetector(
      onTap: () => _cambiarFiltro(filtro),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: activo ? const Color(0xFF1E3A8A) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: activo ? const Color(0xFF1E3A8A) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          texto,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: activo ? FontWeight.bold : FontWeight.normal,
            color: activo ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }
}
