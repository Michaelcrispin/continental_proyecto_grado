import 'package:flutter/material.dart';

/// Tarjeta moderna e interactiva para cada Cuota (Vista UI Cuotas).
/// Refleja fielmente el diseño de tarjetas con ícono temático, título,
/// badge de estado ('En cobro', 'Pendiente', 'Completada'), motivo y monto por chofer.
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
    final estado = cuota['estado_calculado']?.toString().toLowerCase() ?? 'pendiente';

    final categoria = cuota['categoria']?.toString();
    final theme = _getCuotaTheme(nombre, index, categoria: categoria);
    final badge = _getBadgeInfo(estado);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080F2B5B),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          splashColor: theme.color.withOpacity(0.08),
          highlightColor: theme.color.withOpacity(0.04),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Fila superior: Ícono + Título + Badge de estado
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Círculo con ícono
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: theme.bgColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        theme.icon,
                        color: theme.color,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Título y motivo
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Text(
                                  nombre,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15.5,
                                    color: Color(0xFF0F2B5B),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              // Badge de estado ('En cobro', 'Pendiente', 'Completada')
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: badge.bgColor,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: badge.dotColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      badge.label,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: badge.textColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            (descripcion != null && descripcion.trim().isNotEmpty)
                                ? descripcion.trim()
                                : 'Sin motivo registrado',
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFF64748B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                // Separador tenue
                const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 10),

                // Fila inferior: Monto por chofer + Flecha indicadora
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    RichText(
                      text: TextSpan(
                        text: 'Bs. ${_formatearMonto(montoSugerido)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Color(0xFF0F2B5B),
                        ),
                        children: const [
                          TextSpan(
                            text: ' por chofer',
                            style: TextStyle(
                              fontWeight: FontWeight.normal,
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF2563EB),
                      size: 22,
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

  static _CuotaTheme _getCuotaTheme(String nombre, int index, {String? categoria}) {
    final cat = (categoria ?? '').toLowerCase();
    final lower = nombre.toLowerCase();

    if (cat == 'multa' || lower.contains('multa') || lower.contains('reuni')) {
      return const _CuotaTheme(
        icon: Icons.gavel_rounded,
        color: Color(0xFFDC2626),
        bgColor: Color(0xFFFEF2F2),
      );
    }
    if (cat == 'canaston' || lower.contains('canast')) {
      return const _CuotaTheme(
        icon: Icons.card_giftcard_rounded,
        color: Color(0xFFEA580C),
        bgColor: Color(0xFFFFF7ED),
      );
    }
    if (cat == 'deporte' || lower.contains('deport') || lower.contains('campeonato')) {
      return const _CuotaTheme(
        icon: Icons.sports_soccer_rounded,
        color: Color(0xFF0D9488),
        bgColor: Color(0xFFF0FDFA),
      );
    }
    if (cat == 'ayuda' || lower.contains('apoyo') || lower.contains('solidaridad')) {
      return const _CuotaTheme(
        icon: Icons.volunteer_activism_rounded,
        color: Color(0xFF2563EB),
        bgColor: Color(0xFFEFF6FF),
      );
    }
    if (lower.contains('mantenimiento') || lower.contains('reparación') || lower.contains('taller')) {
      return const _CuotaTheme(
        icon: Icons.build_rounded,
        color: Color(0xFF9333EA),
        bgColor: Color(0xFFFAF5FF),
      );
    }
    if (lower.contains('actividad') || lower.contains('sindicato') || lower.contains('social')) {
      return const _CuotaTheme(
        icon: Icons.groups_rounded,
        color: Color(0xFF059669),
        bgColor: Color(0xFFECFDF5),
      );
    }
    if (lower.contains('aporte') || lower.contains('extraordinario') || lower.contains('pro')) {
      return const _CuotaTheme(
        icon: Icons.stars_rounded,
        color: Color(0xFF6366F1),
        bgColor: Color(0xFFEEF2FF),
      );
    }

    // Variaciones cíclicas elegantes
    switch (index % 4) {
      case 0:
        return const _CuotaTheme(
          icon: Icons.account_balance_wallet_rounded,
          color: Color(0xFF2563EB),
          bgColor: Color(0xFFEFF6FF),
        );
      case 1:
        return const _CuotaTheme(
          icon: Icons.build_rounded,
          color: Color(0xFF9333EA),
          bgColor: Color(0xFFFAF5FF),
        );
      case 2:
        return const _CuotaTheme(
          icon: Icons.groups_rounded,
          color: Color(0xFF059669),
          bgColor: Color(0xFFECFDF5),
        );
      default:
        return const _CuotaTheme(
          icon: Icons.stars_rounded,
          color: Color(0xFF6366F1),
          bgColor: Color(0xFFEEF2FF),
        );
    }
  }

  static _BadgeInfo _getBadgeInfo(String estado) {
    switch (estado) {
      case 'en_cobro':
        return const _BadgeInfo(
          label: 'En cobro',
          bgColor: Color(0xFFE8F5E9),
          dotColor: Color(0xFF2E7D32),
          textColor: Color(0xFF2E7D32),
        );
      case 'completada':
        return const _BadgeInfo(
          label: 'Completada',
          bgColor: Color(0xFFD1FAE5),
          dotColor: Color(0xFF059669),
          textColor: Color(0xFF065F46),
        );
      case 'pendiente':
      default:
        return const _BadgeInfo(
          label: 'Pendiente',
          bgColor: Color(0xFFFEF3C7),
          dotColor: Color(0xFFD97706),
          textColor: Color(0xFFB45309),
        );
    }
  }
}

class _CuotaTheme {
  final IconData icon;
  final Color color;
  final Color bgColor;
  const _CuotaTheme({required this.icon, required this.color, required this.bgColor});
}

class _BadgeInfo {
  final String label;
  final Color bgColor;
  final Color dotColor;
  final Color textColor;
  const _BadgeInfo({
    required this.label,
    required this.bgColor,
    required this.dotColor,
    required this.textColor,
  });
}
