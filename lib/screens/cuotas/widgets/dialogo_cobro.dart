import 'package:flutter/material.dart';
import '../../../services/economia_repo.dart';
import '../../../services/sesion_service.dart';
import '../../../widgets/app_snackbar.dart';
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
  }) async {
    final resultado = await showDialog<dynamic>(
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

    if (resultado is Map && context.mounted) {
      final mapaCobro = Map<String, dynamic>.from(resultado);
      await mostrarExito(
        context,
        monto: (mapaCobro['monto'] as num).toDouble(),
        metodo: mapaCobro['metodo']?.toString() ?? 'efectivo',
        conductorNombre:
            conductor['conductor_nombre']?.toString() ?? 'Conductor',
        conductorCi: conductor['conductor_ci']?.toString() ?? '',
        cuotaNombre: cuotaNombre,
      );
      return true;
    }
    return false;
  }

  /// Modal de confirmación de "Cobro Realizado" elegante, amplio y moderno
  static Future<void> mostrarExito(
    BuildContext context, {
    required double monto,
    required String metodo,
    required String conductorNombre,
    required String conductorCi,
    required String cuotaNombre,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icono verde grande con halo suave
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1FAE5),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withValues(alpha: 0.22),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF059669),
                    size: 42,
                  ),
                ),
                const SizedBox(height: 16),

                // Título Cobro Realizado
                const Text(
                  'Cobro Realizado',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F2B5B),
                    letterSpacing: -0.3,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  cuotaNombre,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 18),

                // Tarjeta grande y destacada del Monto
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF0FDF4), Color(0xFFDCFCE7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFF86EFAC)),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'MONTO COBRADO',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF15803D),
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Bs. ${monto.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F2B5B),
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Tarjeta de detalles del cobro
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.person_rounded,
                            size: 18,
                            color: Color(0xFF64748B),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Conductor:',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const Spacer(),
                          Flexible(
                            child: Text(
                              conductorNombre,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F2B5B),
                              ),
                              textAlign: TextAlign.end,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (conductorCi.isNotEmpty) ...[
                        const Divider(height: 14, color: Color(0xFFEEF2F6)),
                        Row(
                          children: [
                            const Icon(
                              Icons.badge_outlined,
                              size: 18,
                              color: Color(0xFF64748B),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'CI:',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              conductorCi,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F2B5B),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const Divider(height: 14, color: Color(0xFFEEF2F6)),
                      Row(
                        children: [
                          Icon(
                            metodo == 'qr'
                                ? Icons.qr_code_2_rounded
                                : Icons.payments_outlined,
                            size: 18,
                            color: metodo == 'qr'
                                ? const Color(0xFF2563EB)
                                : const Color(0xFF059669),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Método:',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            metodo == 'qr' ? 'Pago con QR' : 'Efectivo',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: metodo == 'qr'
                                  ? const Color(0xFF2563EB)
                                  : const Color(0xFF059669),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // Botón Aceptar a ancho completo
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00B074),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text(
                      'Aceptar',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
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
  late double _falta;

  @override
  void initState() {
    super.initState();
    _total = (widget.conductor['monto_total'] as num?)?.toDouble() ?? 0.0;
    final pagado = (widget.conductor['monto_pagado'] as num?)?.toDouble() ?? 0.0;
    _falta = (widget.conductor['monto_falta'] as num?)?.toDouble() ?? (_total - pagado);
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
      await EconomiaRepo.instance.cobrarAConductor(
        idConductor: widget.conductor['id_conductor'].toString(),
        idTipoCuota: widget.idTipoCuota,
        montoACobrar: monto,
        metodo: _metodo,
        idUsuario: idUsuario,
        idCuotaEspecifica: widget.idCuotaEspecifica,
      );

      if (!mounted) return;
      Navigator.pop(context, {'monto': monto, 'metodo': _metodo});
    } catch (e) {
      if (mounted) {
        setState(() => _procesando = false);
        _mostrarSnack('Error al registrar cobro: $e');
      }
    }
  }

  void _mostrarSnack(String mensaje) {
    AppSnackBar.error(context, mensaje);
  }

  @override
  Widget build(BuildContext context) {
    final nombre =
        widget.conductor['conductor_nombre']?.toString() ?? 'Conductor';
    final ci = widget.conductor['conductor_ci']?.toString() ?? 'S/CI';
    final foto = widget.conductor['conductor_foto']?.toString();
    final telefono = widget.conductor['conductor_telefono']?.toString();

    return PopScope(
      canPop: !_procesando,
      child: Dialog(
        backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cabecera elegante
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD1FAE5),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.payments_rounded,
                        color: Color(0xFF059669),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Registrar Cobro',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                              color: Color(0xFF0F2B5B),
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.cuotaNombre,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Color(0xFF94A3B8),
                        size: 22,
                      ),
                      splashRadius: 20,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Tarjeta del conductor
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      AvatarConductor(
                        foto: foto,
                        nombre: nombre,
                        radio: 22,
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
                                fontSize: 15,
                                color: Color(0xFF0F2B5B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'CI: $ci${telefono != null && telefono.isNotEmpty ? '  •  Cel: $telefono' : ''}',
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Campo de monto
                const Text(
                  'Monto a Cobrar (Bs.) *',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _montoCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    color: Color(0xFF0F2B5B),
                  ),
                  decoration: InputDecoration(
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(left: 14, right: 6),
                      child: Text(
                        'Bs.',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: Color(0xFF059669),
                        ),
                      ),
                    ),
                    prefixIconConstraints:
                        const BoxConstraints(minWidth: 0, minHeight: 0),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: Color(0xFFCBD5E1),
                        width: 1.2,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: Color(0xFF00B074),
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Selector moderno de Método de Pago
                const Text(
                  'Método de Pago',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetodoOption(
                        id: 'efectivo',
                        label: 'Efectivo',
                        icono: Icons.payments_outlined,
                        colorActivo: const Color(0xFF00B074),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildMetodoOption(
                        id: 'qr',
                        label: 'Pago con QR',
                        icono: Icons.qr_code_2_rounded,
                        colorActivo: const Color(0xFF2563EB),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Botones de acción alineados y modernos
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          side: const BorderSide(
                            color: Color(0xFFCBD5E1),
                            width: 1.2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: _procesando
                            ? null
                            : () => Navigator.pop(context),
                        child: const Text(
                          'Cancelar',
                          style: TextStyle(
                            color: Color(0xFF475569),
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00B074),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: _procesando ? null : _confirmarCobro,
                        child: _procesando
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Confirmar Cobro',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14.5,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ));
  }

  Widget _buildMetodoOption({
    required String id,
    required String label,
    required IconData icono,
    required Color colorActivo,
  }) {
    final seleccionado = _metodo == id;
    return InkWell(
      onTap: () => setState(() => _metodo = id),
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: seleccionado
              ? colorActivo.withValues(alpha: 0.08)
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: seleccionado ? colorActivo : const Color(0xFFE2E8F0),
            width: seleccionado ? 1.8 : 1.2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icono,
              size: 20,
              color: seleccionado ? colorActivo : const Color(0xFF64748B),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                      seleccionado ? FontWeight.bold : FontWeight.w500,
                  color: seleccionado ? colorActivo : const Color(0xFF475569),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
