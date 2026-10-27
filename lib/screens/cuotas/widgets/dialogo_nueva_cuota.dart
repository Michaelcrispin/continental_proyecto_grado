import 'package:flutter/material.dart';
import '../../../services/economia_repo.dart';
import '../../../services/sesion_service.dart';

/// Diálogo modal desacoplado para Crear o Editar una Cuota.
/// Separa claramente: Título, Motivo descriptivo y Monto por chofer.
class DialogoNuevaCuota extends StatefulWidget {
  final Map<String, dynamic>? cuotaAEditar;

  const DialogoNuevaCuota({super.key, this.cuotaAEditar});

  static Future<bool?> mostrar(BuildContext context, {Map<String, dynamic>? cuotaAEditar}) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => DialogoNuevaCuota(cuotaAEditar: cuotaAEditar),
    );
  }

  @override
  State<DialogoNuevaCuota> createState() => _DialogoNuevaCuotaState();
}

class _DialogoNuevaCuotaState extends State<DialogoNuevaCuota> {
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _motivoCtrl;
  late final TextEditingController _montoCtrl;
  bool _guardando = false;

  bool get _esEdicion => widget.cuotaAEditar != null;

  @override
  void initState() {
    super.initState();
    final cuota = widget.cuotaAEditar;
    _nombreCtrl = TextEditingController(text: cuota?['nombre']?.toString() ?? '');
    _motivoCtrl = TextEditingController(text: cuota?['descripcion']?.toString() ?? '');

    final montoSugerido = (cuota?['monto_sugerido'] as num?)?.toDouble() ?? 50.0;
    _montoCtrl = TextEditingController(
      text: cuota != null ? montoSugerido.toStringAsFixed(2) : '50.00',
    );
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _motivoCtrl.dispose();
    _montoCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final nombre = _nombreCtrl.text.trim();
    final motivo = _motivoCtrl.text.trim();
    final monto = double.tryParse(_montoCtrl.text.trim()) ?? 0.0;

    if (nombre.isEmpty) {
      _mostrarSnack('Ingresa el título de la cuota (ej: Apoyo económico).');
      return;
    }
    if (monto <= 0) {
      _mostrarSnack('Ingresa un monto válido mayor a 0 Bs.');
      return;
    }

    setState(() => _guardando = true);

    try {
      if (_esEdicion) {
        final idTipo = widget.cuotaAEditar!['id_tipo_cuota'].toString();
        await EconomiaRepo.instance.actualizarTipoCuota(
          idTipoCuota: idTipo,
          nombre: nombre,
          descripcion: motivo.isNotEmpty ? motivo : null,
          monto: monto,
        );
      } else {
        final idUsuario = SesionService.instance.idUsuario ?? 'admin';
        await EconomiaRepo.instance.crearNuevoConceptoCuota(
          nombre: nombre,
          descripcion: motivo.isNotEmpty ? motivo : null,
          monto: monto,
          idUsuario: idUsuario,
        );
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _guardando = false);
        _mostrarSnack('Error al guardar la cuota: $e');
      }
    }
  }

  void _mostrarSnack(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: const Color(0xFFDC2626)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      titlePadding: const EdgeInsets.fromLTRB(22, 20, 22, 10),
      contentPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
      actionsPadding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _esEdicion ? Icons.edit_note_rounded : Icons.add_card_rounded,
              color: const Color(0xFF1E3A8A),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _esEdicion ? 'Editar Cuota' : 'Nueva Cuota',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Color(0xFF0F2B5B),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            const Text(
              'Define el concepto y monto obligatorio que aportará cada chofer.',
              style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 18),

            // Título de la cuota
            TextField(
              controller: _nombreCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Título de la Cuota *',
                hintText: 'Ej: Apoyo económico, Mantenimiento',
                prefixIcon: const Icon(Icons.bookmark_outline, color: Color(0xFF1E3A8A)),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Motivo descriptivo
            TextField(
              controller: _motivoCtrl,
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Motivo / Descripción de la Cuota',
                hintText: 'Ej: Apoyo para el compañero David, reparación de unidad...',
                prefixIcon: const Icon(Icons.description_outlined, color: Color(0xFF1E3A8A)),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Monto por chofer
            TextField(
              controller: _montoCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Monto por chofer (Bs.) *',
                prefixText: 'Bs. ',
                prefixStyle: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F2B5B)),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _guardando ? null : () => Navigator.pop(context, false),
          child: const Text('Cancelar', style: TextStyle(color: Color(0xFF64748B))),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0F2B5B),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          ),
          onPressed: _guardando ? null : _guardar,
          child: _guardando
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : Text(
                  _esEdicion ? 'Guardar Cambios' : 'Crear Cuota',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
        ),
      ],
    );
  }
}
