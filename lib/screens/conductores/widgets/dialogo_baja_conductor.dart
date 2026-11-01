import 'package:flutter/material.dart';

/// Muestra el modal para dar de baja lógica a un conductor (inactivación).
/// Retorna el [motivo] de baja ingresado (o cadena vacía si no ingresó)
/// si el usuario confirmó, o [null] si canceló.
Future<String?> mostrarDialogoBajaConductor(
  BuildContext context, {
  required String nombre,
}) async {
  final motivoCtrl = TextEditingController();

  final confirmar = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.person_off_outlined, color: Color(0xFFEF4444)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Dar de baja conductor',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Deseas dar de baja a "$nombre"?',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 18, color: Color(0xFFDC2626)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Su estado pasará a "Inactivo". Ningún viaje, cuota, sanción ni historial será eliminado.',
                      style:
                          TextStyle(fontSize: 11.5, color: Color(0xFF991B1B)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: motivoCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Motivo de baja (opcional)',
                hintText: 'Ej. Solicitud voluntaria, mantenimiento, sanción...',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child:
              const Text('Cancelar', style: TextStyle(color: Color(0xFF64748B))),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFEF4444),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text(
            'Dar de baja',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    ),
  );

  if (confirmar == true) {
    return motivoCtrl.text.trim();
  }
  return null;
}
