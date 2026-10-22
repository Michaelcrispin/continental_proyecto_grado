import 'package:flutter/material.dart';
import '../core/permisos.dart';
import '../models/usuario_model.dart';
import '../services/database_helper.dart';
import '../services/economia_repo.dart';
import '../services/sesion_service.dart';
import '../widgets/avatar_conductor.dart';

/// Vista E7: Cobro Masivo
///
/// Permite generar una misma obligación económica a todos los conductores activos
/// (por ejemplo: "Canastón Navideño", "Rifas de Aniversario", "Aporte Extraordinario")
/// en una sola transacción atómica con identificador de lote (id_lote).
class CobroMasivoScreen extends StatefulWidget {
  const CobroMasivoScreen({super.key});

  @override
  State<CobroMasivoScreen> createState() => _CobroMasivoScreenState();
}

class _CobroMasivoScreenState extends State<CobroMasivoScreen> {
  final _formKey = GlobalKey<FormState>();

  List<Map<String, dynamic>> _conductoresActivos = [];
  final Set<String> _idsExcluidos = {};

  List<Map<String, dynamic>> _tiposCuota = [];
  String? _idTipoSeleccionado;

  final TextEditingController _montoCtrl = TextEditingController(text: '150');
  final TextEditingController _conceptoCtrl =
      TextEditingController(text: 'Canastón Navideño ${DateTime.now().year}');
  final TextEditingController _venceCtrl = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!Permisos.puedeEditar(
          SesionService.instance.rol, Permisos.moduloControlEconomico)) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No tienes permisos para registrar cobros masivos.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    });
    _cargarDatos();
  }

  @override
  void dispose() {
    _montoCtrl.dispose();
    _conceptoCtrl.dispose();
    _venceCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);
    try {
      final todos = await DatabaseHelper.instance.conductoresConAuto();
      final activos = todos.where((c) {
        final est = c['estado']?.toString().toLowerCase() ?? 'activo';
        return est == 'activo';
      }).toList();

      final tipos = await DatabaseHelper.instance.listar('tipo_cuota');
      final tiposActivos = tipos.where((t) => (t['activo'] ?? 1) == 1).toList();

      if (mounted) {
        setState(() {
          _conductoresActivos = activos;
          _tiposCuota = tiposActivos;

          if (tiposActivos.isNotEmpty) {
            // Preseleccionar "Canastón" si existe
            final canaston = tiposActivos.firstWhere(
              (t) => t['nombre']?.toString().toLowerCase().contains('canast') == true,
              orElse: () => tiposActivos.first,
            );
            _idTipoSeleccionado = canaston['id_tipo_cuota']?.toString();
            final sug = (canaston['monto_sugerido'] as num?)?.toDouble() ?? 0.0;
            if (sug > 0) {
              _montoCtrl.text = sug.toStringAsFixed(2);
            }
          }

          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onCambioTipo(String? idTipo) {
    if (idTipo == null) return;
    setState(() {
      _idTipoSeleccionado = idTipo;
      final tipo = _tiposCuota.firstWhere(
        (t) => t['id_tipo_cuota']?.toString() == idTipo,
        orElse: () => {},
      );
      if (tipo.isNotEmpty) {
        final sug = (tipo['monto_sugerido'] as num?)?.toDouble() ?? 0.0;
        if (sug > 0) {
          _montoCtrl.text = sug.toStringAsFixed(2);
        }
      }
    });
  }

  Future<void> _seleccionarFechaVence() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 30)),
      firstDate: now,
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) {
      setState(() {
        _venceCtrl.text = picked.toIso8601String().substring(0, 10);
      });
    }
  }

  Future<void> _procesarCobroMasivo() async {
    if (!_formKey.currentState!.validate()) return;
    if (_idTipoSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona el tipo de cuota.')),
      );
      return;
    }

    final monto = double.tryParse(_montoCtrl.text.trim()) ?? 0.0;
    if (monto <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El monto individual debe ser mayor a 0 Bs.')),
      );
      return;
    }

    final cantSeleccionados = _conductoresActivos.length - _idsExcluidos.length;
    if (cantSeleccionados <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay ningún conductor seleccionado para aplicar el cobro.')),
      );
      return;
    }

    final totalBs = monto * cantSeleccionados;
    final concepto = _conceptoCtrl.text.trim();

    // Diálogo de confirmación con vista previa
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.campaign, color: Color(0xFF2563EB), size: 28),
            SizedBox(width: 10),
            Text('Confirmar Cobro Masivo'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Estás seguro de crear esta deuda en bloque para $cantSeleccionados conductores activos?',
              style: const TextStyle(fontSize: 13.5),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Concepto:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      Text(concepto, style: const TextStyle(fontSize: 12, color: Color(0xFF1E3A8A))),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Monto individual:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      Text('Bs. ${monto.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, color: Color(0xFF1E3A8A))),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total a generar:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E3A8A))),
                      Text('Bs. ${totalBs.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF10B981))),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Crear Deudas'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    final idUsuario = SesionService.instance.idUsuario ??
        Usuario.currentUser?.id ??
        'superadmin';

    setState(() => _isSaving = true);
    try {
      final res = await EconomiaRepo.instance.crearCobroMasivo(
        idTipoCuota: _idTipoSeleccionado!,
        monto: monto,
        concepto: concepto,
        fechaVencimiento: _venceCtrl.text.trim().isEmpty ? null : _venceCtrl.text.trim(),
        registradoPor: idUsuario,
        idsConductoresExcluidos: _idsExcluidos.toList(),
      );

      if (!mounted) return;
      setState(() => _isSaving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '¡Éxito! Se crearon ${res['cantidad_conductores']} deudas por un total de Bs. ${(res['total_generado_bs'] as num).toStringAsFixed(2)}.',
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cantTotal = _conductoresActivos.length;
    final cantSeleccionados = cantTotal - _idsExcluidos.length;
    final monto = double.tryParse(_montoCtrl.text.trim()) ?? 0.0;
    final totalEstimado = monto * cantSeleccionados;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text(
          'Cobro Masivo (Lote)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              physics: const BouncingScrollPhysics(),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // BANNER DE RESUMEN Y VISTA PREVIA
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1E3A8A).withValues(alpha: 0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.campaign, color: Colors.white, size: 24),
                              SizedBox(width: 8),
                              Text(
                                'Vista Previa del Cobro Masivo',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Se asignará la deuda a $cantSeleccionados de $cantTotal conductores activos.',
                            style: const TextStyle(color: Color(0xFFDBEAFE), fontSize: 13),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Text('TOTAL ESTIMADO A RECAUDAR: ',
                                  style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                              Text(
                                'Bs. ${totalEstimado.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: Color(0xFFA7F3D0),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // FORMULARIO DE DETALLES DEL COBRO
                    _buildTarjetaParametros(),

                    const SizedBox(height: 16),

                    // LISTA DE CONDUCTORES APLICABLES (CON CHECKBOX)
                    _buildTarjetaConductores(cantSeleccionados, cantTotal),

                    const SizedBox(height: 24),

                    // BOTÓN GENERAR COBRO
                    SizedBox(
                      height: 52,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                        ),
                        icon: _isSaving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Icon(Icons.check_circle_outline, size: 22),
                        label: Text(
                          _isSaving
                              ? 'Generando deudas...'
                              : 'Generar Deuda a $cantSeleccionados Conductores',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        onPressed: _isSaving ? null : _procesarCobroMasivo,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTarjetaParametros() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Parámetros de la Cuota Masiva',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 14),

          // 1. Tipo de cuota
          const Text('Tipo de Cuota *',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFCBD5E1)),
              borderRadius: BorderRadius.circular(14),
              color: const Color(0xFFF8FAFC),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: _idTipoSeleccionado,
                items: _tiposCuota.map((t) {
                  return DropdownMenuItem<String>(
                    value: t['id_tipo_cuota'].toString(),
                    child: Text(t['nombre']?.toString() ?? 'Tipo'),
                  );
                }).toList(),
                onChanged: _onCambioTipo,
              ),
            ),
          ),

          const SizedBox(height: 14),

          // 2. Monto individual
          TextFormField(
            controller: _montoCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            decoration: InputDecoration(
              labelText: 'Monto por Conductor (Bs.) *',
              prefixText: 'Bs. ',
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
            ),
            onChanged: (_) => setState(() {}),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'El monto es obligatorio';
              final n = double.tryParse(v.trim());
              if (n == null || n <= 0) return 'Ingrese un monto válido mayor a 0';
              return null;
            },
          ),

          const SizedBox(height: 14),

          // 3. Concepto
          TextFormField(
            controller: _conceptoCtrl,
            decoration: InputDecoration(
              labelText: 'Concepto del Cobro Masivo *',
              hintText: 'Ej. Canastón Navideño 2026',
              prefixIcon: const Icon(Icons.description_outlined, size: 20),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'El concepto es obligatorio' : null,
          ),

          const SizedBox(height: 14),

          // 4. Vencimiento
          InkWell(
            onTap: _seleccionarFechaVence,
            child: IgnorePointer(
              child: TextFormField(
                controller: _venceCtrl,
                decoration: InputDecoration(
                  labelText: 'Fecha de Vencimiento (Opcional)',
                  hintText: 'AAAA-MM-DD',
                  prefixIcon: const Icon(Icons.calendar_month_outlined, size: 20),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTarjetaConductores(int cantSeleccionados, int cantTotal) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Conductores Activos ($cantSeleccionados / $cantTotal)',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
              ),
              Row(
                children: [
                  TextButton(
                    onPressed: () => setState(() => _idsExcluidos.clear()),
                    child: const Text('Todos', style: TextStyle(fontSize: 12)),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _idsExcluidos.addAll(
                          _conductoresActivos
                              .map((c) => c['id_conductor']?.toString() ?? ''),
                        );
                      });
                    },
                    child: const Text('Ninguno', style: TextStyle(fontSize: 12, color: Colors.red)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Puedes desmarcar conductores que tengan licencia o exoneración.',
            style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _conductoresActivos.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (ctx, i) {
              final c = _conductoresActivos[i];
              final id = c['id_conductor']?.toString() ?? '';
              final estaIncluido = !_idsExcluidos.contains(id);

              return CheckboxListTile(
                value: estaIncluido,
                activeColor: const Color(0xFF2563EB),
                contentPadding: EdgeInsets.zero,
                secondary: AvatarConductor(
                  foto: c['foto']?.toString(),
                  nombre: c['nombre']?.toString() ?? '',
                  radio: 18,
                  fontSize: 10,
                ),
                title: Text(
                  c['nombre']?.toString() ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                subtitle: Text('CI: ${c['ci'] ?? 'S/CI'} • ${c['placa'] ?? 'Sin auto'}',
                    style: const TextStyle(fontSize: 11)),
                onChanged: (val) {
                  setState(() {
                    if (val == true) {
                      _idsExcluidos.remove(id);
                    } else {
                      _idsExcluidos.add(id);
                    }
                  });
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
