import 'package:flutter/material.dart';
import '../../../core/app_colors.dart';
import '../../asistencia_screen.dart';

/// Pestaña con el historial de marcas de control y asistencias del chofer.
class TabAsistencias extends StatelessWidget {
  final bool isLoading;
  final List<Map<String, dynamic>> asistencias;

  const TabAsistencias({
    super.key,
    required this.isLoading,
    required this.asistencias,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (asistencias.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              size: 54,
              color: Color(0xFF94A3B8),
            ),
            const SizedBox(height: 12),
            const Text(
              'Sin asistencias registradas',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Las llegadas a Cruce Villadela y Teleférico se mostrarán aquí.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
              ),
              icon: const Icon(Icons.check, color: Colors.white),
              label: const Text(
                'Registrar Asistencia',
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AsistenciaScreen()),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: asistencias.map((a) {
        final punto = a['punto_nombre'] ?? 'Punto de Control';
        final fecha = a['fecha'] ?? '';
        final hora = a['hora_llegada'] ?? '';

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.location_on,
                  color: Color(0xFF10B981),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      punto.toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E3A8A),
                      ),
                    ),
                    Text(
                      '$fecha • $hora',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'REGISTRADO',
                  style: TextStyle(
                    color: Color(0xFF059669),
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
