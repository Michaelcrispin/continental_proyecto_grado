import 'package:flutter/material.dart';

/// Pestaña con el historial de sanciones, memorándums y observaciones del conductor.
class TabObservaciones extends StatelessWidget {
  final bool isLoading;
  final List<Map<String, dynamic>> sanciones;

  const TabObservaciones({
    super.key,
    required this.isLoading,
    required this.sanciones,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (sanciones.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Column(
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 54,
              color: Color(0xFF10B981),
            ),
            SizedBox(height: 12),
            Text(
              'Conductor sin sanciones ni observaciones',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF1E293B),
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Este chofer mantiene un récord limpio en el grupo sindical.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
            ),
          ],
        ),
      );
    }

    return Column(
      children: sanciones.map((s) {
        final motivo = s['motivo'] ?? 'Observación';
        final monto = s['monto']?.toString() ?? '0';
        final estado = s['estado'] ?? 'pendiente';
        final esPagado = estado.toString().toLowerCase() == 'pagada';

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: esPagado
                      ? const Color(0xFFECFDF5)
                      : const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: esPagado
                      ? const Color(0xFF10B981)
                      : const Color(0xFFEF4444),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      motivo.toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E3A8A),
                      ),
                    ),
                    Text(
                      'Monto: Bs. $monto',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: esPagado
                      ? const Color(0xFFECFDF5)
                      : const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  estado.toString().toUpperCase(),
                  style: TextStyle(
                    color: esPagado
                        ? const Color(0xFF059669)
                        : const Color(0xFFDC2626),
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
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
