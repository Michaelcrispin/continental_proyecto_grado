import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/permisos.dart';
import '../services/economia_repo.dart';
import '../services/sesion_service.dart';
import '../widgets/avatar_conductor.dart';
import 'crear_reunion_screen.dart';
import 'cuotas/cuota_detalle_screen.dart';

const _kVerdeOscuro = Color(0xFF02634C);

/// Vista E10: Reuniones y Asambleas (Diseño corporativo idéntico a Cuotas)
///
/// Permite al Secretario de Hacienda / Directorio:
/// 1. Crear reuniones/asambleas fijando el monto de la multa por falta.
/// 2. Llamar lista de asistencia táctil y ágilmente (Presente / Falta / Licencia).
/// 3. Cerrar la reunión generando automáticamente las cuotas de multa en el módulo de Cuotas.
/// 4. Consultar y cobrar las multas generadas con recibos oficiales.
class ReunionesScreen extends StatefulWidget {
  const ReunionesScreen({super.key});

  @override
  State<ReunionesScreen> createState() => _ReunionesScreenState();
}

class _ReunionesScreenState extends State<ReunionesScreen> {
  List<Map<String, dynamic>> _reuniones = [];
  List<Map<String, dynamic>> _reunionesFiltradas = [];
  bool _isLoading = true;

