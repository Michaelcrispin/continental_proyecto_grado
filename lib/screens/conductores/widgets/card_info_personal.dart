import 'package:flutter/material.dart';
import 'detalle_container_card.dart';

/// Tarjeta 1: Información Personal y Padrón Sindical
class CardInformacionPersonal extends StatelessWidget {
  final Map<String, dynamic> conductor;
  final String ci;

  const CardInformacionPersonal({
    super.key,
    required this.conductor,
    required this.ci,
  });

  @override
  Widget build(BuildContext context) {
    final telefono = conductor['telefono']?.toString();
    final fechaNac = conductor['fecha_nacimiento']?.toString();
    final direccion = conductor['direccion']?.toString();
    final estadoCivil = conductor['estado_civil']?.toString();
    final gmail = conductor['gmail']?.toString();
    final extCi = (conductor['extension_ci'] ?? '').toString().trim();
    final ciConExt = extCi.isNotEmpty ? '$ci $extCi' : ci;
    final grupo = (conductor['grupo'] ?? '101').toString();
    final numInterno = conductor['numero_interno']?.toString();

    return DetalleContainerCard(
      icon: Icons.person,
      title: 'Información personal y padrón',
      subtitle: 'Datos de afiliación sindical y básicos del conductor',
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: DetalleDatoItem(
                  icon: Icons.badge_outlined,
                  label: 'Carnet de identidad',
                  value: ciConExt,
                ),
              ),
              Expanded(
                child: DetalleDatoItem(
                  icon: Icons.groups_outlined,
                  label: 'Grupo Sindical',
                  value: 'Continental $grupo',
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
                  icon: Icons.tag,
                  label: 'N.º Interno (Móvil)',
                  value: (numInterno != null && numInterno.isNotEmpty)
                      ? '#$numInterno'
                      : 'Sin asignar',
                ),
              ),
              Expanded(
                child: DetalleDatoItem(
                  icon: Icons.phone_outlined,
                  label: 'Teléfono',
                  value: (telefono != null && telefono.trim().isNotEmpty)
                      ? telefono
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
                  icon: Icons.calendar_today_outlined,
                  label: 'Fecha de nacimiento',
                  value: (fechaNac != null && fechaNac.trim().isNotEmpty)
                      ? fechaNac
                      : 'No registrado',
                ),
              ),
              Expanded(
                child: DetalleDatoItem(
                  icon: Icons.email_outlined,
                  label: 'Correo electrónico',
                  value: (gmail != null && gmail.trim().isNotEmpty)
                      ? gmail
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
                  icon: Icons.location_on_outlined,
                  label: 'Dirección',
                  value: (direccion != null && direccion.trim().isNotEmpty)
                      ? direccion
                      : 'No registrado',
                ),
              ),
              Expanded(
                child: DetalleDatoItem(
                  icon: Icons.person_outline,
                  label: 'Estado civil',
                  value: (estadoCivil != null && estadoCivil.trim().isNotEmpty)
                      ? estadoCivil
                      : 'No registrado',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Tarjeta 2: Estado del Conductor (Habilitado / Inactivo y Botón de Baja/Reactivar)
class CardEstadoConductor extends StatelessWidget {
  final Map<String, dynamic> conductor;
  final bool esActivo;
  final ValueChanged<bool> onCambiarEstado;

  const CardEstadoConductor({
    super.key,
    required this.conductor,
    required this.esActivo,
    required this.onCambiarEstado,
  });

  @override
  Widget build(BuildContext context) {
    final fechaReg =
        conductor['fecha_incorporacion']?.toString() ??
        conductor['created_at']?.toString() ??
        '10/06/2024';
    final fechaRegCorta = fechaReg.length >= 10
        ? fechaReg.substring(0, 10)
        : fechaReg;

    final fechaAct = conductor['updated_at']?.toString() ?? '15/09/2026';
    final fechaActCorta = fechaAct.length >= 10
        ? fechaAct.substring(0, 10)
        : fechaAct;

    final fechaBaja = conductor['fecha_baja']?.toString();
    final fechaBajaCorta = (fechaBaja != null && fechaBaja.length >= 10)
        ? fechaBaja.substring(0, 10)
        : fechaBaja;
    final motivoBaja = conductor['motivo_baja']?.toString();

    return DetalleContainerCard(
      icon: Icons.verified_user_outlined,
      title: 'Estado del conductor',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: esActivo
                  ? const Color(0xFF10B981)
                  : const Color(0xFFEF4444),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              esActivo ? 'Habilitado' : 'Inactivo',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 14),
          DetalleDatoItem(
            icon: Icons.calendar_today_outlined,
            label: 'Registrado el',
            value: fechaRegCorta,
          ),
          const SizedBox(height: 10),
          DetalleDatoItem(
            icon: Icons.access_time,
            label: 'Última actualización',
            value: fechaActCorta,
          ),
          if (!esActivo && fechaBajaCorta != null) ...[
            const SizedBox(height: 10),
            DetalleDatoItem(
              icon: Icons.event_busy_outlined,
              label: 'Fecha de baja',
              value: fechaBajaCorta,
            ),
          ],
          if (!esActivo && motivoBaja != null && motivoBaja.isNotEmpty) ...[
            const SizedBox(height: 10),
            DetalleDatoItem(
              icon: Icons.notes_outlined,
              label: 'Motivo de baja',
              value: motivoBaja,
            ),
          ],
          const SizedBox(height: 16),
          // Botón de acción rápida: Dar de baja o Reactivar
          SizedBox(
            width: double.infinity,
            child: esActivo
                ? OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFEF4444),
                      side: const BorderSide(color: Color(0xFFEF4444)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.person_off_outlined, size: 18),
                    label: const Text(
                      'Dar de baja (Inactivar)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: () => onCambiarEstado(true),
                  )
                : ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text(
                      'Reactivar Conductor',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: () => onCambiarEstado(false),
                  ),
          ),
        ],
      ),
    );
  }
}
