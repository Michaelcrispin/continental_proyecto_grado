import 'package:flutter/material.dart';
import '../core/permisos.dart';
import '../models/usuario_model.dart';
import '../services/database_helper.dart';
import '../services/economia_repo.dart';
import '../services/recibo_pdf_service.dart';
import '../services/sesion_service.dart';
import '../widgets/avatar_conductor.dart';

/// Vista E2: Cobrar (Registro de Pago en 3 toques)
///
/// Flujo:
/// 1. Buscar y seleccionar conductor (por nombre o CI).
/// 2. Ver sus deudas activas con saldos.
/// 3. Elegir monto (total o parcial), método (efectivo/qr/transferencia) y confirmar cobro.
/// Emite el recibo oficial correlativo (E3).
class CobrarScreen extends StatefulWidget {
  final String? idConductorInicial;
  final String? idCuotaInicial;

  const CobrarScreen({
    super.key,
    this.idConductorInicial,
    this.idCuotaInicial,
  });

  @override
  State<CobrarScreen> createState() => _CobrarScreenState();
}

class _CobrarScreenState extends State<CobrarScreen> {
  List<Map<String, dynamic>> _conductores = [];
  Map<String, dynamic>? _conductorSeleccionado;
  List<Map<String, dynamic>> _deudas = [];

  Map<String, dynamic>? _cuotaSeleccionada;
  final TextEditingController _montoCtrl = TextEditingController();
  final TextEditingController _obsCtrl = TextEditingController();
  final TextEditingController _buscarConductorCtrl = TextEditingController();

