import 'package:flutter/material.dart';
import '../../../core/documentos_alerta.dart';
import 'card_info_licencia.dart';
import 'card_info_personal.dart';

/// Pestaña 0: Información General del Conductor.
class TabInfoGeneral extends StatelessWidget {
  final Map<String, dynamic> conductor;
  final String ci;
  final String nombre;
  final bool esActivo;
  final ValueChanged<bool> onCambiarEstado;
  final ValueChanged<int> onIrATab;

  const TabInfoGeneral({
    super.key,
    required this.conductor,
    required this.ci,
    required this.nombre,
    required this.esActivo,
    required this.onCambiarEstado,
    required this.onIrATab,
  });

  @override
  Widget build(BuildContext context) {
    final licVence = conductor['licencia_vencimiento']?.toString();
    final soatVence = conductor['fecha_vencimiento_soat']?.toString();
    final licEstado = DocumentosAlerta.estado(licVence);
    final soatEstado = DocumentosAlerta.estado(soatVence);
    final hayAlerta =
        licEstado == 'Vencida' ||
        licEstado == 'Por vencer' ||
        soatEstado == 'Vencida' ||
        soatEstado == 'Por vencer';

    return Column(
      children: [
        if (hayAlerta) ...[
          _buildBannerAlertaVencimiento(licEstado, soatEstado),
          const SizedBox(height: 16),
        ],

        // Fila 1: Información Personal & Estado del Conductor
        CardInformacionPersonal(conductor: conductor, ci: ci),
        const SizedBox(height: 16),
        CardEstadoConductor(
          conductor: conductor,
          esActivo: esActivo,
          onCambiarEstado: onCambiarEstado,
        ),
        const SizedBox(height: 16),

        // Fila 2: Información de Licencia & Documentos
        CardInformacionLicencia(conductor: conductor),
        const SizedBox(height: 16),
        CardDocumentosResumen(onVerDocumentos: () => onIrATab(1)),
        const SizedBox(height: 20),

        // Mensaje de pie sindical
        const Row(
          children: [
            Icon(Icons.info_outline, size: 16, color: Color(0xFF64748B)),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Esta información es oficial de consulta sindical de la ficha del conductor.',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBannerAlertaVencimiento(String licEstado, String soatEstado) {
    final esCritico = licEstado == 'Vencida' || soatEstado == 'Vencida';
    final color = esCritico ? const Color(0xFFDC2626) : const Color(0xFFD97706);
    final bg = esCritico ? const Color(0xFFFEF2F2) : const Color(0xFFFFFBEB);
    final border = esCritico
        ? const Color(0xFFFECACA)
        : const Color(0xFFFDE68A);

    return InkWell(
      onTap: () => onIrATab(1),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: color, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    esCritico
                        ? '¡Alerta de Documento Vencido!'
                        : 'Aviso: Documento por Vencer',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: esCritico
                          ? const Color(0xFF991B1B)
                          : const Color(0xFF92400E),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Revisa los documentos del conductor. Toca aquí para ver detalles.',
                    style: TextStyle(
                      color: esCritico
                          ? const Color(0xFFB91C1C)
                          : const Color(0xFFB45309),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 12, color: color),
          ],
        ),
      ),
    );
  }
}
