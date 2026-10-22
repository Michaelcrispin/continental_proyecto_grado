import 'package:flutter/material.dart';
import '../core/permisos.dart';
import '../models/usuario_model.dart';
import '../services/database_helper.dart';
import '../services/economia_repo.dart';
import '../services/sesion_service.dart';
import '../widgets/avatar_conductor.dart';

/// Vista E6: Nueva Deuda (Individual)
///
/// Permite al Secretario de Hacienda / Tesorero asignar una obligación o deuda
/// individual a un chofer específico con su respectivo concepto y vencimiento.
class NuevaDeudaScreen extends StatefulWidget {
  final String? idConductorInicial;

  const NuevaDeudaScreen({super.key, this.idConductorInicial});

  @override
  State<NuevaDeudaScreen> createState() => _NuevaDeudaScreenState();
}

class _NuevaDeudaScreenState extends State<NuevaDeudaScreen> {
  final _formKey = GlobalKey<FormState>();

  List<Map<String, dynamic>> _conductores = [];
  List<Map<String, dynamic>> _tiposCuota = [];

  Map<String, dynamic>? _conductorSeleccionado;
  String? _idTipoSeleccionado;

  final TextEditingController _montoCtrl = TextEditingController();
  final TextEditingController _conceptoCtrl = TextEditingController();
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
            content: Text('No tienes permisos para asignar deudas.'),
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
      final conductores = await DatabaseHelper.instance.conductoresConAuto();
      final tipos = await DatabaseHelper.instance.listar('tipo_cuota');

      final tiposActivos = tipos.where((t) => (t['activo'] ?? 1) == 1).toList();

      Map<String, dynamic>? preseleccionado;
      if (widget.idConductorInicial != null) {
        preseleccionado = conductores.firstWhere(
          (c) => c['id_conductor']?.toString() == widget.idConductorInicial,
          orElse: () => {},
        );
        if (preseleccionado.isEmpty) preseleccionado = null;
      }

      if (mounted) {
        setState(() {
          _conductores = conductores;
          _tiposCuota = tiposActivos;
          _conductorSeleccionado = preseleccionado;

          if (tiposActivos.isNotEmpty) {
            _idTipoSeleccionado = tiposActivos.first['id_tipo_cuota']?.toString();
            final sug = tiposActivos.first['monto_sugerido'] as num?;
            if (sug != null && sug > 0) {
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
      initialDate: now.add(const Duration(days: 15)),
      firstDate: now,
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) {
      setState(() {
        _venceCtrl.text = picked.toIso8601String().substring(0, 10);
      });
    }
  }

  Future<void> _guardarDeuda() async {
    if (_conductorSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona el conductor deudor.')),
      );
      return;
    }
    if (_idTipoSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona el tipo de cuota.')),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final monto = double.tryParse(_montoCtrl.text.trim()) ?? 0.0;
    if (monto <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El monto debe ser mayor a 0 Bs.')),
      );
      return;
    }

    final idUsuario = SesionService.instance.idUsuario ??
        Usuario.currentUser?.id ??
        'superadmin';

    setState(() => _isSaving = true);
    try {
      await EconomiaRepo.instance.crearCuota(
        idConductor: _conductorSeleccionado!['id_conductor'].toString(),
        idTipoCuota: _idTipoSeleccionado!,
        monto: monto,
        concepto: _conceptoCtrl.text.trim().isEmpty ? null : _conceptoCtrl.text.trim(),
        fechaVencimiento: _venceCtrl.text.trim().isEmpty ? null : _venceCtrl.text.trim(),
        registradoPor: idUsuario,
      );

      if (!mounted) return;
      setState(() => _isSaving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('¡Deuda asignada con éxito!'),
            ],
          ),
          backgroundColor: Color(0xFF10B981),
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
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text(
          'Nueva Deuda Individual',
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
                    // TARJETA DE CONDUCTOR
                    _buildTarjetaConductor(),

                    const SizedBox(height: 16),

                    // FORMULARIO DE DETALLE DE LA DEUDA
                    _buildTarjetaFormulario(),

                    const SizedBox(height: 24),

                    // BOTÓN GUARDAR
                    SizedBox(
                      height: 50,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 3,
                        ),
                        icon: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.save_outlined),
                        label: Text(
                          _isSaving ? 'Registrando...' : 'Asignar Deuda al Conductor',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        onPressed: _isSaving ? null : _guardarDeuda,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTarjetaConductor() {
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
            'Conductor Deudor *',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 10),
          if (_conductorSeleccionado == null) ...[
            Autocomplete<Map<String, dynamic>>(
              optionsBuilder: (textVal) {
                if (textVal.text.isEmpty) return _conductores.take(8);
                final q = textVal.text.toLowerCase().trim();
                return _conductores.where((c) {
                  final n = (c['nombre'] ?? '').toString().toLowerCase();
                  final ci = (c['ci'] ?? '').toString().toLowerCase();
                  return n.contains(q) || ci.contains(q);
                });
              },
              displayStringForOption: (c) =>
                  '${c['nombre']} (CI: ${c['ci'] ?? 'S/CI'})',
              onSelected: (c) => setState(() => _conductorSeleccionado = c),
              fieldViewBuilder: (ctx, ctrl, focusNode, onFieldSubmitted) {
                return TextField(
                  controller: ctrl,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    hintText: 'Buscar conductor por nombre o CI...',
                    prefixIcon: const Icon(Icons.person_search, color: Color(0xFF3B82F6)),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                  ),
                );
              },
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Row(
                children: [
                  AvatarConductor(
                    foto: _conductorSeleccionado!['foto']?.toString(),
                    nombre: _conductorSeleccionado!['nombre']?.toString() ?? '',
                    radio: 22,
                    fontSize: 12,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _conductorSeleccionado!['nombre']?.toString() ?? '',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xFF1E3A8A),
                          ),
                        ),
                        Text(
                          'CI: ${_conductorSeleccionado!['ci'] ?? 'S/CI'} • Placa: ${_conductorSeleccionado!['placa'] ?? 'Sin auto'}',
                          style: const TextStyle(fontSize: 11.5, color: Color(0xFF475569)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18, color: Color(0xFF2563EB)),
                    tooltip: 'Cambiar',
                    onPressed: () => setState(() => _conductorSeleccionado = null),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTarjetaFormulario() {
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
            'Detalles de la Obligación',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 14),

          // 1. Selector de Tipo de Cuota
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

          // 2. Monto a cobrar
          TextFormField(
            controller: _montoCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            decoration: InputDecoration(
              labelText: 'Monto de la Deuda (Bs.) *',
              prefixText: 'Bs. ',
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'El monto es obligatorio';
              final n = double.tryParse(v.trim());
              if (n == null || n <= 0) return 'Ingrese un monto válido mayor a 0';
              return null;
            },
          ),

          const SizedBox(height: 14),

          // 3. Concepto / Motivo
          TextFormField(
            controller: _conceptoCtrl,
            decoration: InputDecoration(
              labelText: 'Concepto Específico (Opcional)',
              hintText: 'Ej. Cuota mensual de noviembre, Aporte solidario...',
              prefixIcon: const Icon(Icons.description_outlined, size: 20),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // 4. Fecha de Vencimiento
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
}
