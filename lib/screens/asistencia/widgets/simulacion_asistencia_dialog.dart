import 'package:flutter/material.dart';
import '../../../services/asistencia_repo.dart';
import '../../../services/database_helper.dart';

/// Modal para que el Superadmin simule llegadas en tiempo real para la defensa de grado.
class SimulacionAsistenciaDialog extends StatefulWidget {
  final VoidCallback onSimulacionAplicada;

  const SimulacionAsistenciaDialog({super.key, required this.onSimulacionAplicada});

  @override
  State<SimulacionAsistenciaDialog> createState() => _SimulacionAsistenciaDialogState();
}

class _SimulacionAsistenciaDialogState extends State<SimulacionAsistenciaDialog> {
  List<Map<String, dynamic>> _conductores = [];
  Map<String, dynamic>? _puntoAsistencia;
  String? _conductorSeleccionado;
  String _horaSimulada = '07:45';
  bool _cargando = true;
  bool _procesando = false;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final conds = await DatabaseHelper.instance.listar('conductor');
    final pt = await DatabaseHelper.instance.obtenerPuntoAsistencia();
    if (mounted) {
      setState(() {
        _conductores = conds;
        _puntoAsistencia = pt;
        if (conds.isNotEmpty) _conductorSeleccionado = conds.first['id_conductor']?.toString();
        _cargando = false;
      });
    }
  }

  Future<void> _ejecutarSimulacion(String hora) async {
    if (_conductorSeleccionado == null || _puntoAsistencia == null) return;
    setState(() => _procesando = true);

    final idPunto = _puntoAsistencia!['id_punto']?.toString() ?? '';
    final latP = (_puntoAsistencia!['latitud'] as num?)?.toDouble() ?? -16.53453;
    final lonP = (_puntoAsistencia!['longitud'] as num?)?.toDouble() ?? -68.19071;

    final res = await AsistenciaRepo.instance.simularLlegada(
      idConductor: _conductorSeleccionado!,
      idPunto: idPunto,
      horaSimulada: hora,
      latitud: latP,
      longitud: lonP,
      distanciaM: 25.0, // Simulado dentro de geocerca
    );

    if (!mounted) return;
    setState(() => _procesando = false);

    Navigator.pop(context);
    widget.onSimulacionAplicada();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(res.mensaje),
        backgroundColor: res.esTardanza ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _purgarSimuladas() async {
    setState(() => _procesando = true);
    final count = await AsistenciaRepo.instance.purgarAsistenciasSimuladas();
    if (!mounted) return;
    setState(() => _procesando = false);
    Navigator.pop(context);
    widget.onSimulacionAplicada();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Se eliminaron $count registros de prueba simulados.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.science_outlined, color: Colors.purple),
          SizedBox(width: 8),
          Text(
            'Simulador para Defensa',
            style: TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
      content: _cargando
          ? const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()))
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Permite demostrar ante el tribunal el comportamiento automático del GPS y las sanciones sin estar físicamente en Cruce Villadela.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 14),

                  const Text('Conductor a evaluar:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: _conductorSeleccionado,
                    items: _conductores.map((c) {
                      return DropdownMenuItem<String>(
                        value: c['id_conductor']?.toString(),
                        child: Text('${c['nombre']} (CI: ${c['ci']})', overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                      );
                    }).toList(),
                    onChanged: (v) => setState(() => _conductorSeleccionado = v),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text('Pruebas Rápidas con 1 toque:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E3A8A))),
                  const SizedBox(height: 8),

                  // Botón Escenario 1: A tiempo (07:45)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _procesando ? null : () => _ejecutarSimulacion('07:45'),
                      icon: const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 18),
                      label: const Text('Simular Llegada A Tiempo (07:45 AM)', style: TextStyle(fontSize: 12, color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF10B981)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Botón Escenario 2: Tardanza (08:25) -> 2 vueltas castigo
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _procesando ? null : () => _ejecutarSimulacion('08:25'),
                      icon: const Icon(Icons.alarm, color: Color(0xFFF59E0B), size: 18),
                      label: const Text('Simular Tardanza 08:25 AM (+2 Vueltas)', style: TextStyle(fontSize: 12, color: Color(0xFFF59E0B), fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFF59E0B)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Hora personalizada
                  Row(
                    children: [
                      const Text('Hora específica:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _horaSimulada,
                          items: const [
                            DropdownMenuItem(value: '07:15', child: Text('07:15 AM (Presente)')),
                            DropdownMenuItem(value: '07:55', child: Text('07:55 AM (Presente)')),
                            DropdownMenuItem(value: '08:00', child: Text('08:00 AM (Límite)')),
                            DropdownMenuItem(value: '08:05', child: Text('08:05 AM (Tardanza)')),
                            DropdownMenuItem(value: '08:30', child: Text('08:30 AM (Tardanza)')),
                            DropdownMenuItem(value: '09:00', child: Text('09:00 AM (Tardanza)')),
                          ],
                          onChanged: (v) => setState(() => _horaSimulada = v ?? '07:45'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _procesando ? null : () => _ejecutarSimulacion(_horaSimulada),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Aplicar Hora Seleccionada', style: TextStyle(color: Colors.white, fontSize: 12)),
                    ),
                  ),

                  const Divider(height: 24),
                  Center(
                    child: TextButton.icon(
                      onPressed: _procesando ? null : _purgarSimuladas,
                      icon: const Icon(Icons.delete_sweep, color: Colors.red, size: 16),
                      label: const Text('Limpiar Registros Simulados', style: TextStyle(color: Colors.red, fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cerrar', style: TextStyle(color: Color(0xFF64748B))),
        ),
      ],
    );
  }
}
