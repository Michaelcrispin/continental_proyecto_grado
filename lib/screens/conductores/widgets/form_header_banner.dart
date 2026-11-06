import 'package:flutter/material.dart';

const _kVerdeOscuro = Color(0xFF02634C);

/// Banner superior verde corporativo para la pantalla de registro / edición de conductor.
class FormHeaderBanner extends StatelessWidget {
  final String titulo;
  final String? subtitulo;
  final VoidCallback onVolver;

  const FormHeaderBanner({
    super.key,
    required this.titulo,
    this.subtitulo,
    required this.onVolver,
  });

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.of(context).padding;
    final tieneSubtitulo = subtitulo != null && subtitulo!.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16, padding.top + 8, 16, 20),
      decoration: const BoxDecoration(
        color: _kVerdeOscuro,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Botón atrás idéntico a la pantalla de Grupo Continental
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

          // Título principal (y subtítulo opcional si existe)
          Expanded(
            child: tieneSubtitulo
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        titulo,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitulo!,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  )
                : Text(
                    titulo,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      height: 1.15,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
          ),
          const SizedBox(width: 12),

          // Logo Continental en círculo blanco idéntico al de Grupo Continental
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(4),
            child: ClipOval(
              child: Image.asset(
                'assets/images/logo.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.local_taxi_rounded,
                  color: _kVerdeOscuro,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
