import 'package:flutter/material.dart';
import '../../gps_screen.dart';
import 'detalle_container_card.dart';

/// Tarjeta 5: Vehículo Asignado (Minibus Trufi)
class CardVehiculoAsignado extends StatelessWidget {
  final Map<String, dynamic> conductor;

  const CardVehiculoAsignado({super.key, required this.conductor});

  @override
  Widget build(BuildContext context) {
    final placa = conductor['placa']?.toString() ?? '1234-ABC';

    return DetalleContainerCard(
      icon: Icons.local_taxi_outlined,
      title: 'Vehículo asignado',
      subtitle: 'Trufi y datos del vehículo',
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 130,
                height: 85,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.asset(
                    'assets/images/trufi_minibus.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, stack) => const Center(
                      child: Icon(
                        Icons.local_taxi_rounded,
                        size: 48,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Trufi N°',
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
                    ),
                    const Text(
                      '101',
                      style: TextStyle(
                        color: Color(0xFF1E3A8A),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Placa',
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: Text(
                        placa.isNotEmpty ? placa : 'Sin placa',
                        style: const TextStyle(
                          color: Color(0xFF2563EB),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: DetalleDatoItem(
                  icon: Icons.drive_file_rename_outline,
                  label: 'Marca / Modelo',
                  value:
                      ((conductor['marca']?.toString() ?? '').isNotEmpty ||
                          (conductor['modelo']?.toString() ?? '').isNotEmpty)
                      ? '${conductor['marca'] ?? ''} ${conductor['modelo'] ?? ''}'.trim()
                      : 'No registrado',
                ),
              ),
              Expanded(
                child: DetalleDatoItem(
                  icon: Icons.palette_outlined,
                  label: 'Color',
                  value: (conductor['color']?.toString().isNotEmpty == true)
                      ? conductor['color'].toString()
                      : 'No registrado',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DetalleDatoItem(
            icon: Icons.people_outline,
            label: 'Capacidad',
            value: conductor['capacidad'] != null
                ? '${conductor['capacidad']} pasajeros'
                : 'No registrado',
          ),
        ],
      ),
    );
  }
}

/// Tarjeta 6: Actividad Reciente y Accesos Rápidos
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
            subtitulo: 'Ver ubicación actual de la trufi (asignada)',
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
