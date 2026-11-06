import 'package:flutter/material.dart';

const _kVerdeOscuro = Color(0xFF02634C);

/// Tarjeta moderna e interactiva para cada Cuota (Diseño Verde Corporativo).
/// Presenta:
/// - Ícono en círculo (con íconos temáticos y de la pantalla de inicio en verde corporativo).
/// - Título, subtítulo y FECHA visible destacada.
/// - Monto por chofer en verde en la esquina superior derecha.
/// - Barra de progreso en verde corporativo (LinearProgressIndicator).
/// - Pie con "X de Y pagaron" y etiqueta de estado ("Completa" / "En cobro").
class CuotaCard extends StatelessWidget {
  final Map<String, dynamic> cuota;
  final int index;
  final VoidCallback onTap;

  const CuotaCard({
    super.key,
    required this.cuota,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final nombre = cuota['nombre']?.toString() ?? 'Cuota';
    final descripcion = cuota['descripcion']?.toString();
    final montoSugerido = (cuota['monto_sugerido'] as num?)?.toDouble() ?? 0.0;
    final totalConductores = (cuota['total_conductores'] as num?)?.toInt() ?? 0;
    final cantPagados = (cuota['cant_pagados'] as num?)?.toInt() ?? 0;
    final categoria = cuota['categoria']?.toString();
    final fechaRaw = cuota['fecha'] ?? cuota['created_at'];
    final fecha = _formatearFecha(fechaRaw);

    final total = totalConductores > 0 ? totalConductores : 1;
    final progreso = (cantPagados / total).clamp(0.0, 1.0);
    final esCompleta = (cantPagados >= totalConductores && totalConductores > 0) ||
        cuota['estado_calculado'] == 'completada';

    final icono = _getIcono(nombre, categoria: categoria);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
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
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Fila superior: Ícono en círculo + Título / Subtítulo / Fecha + Monto por chofer
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Círculo con ícono en tono suave verde
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE6F4F0),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icono,
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
                            nombre,
                            style: const TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.bold,
                              color: _kVerdeOscuro,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (descripcion != null && descripcion.trim().isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              descripcion.trim(),
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF64748B),
                                height: 1.25,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
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

                    // Monto y "por chofer"
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Bs. ${_formatearMonto(montoSugerido)}',
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

                // 3. Fila inferior: "X de Y pagaron" + Estado ("Completa" / "En cobro")
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$cantPagados de $totalConductores pagaron',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      esCompleta ? 'Completa' : 'En cobro',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: esCompleta
                            ? _kVerdeOscuro
                            : const Color(0xFF64748B),
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

  static String _formatearMonto(double monto) {
    if (monto % 1 == 0) {
      return monto.toInt().toString();
    }
    return monto.toStringAsFixed(2);
  }

  static String _formatearFecha(dynamic raw) {
    if (raw == null) return '';
    final str = raw.toString().trim();
    if (str.isEmpty) return '';
    try {
      final dt = DateTime.parse(str);
      final dia = dt.day.toString().padLeft(2, '0');
      final mes = dt.month.toString().padLeft(2, '0');
      final anio = dt.year.toString();
      return '$dia/$mes/$anio';
    } catch (_) {
      if (str.length >= 10 && str.contains('-')) {
        final partes = str.substring(0, 10).split('-');
        if (partes.length == 3) {
          return '${partes[2]}/${partes[1]}/${partes[0]}';
        }
      }
      return str;
    }
  }

  static IconData _getIcono(String nombre, {String? categoria}) {
    final cat = (categoria ?? '').toLowerCase();
    final lower = nombre.toLowerCase();

    if (cat == 'ayuda' || lower.contains('apoyo') || lower.contains('solidaridad')) {
      return Icons.volunteer_activism_outlined;
    }
    if (cat == 'canaston' || lower.contains('canast')) {
      return Icons.card_giftcard_rounded;
    }
    if (cat == 'multa' ||
        lower.contains('multa') ||
        lower.contains('falta') ||
        lower.contains('sancion')) {
      return Icons.gavel_rounded;
    }
    if (cat == 'deporte' || lower.contains('deport') || lower.contains('campeonato')) {
      return Icons.sports_soccer_rounded;
    }
    if (lower.contains('mantenimiento') ||
        lower.contains('reparaci') ||
        lower.contains('taller')) {
      return Icons.build_rounded;
    }
    if (lower.contains('reuni') || lower.contains('asamblea')) {
      return Icons.groups_rounded;
    }
    // Icono principal de Cuotas de la pantalla de inicio
    return Icons.account_balance_wallet_rounded;
  }
}
