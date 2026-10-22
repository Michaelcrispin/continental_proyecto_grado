import 'package:flutter/material.dart';
import '../services/economia_repo.dart';
import '../services/recibo_pdf_service.dart';
import '../widgets/avatar_conductor.dart';

/// Vista E9: Caja del Día / Historial de Cobros
///
/// Permite al Secretario de Hacienda / Tesorero realizar el arqueo diario
/// con total recaudado, desglose por método (Efectivo / QR / Transferencia)
/// y reimpresión de cualquier comprobante PDF.
class CajaDelDiaScreen extends StatefulWidget {
  final String? fechaInicial;

  const CajaDelDiaScreen({super.key, this.fechaInicial});

  @override
  State<CajaDelDiaScreen> createState() => _CajaDelDiaScreenState();
}

class _CajaDelDiaScreenState extends State<CajaDelDiaScreen> {
  late DateTime _fechaActual;
  Map<String, dynamic>? _caja;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.fechaInicial != null) {
      _fechaActual = DateTime.tryParse(widget.fechaInicial!) ?? DateTime.now();
    } else {
      _fechaActual = DateTime.now();
    }
    _cargarCaja();
  }

  String get _fechaStr => _fechaActual.toIso8601String().substring(0, 10);

  Future<void> _cargarCaja() async {
    setState(() => _isLoading = true);
    try {
      final res = await EconomiaRepo.instance.pagosDelDia(fecha: _fechaStr);
      if (mounted) {
        setState(() {
          _caja = res;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _cambiarDia(int delta) {
    setState(() {
      _fechaActual = _fechaActual.add(Duration(days: delta));
    });
    _cargarCaja();
  }

  Future<void> _elegirFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaActual,
      firstDate: DateTime(2020),
      lastDate: DateTime(DateTime.now().year + 2),
    );
    if (picked != null) {
      setState(() => _fechaActual = picked);
      _cargarCaja();
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalDia = (_caja?['total_dia'] as num?)?.toDouble() ?? 0.0;
    final totalEf = (_caja?['total_efectivo'] as num?)?.toDouble() ?? 0.0;
    final totalQr = (_caja?['total_qr'] as num?)?.toDouble() ?? 0.0;
    final totalTr = (_caja?['total_transferencia'] as num?)?.toDouble() ?? 0.0;
    final pagos = (_caja?['pagos'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text(
          'Caja del Día (Arqueo)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
            onPressed: _cargarCaja,
          ),
        ],
      ),
      body: Column(
        children: [
          // BARRA NAVEGACIÓN DE FECHAS
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, size: 16, color: Color(0xFF1E3A8A)),
                  onPressed: () => _cambiarDia(-1),
                ),
                InkWell(
                  onTap: _elegirFecha,
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 16, color: Color(0xFF2563EB)),
                        const SizedBox(width: 8),
                        Text(
                          _fechaStr,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E3A8A)),
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF1E3A8A)),
                  onPressed: () => _cambiarDia(1),
                ),
              ],
            ),
          ),

          // RESUMEN FINANCIERO DEL DÍA
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F265C), Color(0xFF1E3A8A)],
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'TOTAL RECAUDADO HOY:',
                      style: TextStyle(color: Color(0xFF93C5FD), fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Bs. ${totalDia.toStringAsFixed(2)}',
                      style: const TextStyle(color: Color(0xFFA7F3D0), fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildPillMetodo('Efectivo', totalEf, Icons.money),
                    const SizedBox(width: 8),
                    _buildPillMetodo('QR Simple', totalQr, Icons.qr_code_2),
                    const SizedBox(width: 8),
                    _buildPillMetodo('Transf.', totalTr, Icons.account_balance),
                  ],
                ),
              ],
            ),
          ),

          // LISTA DE COBROS DEL DÍA
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : pagos.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox_outlined, size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 8),
                            const Text(
                              'No se registraron cobros en esta fecha.',
                              style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        physics: const BouncingScrollPhysics(),
                        itemCount: pagos.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (ctx, index) {
                          final p = pagos[index];
                          final nroRecibo = p['nro_recibo']?.toString() ?? '';
                          final hora = (p['created_at']?.toString() ?? '').length >= 19
                              ? p['created_at'].toString().substring(11, 19)
                              : '';
                          final chofer = p['conductor_nombre']?.toString() ?? 'Conductor';
                          final ci = p['conductor_ci']?.toString() ?? '';
                          final foto = p['conductor_foto']?.toString();
                          final monto = (p['monto'] as num).toDouble();
                          final metodo = (p['metodo']?.toString() ?? 'efectivo').toUpperCase();
                          final concepto = p['concepto_cuota']?.toString() ?? 'Cuota';
                          final cobrador = p['cobrador_nombre']?.toString() ?? 'Tesorero';

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
                                AvatarConductor(
                                  foto: foto,
                                  nombre: chofer,
                                  radio: 20,
                                  fontSize: 10,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        chofer,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13.5,
                                          color: Color(0xFF1E293B),
                                        ),
                                      ),
                                      Text(
                                        '$concepto • $metodo',
                                        style: const TextStyle(fontSize: 11.5, color: Color(0xFF475569)),
                                      ),
                                      Text(
                                        '$nroRecibo • $hora • Cobró: $cobrador',
                                        style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '+ Bs. ${monto.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: Color(0xFF059669),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    InkWell(
                                      onTap: () {
                                        final datosPago = {
                                          'nro_recibo': nroRecibo,
                                          'fecha': _fechaStr,
                                          'hora': hora,
                                          'monto_pagado': monto,
                                          'metodo': metodo,
                                          'conductor_nombre': chofer,
                                          'conductor_ci': ci,
                                          'tipo_nombre': p['tipo_nombre'] ?? 'Cuota',
                                          'concepto': concepto,
                                          'total_cuota': monto,
                                          'saldo_restante': 0.0,
                                          'cobrador_nombre': cobrador,
                                          'observacion': p['observacion'],
                                        };
                                        ReciboPdfService.mostrarVistaPrevia(context, datosPago);
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEFF6FF),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.print, size: 12, color: Color(0xFF2563EB)),
                                            SizedBox(width: 4),
                                            Text(
                                              'Ver Recibo',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF2563EB),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildPillMetodo(String label, double monto, IconData icono) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icono, size: 12, color: Colors.white70),
                const SizedBox(width: 4),
                Text(label, style: const TextStyle(fontSize: 10, color: Colors.white70)),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              'Bs. ${monto.toStringAsFixed(2)}',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
