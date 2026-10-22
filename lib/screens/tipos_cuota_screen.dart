import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../core/permisos.dart';
import '../services/database_helper.dart';
import '../services/sesion_service.dart';

/// Vista E8: Tipos de Cuota
///
/// Permite al superadmin y tesorero consultar, crear y configurar los tipos de cuota.
/// Muestra monto sugerido y estado activo/inactivo.
/// Protege los 7 tipos base del sistema contra eliminación o renombrado.
class TiposCuotaScreen extends StatefulWidget {
  const TiposCuotaScreen({super.key});

  @override
  State<TiposCuotaScreen> createState() => _TiposCuotaScreenState();
}

class _TiposCuotaScreenState extends State<TiposCuotaScreen> {
  List<Map<String, dynamic>> _tipos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarTipos();
  }

  Future<void> _cargarTipos() async {
    setState(() => _isLoading = true);
    try {
      final db = await DatabaseHelper.instance.database;
      final lista = await db.rawQuery('''
        SELECT * FROM tipo_cuota 
        ORDER BY es_fijo DESC, nombre ASC
      ''');
      if (mounted) {
        setState(() {
          _tipos = lista;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _mostrarDialogoTipo({Map<String, dynamic>? tipoExistente}) {
    final esEdicion = tipoExistente != null;
    final esFijo = (tipoExistente?['es_fijo'] ?? 0) == 1;

    final nombreCtrl = TextEditingController(text: tipoExistente?['nombre'] ?? '');
    final montoCtrl = TextEditingController(
      text: tipoExistente != null
          ? ((tipoExistente['monto_sugerido'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(2)
          : '20.00',
    );
    bool activo = tipoExistente != null ? (tipoExistente['activo'] ?? 1) == 1 : true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            esEdicion ? 'Editar Tipo de Cuota' : 'Nuevo Tipo de Cuota',
            style: const TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (esFijo)
                  Container(
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.lock_outline, size: 16, color: Color(0xFF2563EB)),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Tipo base del sistema. El nombre no se puede modificar para preservar la integridad operativa.',
                            style: TextStyle(fontSize: 11, color: Color(0xFF1E3A8A)),
                          ),
                        ),
                      ],
                    ),
                  ),
                TextField(
                  controller: nombreCtrl,
                  enabled: !esFijo,
                  decoration: InputDecoration(
                    labelText: 'Nombre del Tipo *',
                    hintText: 'Ej. Cuota de Aniversario',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: montoCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Monto Sugerido (Bs.)',
                    prefixText: 'Bs. ',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Estado Activo', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Disponible para cobros y asignaciones', style: TextStyle(fontSize: 11)),
                  value: activo,
                  activeColor: const Color(0xFF10B981),
                  contentPadding: EdgeInsets.zero,
                  onChanged: (val) => setDialogState(() => activo = val),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar', style: TextStyle(color: Color(0xFF64748B))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                final nombre = nombreCtrl.text.trim();
                final monto = double.tryParse(montoCtrl.text.trim()) ?? 0.0;

                if (nombre.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('El nombre es obligatorio.')),
                  );
                  return;
                }

                Navigator.pop(ctx);
                final db = await DatabaseHelper.instance.database;
                final now = DateTime.now().toIso8601String();

                try {
                  if (esEdicion) {
                    await db.update(
                      'tipo_cuota',
                      {
                        if (!esFijo) 'nombre': nombre,
                        'monto_sugerido': monto,
                        'activo': activo ? 1 : 0,
                        'updated_at': now,
                        'sincronizado': 0,
                      },
                      where: 'id_tipo_cuota = ?',
                      whereArgs: [tipoExistente['id_tipo_cuota']],
                    );
                  } else {
                    await db.insert('tipo_cuota', {
                      'id_tipo_cuota': const Uuid().v4(),
                      'nombre': nombre,
                      'monto_sugerido': monto,
                      'activo': activo ? 1 : 0,
                      'es_fijo': 0,
                      'created_at': now,
                      'updated_at': now,
                      'sincronizado': 0,
                    });
                  }
                  _cargarTipos();
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final puedeEditar = Permisos.puedeEditar(
      SesionService.instance.rol,
      Permisos.moduloControlEconomico,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text(
          'Tipos de Cuota',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              itemCount: _tipos.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (ctx, index) {
                final t = _tipos[index];
                final nombre = t['nombre']?.toString() ?? '';
                final monto = (t['monto_sugerido'] as num?)?.toDouble() ?? 0.0;
                final esActivo = (t['activo'] ?? 1) == 1;
                final esFijo = (t['es_fijo'] ?? 0) == 1;

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: esFijo ? const Color(0xFFEFF6FF) : const Color(0xFFF1F5F9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          esFijo ? Icons.verified : Icons.receipt_long,
                          color: esFijo ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  nombre,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                if (esFijo) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEFF6FF),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text('BASE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Monto sugerido: Bs. ${monto.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: esActivo ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          esActivo ? 'ACTIVO' : 'INACTIVO',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: esActivo ? const Color(0xFF059669) : const Color(0xFFDC2626),
                          ),
                        ),
                      ),
                      if (puedeEditar) ...[
                        const SizedBox(width: 6),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20, color: Color(0xFF2563EB)),
                          tooltip: 'Editar',
                          onPressed: () => _mostrarDialogoTipo(tipoExistente: t),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: puedeEditar
          ? FloatingActionButton.extended(
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Nuevo Tipo', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () => _mostrarDialogoTipo(),
            )
          : null,
    );
  }
}
