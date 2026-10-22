import 'package:flutter/material.dart';
import '../core/permisos.dart';
import '../services/economia_repo.dart';
import '../services/sesion_service.dart';
import '../widgets/avatar_conductor.dart';

/// Vista E10: Reuniones (Asambleas, Control de Asistencia y Cierre con Multas)
///
/// Permite al Secretario de Hacienda / Supervisor:
/// 1. Crear reuniones fijando el monto de la multa por falta.
/// 2. Pasar lista a los conductores activos (Presente / Falta / Licencia).
/// 3. Cerrar la reunión generando automáticamente las cuotas de multa por falta.
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

  void _dialogoCrearReunion() {
    final temaCtrl = TextEditingController(text: 'Asamblea General Ordinaria');
    final fechaCtrl = TextEditingController(
      text: DateTime.now().toIso8601String().substring(0, 10),
    );
    final multaCtrl = TextEditingController(text: '50.00');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.groups, color: Color(0xFF1E3A8A)),
            SizedBox(width: 8),
            Text('Nueva Reunión', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: temaCtrl,
                decoration: InputDecoration(
                  labelText: 'Tema de la Reunión *',
                  hintText: 'Ej. Asamblea de Fin de Mes',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: fechaCtrl,
                decoration: InputDecoration(
                  labelText: 'Fecha (AAAA-MM-DD) *',
                  prefixIcon: const Icon(Icons.calendar_today, size: 18),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: multaCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Multa por Falta (Bs.) *',
                  prefixText: 'Bs. ',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
              final fecha = fechaCtrl.text.trim();
              final multa = double.tryParse(multaCtrl.text.trim()) ?? 50.0;

              if (tema.isEmpty || fecha.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tema y fecha son obligatorios.')),
                );
                return;
              }

              Navigator.pop(ctx);
              try {
                await EconomiaRepo.instance.crearReunion(
                  tema: tema,
                  fecha: fecha,
                  montoMulta: multa,
                );
                _cargarReuniones();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Crear Reunión'),
          ),
        ],
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
            Icon(Icons.lock_clock, color: Color(0xFFDC2626)),
            SizedBox(width: 8),
            Text('Cerrar Reunión'),
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
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Se generarán $faltas multas por falta de Bs. ${multa.toStringAsFixed(2)} c/u (Total Bs. ${totalMultas.toStringAsFixed(2)}).',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF991B1B)),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Una vez cerrada, la lista no podrá ser modificada.',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF7F1D1D)),
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
            child: const Text('Cerrar y Generar Multas'),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Reunión cerrada. Se crearon ${res['multas_generadas']} multas por un total de Bs. ${(res['total_multas_bs'] as num).toStringAsFixed(2)}.',
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

  @override
  Widget build(BuildContext context) {
    final puedeGestionar = Permisos.puedeEditar(
      SesionService.instance.rol,
      Permisos.moduloControlEconomico,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text(
          'Reuniones Sindicales',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
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
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  physics: const BouncingScrollPhysics(),
                  itemCount: _reuniones.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (ctx, i) {
                    final r = _reuniones[i];
                    final tema = r['tema']?.toString() ?? 'Reunión';
                    final fecha = r['fecha']?.toString() ?? '';
                    final multa = (r['monto_multa'] as num?)?.toDouble() ?? 50.0;
                    final estado = r['estado']?.toString().toLowerCase() ?? 'pendiente';
                    final esCerrada = estado == 'cerrada';

                    final presentes = (r['presentes'] as num?)?.toInt() ?? 0;
                    final faltas = (r['faltas'] as num?)?.toInt() ?? 0;
                    final licencias = (r['licencias'] as num?)?.toInt() ?? 0;

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
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
                                child: Text(
                                  tema,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: esCerrada ? const Color(0xFFF1F5F9) : const Color(0xFFECFDF5),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  esCerrada ? 'CERRADA' : 'EN CURSO',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: esCerrada ? const Color(0xFF64748B) : const Color(0xFF059669),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Fecha: $fecha • Multa por falta: Bs. ${multa.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _buildBadgeAsist('Presentes', presentes, const Color(0xFF059669), const Color(0xFFECFDF5)),
                              const SizedBox(width: 8),
                              _buildBadgeAsist('Faltas', faltas, const Color(0xFFDC2626), const Color(0xFFFEF2F2)),
                              const SizedBox(width: 8),
                              _buildBadgeAsist('Licencias', licencias, const Color(0xFFD97706), const Color(0xFFFFFBEB)),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF2563EB),
                                  side: const BorderSide(color: Color(0xFF2563EB)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                icon: const Icon(Icons.checklist, size: 16),
                                label: Text(esCerrada ? 'Ver Asistencia' : 'Pasar Lista'),
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
                                  ),
                                  icon: const Icon(Icons.lock_clock, size: 16),
                                  label: const Text('Cerrar Reunión'),
                                  onPressed: () => _cerrarReunionConfirmar(r),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    );
                  },
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

  Widget _buildBadgeAsist(String label, int cant, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ', style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
          Text('$cant', style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold)),
        ],
      ),
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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarAsistencia();
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
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
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
      _cargarAsistencia();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final tema = widget.reunion['tema']?.toString() ?? 'Reunión';
    final fecha = widget.reunion['fecha']?.toString() ?? '';
    final esCerrada = widget.reunion['estado']?.toString().toLowerCase() == 'cerrada';

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tema, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text('Fecha: $fecha • ${_asistentes.length} conductores', style: const TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _asistentes.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) {
                final a = _asistentes[i];
                final idAsistencia = a['id_asistencia_reunion'].toString();
                final nombre = a['conductor_nombre']?.toString() ?? 'Chofer';
                final ci = a['conductor_ci']?.toString() ?? '';
                final foto = a['conductor_foto']?.toString();
                final estado = a['estado']?.toString().toLowerCase() ?? 'falta';

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      AvatarConductor(
                        foto: foto,
                        nombre: nombre,
                        radio: 19,
                        fontSize: 10,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nombre,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            Text('CI: $ci', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                          ],
                        ),
                      ),
                      if (esCerrada) ...[
                        Text(
                          estado.toUpperCase(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: estado == 'presente'
                                ? const Color(0xFF059669)
                                : estado == 'falta'
                                    ? const Color(0xFFDC2626)
                                    : const Color(0xFFD97706),
                          ),
                        ),
                      ] else ...[
                        _buildBotonToggle('presente', 'P', estado, const Color(0xFF059669), () => _marcar(idAsistencia, 'presente')),
                        const SizedBox(width: 6),
                        _buildBotonToggle('falta', 'F', estado, const Color(0xFFDC2626), () => _marcar(idAsistencia, 'falta')),
                        const SizedBox(width: 6),
                        _buildBotonToggle('licencia', 'L', estado, const Color(0xFFD97706), () => _marcar(idAsistencia, 'licencia')),
                      ],
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildBotonToggle(String valor, String sigla, String actual, Color color, VoidCallback onTap) {
    final seleccionado = actual == valor;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: seleccionado ? color : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            sigla,
            style: TextStyle(
              color: seleccionado ? Colors.white : const Color(0xFF64748B),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
