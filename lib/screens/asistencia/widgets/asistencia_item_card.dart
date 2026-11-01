import 'package:flutter/material.dart';

/// Tarjeta para visualizar un registro individual de asistencia.
class AsistenciaItemCard extends StatelessWidget {
  final Map<String, dynamic> asistencia;

  const AsistenciaItemCard({
    super.key,
    required this.asistencia,
  });

  Color _obtenerColorEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'presente':
        return const Color(0xFF10B981);
      case 'tardanza':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFFEF4444);
    }
  }

  @override
  Widget build(BuildContext context) {
    final conductorNombre = asistencia['conductor_nombre']?.toString() ?? 'Conductor';
    final puntoNombre = asistencia['punto_nombre']?.toString() ?? 'Punto de control';
    final hora = asistencia['hora_llegada']?.toString() ?? '--:--';
    final estado = (asistencia['estado']?.toString() ?? 'presente').toLowerCase();
    final metodo = (asistencia['metodo']?.toString() ?? 'gps').toLowerCase();
    final minutosRetraso = (asistencia['minutos_retraso'] as num?)?.toInt() ?? 0;
    final esSimulada = (asistencia['es_simulada'] as num?)?.toInt() == 1;
    final justificacion = asistencia['justificacion']?.toString();
    final color = _obtenerColorEstado(estado);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: esSimulada ? Colors.purple.shade200 : const Color(0xFFE2E8F0),
          width: esSimulada ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: color.withOpacity(0.12),
                child: Icon(
                  estado == 'presente'
                      ? Icons.check_circle_outline
                      : (estado == 'tardanza' ? Icons.alarm : Icons.close),
                  color: color,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      conductorNombre,
                      style: const TextStyle(
                        color: Color(0xFF1E3A8A),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 13, color: Color(0xFF64748B)),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            '$puntoNombre • $hora',
                            style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: color.withOpacity(0.4)),
                    ),
                    child: Text(
                      estado.toUpperCase(),
                      style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: esSimulada ? Colors.purple.shade50 : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      esSimulada ? 'SIMULADO' : metodo.toUpperCase(),
                      style: TextStyle(
                        color: esSimulada ? Colors.purple.shade700 : const Color(0xFF64748B),
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Aviso de tardanza y vueltas de castigo asignadas
          if (estado == 'tardanza') ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFFD97706)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Retraso: $minutosRetraso min • 2 vueltas de castigo para la noche (21:00)',
                      style: const TextStyle(
                        color: Color(0xFFB45309),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Justificación si fue registro manual
          if (justificacion != null && justificacion.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Nota: $justificacion',
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
