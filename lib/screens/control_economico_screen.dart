import 'package:flutter/material.dart';
import '../core/permisos.dart';
import '../services/database_helper.dart';
import '../services/sesion_service.dart';

class ControlEconomicoScreen extends StatefulWidget {
  const ControlEconomicoScreen({super.key});

  @override
  State<ControlEconomicoScreen> createState() => _ControlEconomicoScreenState();
}

class _ControlEconomicoScreenState extends State<ControlEconomicoScreen> {
  List<Map<String, dynamic>> _cuotas = [];
  List<Map<String, dynamic>> _tiposCuota = [];
  double _totalRecaudado = 0.0;
  double _totalPendiente = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!Permisos.verificarAcceso(context, SesionService.instance.rol, Permisos.moduloControlEconomico)) {
        return;
      }
    });
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);
    try {
      final idConductor = SesionService.instance.esConductor
          ? SesionService.instance.idConductor
          : null;

      final cuotas = await DatabaseHelper.instance.cuotasDetalle(idConductor: idConductor);
      final tipos = await DatabaseHelper.instance.listar('tipo_cuota');

      double recaudado = 0.0;
      double pendiente = 0.0;

      for (final c in cuotas) {
        final monto = (c['monto'] as num?)?.toDouble() ?? 0.0;
        final estado = (c['estado'] ?? '').toString().toLowerCase();
        if (estado == 'pagado') {
          recaudado += monto;
        } else {
          pendiente += monto;
        }
      }

      if (mounted) {
        setState(() {
          _cuotas = cuotas;
          _tiposCuota = tipos;
          _totalRecaudado = recaudado;
          _totalPendiente = pendiente;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _mostrarDialogoRegistrarCuota() async {
    final conductores = await DatabaseHelper.instance.listar('conductor');
    final tipos = await DatabaseHelper.instance.listar('tipo_cuota');

    if (!mounted) return;

    if (conductores.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Primero registra conductores en el sistema.')),
      );
      return;
    }

    String? conductorSeleccionado = conductores.first['id_conductor']?.toString();
    String? tipoSeleccionado = tipos.isNotEmpty ? tipos.first['id_tipo_cuota']?.toString() : null;
    final montoCtrl = TextEditingController(text: '10');
    String estadoSeleccionado = 'pagado';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Registrar Cuota / Aporte', style: TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Conductor:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                DropdownButton<String>(
                  isExpanded: true,
                  value: conductorSeleccionado,
                  items: conductores.map((c) {
                    return DropdownMenuItem<String>(
                      value: c['id_conductor']?.toString(),
                      child: Text('${c['nombre']} (CI: ${c['ci']})', overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (val) => setDialogState(() => conductorSeleccionado = val),
                ),
                const SizedBox(height: 12),
                const Text('Tipo de Cuota:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                if (tipos.isEmpty)
                  const Text('No hay tipos de cuota', style: TextStyle(color: Colors.red, fontSize: 12))
                else
                  DropdownButton<String>(
                    isExpanded: true,
                    value: tipoSeleccionado,
                    items: tipos.map((t) {
                      return DropdownMenuItem<String>(
                        value: t['id_tipo_cuota']?.toString(),
                        child: Text(t['nombre']?.toString() ?? '', overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (val) => setDialogState(() => tipoSeleccionado = val),
                  ),
                const SizedBox(height: 12),
                TextField(
                  controller: montoCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Monto (Bs.)', hintText: 'Ej. 25.00'),
                ),
                const SizedBox(height: 12),
                const Text('Estado de pago:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                DropdownButton<String>(
                  isExpanded: true,
                  value: estadoSeleccionado,
                  items: const [
                    DropdownMenuItem(value: 'pagado', child: Text('Pagado')),
                    DropdownMenuItem(value: 'pendiente', child: Text('Pendiente')),
                  ],
                  onChanged: (val) => setDialogState(() => estadoSeleccionado = val ?? 'pagado'),
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
                backgroundColor: const Color(0xFF3B82F6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              onPressed: () async {
                final monto = double.tryParse(montoCtrl.text.trim()) ?? 0.0;
                if (conductorSeleccionado == null || tipoSeleccionado == null) return;

                final fecha = DateTime.now().toIso8601String().substring(0, 10);

                await DatabaseHelper.instance.insertar('cuota', {
                  'id_conductor': conductorSeleccionado,
                  'id_tipo_cuota': tipoSeleccionado,
                  'monto': monto,
                  'fecha': fecha,
                  'estado': estadoSeleccionado,
                });

                if (ctx.mounted) Navigator.pop(ctx);
                _cargarDatos();
              },
              child: const Text('Guardar', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final esConductor = SesionService.instance.esConductor;
    final puedeEditar = Permisos.puedeEditar(SesionService.instance.rol, Permisos.moduloControlEconomico);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F9FD),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E3A8A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          esConductor ? 'Mis Cuotas y Aportes' : 'Control Económico',
          style: const TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF1E3A8A)),
            onPressed: _cargarDatos,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Image.asset('assets/images/logo.png', height: 32, errorBuilder: (c, e, s) => const Icon(Icons.public, color: Color(0xFF1E3A8A))),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Resumen de montos reales
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(color: Color(0xFFECFDF5), shape: BoxShape.circle),
                              child: const Icon(Icons.account_balance_wallet, color: Color(0xFF10B981), size: 16),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              esConductor ? 'Mis Pagos' : 'Recaudación',
                              style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Bs. ${_totalRecaudado.toStringAsFixed(2)}', 
                          style: const TextStyle(color: Color(0xFF10B981), fontSize: 20, fontWeight: FontWeight.bold)
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(color: Color(0xFFFFFBEB), shape: BoxShape.circle),
                              child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B), size: 16),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              esConductor ? 'Mis Pendientes' : 'Pagos pendientes',
                              style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Bs. ${_totalPendiente.toStringAsFixed(2)}', 
                          style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 20, fontWeight: FontWeight.bold)
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Tipos de Cuota configurados en la BD
            const Text('Tipos de cuota configurados', style: TextStyle(color: Color(0xFF1E3A8A), fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (_tiposCuota.isEmpty)
              const Text('No hay tipos de cuota registrados en la base de datos.', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13))
            else
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: _tiposCuota.map((t) {
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.savings_outlined, color: Color(0xFF3B82F6)),
                      ),
                      title: Text(t['nombre']?.toString() ?? '', style: const TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold, fontSize: 14)),
                    );
                  }).toList(),
                ),
              ),
            
            const SizedBox(height: 24),
            const Text('Últimos pagos / cuotas', style: TextStyle(color: Color(0xFF1E3A8A), fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            if (_isLoading)
              const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
            else if (_cuotas.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Center(
                  child: Text('No hay cuotas registradas en la base de datos.', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _cuotas.length,
                itemBuilder: (context, index) {
                  final c = _cuotas[index];
                  final conductor = c['conductor_nombre'] ?? 'Conductor';
                  final tipo = c['tipo_nombre'] ?? 'Cuota';
                  final monto = c['monto'] ?? 0;
                  final fecha = c['fecha'] ?? '';
                  final estado = (c['estado'] ?? 'pendiente').toString();
                  final esPagado = estado.toLowerCase() == 'pagado';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: const Color(0xFF3B82F6).withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: esPagado ? const Color(0xFFECFDF5) : const Color(0xFFFFFBEB),
                          child: Icon(
                            esPagado ? Icons.check : Icons.access_time, 
                            color: esPagado ? const Color(0xFF10B981) : const Color(0xFFF59E0B)
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(conductor, style: const TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold, fontSize: 14)),
                              Text('$tipo • $fecha', style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                            ],
                          ),
                        ),
                        Text(
                          'Bs. $monto', 
                          style: TextStyle(
                            color: esPagado ? const Color(0xFF10B981) : const Color(0xFFF59E0B), 
                            fontWeight: FontWeight.bold, 
                            fontSize: 15
                          )
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
      bottomNavigationBar: puedeEditar
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _mostrarDialogoRegistrarCuota,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.account_balance_wallet_outlined, color: Colors.white),
                    label: const Text('Registrar cuota / pago', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}
