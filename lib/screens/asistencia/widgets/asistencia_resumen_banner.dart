import 'package:flutter/material.dart';

/// Banner de resumen visual con métricas de asistencia del día.
class AsistenciaResumenBanner extends StatelessWidget {
  final int presentes;
  final int tardanzas;
  final int faltas;
  final int total;

  const AsistenciaResumenBanner({
    super.key,
    required this.presentes,
    required this.tardanzas,
    required this.faltas,
    required this.total,
  });

  Widget _buildCard({
    required String label,
    required int count,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 14, color: color),
                  const SizedBox(width: 4),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildCard(
          label: 'A tiempo',
          count: presentes,
          color: const Color(0xFF10B981),
          icon: Icons.check_circle_outline,
        ),
        const SizedBox(width: 8),
        _buildCard(
          label: 'Tardanzas',
          count: tardanzas,
          color: const Color(0xFFF59E0B),
          icon: Icons.alarm,
        ),
        const SizedBox(width: 8),
        _buildCard(
          label: 'Faltas',
          count: faltas,
          color: const Color(0xFFEF4444),
          icon: Icons.highlight_off,
        ),
        const SizedBox(width: 8),
        _buildCard(
          label: 'Total',
          count: total,
          color: const Color(0xFF3B82F6),
          icon: Icons.groups_outlined,
        ),
      ],
    );
  }
}
