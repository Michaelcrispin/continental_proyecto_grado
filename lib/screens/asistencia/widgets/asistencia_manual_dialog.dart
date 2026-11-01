import 'package:flutter/material.dart';
import '../../../services/asistencia_repo.dart';
import '../../../services/database_helper.dart';
import '../../../services/sesion_service.dart';

/// Diálogo para que supervisores o administradores registren asistencia manual con justificación.
class AsistenciaManualDialog extends StatefulWidget {
  final VoidCallback onGuardado;

  const AsistenciaManualDialog({super.key, required this.onGuardado});

  @override
  State<AsistenciaManualDialog> createState() => _AsistenciaManualDialogState();
}

class _AsistenciaManualDialogState extends State<AsistenciaManualDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _justificacionCtrl = TextEditingController();

  List<Map<String, dynamic>> _conductores = [];
  List<Map<String, dynamic>> _puntos = [];
  String? _conductorSeleccionado;
  String? _puntoSeleccionado;
  String _estado = 'presente';
  bool _cargando = true;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  @override
  void dispose() {
    _justificacionCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    final conds = await DatabaseHelper.instance.listar('conductor');
    final pts = await DatabaseHelper.instance.obtenerPuntosControl();

    if (mounted) {
      setState(() {
        _conductores = conds;
        _puntos = pts;
        if (conds.isNotEmpty) _conductorSeleccionado = conds.first['id_conductor']?.toString();
        if (pts.isNotEmpty) {
          final ptAsist = pts.firstWhere(
            (p) => (p['es_punto_asistencia'] as num?)?.toInt() == 1,
            orElse: () => pts.first,
          );
          _puntoSeleccionado = ptAsist['id_punto']?.toString();
        }
        _cargando = false;
      });
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_conductorSeleccionado == null || _puntoSeleccionado == null) return;

    setState(() => _guardando = true);
    final idSupervisor = SesionService.instance.idUsuario ?? 'supervisor';

    final res = await AsistenciaRepo.instance.registrarAsistenciaManual(
      idConductor: _conductorSeleccionado!,
      idPunto: _puntoSeleccionado!,
      idSupervisor: idSupervisor,
      estado: _estado,
      justificacion: _justificacionCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() => _guardando = false);

    if (res.exito) {
      Navigator.pop(context);
      widget.onGuardado();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.mensaje),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.mensaje),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.edit_note, color: Color(0xFF3B82F6)),
          SizedBox(width: 8),
          Text(
            'Registro Manual Supervisor',
            style: TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
      content: _cargando
          ? const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()))
          : SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Conductor:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: _conductorSeleccionado,
                      items: _conductores.map((c) {
                        return DropdownMenuItem<String>(
                          value: c['id_conductor']?.toString(),
                          child: Text('${c['nombre']} (CI: ${c['ci']})', overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                        );
                      }).toList(),
                      onChanged: (v) => setState(() => _conductorSeleccionado = v),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    const Text('Punto de control:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: _puntoSeleccionado,
                      items: _puntos.map((p) {
                        return DropdownMenuItem<String>(
                          value: p['id_punto']?.toString(),
                          child: Text(p['nombre']?.toString() ?? '', overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                        );
                      }).toList(),
                      onChanged: (v) => setState(() => _puntoSeleccionado = v),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    const Text('Estado de llegada:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      value: _estado,
                      items: const [
                        DropdownMenuItem(value: 'presente', child: Text('Presente (A tiempo)')),
                        DropdownMenuItem(value: 'tardanza', child: Text('Tardanza (+2 vueltas castigo)')),
                        DropdownMenuItem(value: 'falta', child: Text('Falta')),
                      ],
                      onChanged: (v) => setState(() => _estado = v ?? 'presente'),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    const Text('Justificación (obligatoria):', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: _justificacionCtrl,
                      maxLines: 2,
                      validator: (v) {
                        if (v == null || v.trim().length < 5) {
                          return 'Ingresa al menos 5 caracteres de justificación.';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        hintText: 'Ej. Falla de batería del celular del chofer...',
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                        contentPadding: const EdgeInsets.all(12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar', style: TextStyle(color: Color(0xFF64748B))),
        ),
        ElevatedButton(
          onPressed: _guardando ? null : _guardar,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3B82F6),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _guardando
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Guardar Asistencia', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
