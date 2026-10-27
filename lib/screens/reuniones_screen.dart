import 'package:flutter/material.dart';
import '../core/permisos.dart';
import '../services/economia_repo.dart';
import '../services/sesion_service.dart';
import '../widgets/app_background.dart';
import '../widgets/avatar_conductor.dart';
import 'cuotas/cuota_detalle_screen.dart';

/// Vista E10: Reuniones (Asambleas, Control de Asistencia y Cierre con Multas Automáticas)
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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarReuniones();
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
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _dialogoCrearReunion() async {
    final temaCtrl = TextEditingController(text: 'Asamblea General Ordinaria');
    final multaCtrl = TextEditingController(text: '50.00');
    DateTime fechaSeleccionada = DateTime.now();
    bool iniciarTodosPresentes = true;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setModalState) {
          final fechaStr =
              '${fechaSeleccionada.year.toString().padLeft(4, '0')}-${fechaSeleccionada.month.toString().padLeft(2, '0')}-${fechaSeleccionada.day.toString().padLeft(2, '0')}';

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                ContainerIcon(icon: Icons.groups_rounded, color: Color(0xFF1E3A8A), bg: Color(0xFFEFF6FF)),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Nueva Reunión / Asamblea',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F2B5B)),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sugerencias rápidas:',
                    style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _chipTema('Asamblea General', temaCtrl, setModalState),
                      _chipTema('Asamblea Extraordinaria', temaCtrl, setModalState),
                      _chipTema('Reunión de Rutas', temaCtrl, setModalState),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // TEMA
                  TextField(
                    controller: temaCtrl,
                    decoration: InputDecoration(
                      labelText: 'Tema de la Reunión *',
                      hintText: 'Ej. Asamblea de Fin de Mes',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // FECHA CON SELECTOR
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: dialogCtx,
                        initialDate: fechaSeleccionada,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                        builder: (context, child) {
                          return Theme(
                            data: ThemeData.light().copyWith(
                              colorScheme: const ColorScheme.light(primary: Color(0xFF1E3A8A)),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setModalState(() => fechaSeleccionada = picked);
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Fecha de la reunión', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                              Text(fechaStr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            ],
                          ),
                          const Icon(Icons.calendar_today_rounded, color: Color(0xFF1E3A8A), size: 20),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // MULTA
                  TextField(
                    controller: multaCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Multa por Falta *',
                      prefixText: 'Bs. ',
                      helperText: 'Monto que se cobrará a los que no asistan',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // SWITCH INICIAR TODOS PRESENTES
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: SwitchListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                      title: const Text(
                        'Marcar a todos como Presentes al iniciar',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      subtitle: const Text(
                        'Ahorra tiempo: solo marcarás Falta a los que no vinieron',
                        style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                      ),
                      value: iniciarTodosPresentes,
                      activeColor: const Color(0xFF059669),
                      onChanged: (val) {
                        setModalState(() => iniciarTodosPresentes = val);
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar', style: TextStyle(color: Color(0xFF64748B))),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  final tema = temaCtrl.text.trim();
                  final multa = double.tryParse(multaCtrl.text.trim()) ?? 50.0;

                  if (tema.isEmpty) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('El tema de la reunión es obligatorio.')),
                    );
                    return;
                  }

                  Navigator.pop(ctx);
                  try {
                    final id = await EconomiaRepo.instance.crearReunion(
                      tema: tema,
                      fecha: fechaStr,
                      montoMulta: multa,
                      estadoInicial: iniciarTodosPresentes ? 'presente' : 'falta',
                    );
                    await _cargarReuniones();
                    if (!mounted) return;
                    final reunionCreada = _reuniones.firstWhere((r) => r['id_reunion'].toString() == id);
                    _abrirPasarLista(reunionCreada);
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error al crear reunión: $e'), backgroundColor: Colors.red),
                    );
                  }
                },
                child: const Text('Crear y Llamar Lista'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _chipTema(String texto, TextEditingController ctrl, StateSetter setModalState) {
    return InkWell(
      onTap: () {
        setModalState(() {
          ctrl.text = texto;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFBFDBFE)),
        ),
        child: Text(
          texto,
          style: const TextStyle(fontSize: 10.5, color: Color(0xFF1E40AF), fontWeight: FontWeight.bold),
        ),
      ),
    );
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
            Text('Finalizar Reunión', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
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
                        const Icon(Icons.warning_amber_rounded, size: 18, color: Color(0xFFDC2626)),
                        const SizedBox(width: 6),
                        Text(
                          '$faltas choferes con FALTA detectados',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF991B1B)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Se generará una cuota de Bs. ${multa.toStringAsFixed(2)} para cada uno.\nTotal a cobrar en multas: Bs. ${totalMultas.toStringAsFixed(2)}.',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF7F1D1D)),
                    ),
                  ] else ...[
                    const Row(
                      children: [
                        Icon(Icons.check_circle_rounded, size: 18, color: Color(0xFF059669)),
                        SizedBox(width: 6),
                        Text(
                          '¡Asistencia perfecta! 0 faltas.',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF065F46)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Todos asistieron o tienen permiso. No se generarán multas.',
                      style: TextStyle(fontSize: 11.5, color: Color(0xFF065F46)),
                    ),
                  ],
                  const SizedBox(height: 8),
                  const Text(
                    'Una vez cerrada, la lista no podrá ser modificada.',
                    style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
            Text('Eliminar Reunión', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar', style: TextStyle(fontWeight: FontWeight.bold)),
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

  @override
  Widget build(BuildContext context) {
    final puedeGestionar = Permisos.puedeEditar(
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
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E3A8A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Reuniones y Asambleas',
          style: TextStyle(
            color: Color(0xFF0F2B5B),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: AppBackground(
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _cargarReuniones,
            color: const Color(0xFF1E3A8A),
            child: Column(
              children: [
                // BANNER EXPLICATIVO SUPERIOR
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x060F2B5B),
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFEF2F2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.gavel_rounded, color: Color(0xFFDC2626), size: 22),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Control de Asistencias y Multas',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF0F2B5B)),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Pasa lista en las reuniones sindicales. Al cerrar la reunión, se crean las multas automáticas.',
                                style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // LISTA DE REUNIONES
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _reuniones.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.groups_outlined, size: 56, color: Colors.grey.shade400),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'No hay reuniones registradas.',
                                    style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Presiona "+ Nueva Reunión" para convocar una asamblea.',
                                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                              itemCount: _reuniones.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 12),
                              itemBuilder: (ctx, i) {
                                final r = _reuniones[i];
                                final tema = r['tema']?.toString() ?? 'Reunión';
                                final fecha = r['fecha']?.toString() ?? '';
                                final multa = (r['monto_multa'] as num?)?.toDouble() ?? 50.0;
                                final estado = r['estado']?.toString().toLowerCase() ?? 'pendiente';
                                final esCerrada = estado == 'cerrada';
                                final idTipoCuota = r['id_tipo_cuota']?.toString();

                                final presentes = (r['presentes'] as num?)?.toInt() ?? 0;
                                final faltas = (r['faltas'] as num?)?.toInt() ?? 0;
                                final licencias = (r['licencias'] as num?)?.toInt() ?? 0;

                                return Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: esCerrada ? const Color(0xFFE2E8F0) : const Color(0xFFFECACA),
                                      width: 1.2,
                                    ),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x080F2B5B),
                                        blurRadius: 10,
                                        offset: Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // CABECERA: TÍTULO + BADGE ESTADO + POPUP
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              color: esCerrada ? const Color(0xFFF1F5F9) : const Color(0xFFFEF2F2),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              esCerrada ? Icons.lock_outline_rounded : Icons.groups_rounded,
                                              color: esCerrada ? const Color(0xFF64748B) : const Color(0xFFDC2626),
                                              size: 20,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  tema,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 15,
                                                    color: Color(0xFF0F2B5B),
                                                  ),
                                                ),
                                                const SizedBox(height: 3),
                                                Row(
                                                  children: [
                                                    const Icon(Icons.calendar_today_rounded, size: 12, color: Color(0xFF64748B)),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      fecha,
                                                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      '• Multa: Bs. ${multa.toStringAsFixed(0)}',
                                                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFFDC2626)),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: esCerrada ? const Color(0xFFF1F5F9) : const Color(0xFFFEF2F2),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              esCerrada ? 'CERRADA' : 'EN CURSO',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: esCerrada ? const Color(0xFF64748B) : const Color(0xFFDC2626),
                                              ),
                                            ),
                                          ),
                                          if (puedeGestionar)
                                            PopupMenuButton<String>(
                                              icon: const Icon(Icons.more_vert, size: 18, color: Color(0xFF64748B)),
                                              padding: EdgeInsets.zero,
                                              onSelected: (val) {
                                                if (val == 'eliminar') {
                                                  _confirmarEliminarReunion(r);
                                                }
                                              },
                                              itemBuilder: (_) => [
                                                const PopupMenuItem(
                                                  value: 'eliminar',
                                                  child: Row(
                                                    children: [
                                                      Icon(Icons.delete_outline, color: Colors.red, size: 18),
                                                      SizedBox(width: 8),
                                                      Text('Eliminar Reunión', style: TextStyle(color: Colors.red, fontSize: 13)),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),

                                      // PÍLDORAS DE ESTADÍSTICAS
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 6,
                                        children: [
                                          _buildBadgeAsist(
                                            'Presentes',
                                            presentes,
                                            const Color(0xFF059669),
                                            const Color(0xFFECFDF5),
                                            Icons.check_circle_outline_rounded,
                                          ),
                                          _buildBadgeAsist(
                                            'Faltas',
                                            faltas,
                                            const Color(0xFFDC2626),
                                            const Color(0xFFFEF2F2),
                                            Icons.cancel_outlined,
                                            subTexto: faltas > 0 ? ' (Bs. ${(faltas * multa).toStringAsFixed(0)})' : null,
                                          ),
                                          _buildBadgeAsist(
                                            'Licencias',
                                            licencias,
                                            const Color(0xFFD97706),
                                            const Color(0xFFFFFBEB),
                                            Icons.assignment_turned_in_outlined,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 14),

                                      // BOTONES DE ACCIÓN
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          OutlinedButton.icon(
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: const Color(0xFF1E3A8A),
                                              side: const BorderSide(color: Color(0xFFCBD5E1)),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            ),
                                            icon: Icon(esCerrada ? Icons.visibility_outlined : Icons.how_to_reg_rounded, size: 16),
                                            label: Text(esCerrada ? 'Ver Asistencia' : 'Llamar Lista'),
                                            onPressed: () => _abrirPasarLista(r),
                                          ),
                                          if (puedeGestionar && !esCerrada) ...[
                                            const SizedBox(width: 8),
                                            ElevatedButton.icon(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFFDC2626),
                                                foregroundColor: Colors.white,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                elevation: 0,
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                              ),
                                              icon: const Icon(Icons.lock_clock, size: 16),
                                              label: const Text('Cerrar y Multar'),
                                              onPressed: () => _cerrarReunionConfirmar(r),
                                            ),
                                          ],
                                          if (esCerrada && idTipoCuota != null && faltas > 0) ...[
                                            const SizedBox(width: 8),
                                            ElevatedButton.icon(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFF0F2B5B),
                                                foregroundColor: Colors.white,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                elevation: 0,
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                              ),
                                              icon: const Icon(Icons.receipt_long_rounded, size: 16),
                                              label: const Text('Cobrar Multas'),
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) => CuotaDetalleScreen(
                                                      cuota: {
                                                        'id_tipo_cuota': idTipoCuota,
                                                        'nombre': 'Multa: $tema',
                                                        'descripcion': 'Multas por falta a la asamblea "$tema" ($fecha)',
                                                        'monto_sugerido': multa,
                                                        'categoria': 'multa',
                                                      },
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: puedeGestionar
          ? FloatingActionButton.extended(
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Nueva Reunión', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: _dialogoCrearReunion,
            )
          : null,
    );
  }

  Widget _buildBadgeAsist(String label, int cant, Color color, Color bg, IconData icon, {String? subTexto}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text('$label: ', style: TextStyle(fontSize: 10.5, color: color, fontWeight: FontWeight.w600)),
          Text('$cant', style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold)),
          if (subTexto != null)
            Text(subTexto, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w700)),
        ],
      ),
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

