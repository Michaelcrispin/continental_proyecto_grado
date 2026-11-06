import 'package:flutter/material.dart';
import '../../../widgets/avatar_conductor.dart';

/// Banner superior azul marino con foto de perfil dinámica, estado y datos del chofer.
class DetalleHeaderBanner extends StatelessWidget {
  final Map<String, dynamic> conductor;
  final bool esActivo;
  final VoidCallback onVolver;
  final VoidCallback onEditar;
  final VoidCallback onCambiarFoto;

  const DetalleHeaderBanner({
    super.key,
    required this.conductor,
    required this.esActivo,
    required this.onVolver,
    required this.onEditar,
    required this.onCambiarFoto,
  });

  @override
  Widget build(BuildContext context) {
    final nombre = conductor['nombre']?.toString() ?? 'Sin nombre';
    final grupo = conductor['grupo']?.toString() ?? '101-127';
    final numInterno = conductor['numero_interno']?.toString();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.of(context).padding.top + 10,
        16,
        24,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF02634C),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Color(0x3302634C),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Barra superior: Volver atrás y botón Editar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                        tooltip: 'Volver',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: onVolver,
                      ),
                      const SizedBox(width: 14),
                      const Text(
                        'Ficha del Conductor',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: onEditar,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit, size: 14, color: Colors.white),
                          SizedBox(width: 6),
                          Text(
                            'Editar',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Datos del Conductor con Avatar
              Row(
                children: [
                  // Avatar circular dinámico con botón de cámara
                  AvatarConductor(
                    foto: conductor['foto']?.toString(),
                    nombre: nombre,
                    radio: 41,
                    mostrarBotonCamara: true,
                    onTap: onCambiarFoto,
                    onTapCamara: onCambiarFoto,
                  ),

                  const SizedBox(width: 16),

                  // Nombre, Estado y Código
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nombre,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            letterSpacing: 0.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: esActivo
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFEF4444),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                esActivo ? 'Habilitado' : 'Inactivo',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Grupo $grupo',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            if (numInterno != null && numInterno.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Móvil #$numInterno',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
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
