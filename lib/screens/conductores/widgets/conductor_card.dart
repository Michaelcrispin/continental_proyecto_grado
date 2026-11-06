import 'package:flutter/material.dart';
import '../../../core/documentos_alerta.dart';
import '../../../widgets/avatar_conductor.dart';

class ConductorCard extends StatelessWidget {
  final Map<String, dynamic> conductor;
  final int numeroLista;
  final VoidCallback onTap;
  final VoidCallback onTapVer;
  final VoidCallback onTapEditar;
  final VoidCallback onTapCambiarEstado;
  final bool modoLista;

  const ConductorCard({
    super.key,
    required this.conductor,
    required this.numeroLista,
    required this.onTap,
    required this.onTapVer,
    required this.onTapEditar,
    required this.onTapCambiarEstado,
    this.modoLista = false,
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
    final numInterno = conductor['numero_interno']?.toString();
    final estadoLic = DocumentosAlerta.estado(
      conductor['licencia_vencimiento']?.toString(),
    );
    final estadoSoat = DocumentosAlerta.estado(
      conductor['fecha_vencimiento_soat']?.toString(),
    );
    final tieneAlerta =
        estadoLic == 'Vencida' ||
        estadoLic == 'Por vencer' ||
        estadoSoat == 'Vencida';

    if (modoLista) {
      return _buildModoLista(
        context: context,
        nombre: nombre,
        ciDisplay: ciDisplay,
        placa: placa,
        esActivo: esActivo,
        numInterno: numInterno,
        tieneAlerta: tieneAlerta,
        estadoLic: estadoLic,
        estadoSoat: estadoSoat,
      );
    }

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
            // Fila superior: Avatar del conductor restaurado + Número arribita
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar del conductor restaurado
                AvatarConductor(
                  foto: conductor['foto']?.toString(),
                  nombre: nombre,
                  radio: 21,
                  fontSize: 11,
                ),
                // Arribita de la columna: número de lista ("solo número")
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5EF),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: const Color(0xFF02634C).withOpacity(0.2),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    '$numeroLista',
                    style: const TextStyle(
                      color: Color(0xFF02634C),
                      fontWeight: FontWeight.w800,
                      fontSize: 11.5,
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (numInterno != null && numInterno.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFFCBD5E1),
                            width: 1.0,
                          ),
                        ),
                        child: Text(
                          '#$numInterno',
                          style: const TextStyle(
                            color: Color(0xFF0F2B5B),
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
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

  Widget _buildModoLista({
    required BuildContext context,
    required String nombre,
    required String ciDisplay,
    required String? placa,
    required bool esActivo,
    required String? numInterno,
    required bool tieneAlerta,
    required String estadoLic,
    required String estadoSoat,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          splashColor: const Color(0xFF02634C).withOpacity(0.08),
          highlightColor: const Color(0xFF02634C).withOpacity(0.04),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            child: Row(
              children: [
                // 1. Avatar del conductor (Restaurado)
                AvatarConductor(
                  foto: conductor['foto']?.toString(),
                  nombre: nombre,
                  radio: 22,
                  fontSize: 12,
                ),
                const SizedBox(width: 14),

                // 2. Información del conductor (Nombre, Placa, Estado)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Arribita de la columna: solo el número de lista
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        margin: const EdgeInsets.only(bottom: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5EF),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: const Color(0xFF02634C).withOpacity(0.2),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          '$numeroLista',
                          style: const TextStyle(
                            color: Color(0xFF02634C),
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      Text(
                        nombre,
                        style: const TextStyle(
                          color: Color(0xFF1E293B),
                          fontWeight: FontWeight.bold,
                          fontSize: 15.5,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(
                            Icons.directions_car_rounded,
                            size: 14,
                            color: Color(0xFF64748B),
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              (placa != null && placa.isNotEmpty)
                                  ? placa
                                  : 'Sin unidad asignada',
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
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
                                  ? const Color(0xFF059669)
                                  : const Color(0xFFEF4444),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                        ],
                      ),
                    ],
                  ),
                ),

                // 3. Ícono Chevron para navegar al detalle
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF02634C),
                  size: 26,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
