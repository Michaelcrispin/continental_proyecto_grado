import 'package:flutter/material.dart';
import '../../../core/documentos_alerta.dart';
import '../../../widgets/avatar_conductor.dart';

class ConductorCard extends StatelessWidget {
  final Map<String, dynamic> conductor;
  final VoidCallback onTap;
  final VoidCallback onTapVer;
  final VoidCallback onTapEditar;
  final VoidCallback onTapCambiarEstado;

  const ConductorCard({
    super.key,
    required this.conductor,
    required this.onTap,
    required this.onTapVer,
    required this.onTapEditar,
    required this.onTapCambiarEstado,
  });

  @override
  Widget build(BuildContext context) {
    final nombre = conductor['nombre'] ?? 'Sin nombre';
    final ci = conductor['ci'] ?? 'S/CI';
    final extCi = (conductor['extension_ci'] ?? '').toString().trim();
    final ciDisplay = extCi.isNotEmpty ? '$ci $extCi' : ci;
    final placa = conductor['placa']?.toString();
    final estado = conductor['estado']?.toString() ?? 'activo';
    final esActivo = estado.toLowerCase() == 'activo';
    final grupo = (conductor['grupo'] ?? '101').toString();
    final numInterno = conductor['numero_interno']?.toString();
    final estadoLic = DocumentosAlerta.estado(
      conductor['licencia_vencimiento']?.toString(),
    );
    final estadoSoat = DocumentosAlerta.estado(
      conductor['fecha_vencimiento_soat']?.toString(),
    );
    final tieneAlerta = estadoLic == 'Vencida' ||
        estadoLic == 'Por vencer' ||
        estadoSoat == 'Vencida';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: !esActivo
              ? Border.all(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.5),
                  width: 1.3,
                )
              : tieneAlerta
                  ? Border.all(
                      color: (estadoLic == 'Vencida' || estadoSoat == 'Vencida')
                          ? const Color(0xFFEF4444).withValues(alpha: 0.4)
                          : const Color(0xFFF59E0B).withValues(alpha: 0.4),
                      width: 1.2,
                    )
                  : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fila superior: Avatar circular + Badges de Grupo y Móvil
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AvatarConductor(
                  foto: conductor['foto']?.toString(),
                  nombre: nombre,
                  radio: 21,
                  fontSize: 11,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2.5,
                          ),
                          decoration: BoxDecoration(
                            color: grupo == '101'
                                ? const Color(0xFF1E3A8A)
                                : const Color(0xFF0D9488),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'G-$grupo',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 8.5,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                        if (numInterno != null && numInterno.isNotEmpty) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 2.5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: const Color(0xFFCBD5E1),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              '#$numInterno',
                              style: const TextStyle(
                                color: Color(0xFF334155),
                                fontWeight: FontWeight.bold,
                                fontSize: 8.5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (tieneAlerta) ...[
                      const SizedBox(height: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: DocumentosAlerta.colorFondo(
                            estadoLic == 'Vencida'
                                ? 'Vencida'
                                : estadoLic == 'Por vencer'
                                    ? 'Por vencer'
                                    : 'Vencida',
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          estadoLic == 'Vencida'
                              ? 'Lic. Vencida'
                              : estadoLic == 'Por vencer'
                                  ? 'Lic. vence pronto'
                                  : 'SOAT Vencido',
                          style: TextStyle(
                            color: DocumentosAlerta.color(
                              estadoLic == 'Vencida'
                                  ? 'Vencida'
                                  : estadoLic == 'Por vencer'
                                      ? 'Por vencer'
                                      : 'Vencida',
                            ),
                            fontWeight: FontWeight.bold,
                            fontSize: 8,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Nombre del Conductor
            Text(
              nombre,
              style: const TextStyle(
                color: Color(0xFF1E3A8A),
                fontWeight: FontWeight.bold,
                fontSize: 13.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),

            // CI con extensión
            Row(
              children: [
                const Icon(
                  Icons.badge_outlined,
                  size: 13,
                  color: Color(0xFF64748B),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'CI: $ciDisplay',
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Placa / Auto
            Row(
              children: [
                const Icon(
                  Icons.directions_car_outlined,
                  size: 13,
                  color: Color(0xFF2563EB),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    (placa != null && placa.isNotEmpty) ? placa : 'Sin unidad',
                    style: const TextStyle(
                      color: Color(0xFF2563EB),
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Estado Habilitado / Inactivo
            Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: esActivo
                        ? const Color(0xFF10B981)
                        : const Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  esActivo ? 'Habilitado' : 'Inactivo',
                  style: TextStyle(
                    color: esActivo
                        ? const Color(0xFF10B981)
                        : const Color(0xFFEF4444),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            const Spacer(),

            // Botones de acción: Ver información, Editar y Dar de baja / Reactivar
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(
                      Icons.visibility_outlined,
                      size: 16,
                      color: Color(0xFF475569),
                    ),
                    tooltip: 'Ver información',
                    onPressed: onTapVer,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(
                      Icons.edit,
                      size: 15,
                      color: Color(0xFF3B82F6),
                    ),
                    tooltip: 'Editar',
                    onPressed: onTapEditar,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: esActivo
                        ? const Color(0xFFFEF2F2)
                        : const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      esActivo
                          ? Icons.person_off_outlined
                          : Icons.check_circle_outline,
                      size: 15,
                      color: esActivo
                          ? const Color(0xFFEF4444)
                          : const Color(0xFF10B981),
                    ),
                    tooltip: esActivo
                        ? 'Dar de baja (Inactivar)'
                        : 'Reactivar conductor',
                    onPressed: onTapCambiarEstado,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
