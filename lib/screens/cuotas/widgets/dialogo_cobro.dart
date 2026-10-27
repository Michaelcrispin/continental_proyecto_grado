import 'package:flutter/material.dart';
import '../../../services/economia_repo.dart';
import '../../../services/recibo_pdf_service.dart';
import '../../../services/sesion_service.dart';
import '../../../widgets/avatar_conductor.dart';

/// Diálogo modal desacoplado para registrar cobro (completo o abono parcial)
/// a un chofer para una cuota determinada.
class DialogoCobro extends StatefulWidget {
  final Map<String, dynamic> conductor;
  final String idTipoCuota;
  final String cuotaNombre;
  final double? montoInicial;
  final String? idCuotaEspecifica;
  final String? conceptoCuota;

  const DialogoCobro({
    super.key,
    required this.conductor,
    required this.idTipoCuota,
    required this.cuotaNombre,
    this.montoInicial,
    this.idCuotaEspecifica,
    this.conceptoCuota,
  });

  static Future<bool?> mostrar(
    BuildContext context, {
    required Map<String, dynamic> conductor,
    required String idTipoCuota,
    required String cuotaNombre,
    double? montoInicial,
    String? idCuotaEspecifica,
    String? conceptoCuota,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => DialogoCobro(
        conductor: conductor,
        idTipoCuota: idTipoCuota,
        cuotaNombre: cuotaNombre,
        montoInicial: montoInicial,
        idCuotaEspecifica: idCuotaEspecifica,
        conceptoCuota: conceptoCuota,
      ),
    );
  }

  @override
  State<DialogoCobro> createState() => _DialogoCobroState();
}

class _DialogoCobroState extends State<DialogoCobro> {
  late final TextEditingController _montoCtrl;
  String _metodo = 'efectivo';
  bool _procesando = false;

  late double _total;
  late double _pagado;
  late double _falta;

  @override
  void initState() {
    super.initState();
    _total = (widget.conductor['monto_total'] as num?)?.toDouble() ?? 0.0;
    _pagado = (widget.conductor['monto_pagado'] as num?)?.toDouble() ?? 0.0;
    _falta = (widget.conductor['monto_falta'] as num?)?.toDouble() ?? (_total - _pagado);
    if (_falta < 0) _falta = 0.0;

    double montoDefecto = _falta;
    if (widget.montoInicial != null && widget.montoInicial! > 0) {
      montoDefecto = widget.montoInicial!;
    } else {
      final proxMonto = (widget.conductor['proximo_monto_pago'] as num?)?.toDouble();
      if (proxMonto != null && proxMonto > 0 && proxMonto <= _falta) {
        montoDefecto = proxMonto;
      }
    }
    if (montoDefecto > _falta) montoDefecto = _falta;

    _montoCtrl = TextEditingController(text: montoDefecto > 0 ? montoDefecto.toStringAsFixed(2) : '');
  }

