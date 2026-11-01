import 'package:flutter/material.dart';

/// Modal estilizado para visualizar los detalles del recibo / comprobante de pago
/// en interfaz nativa (reemplaza el visor PDF por una tarjeta visual estética).
class DialogoReciboModal extends StatelessWidget {
  final Map<String, dynamic> datos;

  const DialogoReciboModal({
    super.key,
    required this.datos,
  });

  /// Muestra el modal estético de recibo en el contexto proporcionado.
  static Future<void> mostrar(
    BuildContext context,
    Map<String, dynamic> datos,
  ) async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => DialogoReciboModal(datos: datos),
    );
  }

  String _formatearFechaLarga(dynamic fechaRaw) {
    if (fechaRaw == null || fechaRaw.toString().trim().isEmpty) {
      return 'Fecha no especificada';
    }
    try {
      final f = DateTime.parse(fechaRaw.toString().trim());
      const dias = [
        'Lunes',
        'Martes',
        'Miércoles',
        'Jueves',
        'Viernes',
        'Sábado',
        'Domingo',
      ];
      const meses = [
        'Enero',
        'Febrero',
        'Marzo',
        'Abril',
        'Mayo',
        'Junio',
        'Julio',
        'Agosto',
        'Septiembre',
        'Octubre',
        'Noviembre',
        'Diciembre',
      ];
      final diaSem = dias[f.weekday - 1];
      final mes = meses[f.month - 1];
      final hora = f.hour.toString().padLeft(2, '0');
      final min = f.minute.toString().padLeft(2, '0');
      if (f.hour != 0 || f.minute != 0) {
        return '$diaSem, ${f.day} de $mes de ${f.year} • $hora:$min';
      }
      return '$diaSem, ${f.day} de $mes de ${f.year}';
    } catch (_) {
      return fechaRaw.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final conductorNombre =
        datos['conductor_nombre']?.toString() ?? 'Conductor no especificado';
    final conductorCi = datos['conductor_ci']?.toString() ?? '';
    final concepto =
        datos['concepto']?.toString() ??
        datos['tipo_nombre']?.toString() ??
        'Cuota Sindicato';
    final tipoNombre = datos['tipo_nombre']?.toString() ?? 'Cuota';
    final montoPagado = (datos['monto_pagado'] as num?)?.toDouble() ?? 0.0;
    final totalCuota = (datos['total_cuota'] as num?)?.toDouble() ?? montoPagado;
    final saldoRestante = (datos['saldo_restante'] as num?)?.toDouble() ?? 0.0;
    final metodo = (datos['metodo']?.toString() ?? 'efectivo').toLowerCase();
    final fechaRaw = datos['fecha'] ?? datos['created_at'];
    final fechaFormateada = _formatearFechaLarga(fechaRaw);
    final cobrador =
        datos['cobrador_nombre']?.toString() ?? 'Secretaría de Hacienda';
    final observacion = datos['observacion']?.toString();

    // Obtener iniciales del conductor
    final partes = conductorNombre.trim().split(RegExp(r'\s+'));
    final iniciales = partes.length >= 2
        ? '${partes[0][0]}${partes[1][0]}'.toUpperCase()
        : conductorNombre.isNotEmpty
            ? conductorNombre.substring(0, 1).toUpperCase()
            : 'C';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x220F2B5B),
                  blurRadius: 28,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Fila superior con botón cerrar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'COMPROBANTE OFICIAL',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1D4ED8),
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Color(0xFF94A3B8),
                          size: 22,
                        ),
                        splashRadius: 18,
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),

                  // Icono Insignia de Recibo Pagado
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFA7F3D0),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withOpacity(0.18),
                          blurRadius: 16,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF059669),
                      size: 34,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Títulos
                  const Text(
                    'Recibo de Cobro',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F2B5B),
                      letterSpacing: -0.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    'Sindicato Mixto Continental Trufi',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  // Tarjeta grande destacada del Monto Cobrado
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
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
                          'MONTO PAGADO',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF15803D),
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Bs. ${montoPagado.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 27,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F2B5B),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3.5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.verified_rounded,
                                color: Colors.white,
                                size: 13,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'COBRO CONFIRMADO',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Tarjeta con los detalles del cobro
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
                        // Conductor
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: const Color(0xFF3B82F6),
                              child: Text(
                                iniciales,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    conductorNombre,
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0F2B5B),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (conductorCi.isNotEmpty)
                                    Text(
                                      'CI: $conductorCi',
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 16, color: Color(0xFFEEF2F6)),

                        // Cuota / Concepto
                        _buildFilaDetalle(
                          icon: Icons.event_note_rounded,
                          iconColor: const Color(0xFF2563EB),
                          label: 'Cuota:',
                          valorWidget: Text(
                            concepto,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F2B5B),
                            ),
                            textAlign: TextAlign.end,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (concepto != tipoNombre) ...[
                          const SizedBox(height: 8),
                          _buildFilaDetalle(
                            icon: Icons.category_outlined,
                            iconColor: const Color(0xFF64748B),
                            label: 'Categoría:',
                            valorWidget: Text(
                              tipoNombre,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF334155),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                        const Divider(height: 16, color: Color(0xFFEEF2F6)),

                        // Fecha de Cobro
                        _buildFilaDetalle(
                          icon: Icons.calendar_today_rounded,
                          iconColor: const Color(0xFFD97706),
                          label: 'Fecha de pago:',
                          valorWidget: Text(
                            fechaFormateada,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0F2B5B),
                            ),
                            textAlign: TextAlign.end,
                          ),
                        ),
                        const Divider(height: 16, color: Color(0xFFEEF2F6)),

                        // Método de Pago
                        _buildFilaDetalle(
                          icon: metodo == 'qr'
                              ? Icons.qr_code_2_rounded
                              : Icons.payments_outlined,
                          iconColor: metodo == 'qr'
                              ? const Color(0xFF2563EB)
                              : const Color(0xFF059669),
                          label: 'Método:',
                          valorWidget: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: metodo == 'qr'
                                  ? const Color(0xFFEFF6FF)
                                  : const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: metodo == 'qr'
                                    ? const Color(0xFFBFDBFE)
                                    : const Color(0xFFA7F3D0),
                              ),
                            ),
                            child: Text(
                              metodo == 'qr' ? 'Pago con QR' : 'Efectivo',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: metodo == 'qr'
                                    ? const Color(0xFF1D4ED8)
                                    : const Color(0xFF059669),
                              ),
                            ),
                          ),
                        ),
                        const Divider(height: 16, color: Color(0xFFEEF2F6)),

                        // Registrado Por
                        _buildFilaDetalle(
                          icon: Icons.admin_panel_settings_outlined,
                          iconColor: const Color(0xFF64748B),
                          label: 'Registrado por:',
                          valorWidget: Text(
                            cobrador,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF475569),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),

                        // Si hubo saldo pendiente en ese momento
                        if (saldoRestante > 0.001) ...[
                          const Divider(height: 16, color: Color(0xFFEEF2F6)),
                          _buildFilaDetalle(
                            icon: Icons.info_outline_rounded,
                            iconColor: const Color(0xFFDC2626),
                            label: 'Saldo restante:',
                            valorWidget: Text(
                              'Bs. ${saldoRestante.toStringAsFixed(2)} de ${totalCuota.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFDC2626),
                              ),
                            ),
                          ),
                        ],

                        // Observación si existe
                        if (observacion != null &&
                            observacion.trim().isNotEmpty) ...[
                          const Divider(height: 16, color: Color(0xFFEEF2F6)),
                          _buildFilaDetalle(
                            icon: Icons.notes_rounded,
                            iconColor: const Color(0xFF64748B),
                            label: 'Nota:',
                            valorWidget: Text(
                              observacion.trim(),
                              style: const TextStyle(
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                                color: Color(0xFF334155),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Botón Cerrar Recibo
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F2B5B),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Cerrar Recibo',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilaDetalle({
    required IconData icon,
    required Color iconColor,
    required String label,
    required Widget valorWidget,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: valorWidget,
          ),
        ),
      ],
    );
  }
}

