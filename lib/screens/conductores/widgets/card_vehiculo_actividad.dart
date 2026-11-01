import 'package:flutter/material.dart';
import '../../gps_screen.dart';
import 'detalle_container_card.dart';

/// Actividad Reciente y Accesos Rápidos
class CardActividadReciente extends StatelessWidget {
  final VoidCallback onIrAsistencias;
  final VoidCallback onIrObservaciones;

  const CardActividadReciente({
    super.key,
    required this.onIrAsistencias,
    required this.onIrObservaciones,
  });

  @override
  Widget build(BuildContext context) {
    return DetalleContainerCard(
      icon: Icons.access_time,
      title: 'Actividad reciente',
      subtitle: 'Accesos y registros del conductor',
      child: Column(
        children: [
          _buildAccionEnlace(
            icon: Icons.calendar_today,
            colorIcon: const Color(0xFF10B981),
            titulo: 'Asistencias',
            subtitulo: 'Consultar registros de asistencias del conductor',
            onTap: onIrAsistencias,
          ),
          const SizedBox(height: 10),
          _buildAccionEnlace(
            icon: Icons.receipt_long_outlined,
            colorIcon: const Color(0xFF3B82F6),
            titulo: 'Historial de observaciones',
            subtitulo: 'Consultar registros de observaciones y sanciones',
            onTap: onIrObservaciones,
          ),
          const SizedBox(height: 10),
          _buildAccionEnlace(
            icon: Icons.location_on,
            colorIcon: const Color(0xFF8B5CF6),
            titulo: 'Ubicación en tiempo real',
            subtitulo: 'Ver ubicación del vehículo en tiempo real',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const GpsScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccionEnlace({
    required IconData icon,
    required Color colorIcon,
    required String titulo,
    required String subtitulo,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorIcon.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: colorIcon, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                      color: Color(0xFF1E3A8A),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitulo,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: Color(0xFF94A3B8),
            ),
          ],
        ),
      ),
    );
  }
}
