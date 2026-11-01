import 'package:flutter/material.dart';

/// Muestra el modal de confirmación para reactivar a un conductor.
/// Retorna `true` si el usuario confirmó, o `false` si canceló.
Future<bool> mostrarDialogoReactivarConductor(
  BuildContext context, {
  required String nombre,
}) async {
  final confirmar = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.check_circle_outline, color: Color(0xFF10B981)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Reactivar conductor',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: Text(
        '¿Deseas volver a habilitar a "$nombre" en el padrón sindical activo?',
        style: const TextStyle(fontSize: 13.5),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child:
              const Text('Cancelar', style: TextStyle(color: Color(0xFF64748B))),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text(
            'Reactivar',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    ),
  );

  return confirmar ?? false;
}