/// Pantalla para pasar lista en una reunión específica
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
          _filtrar(_busqueda);
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filtrar(String query) {
    _busqueda = query.toLowerCase().trim();
    setState(() {
      if (_busqueda.isEmpty) {
        _asistentesFiltrados = List.from(_asistentes);
      } else {
        _asistentesFiltrados = _asistentes.where((a) {
          final nombre = (a['conductor_nombre'] ?? '').toString().toLowerCase();
          final ci = (a['conductor_ci'] ?? '').toString().toLowerCase();
          return nombre.contains(_busqueda) || ci.contains(_busqueda);
        }).toList();
      }
    });
  }

  Future<void> _marcar(String idAsistencia, String nuevoEstado) async {
    final esCerrada = widget.reunion['estado']?.toString().toLowerCase() == 'cerrada';
    if (esCerrada) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Esta reunión ya fue cerrada.')),
      );
      return;
    }

    try {
      await EconomiaRepo.instance.actualizarAsistenciaReunion(idAsistencia, nuevoEstado);
      // Actualización optimista local rápida para máxima fluidez
      setState(() {
        final idx = _asistentes.indexWhere((a) => a['id_asistencia_reunion'].toString() == idAsistencia);
        if (idx != -1) {
          final map = Map<String, dynamic>.from(_asistentes[idx]);
          map['estado'] = nuevoEstado;
          _asistentes[idx] = map;
          _filtrar(_busqueda);
        }
      });
    } catch (_) {
      _cargarAsistencia();
    }
  }

  Future<void> _marcarTodos(String nuevoEstado) async {
    final esCerrada = widget.reunion['estado']?.toString().toLowerCase() == 'cerrada';
    if (esCerrada) return;

    try {
      final idReunion = widget.reunion['id_reunion'].toString();
      await EconomiaRepo.instance.marcarTodosAsistenciaReunion(idReunion, nuevoEstado);
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
    final faltas = _asistentes.where((a) => a['estado']?.toString().toLowerCase() == 'falta').length;
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
            Text('Finalizar Reunión', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
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
                      color: faltas > 0 ? const Color(0xFF991B1B) : const Color(0xFF065F46),
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
            child: const Text('Cancelar', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
            content: Text('Reunión cerrada. Se crearon $cant multas por Bs. ${total.toStringAsFixed(2)}.'),
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
    final esCerrada = widget.reunion['estado']?.toString().toLowerCase() == 'cerrada';

    final presentes = _asistentes.where((a) => a['estado']?.toString().toLowerCase() == 'presente').length;
    final faltas = _asistentes.where((a) => a['estado']?.toString().toLowerCase() == 'falta').length;
    final licencias = _asistentes.where((a) => a['estado']?.toString().toLowerCase() == 'licencia').length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E3A8A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tema,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF0F2B5B),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              'Fecha: $fecha • ${_asistentes.length} Choferes • Multa: Bs. ${multa.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
          ],
        ),
        actions: [
          if (!esCerrada)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Color(0xFF1E3A8A)),
              onSelected: (val) {
                if (val == 'todos_presentes') _marcarTodos('presente');
                if (val == 'todos_faltas') _marcarTodos('falta');
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'todos_presentes',
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 18),
                      SizedBox(width: 8),
                      Text('Marcar todos Presentes', style: TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'todos_faltas',
                  child: Row(
                    children: [
                      Icon(Icons.cancel_rounded, color: Color(0xFFDC2626), size: 18),
                      SizedBox(width: 8),
                      Text('Marcar todos con Falta', style: TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              // RESUMEN EN VIVO DE ASISTENCIA
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x060F2B5B),
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildHeaderPill('PRESENTES', presentes, const Color(0xFF059669), const Color(0xFFECFDF5)),
                      _buildHeaderPill(
                        'FALTAS',
                        faltas,
                        const Color(0xFFDC2626),
                        const Color(0xFFFEF2F2),
                        sub: 'Bs. ${(faltas * multa).toStringAsFixed(0)}',
                      ),
                      _buildHeaderPill('LICENCIAS', licencias, const Color(0xFFD97706), const Color(0xFFFFFBEB)),
                    ],
                  ),
                ),
              ),

              // BUSCADOR DE CONDUCTOR
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: _filtrar,
                    decoration: const InputDecoration(
                      hintText: 'Buscar conductor por nombre o CI...',
                      hintStyle: TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                      prefixIcon: Icon(Icons.search, size: 18, color: Color(0xFF64748B)),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // LISTA DE ASISTENCIA
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _asistentesFiltrados.isEmpty
                        ? const Center(
                            child: Text(
                              'No se encontraron conductores.',
                              style: TextStyle(color: Color(0xFF64748B)),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
                            physics: const BouncingScrollPhysics(),
                            itemCount: _asistentesFiltrados.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 8),
                            itemBuilder: (ctx, i) {
                              final a = _asistentesFiltrados[i];
                              final idAsistencia = a['id_asistencia_reunion'].toString();
                              final nombre = a['conductor_nombre']?.toString() ?? 'Chofer';
                              final ci = a['conductor_ci']?.toString() ?? '';
                              final foto = a['conductor_foto']?.toString();
                              final estado = a['estado']?.toString().toLowerCase() ?? 'falta';

                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: estado == 'falta'
                                        ? const Color(0xFFFECACA)
                                        : estado == 'presente'
                                            ? const Color(0xFFA7F3D0)
                                            : const Color(0xFFFDE68A),
                                    width: 1.1,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x050F2B5B),
                                      blurRadius: 6,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    AvatarConductor(
                                      foto: foto,
                                      nombre: nombre,
                                      radio: 20,
                                      fontSize: 11,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            nombre,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13.5,
                                              color: Color(0xFF0F2B5B),
                                            ),
                                          ),
                                          const SizedBox(height: 1),
                                          Text('CI: $ci', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                        ],
                                      ),
                                    ),
                                    if (esCerrada) ...[
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: estado == 'presente'
                                              ? const Color(0xFFECFDF5)
                                              : estado == 'falta'
                                                  ? const Color(0xFFFEF2F2)
                                                  : const Color(0xFFFFFBEB),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          estado == 'falta'
                                              ? 'FALTA (Bs. ${multa.toStringAsFixed(0)})'
                                              : estado.toUpperCase(),
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                            color: estado == 'presente'
                                                ? const Color(0xFF059669)
                                                : estado == 'falta'
                                                    ? const Color(0xFFDC2626)
                                                    : const Color(0xFFD97706),
                                          ),
                                        ),
                                      ),
                                    ] else ...[
                                      // 3 BOTONES TÁCTILES RÁPIDOS (P / F / L)
                                      _buildBotonToggle(
                                        'presente',
                                        'P',
                                        'Presente',
                                        estado,
                                        const Color(0xFF059669),
                                        () => _marcar(idAsistencia, 'presente'),
                                      ),
                                      const SizedBox(width: 6),
                                      _buildBotonToggle(
                                        'falta',
                                        'F',
                                        'Falta',
                                        estado,
                                        const Color(0xFFDC2626),
                                        () => _marcar(idAsistencia, 'falta'),
                                      ),
                                      const SizedBox(width: 6),
                                      _buildBotonToggle(
                                        'licencia',
                                        'L',
                                        'Permiso',
                                        estado,
                                        const Color(0xFFD97706),
                                        () => _marcar(idAsistencia, 'licencia'),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
      bottomSheet: !esCerrada
          ? Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.gavel_rounded, size: 18),
                    label: Text(
                      'Finalizar Reunión ($faltas Faltas = Bs. ${(faltas * multa).toStringAsFixed(0)})',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                    ),
                    onPressed: _cerrarDesdeAqui,
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildHeaderPill(String title, int count, Color color, Color bg, {String? sub}) {
    return Column(
      children: [
        Text(title, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color, letterSpacing: 0.5)),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '$count',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color),
            ),
            if (sub != null) ...[
              const SizedBox(width: 3),
              Text(
                sub,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color.withOpacity(0.85)),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildBotonToggle(
    String valor,
    String sigla,
    String tooltip,
    String actual,
    Color color,
    VoidCallback onTap,
  ) {
    final seleccionado = actual == valor;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: seleccionado ? color : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
          boxShadow: seleccionado
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.35),
                    blurRadius: 6,
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
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
