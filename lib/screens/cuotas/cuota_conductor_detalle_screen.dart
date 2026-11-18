import 'package:flutter/material.dart';
import '../../core/formato_moneda.dart';
import '../../services/economia_repo.dart';
import '../pasanaco_screen.dart';
import 'widgets/dialogo_recibo_modal.dart';

const _kVerdeOscuro = Color(0xFF02634C);
const _kMintBg = Color(0xFFE6F4F0);

/// Pantalla informativa de Detalle de Cuota para Conductores y Supervisores.
/// Muestra en solo lectura:
/// - Resumen de importes (Total, Pagado, Debes) con barra de progreso.
/// - Cronograma de vencimientos y estado de cada cuota.
/// - Historial de recibos/pagos con acceso a ver comprobante digital.
class CuotaConductorDetalleScreen extends StatefulWidget {
  final String idConductor;
  final String idTipoCuota;
  final String nombreCuota;
  final String? categoria;
  final String? nombreConductor;

  const CuotaConductorDetalleScreen({
    super.key,
    required this.idConductor,
    required this.idTipoCuota,
    required this.nombreCuota,
    this.categoria,
    this.nombreConductor,
  });

  @override
  State<CuotaConductorDetalleScreen> createState() =>
      _CuotaConductorDetalleScreenState();
}