  @override
  void dispose() {
    _montoCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirmarCobro() async {
    final monto = double.tryParse(_montoCtrl.text.trim()) ?? 0.0;
    if (monto <= 0) {
      _mostrarSnack('Ingresa un monto válido mayor a 0 Bs.');
      return;
    }
    if (monto > (_falta + 0.01)) {
      _mostrarSnack('El monto no puede superar lo que falta pagar (Bs. ${_falta.toStringAsFixed(2)}).');
      return;
    }

    setState(() => _procesando = true);

    try {
      final idUsuario = SesionService.instance.idUsuario ?? 'admin';
      final resultado = await EconomiaRepo.instance.cobrarAConductor(
        idConductor: widget.conductor['id_conductor'].toString(),
        idTipoCuota: widget.idTipoCuota,
        montoACobrar: monto,
        metodo: _metodo,
        idUsuario: idUsuario,
        idCuotaEspecifica: widget.idCuotaEspecifica,
      );

      if (!mounted) return;
      Navigator.pop(context, true);

      // Ofrecer visualización de recibo oficial
      _mostrarDialogoReciboGenerado(resultado);
    } catch (e) {
      if (mounted) {
        setState(() => _procesando = false);
        _mostrarSnack('Error al registrar cobro: $e');
      }
    }
  }

  void _mostrarDialogoReciboGenerado(Map<String, dynamic> datosRecibo) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Color(0xFF10B981)),
            SizedBox(width: 8),
            Text('Cobro Exitoso', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Recibo N° ${datosRecibo['nro_recibo']}'),
            const SizedBox(height: 6),
            Text('Monto: Bs. ${((datosRecibo['monto_pagado'] ?? datosRecibo['monto']) as num?)?.toStringAsFixed(2) ?? '0.00'}'),
            const SizedBox(height: 6),
            const Text('¿Deseas ver o imprimir el recibo oficial en PDF?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F2B5B),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ReciboPdfService.mostrarVistaPrevia(
                context,
                datosRecibo,
              );
            },
            icon: const Icon(Icons.picture_as_pdf, size: 18),
            label: const Text('Ver Recibo'),
          ),
        ],
      ),
    );
  }

  void _mostrarSnack(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: const Color(0xFFDC2626)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nombre = widget.conductor['conductor_nombre']?.toString() ?? 'Conductor';
    final ci = widget.conductor['conductor_ci']?.toString() ?? 'S/CI';
    final foto = widget.conductor['conductor_foto']?.toString();
    final proxMonto = (widget.conductor['proximo_monto_pago'] as num?)?.toDouble() ?? 50.0;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      titlePadding: const EdgeInsets.fromLTRB(22, 20, 22, 10),
      contentPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
      actionsPadding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      title: const Row(
        children: [
          Icon(Icons.payments_rounded, color: Color(0xFF10B981), size: 26),
          SizedBox(width: 10),
          Text(
            'Registrar Cobro',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F2B5B)),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tarjeta del conductor
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  AvatarConductor(
                    foto: foto,
                    nombre: nombre,
                    radio: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nombre,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: Color(0xFF0F2B5B)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'CI: $ci',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Resumen de la cuota
            Text(
              widget.conceptoCuota != null
                  ? widget.conceptoCuota!
                  : 'Cuota: ${widget.cuotaNombre} (Total: Bs. ${_total.toStringAsFixed(2)})',
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  'Ya pagó: Bs. ${_pagado.toStringAsFixed(2)}  •  ',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF059669), fontWeight: FontWeight.bold),
                ),
                Text(
                  'Le falta: Bs. ${_falta.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFFDC2626), fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 22, color: Color(0xFFE2E8F0)),

            // Campo de monto
            TextField(
              controller: _montoCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Monto a Cobrar (Bs.) *',
                prefixText: 'Bs. ',
                prefixStyle: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F2B5B)),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                helperText: 'Acepta abono parcial o liquidación total',
              ),
            ),
            const SizedBox(height: 8),

            // Chips rápidos de monto
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (proxMonto > 0 && proxMonto <= _falta)
                  ActionChip(
                    label: Text('1 Cuota (Bs. ${proxMonto.toStringAsFixed(0)})', style: const TextStyle(fontSize: 11)),
                    backgroundColor: const Color(0xFFEFF6FF),
                    side: const BorderSide(color: Color(0xFFBFDBFE)),
                    onPressed: () => setState(() => _montoCtrl.text = proxMonto.toStringAsFixed(2)),
                  ),
                if ((proxMonto * 2) <= _falta)
                  ActionChip(
                    label: Text('2 Cuotas (Bs. ${(proxMonto * 2).toStringAsFixed(0)})', style: const TextStyle(fontSize: 11)),
                    backgroundColor: const Color(0xFFEFF6FF),
                    side: const BorderSide(color: Color(0xFFBFDBFE)),
                    onPressed: () => setState(() => _montoCtrl.text = (proxMonto * 2).toStringAsFixed(2)),
                  ),
                if (_falta > 0)
                  ActionChip(
                    label: Text('Todo (Bs. ${_falta.toStringAsFixed(0)})', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    backgroundColor: const Color(0xFFECFDF5),
                    side: const BorderSide(color: Color(0xFFA7F3D0)),
                    onPressed: () => setState(() => _montoCtrl.text = _falta.toStringAsFixed(2)),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            const SizedBox(height: 14),

            // Método de pago
            DropdownButtonFormField<String>(
              value: _metodo,
              decoration: InputDecoration(
                labelText: 'Método de Pago',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
              items: const [
                DropdownMenuItem(value: 'efectivo', child: Text('Efectivo')),
                DropdownMenuItem(value: 'qr', child: Text('Pago con QR')),
                DropdownMenuItem(value: 'transferencia', child: Text('Transferencia Bancaria')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _metodo = val);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _procesando ? null : () => Navigator.pop(context, false),
          child: const Text('Cancelar', style: TextStyle(color: Color(0xFF64748B))),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          ),
          onPressed: _procesando ? null : _confirmarCobro,
          child: _procesando
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : const Text('Confirmar Cobro', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
