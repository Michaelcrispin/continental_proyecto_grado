import 'package:flutter/material.dart';
import '../../../core/app_colors.dart';
import '../../../core/documentos_alerta.dart';

/// Pestaña que lista en detalle los documentos del conductor con vigencia y días restantes.
class TabDocumentos extends StatelessWidget {
  final Map<String, dynamic> conductor;
  final String ci;

  const TabDocumentos({
    super.key,
    required this.conductor,
    required this.ci,
  });

  @override
  Widget build(BuildContext context) {
    final licVence = conductor['licencia_vencimiento']?.toString();
    final licEstado = DocumentosAlerta.estado(licVence);
    final licColor = DocumentosAlerta.color(licEstado);
    final licDias = DocumentosAlerta.diasRestantes(licVence);

    final soatVence = conductor['fecha_vencimiento_soat']?.toString();
    final soatEstado = DocumentosAlerta.estado(soatVence);
    final soatColor = DocumentosAlerta.color(soatEstado);
    final soatDias = DocumentosAlerta.diasRestantes(soatVence);

    final ruat = conductor['ruat']?.toString();
    final soatNum = conductor['soat']?.toString();

    final docs = [
      {
        'nombre': 'Cédula de Identidad (CI)',
        'estado': 'Registrado',
        'color': const Color(0xFF10B981),
        'detalle': 'CI: $ci',
        'icono': Icons.badge,
      },
      {
        'nombre': 'Licencia de Conducir',
        'estado': licEstado,
        'color': licColor,
        'detalle': (licVence != null && licVence.isNotEmpty)
            ? 'Vence: $licVence ${licDias != null ? (licDias < 0 ? '• Vencida hace ${-licDias} días' : '• Quedan $licDias días') : ''}'
            : 'Fecha de vencimiento no registrada',
        'icono': Icons.credit_card,
      },
      {
        'nombre': 'SOAT Vehicular',
        'estado': soatEstado,
        'color': soatColor,
        'detalle': (soatVence != null && soatVence.isNotEmpty)
            ? 'Vence: $soatVence ${soatDias != null ? (soatDias < 0 ? '• Vencido hace ${-soatDias} días' : '• Quedan $soatDias días') : ''}'
            : (soatNum != null && soatNum.isNotEmpty
                  ? 'Póliza: $soatNum (Sin fecha)'
                  : 'No registrado'),
        'icono': Icons.security,
      },
      {
        'nombre': 'RUAT / Registro de Vehículo',
        'estado': (ruat != null && ruat.isNotEmpty)
            ? 'Registrado'
            : 'No registrado',
        'color': (ruat != null && ruat.isNotEmpty)
            ? const Color(0xFF10B981)
            : const Color(0xFF94A3B8),
        'detalle': (ruat != null && ruat.isNotEmpty)
            ? 'N° RUAT: $ruat'
            : 'Documento pendiente de registro',
        'icono': Icons.description,
      },
    ];

    return Column(
      children: docs.map((d) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  d['icono'] as IconData,
                  color: AppColors.primaryBlue,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d['nombre'] as String,
                      style: const TextStyle(
                        color: Color(0xFF1E3A8A),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      d['detalle'] as String,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: (d['color'] as Color).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  d['estado'] as String,
                  style: TextStyle(
                    color: d['color'] as Color,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
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