  String _metodoPago = 'efectivo';
  bool _isLoading = true;
  bool _isCobrando = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!Permisos.puedeEditar(
          SesionService.instance.rol, Permisos.moduloControlEconomico)) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No tienes permisos para registrar cobros.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    });
    _cargarConductores();
  }

  @override
  void dispose() {
    _montoCtrl.dispose();
    _obsCtrl.dispose();
    _buscarConductorCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarConductores() async {
    setState(() => _isLoading = true);
    try {
      final list = await DatabaseHelper.instance.conductoresConAuto();
      if (!mounted) return;

      Map<String, dynamic>? preseleccionado;
      if (widget.idConductorInicial != null) {
        preseleccionado = list.firstWhere(
          (c) => c['id_conductor']?.toString() == widget.idConductorInicial,
          orElse: () => {},
        );
        if (preseleccionado.isEmpty) preseleccionado = null;
      }

      setState(() {
        _conductores = list;
        _isLoading = false;
      });

      if (preseleccionado != null) {
        _seleccionarConductor(preseleccionado);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _seleccionarConductor(Map<String, dynamic> c) async {
    setState(() {
      _conductorSeleccionado = c;
      _cuotaSeleccionada = null;
      _montoCtrl.clear();
      _isLoading = true;
    });

    try {
      final idConductor = c['id_conductor']?.toString() ?? '';
      final deudas = await EconomiaRepo.instance.deudasDeConductor(idConductor);

      Map<String, dynamic>? cuotaPrevia;
      if (widget.idCuotaInicial != null) {
        cuotaPrevia = deudas.firstWhere(
          (d) => d['id_cuota']?.toString() == widget.idCuotaInicial,
          orElse: () => {},
        );
        if (cuotaPrevia.isEmpty) cuotaPrevia = null;
      }

      if (mounted) {
        setState(() {
          _deudas = deudas;
          _isLoading = false;
        });

        if (cuotaPrevia != null) {
          _seleccionarCuota(cuotaPrevia);
        } else if (deudas.isNotEmpty) {
          _seleccionarCuota(deudas.first);
        }
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _seleccionarCuota(Map<String, dynamic> deuda) {
    setState(() {
      _cuotaSeleccionada = deuda;
      final saldo = (deuda['saldo'] as num?)?.toDouble() ??
          (deuda['monto'] as num).toDouble();
      _montoCtrl.text = saldo.toStringAsFixed(2);
    });
  }

  Future<void> _procesarCobro() async {
    if (_conductorSeleccionado == null) {
      _mostrarAlerta('Por favor selecciona primero un conductor.');
      return;
    }
    if (_cuotaSeleccionada == null) {
      _mostrarAlerta('Por favor selecciona la deuda que deseas cobrar.');
      return;
    }

    final monto = double.tryParse(_montoCtrl.text.trim()) ?? 0.0;
    if (monto <= 0) {
      _mostrarAlerta('El monto a cobrar debe ser mayor a 0 Bs.');
      return;
    }

    final saldo = (_cuotaSeleccionada!['saldo'] as num).toDouble();
    if (monto > (saldo + 0.01)) {
      _mostrarAlerta(
        'El monto ingresado (Bs. ${monto.toStringAsFixed(2)}) supera el saldo de la deuda (Bs. ${saldo.toStringAsFixed(2)}).',
      );
      return;
    }

    final idUsuario = SesionService.instance.idUsuario ??
        Usuario.currentUser?.id ??
        'superadmin';

    // Diálogo de confirmación
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.monetization_on, color: Color(0xFF10B981), size: 28),
            SizedBox(width: 10),
            Text('Confirmar Cobro'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Deseas registrar el cobro de Bs. ${monto.toStringAsFixed(2)} para ${_conductorSeleccionado!['nombre']}?',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Text('Método: ',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Text(_metodoPago.toUpperCase(),
                      style: const TextStyle(
                          color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold)),
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
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmar y Emitir Recibo'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    setState(() => _isCobrando = true);

    try {
      final resultado = await EconomiaRepo.instance.registrarPago(
        idCuota: _cuotaSeleccionada!['id_cuota'].toString(),
        monto: monto,
        metodo: _metodoPago,
        observacion: _obsCtrl.text.trim(),
        idUsuario: idUsuario,
      );

      if (!mounted) return;
      setState(() => _isCobrando = false);

      // Mostrar Vista Previa del Recibo PDF de inmediato (E3)
      await ReciboPdfService.mostrarVistaPrevia(context, resultado);

      if (mounted) {
        // Recargar deudas del conductor
        _seleccionarConductor(_conductorSeleccionado!);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCobrando = false);
        _mostrarAlerta('Error al registrar cobro: $e');
      }
    }
  }

  void _mostrarAlerta(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text(
          'Cobrar Cuota / Aporte',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading && _conductorSeleccionado == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // PASO 1: SELECCIONAR CONDUCTOR
                  _buildPaso1SeleccionConductor(),

                  const SizedBox(height: 16),

                  // PASO 2: VER DEUDAS DEL CONDUCTOR
                  if (_conductorSeleccionado != null) ...[
                    _buildPaso2Deudas(),
                    const SizedBox(height: 16),
                  ],

                  // PASO 3: DETALLE DEL COBRO (MONTO, MÉTODO, BOTÓN)
                  if (_cuotaSeleccionada != null) ...[
                    _buildPaso3FormularioCobro(),
                  ],
                ],
              ),
            ),
    );
  }

  // ---------------------------------------------------------------------------
  // PASO 1: SELECTOR DE CONDUCTOR
  // ---------------------------------------------------------------------------
  Widget _buildPaso1SeleccionConductor() {
    final tieneConductor = _conductorSeleccionado != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: const BoxDecoration(
                  color: Color(0xFFEFF6FF),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    '1',
                    style: TextStyle(
                      color: Color(0xFF2563EB),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Seleccionar Conductor',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const Spacer(),
              if (tieneConductor)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _conductorSeleccionado = null;
                      _deudas.clear();
                      _cuotaSeleccionada = null;
                    });
                  },
                  child: const Text('Cambiar', style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (!tieneConductor) ...[
            // Buscador / Autocompletado de conductores
            Autocomplete<Map<String, dynamic>>(
              optionsBuilder: (TextEditingValue textValue) {
                if (textValue.text.isEmpty) {
                  return _conductores.take(10);
                }
                final query = textValue.text.toLowerCase().trim();
                return _conductores.where((c) {
                  final n = (c['nombre'] ?? '').toString().toLowerCase();
                  final ci = (c['ci'] ?? '').toString().toLowerCase();
                  final placa = (c['placa'] ?? '').toString().toLowerCase();
                  return n.contains(query) || ci.contains(query) || placa.contains(query);
                });
              },
              displayStringForOption: (c) =>
                  '${c['nombre']} (CI: ${c['ci'] ?? 'S/CI'})',
              onSelected: _seleccionarConductor,
              fieldViewBuilder: (ctx, ctrl, focusNode, onFieldSubmitted) {
                return TextField(
                  controller: ctrl,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    hintText: 'Buscar chofer por nombre, CI o placa...',
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF3B82F6)),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                );
              },
              optionsViewBuilder: (ctx, onSelected, options) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 6,
                    borderRadius: BorderRadius.circular(16),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 250, maxWidth: 350),
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        shrinkWrap: true,
                        itemCount: options.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (ctx, index) {
                          final c = options.elementAt(index);
                          return ListTile(
                            leading: AvatarConductor(
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
                            onTap: () => onSelected(c),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ] else ...[
            // Conductor Seleccionado Card
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
                  const Icon(Icons.check_circle, color: Color(0xFF2563EB), size: 22),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // PASO 2: VER DEUDAS DEL CONDUCTOR
  // ---------------------------------------------------------------------------
  Widget _buildPaso2Deudas() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: const BoxDecoration(
                  color: Color(0xFFEFF6FF),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    '2',
                    style: TextStyle(
                      color: Color(0xFF2563EB),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Deudas Pendientes',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const Spacer(),
              Text(
                '${_deudas.length} pendientes',
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_deudas.isEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle_outline, color: Color(0xFF059669), size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '¡Excelente! Este conductor no tiene ninguna deuda pendiente registrada.',
                      style: TextStyle(color: Color(0xFF065F46), fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _deudas.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) {
                final d = _deudas[i];
                final esSeleccionada =
                    _cuotaSeleccionada?['id_cuota'] == d['id_cuota'];
                final montoTotal = (d['monto'] as num).toDouble();
                final saldo = (d['saldo'] as num).toDouble();
                final concepto = d['concepto'] ?? d['tipo_nombre'] ?? 'Cuota';
                final fecha = d['fecha']?.toString() ?? '';
                final tipo = d['tipo_nombre']?.toString() ?? 'General';

                return InkWell(
                  onTap: () => _seleccionarCuota(d),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: esSeleccionada ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: esSeleccionada ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
                        width: esSeleccionada ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          esSeleccionada
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                          color: esSeleccionada
                              ? const Color(0xFF2563EB)
                              : const Color(0xFF94A3B8),
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tipo,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              Text(
                                concepto,
                                style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Fecha: $fecha',
                                style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8)),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Bs. ${saldo.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Color(0xFFEF4444),
                              ),
                            ),
                            Text(
                              'de Bs. ${montoTotal.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // PASO 3: FORMULARIO DE COBRO (MONTO, MÉTODO, CONFIRMAR)
  // ---------------------------------------------------------------------------
  Widget _buildPaso3FormularioCobro() {
    final saldo = (_cuotaSeleccionada!['saldo'] as num).toDouble();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: const BoxDecoration(
                  color: Color(0xFFEFF6FF),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    '3',
                    style: TextStyle(
                      color: Color(0xFF2563EB),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Detalle del Cobro',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Campo Monto con atajo de "Pagar Saldo Completo"
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _montoCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  decoration: InputDecoration(
                    labelText: 'Monto a Cobrar (Bs.) *',
                    prefixText: 'Bs. ',
                    prefixStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEFF6FF),
                  foregroundColor: const Color(0xFF2563EB),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  setState(() {
                    _montoCtrl.text = saldo.toStringAsFixed(2);
                  });
                },
                child: const Text('Todo el saldo', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Selector de Método de Pago
          const Text('Método de Pago:',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5, color: Color(0xFF475569))),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildBotonMetodo('efectivo', 'Efectivo', Icons.money),
              const SizedBox(width: 8),
              _buildBotonMetodo('qr', 'QR Simple', Icons.qr_code_2),
              const SizedBox(width: 8),
              _buildBotonMetodo('transferencia', 'Transf.', Icons.account_balance),
            ],
          ),

          const SizedBox(height: 14),

          // Observación opcional
          TextField(
            controller: _obsCtrl,
            decoration: InputDecoration(
              labelText: 'Observación / N° Referencia (Opcional)',
              hintText: 'Ej. Pago con QR del Banco Unión',
              prefixIcon: const Icon(Icons.note_alt_outlined, size: 20),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Botón Confirmar Cobro
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
              ),
              icon: _isCobrando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.check_circle, size: 22),
              label: Text(
                _isCobrando ? 'Registrando cobro...' : 'Confirmar Cobro y Emitir Recibo',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              onPressed: _isCobrando ? null : _procesarCobro,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBotonMetodo(String valor, String label, IconData icono) {
    final esActivo = _metodoPago == valor;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _metodoPago = valor),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: esActivo ? const Color(0xFF10B981) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: esActivo ? const Color(0xFF059669) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Column(
            children: [
              Icon(icono, size: 20, color: esActivo ? Colors.white : const Color(0xFF64748B)),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: esActivo ? Colors.white : const Color(0xFF475569),
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
