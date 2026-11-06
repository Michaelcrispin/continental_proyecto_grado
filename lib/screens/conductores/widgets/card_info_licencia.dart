import 'package:flutter/material.dart';
import '../../../core/documentos_alerta.dart';
import 'detalle_container_card.dart';

/// Tarjeta 3: Información de Licencia de Conducir
class CardInformacionLicencia extends StatelessWidget {
  final Map<String, dynamic> conductor;

  const CardInformacionLicencia({super.key, required this.conductor});

  @override
  Widget build(BuildContext context) {
    final numLicencia = conductor['licencia']?.toString();
    final fechaVence = conductor['licencia_vencimiento']?.toString();
    final fechaEmision = conductor['licencia_emision']?.toString();
    final categoria = conductor['licencia_categoria']?.toString();
    final estadoLic = DocumentosAlerta.estado(fechaVence);
    final colorLic = DocumentosAlerta.color(estadoLic);

    return DetalleContainerCard(
      icon: Icons.badge_outlined,
      title: 'Información de licencia',
      subtitle: 'Datos de la licencia de conducir',
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: DetalleDatoItem(
                  icon: Icons.credit_card_outlined,
                  label: 'Número de licencia',
                  value: (numLicencia != null && numLicencia.trim().isNotEmpty)
                      ? numLicencia
                      : 'No registrado',
                ),
              ),
              Expanded(
                child: DetalleDatoItem(
                  icon: Icons.event_available_outlined,
                  label: 'Fecha de vencimiento',
                  value: (fechaVence != null && fechaVence.trim().isNotEmpty)
                      ? fechaVence
                      : 'No registrado',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: DetalleDatoItem(
                  icon: Icons.drive_eta_outlined,
                  label: 'Categoría',
                  value: (categoria != null && categoria.trim().isNotEmpty)
                      ? categoria
                      : 'No registrado',
                ),
              ),
              Expanded(
                child: DetalleDatoItem(
                  icon: Icons.calendar_today_outlined,
                  label: 'Fecha de emisión',
                  value:
                      (fechaEmision != null && fechaEmision.trim().isNotEmpty)
                      ? fechaEmision
                      : 'No registrado',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Estado de la licencia',
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          estadoLic == 'Vigente'
                              ? Icons.check_circle_rounded
                              : (estadoLic == 'Por vencer'
                                    ? Icons.access_time_filled
                                    : Icons.cancel),
                          color: colorLic,
                          size: 15,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          estadoLic,
                          style: TextStyle(
                            color: colorLic,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Tarjeta 4: Resumen de Documentos y Acceso directo
class CardDocumentosResumen extends StatelessWidget {
  final VoidCallback onVerDocumentos;

  const CardDocumentosResumen({super.key, required this.onVerDocumentos});

  @override
  Widget build(BuildContext context) {
    return DetalleContainerCard(
      icon: Icons.description_outlined,
      title: 'Documentos',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Todos los documentos del conductor se encuentran registrados y validados en el sistema sindical.',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          InkWell(
            onTap: onVerDocumentos,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFE6F4F0),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0x3302634C)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.description, size: 18, color: Color(0xFF02634C)),
                  SizedBox(width: 8),
                  Text(
                    'Ver documentos del conductor',
                    style: TextStyle(
                      color: Color(0xFF02634C),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  SizedBox(width: 6),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: Color(0xFF02634C),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