  String _busqueda = '';
  String _filtroEstado = 'todas'; // 'todas' | 'en_curso' | 'completada'
  bool _mostrarBuscador = false;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargarReuniones();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarReuniones() async {
    setState(() => _isLoading = true);
    try {
      final list = await EconomiaRepo.instance.listarReuniones();
      if (mounted) {
        setState(() {
          _reuniones = list;
          _isLoading = false;
        });
        _filtrar(_busqueda);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filtrar(String query) {
    _busqueda = query;
    final q = query.toLowerCase().trim();
    setState(() {
      _reunionesFiltradas = _reuniones.where((r) {
        final estado = r['estado']?.toString().toLowerCase() ?? 'pendiente';
        final esCerrada = estado == 'cerrada';

        if (_filtroEstado == 'en_curso' && esCerrada) return false;
        if (_filtroEstado == 'completada' && !esCerrada) return false;

        if (q.isNotEmpty) {
          final tema = (r['tema'] ?? '').toString().toLowerCase();
          final fecha = (r['fecha'] ?? '').toString().toLowerCase();
          if (!tema.contains(q) && !fecha.contains(q)) return false;
        }

        return true;
      }).toList();
    });
  }

  Future<void> _abrirCrearReunion() async {
    final String? idCreado = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const CrearReunionScreen()),
    );

    if (idCreado != null) {
      await _cargarReuniones();
      if (!mounted) return;
      final reunionCreada = _reuniones.firstWhere(
        (r) => r['id_reunion'].toString() == idCreado,
        orElse: () => <String, dynamic>{},
      );
      if (reunionCreada.isNotEmpty) {
        _abrirPasarLista(reunionCreada);
      }
    }
  }

  void _abrirPasarLista(Map<String, dynamic> reunion) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PasarListaScreen(reunion: reunion),
      ),
    ).then((_) => _cargarReuniones());
  }

  Future<void> _cerrarReunionConfirmar(Map<String, dynamic> r) async {
    final faltas = (r['faltas'] as num?)?.toInt() ?? 0;
    final multa = (r['monto_multa'] as num?)?.toDouble() ?? 50.0;
    final totalMultas = faltas * multa;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.gavel_rounded, color: Color(0xFFDC2626)),
            SizedBox(width: 8),
            Text('Finalizar Reunión',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Deseas cerrar definitivamente la reunión "${r['tema']}"?',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (faltas > 0) ...[
                    Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            size: 18, color: Color(0xFFDC2626)),
                        const SizedBox(width: 6),
                        Text(
                          '$faltas choferes con FALTA detectados',
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF991B1B)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Se generará una cuota de Bs. ${multa.toStringAsFixed(2)} para cada uno.\nTotal a cobrar en multas: Bs. ${totalMultas.toStringAsFixed(2)}.',
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF7F1D1D)),
                    ),
                  ] else ...[
                    const Row(
                      children: [
                        Icon(Icons.check_circle_rounded,
                            size: 18, color: Color(0xFF059669)),
                        SizedBox(width: 6),
                        Text(
                          '¡Asistencia perfecta! 0 faltas.',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF065F46)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Todos asistieron o tienen permiso. No se generarán multas.',
                      style: TextStyle(
                          fontSize: 11.5, color: Color(0xFF065F46)),
                    ),
                  ],
                  const SizedBox(height: 8),
                  const Text(
                    'Una vez cerrada, la lista no podrá ser modificada.',
                    style: TextStyle(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar',
                style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(faltas > 0 ? 'Cerrar y Multar' : 'Cerrar Reunión'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    final idUsuario = SesionService.instance.idUsuario ?? 'superadmin';
    try {
      final res = await EconomiaRepo.instance.cerrarReunion(
        r['id_reunion'].toString(),
        idUsuario,
      );
      _cargarReuniones();
      if (mounted) {
        final cant = res['multas_generadas'] as int? ?? 0;
        final total = (res['total_multas_bs'] as num?)?.toDouble() ?? 0.0;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              cant > 0
                  ? 'Reunión cerrada. Se crearon $cant multas por Bs. ${total.toStringAsFixed(2)}.'
                  : 'Reunión cerrada sin multas (asistencia perfecta).',
            ),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _confirmarEliminarReunion(Map<String, dynamic> r) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline, color: Colors.red),
            SizedBox(width: 8),
            Text('Eliminar Reunión',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          ],
        ),
        content: Text(
          '¿Estás seguro de eliminar la reunión "${r['tema']}"? Si ya generó multas, también se borrarán del sistema.',
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
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        await EconomiaRepo.instance.eliminarReunion(r['id_reunion'].toString());
        _cargarReuniones();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Reunión eliminada correctamente.')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al eliminar reunión: $e')),
          );
        }
      }
    }
  }

  /// Encabezado verde curvo corporativo con botón atrás, buscador y squircle de usuario
  Widget _buildHeader(BuildContext context, bool puedeGestionar) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
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
                      icon: Icon(
                        _mostrarBuscador ? Icons.close : Icons.search,
                        color: Colors.white,
                        size: 22,
                      ),
                      tooltip: _mostrarBuscador
                          ? 'Cerrar búsqueda'
                          : 'Buscar reunión',
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
                    // Botón blanco squircle con menú / usuario idéntico a Cuotas
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
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
                          size: 26,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        onSelected: (val) {
                          if (val == 'crear') _abrirCrearReunion();
                          if (val == 'recargar') _cargarReuniones();
                        },
                        itemBuilder: (ctx) => [
                          if (puedeGestionar)
                            const PopupMenuItem(
                              value: 'crear',
                              child: Row(
                                children: [
                                  Icon(Icons.add_circle_outline,
                                      color: _kVerdeOscuro, size: 20),
                                  SizedBox(width: 8),
                                  Text('Nueva Reunión'),
                                ],
                              ),
                            ),
                          const PopupMenuItem(
                            value: 'recargar',
                            child: Row(
                              children: [
                                Icon(Icons.refresh,
                                    color: _kVerdeOscuro, size: 20),
                                SizedBox(width: 8),
                                Text('Recargar Lista'),
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
            // Título grande "Reuniones" idéntico a Cuotas
            const Text(
              'Reuniones',
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
                      fontSize: 14, color: _kVerdeOscuro),
                  decoration: InputDecoration(
                    hintText: 'Buscar reunión o tema...',
                    hintStyle: const TextStyle(
                        fontSize: 13.5, color: Color(0xFF94A3B8)),
                    prefixIcon: const Icon(Icons.search,
                        color: _kVerdeOscuro, size: 20),
                    suffixIcon: _busqueda.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear,
                                size: 18, color: Color(0xFF94A3B8)),
                            onPressed: () {
                              _searchCtrl.clear();
                              _filtrar('');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Píldora de filtrado estilo Cuotas ([Todas] [En curso] [Completadas])
  Widget _buildFilterPill(String filtro, String label) {
    final isSelected = _filtroEstado == filtro;
    return GestureDetector(
      onTap: () {
        setState(() {
          _filtroEstado = filtro;
        });
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
                    color: _kVerdeOscuro.withOpacity(0.25),
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

  /// Tarjeta moderna de reunión / asamblea idéntica al diseño de CuotaCard
  Widget _buildReunionCard(Map<String, dynamic> r, bool puedeGestionar, int index) {
    final tema = r['tema']?.toString() ?? 'Reunión';
    final fecha = r['fecha']?.toString() ?? '';
    final multa = (r['monto_multa'] as num?)?.toDouble() ?? 50.0;
    final estado = r['estado']?.toString().toLowerCase() ?? 'pendiente';
    final esCerrada = estado == 'cerrada';
    final idTipoCuota = r['id_tipo_cuota']?.toString();

    final presentes = (r['presentes'] as num?)?.toInt() ?? 0;
    final faltas = (r['faltas'] as num?)?.toInt() ?? 0;
    final licencias = (r['licencias'] as num?)?.toInt() ?? 0;
    final totalConductores = (r['total_asistentes'] as num?)?.toInt() ??
        (presentes + faltas + licencias);

    final total = totalConductores > 0 ? totalConductores : 1;
    final progreso = (presentes / total).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _abrirPasarLista(r),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Fila superior: Ícono en círculo + Título / Subtítulo / Fecha + Monto por chofer
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Círculo con ícono en tono suave verde idéntico a CuotaCard
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE6F4F0),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        esCerrada
                            ? Icons.gavel_rounded
                            : Icons.groups_rounded,
                        color: _kVerdeOscuro,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Título, subtítulo y fecha
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tema,
                            style: const TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.bold,
                              color: _kVerdeOscuro,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            esCerrada
                                ? 'Asamblea finalizada • $faltas faltas registradas'
                                : 'Asamblea ordinaria • Control de asistencia activo',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF64748B),
                              height: 1.25,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (fecha.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.calendar_today_rounded,
                                  size: 11.5,
                                  color: _kVerdeOscuro,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  fecha,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: _kVerdeOscuro,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Monto y "por chofer" + Menú de opciones
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Bs. ${multa.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                color: _kVerdeOscuro,
                              ),
                            ),
                            const SizedBox(height: 1),
                            const Text(
                              'por chofer',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                        if (puedeGestionar) ...[
                          const SizedBox(width: 4),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert_rounded,
                                size: 18, color: Color(0xFF94A3B8)),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onSelected: (val) {
                              if (val == 'asistencia') _abrirPasarLista(r);
                              if (val == 'cerrar') _cerrarReunionConfirmar(r);
                              if (val == 'cobrar' && idTipoCuota != null) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => CuotaDetalleScreen(
                                      cuota: {
                                        'id_tipo_cuota': idTipoCuota,
                                        'nombre': 'Multa: $tema',
                                        'descripcion':
                                            'Multas por falta a la reunión "$tema" ($fecha)',
                                        'monto_sugerido': multa,
                                        'categoria': 'multa',
                                      },
                                    ),
                                  ),
                                );
                              }
                              if (val == 'eliminar') _confirmarEliminarReunion(r);
                            },
                            itemBuilder: (_) => [
                              PopupMenuItem(
                                value: 'asistencia',
                                child: Row(
                                  children: [
                                    Icon(
                                        esCerrada
                                            ? Icons.visibility_outlined
                                            : Icons.how_to_reg_rounded,
                                        color: _kVerdeOscuro,
                                        size: 18),
                                    const SizedBox(width: 8),
                                    Text(esCerrada
                                        ? 'Ver Asistencia'
                                        : 'Llamar Lista'),
                                  ],
                                ),
                              ),
                              if (!esCerrada)
                                const PopupMenuItem(
                                  value: 'cerrar',
                                  child: Row(
                                    children: [
                                      Icon(Icons.lock_clock_rounded,
                                          color: Color(0xFFDC2626), size: 18),
                                      SizedBox(width: 8),
                                      Text('Cerrar y Multar',
                                          style: TextStyle(
                                              color: Color(0xFFDC2626))),
                                    ],
                                  ),
                                ),
                              if (esCerrada && idTipoCuota != null && faltas > 0)
                                const PopupMenuItem(
                                  value: 'cobrar',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit_note_rounded,
                                          color: _kVerdeOscuro, size: 18),
                                      SizedBox(width: 8),
                                      Text('Cobrar Multas'),
                                    ],
                                  ),
                                ),
                              const PopupMenuDivider(),
                              const PopupMenuItem(
                                value: 'eliminar',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete_outline_rounded,
                                        color: Colors.red, size: 18),
                                    SizedBox(width: 8),
                                    Text('Eliminar Reunión',
                                        style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // 2. Barra de progreso en verde corporativo
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progreso,
                    minHeight: 4.5,
                    backgroundColor: const Color(0xFFF1F5F9),
                    color: _kVerdeOscuro,
                  ),
                ),

                const SizedBox(height: 8),

                // 3. Fila inferior: "X de Y asistieron" + Estado ("Completa" / "En curso")
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$presentes de $totalConductores choferes asistieron',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      esCerrada ? 'Completa' : 'En curso',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: esCerrada
                            ? _kVerdeOscuro
                            : const Color(0xFFD97706),
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

  Widget _buildEstadoVacio(bool puedeGestionar) {
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
                    : Icons.groups_rounded,
                size: 48,
                color: _kVerdeOscuro,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Aún no hay reuniones creadas',
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
                  : 'Crea una reunión o asamblea para controlar asistencia y multas de choferes.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
              ),
            ),
            if (!hayFiltro && puedeGestionar) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kVerdeOscuro,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                ),
                onPressed: _abrirCrearReunion,
                icon: const Icon(Icons.add, size: 20),
                label: const Text(
                  'Crear Primera Reunión',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final puedeGestionar = Permisos.puedeEditar(
      SesionService.instance.rol,
      Permisos.moduloControlEconomico,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Encabezado verde curvo corporativo con buscador integrado
          _buildHeader(context, puedeGestionar),

          // 2. Píldoras de filtrado: [Todas] [En curso] [Completadas]
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              children: [
                _buildFilterPill('todas', 'Todas'),
                const SizedBox(width: 8),
                _buildFilterPill('en_curso', 'En curso'),
                const SizedBox(width: 8),
                _buildFilterPill('completada', 'Completadas'),
              ],
            ),
          ),

          // 3. Lista de tarjetas de reuniones
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: _kVerdeOscuro),
                  )
                : _reunionesFiltradas.isEmpty
                    ? _buildEstadoVacio(puedeGestionar)
                    : RefreshIndicator(
                        onRefresh: _cargarReuniones,
                        color: _kVerdeOscuro,
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 85),
                          itemCount: _reunionesFiltradas.length,
                          itemBuilder: (context, index) {
                            return _buildReunionCard(
                              _reunionesFiltradas[index],
                              puedeGestionar,
                              index,
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: puedeGestionar
          ? FloatingActionButton.extended(
              onPressed: _abrirCrearReunion,
              backgroundColor: _kVerdeOscuro,
              foregroundColor: Colors.white,
              elevation: 4,
              icon: const Icon(Icons.add_rounded, size: 22, color: Colors.white),
              label: const Text(
                'Nueva reunión',
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
    );
  }
}

class ContainerIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bg;

  const ContainerIcon({super.key, required this.icon, required this.color, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Icon(icon, color: color, size: 20),
    );
  }
}