class _CuotaConductorDetalleScreenState
    extends State<CuotaConductorDetalleScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _cronograma = [];
  List<Map<String, dynamic>> _pagos = [];
  Map<String, dynamic>? _pasanacoVinculado;

  double _total = 0.0;
  double _pagado = 0.0;
  double _saldo = 0.0;

  @override
  void initState() {
    super.initState();
    _cargarDetalles();
  }

  Future<void> _cargarDetalles() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        EconomiaRepo.instance.cronogramaCuotasConductor(
          widget.idConductor,
          widget.idTipoCuota,
        ),
        EconomiaRepo.instance.pagosConductorConcepto(
          widget.idConductor,
          widget.idTipoCuota,
        ),
        EconomiaRepo.instance.obtenerPasanacoPorTipoCuota(
          widget.idTipoCuota,
        ),
      ]);

      final cronograma = results[0] as List<Map<String, dynamic>>;
      final pagos = results[1] as List<Map<String, dynamic>>;
      final pasanaco = results[2] as Map<String, dynamic>?;

      double tot = 0.0;
      double pag = 0.0;
      for (final c in cronograma) {
        final m = (c['monto'] as num?)?.toDouble() ?? 0.0;
        final p = (c['monto_pagado'] as num?)?.toDouble() ?? 0.0;
        tot += m;
        pag += p;
      }

      if (mounted) {
        setState(() {
          _cronograma = cronograma;
          _pagos = pagos;
          _pasanacoVinculado = pasanaco;
          _total = tot;
          _pagado = pag;
          _saldo = (tot - pag).clamp(0.0, double.infinity);
          _isLoading = false;
        });
      }
    } catch (e, stack) {
      debugPrint('Error en _cargarDetalles: $e\n$stack');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatearFechaCorta(String? iso) {
    if (iso == null || iso.length < 10) return '--/--';
    final partes = iso.substring(0, 10).split('-');
    if (partes.length != 3) return iso;
    return '${partes[2]}/${partes[1]}/${partes[0]}';
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final porcentaje = _total > 0 ? (_pagado / _total).clamp(0.0, 1.0) : 1.0;
    final esAlDia = _saldo <= 0.01;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // 1. CABECERA CURVA VERDE CORPORATIVO
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: _kVerdeOscuro,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
            padding: EdgeInsets.fromLTRB(16, topPadding + 8, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.nombreCuota,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (widget.nombreConductor != null) ...[
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.only(left: 32),
                    child: Text(
                      'Chofer: ${widget.nombreConductor!}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // 2. CONTENIDO PRINCIPAL
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: _kVerdeOscuro),
                  )
                : RefreshIndicator(
                    color: _kVerdeOscuro,
                    onRefresh: _cargarDetalles,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        if (_pasanacoVinculado != null) ...[
                          Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: _kMintBg,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: _kVerdeOscuro.withOpacity(0.35),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: _kVerdeOscuro,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.savings_rounded,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Tablero de Pasanaku',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 14,
                                          color: _kVerdeOscuro,
                                        ),
                                      ),
                                      Text(
                                        'Consulta el orden de turnos sorteados y las fechas de entrega de cada pozo.',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          color: Color(0xFF334155),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _kVerdeOscuro,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => PasanacoDetalleScreen(
                                          idPasanaco: _pasanacoVinculado![
                                                  'id_pasanaco']
                                              .toString(),
                                          puedeEditar: false,
                                        ),
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    'Ver Turnos',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        // TARJETA DE RESUMEN FINANCIERO
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFFE2E8F0),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildColumnaMonto(
                                    etiqueta: 'Total',
                                    monto: _total,
                                    colorMonto: const Color(0xFF1E293B),
                                  ),
                                  _buildColumnaMonto(
                                    etiqueta: 'Pagado',
                                    monto: _pagado,
                                    colorMonto: const Color(0xFF059669),
                                  ),
                                  _buildColumnaMonto(
                                    etiqueta: 'Debes',
                                    monto: _saldo,
                                    colorMonto: esAlDia
                                        ? const Color(0xFF059669)
                                        : const Color(0xFFDC2626),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: porcentaje,
                                  minHeight: 7,
                                  backgroundColor: const Color(0xFFF1F5F9),
                                  color: esAlDia
                                      ? const Color(0xFF059669)
                                      : _kVerdeOscuro,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    esAlDia
                                        ? '¡Estás al día con esta cuota!'
                                        : 'Avance: ${(porcentaje * 100).toStringAsFixed(0)}% del total',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: esAlDia
                                          ? const Color(0xFF059669)
                                          : const Color(0xFF64748B),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: esAlDia
                                          ? _kMintBg
                                          : const Color(0xFFFEF3C7),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      esAlDia ? 'AL DÍA' : 'PENDIENTE',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w800,
                                        color: esAlDia
                                            ? _kVerdeOscuro
                                            : const Color(0xFFB45309),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 22),

                        // SECCIÓN CRONOGRAMA
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_month_rounded,
                              size: 19,
                              color: _kVerdeOscuro,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Cronograma de Cuotas',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${_cronograma.length} cuota(s)',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        if (_cronograma.isEmpty)
                          _buildVacio(
                            'No hay fechas de cronograma registradas.',
                          )
                        else
                          ..._cronograma.map((c) => _buildFilaCronograma(c)),

                        const SizedBox(height: 22),

                        // SECCIÓN MIS PAGOS
                        Row(
                          children: [
                            const Icon(
                              Icons.receipt_long_rounded,
                              size: 19,
                              color: _kVerdeOscuro,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Mis Pagos Realizados',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${_pagos.length} comprobante(s)',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        if (_pagos.isEmpty)
                          _buildVacio(
                            'Aún no registras ningún pago para esta cuota.',
                          )
                        else
                          ..._pagos.map((p) => _buildFilaPago(p)),

                        const SizedBox(height: 18),

                        // AVISO INFORMATIVO AL PIE
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                size: 18,
                                color: Color(0xFF475569),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Para pagar o regularizar cuotas pendientes, acércate a la Secretaría de Hacienda.',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: Color(0xFF475569),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildColumnaMonto({
    required String etiqueta,
    required double monto,
    required Color colorMonto,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          etiqueta,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          formatearBs(monto),
          style: TextStyle(
            fontSize: 16.5,
            fontWeight: FontWeight.w800,
            color: colorMonto,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildFilaCronograma(Map<String, dynamic> c) {
    final concepto = c['concepto']?.toString() ?? 'Cuota';
    final fechaVenc = (c['fecha_vencimiento'] ?? c['fecha'])?.toString();
    final fechaTexto = _formatearFechaCorta(fechaVenc);
    final monto = (c['monto'] as num?)?.toDouble() ?? 0.0;
    final pagado = (c['monto_pagado'] as num?)?.toDouble() ?? 0.0;
    final saldo = (monto - pagado).clamp(0.0, double.infinity);
    final estado = c['estado']?.toString().toLowerCase() ?? 'pendiente';

    final hoyStr = DateTime.now().toIso8601String().substring(0, 10);
    final esVencida =
        (estado == 'pendiente' || estado == 'parcial') &&
        fechaVenc != null &&
        fechaVenc.compareTo(hoyStr) < 0;

    final esPagada = estado == 'pagado' || saldo <= 0.01;

    Color badgeBg;
    Color badgeColor;
    String badgeTexto;
    IconData badgeIcon;

    if (esPagada) {
      badgeBg = _kMintBg;
      badgeColor = _kVerdeOscuro;
      badgeTexto = 'Pagada';
      badgeIcon = Icons.check_circle_rounded;
    } else if (esVencida) {
      badgeBg = const Color(0xFFFEF2F2);
      badgeColor = const Color(0xFFDC2626);
      badgeTexto = 'Vencida · Debe ${formatearBs(saldo)}';
      badgeIcon = Icons.warning_amber_rounded;
    } else if (estado == 'parcial') {
      badgeBg = const Color(0xFFFFFBEB);
      badgeColor = const Color(0xFFD97706);
      badgeTexto = 'Abono: ${formatearBs(pagado)} (Falta ${formatearBs(saldo)})';
      badgeIcon = Icons.schedule_rounded;
    } else {
      badgeBg = const Color(0xFFF1F5F9);
      badgeColor = const Color(0xFF475569);
      badgeTexto = 'Pendiente · ${formatearBs(monto)}';
      badgeIcon = Icons.schedule_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: esVencida ? const Color(0xFFFECACA) : const Color(0xFFE2E8F0),
          width: esVencida ? 1.3 : 1.0,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  concepto,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Vence: $fechaTexto',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(badgeIcon, size: 13, color: badgeColor),
                const SizedBox(width: 4),
                Text(
                  badgeTexto,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: badgeColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilaPago(Map<String, dynamic> p) {
    final nroRecibo = p['nro_recibo']?.toString() ?? 'S/N';
    final fecha = _formatearFechaCorta(p['fecha']?.toString());
    final metodo = (p['metodo']?.toString() ?? 'efectivo').toUpperCase();
    final monto = (p['monto'] as num?)?.toDouble() ?? 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            DialogoReciboModal.mostrar(context, p);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: _kMintBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.receipt_rounded,
                    color: _kVerdeOscuro,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nroRecibo,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$fecha · $metodo',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '+ ${formatearBs(monto)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF059669),
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Ver recibo',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: _kVerdeOscuro,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 14,
                          color: _kVerdeOscuro,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVacio(String mensaje) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Center(
        child: Text(
          mensaje,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
        ),
      ),
    );
  }
}
