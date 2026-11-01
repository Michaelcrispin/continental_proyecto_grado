import 'package:flutter/material.dart';

/// Banner superior azul marino para la pantalla de registro / edición de conductor.
class FormHeaderBanner extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final VoidCallback onVolver;

  const FormHeaderBanner({
    super.key,
    required this.titulo,
    required this.subtitulo,
    required this.onVolver,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.of(context).padding.top + 10,
        16,
        20,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F265C), Color(0xFF1E3A8A), Color(0xFF1D4ED8)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(26)),
        boxShadow: [
          BoxShadow(
            color: Color(0x331E3A8A),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  tooltip: 'Volver',
                  onPressed: onVolver,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitulo,
                      style: const TextStyle(
                        color: Color(0xFFBFDBFE),
                        fontSize: 11.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Image.asset(
                'assets/images/logo.png',
                height: 34,
                errorBuilder: (c, e, s) =>
                    const Icon(Icons.local_taxi_rounded, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