/// Pantalla para pasar lista en una reunión específica con el diseño de ConductorCard
class PasarListaScreen extends StatefulWidget {
  final Map<String, dynamic> reunion;

  const PasarListaScreen({super.key, required this.reunion});

  @override
  State<PasarListaScreen> createState() => _PasarListaScreenState();
}

class _PasarListaScreenState extends State<PasarListaScreen> {
  List<Map<String, dynamic>> _asistentes = [];
  List<Map<String, dynamic>> _asistentesFiltrados = [];
  bool _isLoading = true;
  String _busqueda = '';
  String _filtroActivo = 'todos'; // 'todos', 'presentes', 'faltas', 'licencias'
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargarAsistencia();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarAsistencia() async {
    setState(() => _isLoading = true);
    try {
      final idReunion = widget.reunion['id_reunion'].toString();
      final list = await EconomiaRepo.instance.asistenciasDeReunion(idReunion);
      if (mounted) {
        setState(() {
          _asistentes = list;
          _isLoading = false;
        });
        _aplicarFiltros(_busqueda);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _aplicarFiltros([String? query]) {
    if (query != null) {
      _busqueda = query.toLowerCase().trim();
    }
    final q = _busqueda;
    setState(() {
      _asistentesFiltrados = _asistentes.where((a) {
        // 1. Filtrado por texto (nombre, CI o auto)
        final nombre = (a['conductor_nombre'] ?? '').toString().toLowerCase();
        final ci = (a['conductor_ci'] ?? '').toString().toLowerCase();
        final auto = (a['conductor_numero_interno'] ?? a['numero_interno'] ?? '')
            .toString()
            .toLowerCase();
        final coincide = q.isEmpty ||
            nombre.contains(q) ||
            ci.contains(q) ||
            auto.contains(q);
        if (!coincide) return false;

        // 2. Sub-filtro por estado
        final estado = (a['estado'] ?? 'falta').toString().toLowerCase();
        switch (_filtroActivo) {
          case 'presentes':
            return estado == 'presente';
          case 'faltas':
            return estado == 'falta';
          case 'licencias':
            return estado == 'licencia';
          default:
            return true;
        }
      }).toList();
    });
  }

  Future<void> _marcar(String idAsistencia, String nuevoEstado) async {
    final esCerrada =
        widget.reunion['estado']?.toString().toLowerCase() == 'cerrada';
    if (esCerrada) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Esta reunión ya fue cerrada.')),
      );
      return;
    }

    try {
      await EconomiaRepo.instance
          .actualizarAsistenciaReunion(idAsistencia, nuevoEstado);
      // Actualización optimista local para fluidez inmediata
      setState(() {
        final idx = _asistentes.indexWhere(
            (a) => a['id_asistencia_reunion'].toString() == idAsistencia);
        if (idx != -1) {
          final map = Map<String, dynamic>.from(_asistentes[idx]);
          map['estado'] = nuevoEstado;
          _asistentes[idx] = map;
        }
      });
      _aplicarFiltros();
    } catch (_) {
      _cargarAsistencia();
    }
  }

  Future<void> _marcarTodos(String nuevoEstado) async {
    final esCerrada =
        widget.reunion['estado']?.toString().toLowerCase() == 'cerrada';
    if (esCerrada) return;

    try {
      final idReunion = widget.reunion['id_reunion'].toString();
      await EconomiaRepo.instance
          .marcarTodosAsistenciaReunion(idReunion, nuevoEstado);
      await _cargarAsistencia();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              nuevoEstado == 'presente'
                  ? 'Todos los conductores fueron marcados como PRESENTES.'
                  : 'Todos los conductores fueron marcados con FALTA.',
            ),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (_) {}
  }

  Future<void> _cerrarDesdeAqui() async {
    final faltas = _asistentes
        .where((a) => a['estado']?.toString().toLowerCase() == 'falta')
        .length;
    final multa = (widget.reunion['monto_multa'] as num?)?.toDouble() ?? 50.0;
    final totalMultas = faltas * multa;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.gavel_rounded, color: Color(0xFFDC2626)),
            SizedBox(width: 8),
            Text('Finalizar Reunión',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Cerrar y generar multas para "${widget.reunion['tema']}"?',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    faltas > 0
                        ? 'Se detectaron $faltas FALTAS.\nSe creará una cuota de Bs. ${multa.toStringAsFixed(2)} por chofer (Total: Bs. ${totalMultas.toStringAsFixed(2)}).'
                        : '¡Excelente! 0 Faltas. Todos asistieron o tienen permiso justificado.',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: faltas > 0
                          ? const Color(0xFF991B1B)
                          : const Color(0xFF065F46),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar',
                style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cerrar y Generar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    final idUsuario = SesionService.instance.idUsuario ?? 'superadmin';
    try {
      final res = await EconomiaRepo.instance.cerrarReunion(
        widget.reunion['id_reunion'].toString(),
        idUsuario,
      );
      if (mounted) {
        final cant = res['multas_generadas'] as int? ?? 0;
        final total = (res['total_multas_bs'] as num?)?.toDouble() ?? 0.0;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Reunión cerrada. Se crearon $cant multas por Bs. ${total.toStringAsFixed(2)}.'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = widget.reunion['tema']?.toString() ?? 'Reunión';
    final fecha = widget.reunion['fecha']?.toString() ?? '';
    final multa = (widget.reunion['monto_multa'] as num?)?.toDouble() ?? 50.0;
    final esCerrada =
        widget.reunion['estado']?.toString().toLowerCase() == 'cerrada';

    final total = _asistentes.length;
    final presentes = _asistentes
        .where((a) => a['estado']?.toString().toLowerCase() == 'presente')
        .length;
    final faltas = _asistentes
        .where((a) => a['estado']?.toString().toLowerCase() == 'falta')
        .length;
    final licencias = _asistentes
        .where((a) => a['estado']?.toString().toLowerCase() == 'licencia')
        .length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // 1. ENCABEZADO VERDE CURVO CON BUSCADOR Y ACCIONES INTEGRADAS
          _buildHeader(
            context: context,
            tema: tema,
            fecha: fecha,
            multa: multa,
            esCerrada: esCerrada,
          ),

          const SizedBox(height: 12),

          // 2. SUB-FILTROS HORIZONTALES (Todos, Presentes, Faltas, Licencias)
          _buildFiltrosBar(
            total: total,
            presentes: presentes,
            faltas: faltas,
            licencias: licencias,
          ),

          const SizedBox(height: 10),

          // 3. LISTADO DE CONDUCTORES EN EL FORMATO DE CONDUCTORCARD
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: _kVerdeOscuro),
                  )
                : _asistentesFiltrados.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        color: _kVerdeOscuro,
                        onRefresh: _cargarAsistencia,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
                          physics: const BouncingScrollPhysics(),
                          itemCount: _asistentesFiltrados.length,
                          itemBuilder: (context, index) {
                            final a = _asistentesFiltrados[index];
                            final idAsistencia =
                                a['id_asistencia_reunion'].toString();
                            final nombre =
                                a['conductor_nombre']?.toString() ?? 'Chofer';
                            final ci = a['conductor_ci']?.toString() ?? '';
                            final foto = a['conductor_foto']?.toString();
                            final auto =
                                a['conductor_numero_interno']?.toString() ??
                                    a['numero_interno']?.toString();
                            final estado =
                                a['estado']?.toString().toLowerCase() ??
                                    'falta';

                            return ConductorAsistenciaCard(
                              numeroLista: index + 1,
                              nombre: nombre,
                              ci: ci,
                              auto: auto,
                              foto: foto,
                              estado: estado,
                              multa: multa,
                              esCerrada: esCerrada,
                              onMarcar: (nuevoEstado) =>
                                  _marcar(idAsistencia, nuevoEstado),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: !esCerrada
          ? FloatingActionButton.extended(
              backgroundColor: _kVerdeOscuro,
              foregroundColor: Colors.white,
              elevation: 4,
              icon: const Icon(Icons.gavel_rounded),
              label: Text(
                faltas > 0
                    ? 'Finalizar ($faltas Faltas)'
                    : 'Finalizar Reunión',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: _cerrarDesdeAqui,
            )
          : null,
    );
  }

  /// Encabezado verde curvo idéntico a ConductoresScreen
  Widget _buildHeader({
    required BuildContext context,
    required String tema,
    required String fecha,
    required double multa,
    required bool esCerrada,
  }) {
    final padding = MediaQuery.of(context).padding;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: _kVerdeOscuro,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(32),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, padding.top + 8, 16, 20),
        child: Column(
          children: [
            Row(
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
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              tema,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 21,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (esCerrada)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.white70),
                              ),
                              child: const Text(
                                'CERRADA',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Fecha: $fecha • Multa: Bs. ${multa.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Logo Continental en círculo blanco como en ConductoresScreen
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(4),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.local_taxi_rounded,
                        color: _kVerdeOscuro,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Buscador blanco y botón de opciones DENTRO del encabezado verde
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF1E293B),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Buscar por nombre, CI o placa...',
                        hintStyle: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF94A3B8),
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: Color(0xFF94A3B8),
                          size: 20,
                        ),
                        suffixIcon: _busqueda.isNotEmpty
                            ? IconButton(
                                icon: const Icon(
                                  Icons.clear,
                                  size: 18,
                                  color: Colors.grey,
                                ),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  _aplicarFiltros('');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onChanged: _aplicarFiltros,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                _buildBotonAccionesRapidas(esCerrada),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Botón de opciones rápidas (Marcar todos Presentes / Faltas)
  Widget _buildBotonAccionesRapidas(bool esCerrada) {
    return PopupMenuButton<String>(
      enabled: !esCerrada,
      tooltip: 'Opciones de lista',
      offset: const Offset(0, 52),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      icon: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: const Icon(
          Icons.tune_rounded,
          size: 22,
          color: _kVerdeOscuro,
        ),
      ),
      onSelected: (val) {
        if (val == 'todos_presentes') _marcarTodos('presente');
        if (val == 'todos_faltas') _marcarTodos('falta');
      },
      itemBuilder: (_) => [
        const PopupMenuItem(
          value: 'todos_presentes',
          child: Row(
            children: [
              Icon(Icons.check_circle_rounded,
                  color: Color(0xFF059669), size: 18),
              SizedBox(width: 8),
              Text(
                'Marcar todos Presentes',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'todos_faltas',
          child: Row(
            children: [
              Icon(Icons.cancel_rounded,
                  color: Color(0xFFDC2626), size: 18),
              SizedBox(width: 8),
              Text(
                'Marcar todos con Falta',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Sub-filtros estilo FiltroConductoresBar
  Widget _buildFiltrosBar({
    required int total,
    required int presentes,
    required int faltas,
    required int licencias,
  }) {
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildChip('todos', 'Todos', total),
          _buildChip('presentes', 'Presentes', presentes,
              color: const Color(0xFF059669)),
          _buildChip('faltas', 'Faltas', faltas,
              color: const Color(0xFFDC2626)),
          if (licencias > 0 || _filtroActivo == 'licencias')
            _buildChip('licencias', 'Licencias', licencias,
                color: const Color(0xFFD97706)),
        ],
      ),
    );
  }

  Widget _buildChip(String key, String label, int count, {Color? color}) {
    final isSelected = _filtroActivo == key;
    final chipColor = color ?? _kVerdeOscuro;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () {
          setState(() {
            _filtroActivo = key;
            _aplicarFiltros();
          });
        },
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? chipColor : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isSelected ? chipColor : const Color(0xFFE2E8F0),
              width: 1.2,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: chipColor.withOpacity(0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
          ),
          child: Text(
            '$label ($count)',
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF475569),
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              fontSize: 12.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline_rounded,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            const Text(
              'No hay conductores encontrados',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Intenta con otro filtro o término de búsqueda.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tarjeta de conductor para Asistencia siguiendo el diseño exacto de ConductorCard
class ConductorAsistenciaCard extends StatelessWidget {
  final int numeroLista;
  final String nombre;
  final String ci;
  final String? auto;
  final String? foto;
  final String estado;
  final double multa;
  final bool esCerrada;
  final ValueChanged<String> onMarcar;

  const ConductorAsistenciaCard({
    super.key,
    required this.numeroLista,
    required this.nombre,
    required this.ci,
    required this.auto,
    required this.foto,
    required this.estado,
    required this.multa,
    required this.esCerrada,
    required this.onMarcar,
  });

  @override
  Widget build(BuildContext context) {
    Color estadoColor;
    String estadoTexto;
    switch (estado) {
      case 'presente':
        estadoColor = const Color(0xFF059669);
        estadoTexto = 'Presente';
        break;
      case 'licencia':
        estadoColor = const Color(0xFFD97706);
        estadoTexto = 'Licencia / Permiso';
        break;
      case 'falta':
      default:
        estadoColor = const Color(0xFFDC2626);
        estadoTexto = 'Falta';
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFE2E8F0),
            width: 1.1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            // 1. Avatar del conductor idéntico a ConductorCard
            AvatarConductor(
              foto: foto,
              nombre: nombre,
              radio: 22,
              fontSize: 12,
            ),
            const SizedBox(width: 14),

            // 2. Información del conductor (Número de lista, Nombre, Auto/CI, Estado)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Arribita de la columna: solo el número de lista ("solo número")
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 1.5),
                    margin: const EdgeInsets.only(bottom: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5EF),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: const Color(0xFF02634C).withOpacity(0.2),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      '$numeroLista',
                      style: const TextStyle(
                        color: Color(0xFF02634C),
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  Text(
                    nombre,
                    style: const TextStyle(
                      color: Color(0xFF1E293B),
                      fontWeight: FontWeight.bold,
                      fontSize: 15.5,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(
                        Icons.directions_car_rounded,
                        size: 14,
                        color: Color(0xFF64748B),
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          (auto != null && auto!.isNotEmpty)
                              ? 'Auto N° $auto'
                              : (ci.isNotEmpty
                                  ? 'CI: $ci'
                                  : 'Sin unidad asignada'),
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: estadoColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        estadoTexto,
                        style: TextStyle(
                          color: estadoColor,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (estado == 'falta') ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: const Color(0xFFEF4444).withOpacity(0.3),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            'Bs. ${multa.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: Color(0xFFDC2626),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // 3. Marcación rápida táctil (P / F / L) o Badge si reunión cerrada
            if (!esCerrada) ...[
              _buildBotonToggle(
                valor: 'presente',
                sigla: 'P',
                tooltip: 'Presente',
                actual: estado,
                color: const Color(0xFF059669),
                onTap: () => onMarcar('presente'),
              ),
              const SizedBox(width: 4),
              _buildBotonToggle(
                valor: 'falta',
                sigla: 'F',
                tooltip: 'Falta',
                actual: estado,
                color: const Color(0xFFDC2626),
                onTap: () => onMarcar('falta'),
              ),
              const SizedBox(width: 4),
              _buildBotonToggle(
                valor: 'licencia',
                sigla: 'L',
                tooltip: 'Licencia',
                actual: estado,
                color: const Color(0xFFD97706),
                onTap: () => onMarcar('licencia'),
              ),
            ] else ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: estado == 'presente'
                      ? const Color(0xFFE6F4F0)
                      : estado == 'falta'
                          ? const Color(0xFFFEF2F2)
                          : const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: estado == 'presente'
                        ? const Color(0xFF10B981).withOpacity(0.4)
                        : estado == 'falta'
                            ? const Color(0xFFEF4444).withOpacity(0.4)
                            : const Color(0xFFF59E0B).withOpacity(0.4),
                  ),
                ),
                child: Text(
                  estado == 'falta'
                      ? 'FALTA (Bs. ${multa.toStringAsFixed(0)})'
                      : estado.toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    color: estado == 'presente'
                        ? const Color(0xFF059669)
                        : estado == 'falta'
                            ? const Color(0xFFDC2626)
                            : const Color(0xFFD97706),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBotonToggle({
    required String valor,
    required String sigla,
    required String tooltip,
    required String actual,
    required Color color,
    required VoidCallback onTap,
  }) {
    final seleccionado = actual == valor;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Tooltip(
        message: tooltip,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: seleccionado ? color : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: seleccionado ? color : const Color(0xFFCBD5E1),
              width: seleccionado ? 1.5 : 1,
            ),
            boxShadow: seleccionado
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.32),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              sigla,
              style: TextStyle(
                color: seleccionado ? Colors.white : const Color(0xFF64748B),
                fontWeight: FontWeight.w800,
                fontSize: 12.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
