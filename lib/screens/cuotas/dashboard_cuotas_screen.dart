import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../services/economia_repo.dart';

const _kVerde = Color(0xFF02634C);
const _kTeal = Color(0xFF0D9488);
const _kFondo = Color(0xFFF8FAFC);
const _kTexto = Color(0xFF0F172A);
const _kTextoSuave = Color(0xFF64748B);
const _kAmbar = Color(0xFFD97706);
const _kRojo = Color(0xFFDC2626);
const _kAzul = Color(0xFF2563EB);
const _kVioleta = Color(0xFF7C3AED);
const _kRosa = Color(0xFFE11D48);

enum _Periodo { hoy, mes, anio, todo }

extension _PeriodoX on _Periodo {
  String get etiqueta {
    switch (this) {
      case _Periodo.hoy:
        return 'Hoy';
      case _Periodo.mes:
        return 'Mes';
      case _Periodo.anio:
        return 'Año';
      case _Periodo.todo:
        return 'Todo';
    }
  }

  DateTime? get desde {
    final ahora = DateTime.now();
    switch (this) {
      case _Periodo.hoy:
        return ahora;
      case _Periodo.mes:
        return DateTime(ahora.year, ahora.month, 1);
      case _Periodo.anio:
        return DateTime(ahora.year, 1, 1);
      case _Periodo.todo:
        return null;
    }
  }

  DateTime? get hasta => this == _Periodo.todo ? null : DateTime.now();
}

/// Dashboard avanzado de recaudación de cuotas.
///
/// Muestra: KPIs del período, estado de la cartera, evolución mensual,
/// recaudación por concepto y método de pago, estados de las cuotas,
/// top deudores y últimos pagos registrados.
class DashboardCuotasScreen extends StatefulWidget {
  const DashboardCuotasScreen({super.key});

  @override
  State<DashboardCuotasScreen> createState() => _DashboardCuotasScreenState();
}

class _DashboardCuotasScreenState extends State<DashboardCuotasScreen> {
  _Periodo _periodo = _Periodo.mes;
  Map<String, dynamic>? _data;
  bool _cargando = true;
  String? _error;
  bool _pagosExpandidos = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    if (mounted) {
      setState(() {
        _cargando = true;
        _error = null;
      });
    }
    try {
      final desde = _periodo.desde;
      final hasta = _periodo.hasta;
      final data = await EconomiaRepo.instance.dashboardCuotas(
        fechaDesde: desde == null ? null : _fecha(desde),
        fechaHasta: hasta == null ? null : _fecha(hasta),
      );
      if (!mounted) return;
      setState(() {
        _data = data;
        _cargando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudo cargar la información del dashboard.';
        _cargando = false;
      });
    }
  }

  String _fecha(DateTime d) {
    final mes = d.month.toString().padLeft(2, '0');
    final dia = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mes-$dia';
  }

  double _num(dynamic valor) =>
      valor is num ? valor.toDouble() : double.tryParse('$valor') ?? 0.0;

  int _entero(dynamic valor) =>
      valor is num ? valor.toInt() : int.tryParse('$valor') ?? 0;

  List<Map<String, dynamic>> _lista(String clave) {
    final raw = _data?[clave];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  double get _variacion {
    final serie = _lista('serie_mensual');
    if (serie.length < 2) return 0;
    final actual = _num(serie.last['total']);
    final anterior = _num(serie[serie.length - 2]['total']);
    if (anterior <= 0) return actual > 0 ? 100 : 0;
    return ((actual - anterior) / anterior) * 100;
  }

  @override
  Widget build(BuildContext context) {
    final recaudado = _num(_data?['recaudado']);

    return Scaffold(
      backgroundColor: _kFondo,
      body: Column(
        children: [
          _buildHeader(recaudado),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _cargar,
              color: _kVerde,
              child: _cargando
                  ? const _CargandoDashboard()
                  : _error != null
                  ? _buildError()
                  : _buildContenido(),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Encabezado
  // ---------------------------------------------------------------------------
  Widget _buildHeader(double recaudado) {
    final variacion = _variacion;
    final positiva = variacion >= 0;
    final mostrarVariacion = _periodo == _Periodo.mes;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_kVerde, _kTeal],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 4, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 21,
                    ),
                    tooltip: 'Volver',
                  ),
                  const Expanded(
                    child: Text(
                      'Dashboard de Cuotas',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _cargar,
                    icon: const Icon(
                      Icons.refresh_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                    tooltip: 'Actualizar',
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(left: 8, right: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recaudado · ${_periodo.etiqueta.toLowerCase()}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.78),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Flexible(
                          child: Text(
                            _bs(recaudado),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.8,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        if (mostrarVariacion)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 5),
                            child: _chipVariacion(variacion, positiva),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      mostrarVariacion
                          ? 'vs. mes anterior · cartera total ${_bs(_num(_data?['comprometido']))}'
                          : 'Cartera total ${_bs(_num(_data?['comprometido']))} · ${_entero(_data?['deudores'])} deudores',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.62),
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chipVariacion(double variacion, bool positiva) {
    final color = positiva ? const Color(0xFFBBF7D0) : const Color(0xFFFECACA);
    final fondo = positiva
        ? Colors.white.withValues(alpha: 0.16)
        : const Color(0xFF7F1D1D).withValues(alpha: 0.45);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            positiva ? Icons.trending_up_rounded : Icons.trending_down_rounded,
            color: color,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            '${positiva ? '+' : ''}${variacion.toStringAsFixed(1)}%',
            style: TextStyle(
              color: color,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Contenido
  // ---------------------------------------------------------------------------
  Widget _buildContenido() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        _buildPeriodos(),
        const SizedBox(height: 14),
        _buildKpis(),
        const SizedBox(height: 14),
        _buildCartera(),
        const SizedBox(height: 14),
        _buildSerieMensual(),
        const SizedBox(height: 14),
        _buildPorTipo(),
        const SizedBox(height: 14),
        _buildMetodos(),
        const SizedBox(height: 14),
        _buildEstados(),
        const SizedBox(height: 14),
        _buildDeudores(),
        const SizedBox(height: 14),
        _buildUltimosPagos(),
      ],
    );
  }

  Widget _buildPeriodos() {
    return Row(
      children: _Periodo.values.map((p) {
        final activo = p == _periodo;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              if (p == _periodo) return;
              setState(() => _periodo = p);
              _cargar();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: activo ? _kVerde : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: activo ? _kVerde : const Color(0xFFE2E8F0),
                ),
                boxShadow: activo
                    ? [
                        BoxShadow(
                          color: _kVerde.withValues(alpha: 0.22),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                p.etiqueta,
                style: TextStyle(
                  color: activo ? Colors.white : _kTextoSuave,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildKpis() {
    final kpis = <Widget>[
      _kpiCard(
        titulo: 'Recaudado',
        valor: _bs(_num(_data?['recaudado'])),
        detalle: _periodo.etiqueta.toLowerCase(),
        icono: Icons.payments_rounded,
        color: _kVerde,
        fondo: const Color(0xFFE7F5F0),
      ),
      _kpiCard(
        titulo: 'Recaudado hoy',
        valor: _bs(_num(_data?['recaudado_hoy'])),
        detalle: 'cobros del día',
        icono: Icons.today_rounded,
        color: _kTeal,
        fondo: const Color(0xFFE6FAF7),
      ),
      _kpiCard(
        titulo: 'Pagos registrados',
        valor: '${_entero(_data?['cantidad_pagos'])}',
        detalle: 'en el período',
        icono: Icons.receipt_long_rounded,
        color: _kAzul,
        fondo: const Color(0xFFEFF6FF),
      ),
      _kpiCard(
        titulo: 'Por cobrar',
        valor: _bs(_num(_data?['pendiente'])),
        detalle: 'cartera pendiente',
        icono: Icons.hourglass_bottom_rounded,
        color: _kAmbar,
        fondo: const Color(0xFFFFF7ED),
      ),
      _kpiCard(
        titulo: 'Deudores',
        valor: '${_entero(_data?['deudores'])}',
        detalle: 'conductores',
        icono: Icons.people_alt_rounded,
        color: _kRosa,
        fondo: const Color(0xFFFFF1F4),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final ancho = (constraints.maxWidth - 10) / 2;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: kpis.map((w) => SizedBox(width: ancho, child: w)).toList(),
        );
      },
    );
  }

  Widget _kpiCard({
    required String titulo,
    required String valor,
    required String detalle,
    required IconData icono,
    required Color color,
    required Color fondo,
  }) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE9EEF5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: fondo,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icono, color: color, size: 18),
          ),
          const SizedBox(height: 9),
          Text(
            valor,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _kTexto,
              fontSize: 17,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            titulo,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _kTextoSuave,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            detalle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 9.5),
          ),
        ],
      ),
    );
  }

  Widget _buildCartera() {
    final efectividad = _num(_data?['efectividad']).clamp(0.0, 100.0);
    final comprometido = _num(_data?['comprometido']);
    final pagado = _num(_data?['pagado']);
    final pendiente = _num(_data?['pendiente']);

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _tituloSeccion(
            icono: Icons.donut_large_rounded,
            titulo: 'Estado de la cartera',
            subtitulo: 'Total histórico de cuotas activas',
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${efectividad.toStringAsFixed(1)}%',
                style: const TextStyle(
                  color: _kVerde,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Text(
                  'cobrado',
                  style: TextStyle(
                    color: _kTextoSuave.withValues(alpha: 0.9),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: efectividad / 100,
              minHeight: 11,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: const AlwaysStoppedAnimation<Color>(_kVerde),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _miniTotal('Comprometido', comprometido, const Color(0xFF334155)),
              const SizedBox(width: 10),
              _miniTotal('Cobrado', pagado, _kVerde),
              const SizedBox(width: 10),
              _miniTotal('Pendiente', pendiente, _kAmbar),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniTotal(String titulo, double valor, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.14)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titulo,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _bs(valor),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSerieMensual() {
    final serie = _lista('serie_mensual');
    final hayDatos = serie.any((m) => _num(m['total']) > 0);

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _tituloSeccion(
            icono: Icons.bar_chart_rounded,
            titulo: 'Evolución mensual',
            subtitulo: 'Últimos 6 meses',
          ),
          const SizedBox(height: 12),
          if (!hayDatos)
            _vacio('Aún no hay pagos registrados en los últimos 6 meses.')
          else
            SizedBox(
              height: 190,
              width: double.infinity,
              child: CustomPaint(
                painter: _BarrasPainter(
                  datos: serie,
                  colorInicio: _kVerde,
                  colorFin: _kTeal,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPorTipo() {
    final tipos = _lista('por_tipo').take(6).toList();
    final conMovimiento = tipos
        .where((t) => _num(t['recaudado']) > 0 || _num(t['pendiente']) > 0)
        .toList();

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _tituloSeccion(
            icono: Icons.pie_chart_rounded,
            titulo: 'Recaudación por concepto',
            subtitulo: 'Cobrado vs. pendiente (período)',
          ),
          const SizedBox(height: 12),
          if (conMovimiento.isEmpty)
            _vacio('Sin movimientos en el período seleccionado.')
          else
            ...conMovimiento.map(_filaTipo),
        ],
      ),
    );
  }

  Widget _filaTipo(Map<String, dynamic> t) {
    final recaudado = _num(t['recaudado']);
    final pendiente = _num(t['pendiente']);
    final total = recaudado + pendiente;
    final avance = total > 0 ? (recaudado / total).clamp(0.0, 1.0) : 0.0;
    final nombre = t['tipo_nombre']?.toString() ?? 'Concepto';

    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  nombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _kTexto,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _bs(recaudado),
                style: const TextStyle(
                  color: _kVerde,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: avance,
              minHeight: 7,
              backgroundColor: const Color(0xFFEEF2F7),
              valueColor: const AlwaysStoppedAnimation<Color>(_kVerde),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Pendiente ${_bs(pendiente)} · ${_entero(t['pagos'])} pago(s)',
            style: const TextStyle(color: Color(0xFF8A97A8), fontSize: 9.5),
          ),
        ],
      ),
    );
  }

  Widget _buildMetodos() {
    final metodos = _lista(
      'por_metodo',
    ).where((m) => _num(m['total']) > 0).toList();
    final total = metodos.fold<double>(0, (s, m) => s + _num(m['total']));

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _tituloSeccion(
            icono: Icons.account_balance_wallet_rounded,
            titulo: 'Métodos de pago',
            subtitulo: 'Distribución de lo recaudado',
          ),
          const SizedBox(height: 14),
          if (metodos.isEmpty)
            _vacio('Sin pagos registrados en el período.')
          else
            Row(
              children: [
                SizedBox(
                  width: 118,
                  height: 118,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: const Size.square(118),
                        painter: _DonaPainter(
                          segmentos: metodos
                              .map(
                                (m) => _SegmentoDona(
                                  valor: _num(m['total']),
                                  color: _colorMetodo(m['metodo']?.toString()),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _compacto(total),
                            style: const TextStyle(
                              color: _kTexto,
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const Text(
                            'total',
                            style: TextStyle(color: _kTextoSuave, fontSize: 9),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: metodos.map((m) {
                      final valor = _num(m['total']);
                      final porcentaje = total > 0
                          ? (valor / total) * 100
                          : 0.0;
                      final metodo = m['metodo']?.toString() ?? 'otro';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 9),
                        child: Row(
                          children: [
                            Container(
                              width: 9,
                              height: 9,
                              decoration: BoxDecoration(
                                color: _colorMetodo(metodo),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 7),
                            Expanded(
                              child: Text(
                                _nombreMetodo(metodo),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: _kTexto,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              '${porcentaje.toStringAsFixed(1)}%',
                              style: const TextStyle(
                                color: _kTextoSuave,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildEstados() {
    final estados = _data?['estados_cuotas'];
    final completadas = estados is Map ? _entero(estados['completadas']) : 0;
    final enCobro = estados is Map ? _entero(estados['en_cobro']) : 0;
    final pendientes = estados is Map ? _entero(estados['pendientes']) : 0;
    final total = completadas + enCobro + pendientes;

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _tituloSeccion(
            icono: Icons.inventory_2_rounded,
            titulo: 'Cuotas por estado',
            subtitulo: 'Conceptos de cuota activos',
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              _miniEstado('Completadas', completadas, _kVerde),
              const SizedBox(width: 8),
              _miniEstado('En cobro', enCobro, _kAmbar),
              const SizedBox(width: 8),
              _miniEstado('Pendientes', pendientes, _kAzul),
            ],
          ),
          if (total > 0) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 9,
                child: Row(
                  children: [
                    if (completadas > 0)
                      Expanded(
                        flex: completadas,
                        child: Container(color: _kVerde),
                      ),
                    if (enCobro > 0)
                      Expanded(
                        flex: enCobro,
                        child: Container(color: _kAmbar),
                      ),
                    if (pendientes > 0)
                      Expanded(
                        flex: pendientes,
                        child: Container(color: _kAzul),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _miniEstado(String titulo, int valor, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$valor',
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              titulo,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color.withValues(alpha: 0.85),
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeudores() {
    final deudores = _lista('top_deudores');

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _tituloSeccion(
            icono: Icons.groups_rounded,
            titulo: 'Top deudores',
            subtitulo: 'Mayor saldo pendiente',
          ),
          const SizedBox(height: 10),
          if (deudores.isEmpty)
            _vacio('Sin deudas pendientes. ¡Todo al día!')
          else
            ...deudores.map((d) {
              final nombre = d['conductor_nombre']?.toString() ?? 'Conductor';
              final deuda = _num(d['deuda_total']);
              final cuotas = _entero(d['cantidad_cuotas']);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: _kRosa.withValues(alpha: 0.12),
                      child: Text(
                        _inicial(nombre),
                        style: const TextStyle(
                          color: _kRosa,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nombre,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _kTexto,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '$cuotas cuota(s) pendiente(s)',
                            style: const TextStyle(
                              color: _kTextoSuave,
                              fontSize: 9.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _bs(deuda),
                      style: const TextStyle(
                        color: _kRojo,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildUltimosPagos() {
    final pagos = _lista('ultimos_pagos');
    final visibles = _pagosExpandidos ? pagos : pagos.take(5).toList();

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _tituloSeccion(
            icono: Icons.history_rounded,
            titulo: 'Pagos del período',
            subtitulo: '${pagos.length} movimiento(s) encontrados',
          ),
          const SizedBox(height: 10),
          if (pagos.isEmpty)
            _vacio('Aún no hay pagos en el período seleccionado.')
          else ...[
            ...visibles.map((p) {
              final nombre = p['conductor_nombre']?.toString() ?? 'Conductor';
              final concepto = p['concepto']?.toString() ?? 'Cuota';
              final monto = _num(p['monto']);
              final metodo = p['metodo']?.toString() ?? 'efectivo';
              final fecha = _fechaLinda(p['fecha']?.toString());
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: _colorMetodo(metodo).withValues(alpha: 0.11),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _iconoMetodo(metodo),
                        color: _colorMetodo(metodo),
                        size: 17,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nombre,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _kTexto,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '$concepto · $fecha · ${_nombreMetodo(metodo)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _kTextoSuave,
                              fontSize: 9.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '+${_bs(monto)}',
                      style: const TextStyle(
                        color: _kVerde,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              );
            }),
            if (pagos.length > 5)
              Center(
                child: TextButton.icon(
                  onPressed: () =>
                      setState(() => _pagosExpandidos = !_pagosExpandidos),
                  icon: Icon(
                    _pagosExpandidos
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    size: 18,
                  ),
                  label: Text(
                    _pagosExpandidos
                        ? 'Ver menos'
                        : 'Ver todos (${pagos.length})',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: TextButton.styleFrom(foregroundColor: _kVerde),
                ),
              ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Auxiliares de UI
  // ---------------------------------------------------------------------------
  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE9EEF5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _tituloSeccion({
    required IconData icono,
    required String titulo,
    required String subtitulo,
  }) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: _kVerde.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icono, color: _kVerde, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _kTexto,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                subtitulo,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: _kTextoSuave, fontSize: 9.5),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _vacio(String texto) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        texto,
        textAlign: TextAlign.center,
        style: const TextStyle(color: _kTextoSuave, fontSize: 11),
      ),
    );
  }

  Widget _buildError() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 60),
        const Icon(Icons.cloud_off_rounded, color: _kTextoSuave, size: 48),
        const SizedBox(height: 12),
        Text(
          _error ?? 'Ocurrió un error.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: _kTextoSuave, fontSize: 13),
        ),
        const SizedBox(height: 16),
        Center(
          child: ElevatedButton.icon(
            onPressed: _cargar,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Reintentar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kVerde,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

class _CargandoDashboard extends StatelessWidget {
  const _CargandoDashboard();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        SizedBox(height: 140),
        Center(child: CircularProgressIndicator(color: _kVerde)),
        SizedBox(height: 14),
        Center(
          child: Text(
            'Calculando recaudación...',
            style: TextStyle(color: _kTextoSuave, fontSize: 12),
          ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Gráficos
// -----------------------------------------------------------------------------
class _BarrasPainter extends CustomPainter {
  _BarrasPainter({
    required this.datos,
    required this.colorInicio,
    required this.colorFin,
  });

  final List<Map<String, dynamic>> datos;
  final Color colorInicio;
  final Color colorFin;

  static const _meses = [
    'Ene',
    'Feb',
    'Mar',
    'Abr',
    'May',
    'Jun',
    'Jul',
    'Ago',
    'Sep',
    'Oct',
    'Nov',
    'Dic',
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (datos.isEmpty) return;

    final valores = datos
        .map((d) => (d['total'] as num?)?.toDouble() ?? 0.0)
        .toList();
    final maximo = valores.fold<double>(0, math.max);
    final n = datos.length;

    const arriba = 26.0;
    const abajo = 24.0;
    final alto = size.height - arriba - abajo;
    final anchoSlot = size.width / n;
    final anchoBarra = math.min(28.0, anchoSlot * 0.52);

    final gridPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.055)
      ..strokeWidth = 1;
    for (var i = 0; i <= 3; i++) {
      final y = arriba + alto * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    for (var i = 0; i < n; i++) {
      final valor = valores[i];
      final proporcion = maximo <= 0 ? 0.0 : valor / maximo;
      final altura = alto * proporcion;
      final x = anchoSlot * i + (anchoSlot - anchoBarra) / 2;
      final y = arriba + alto - altura;

      if (altura > 0.5) {
        final rect = Rect.fromLTWH(x, y, anchoBarra, altura);
        final paint = Paint()
          ..shader = LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [colorInicio, colorFin],
          ).createShader(rect);
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(7)),
          paint,
        );
      }

      if (valor > 0) {
        _texto(
          canvas,
          _compacto(valor),
          Offset(anchoSlot * i + anchoSlot / 2, math.max(0, y - 15)),
          const TextStyle(
            color: Color(0xFF334155),
            fontSize: 8.5,
            fontWeight: FontWeight.w700,
          ),
          anchoSlot,
        );
      }

      final mes = datos[i]['mes']?.toString() ?? '';
      final etiqueta = _etiquetaMes(mes, _meses);
      _texto(
        canvas,
        etiqueta,
        Offset(anchoSlot * i + anchoSlot / 2, size.height - abajo + 7),
        const TextStyle(color: Color(0xFF8A97A8), fontSize: 9),
        anchoSlot,
      );
    }
  }

  void _texto(
    Canvas canvas,
    String texto,
    Offset centro,
    TextStyle estilo,
    double anchoMaximo,
  ) {
    final tp = TextPainter(
      text: TextSpan(text: texto, style: estilo),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout(maxWidth: anchoMaximo);
    tp.paint(canvas, Offset(centro.dx - tp.width / 2, centro.dy));
  }

  @override
  bool shouldRepaint(covariant _BarrasPainter oldDelegate) {
    return oldDelegate.datos != datos ||
        oldDelegate.colorInicio != colorInicio ||
        oldDelegate.colorFin != colorFin;
  }
}

class _SegmentoDona {
  const _SegmentoDona({required this.valor, required this.color});

  final double valor;
  final Color color;
}

class _DonaPainter extends CustomPainter {
  _DonaPainter({required this.segmentos});

  final List<_SegmentoDona> segmentos;

  @override
  void paint(Canvas canvas, Size size) {
    final total = segmentos.fold<double>(0, (s, e) => s + e.valor);
    if (total <= 0) return;

    final centro = size.center(Offset.zero);
    final radio = math.min(size.width, size.height) / 2 - 9;
    final rect = Rect.fromCircle(center: centro, radius: radio);

    var inicio = -math.pi / 2;
    const separacion = 0.05;

    for (final segmento in segmentos) {
      final barrido = (segmento.valor / total) * 2 * math.pi;
      if (barrido <= 0) continue;

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 17
        ..strokeCap = StrokeCap.butt
        ..color = segmento.color;

      canvas.drawArc(
        rect,
        inicio + separacion / 2,
        math.max(0.01, barrido - separacion),
        false,
        paint,
      );
      inicio += barrido;
    }
  }

  @override
  bool shouldRepaint(covariant _DonaPainter oldDelegate) {
    return oldDelegate.segmentos != segmentos;
  }
}

// -----------------------------------------------------------------------------
// Formato
// -----------------------------------------------------------------------------
String _etiquetaMes(String clave, List<String> meses) {
  final partes = clave.split('-');
  if (partes.length < 2) return clave;
  final mes = int.tryParse(partes[1]);
  if (mes == null || mes < 1 || mes > 12) return clave;
  return meses[mes - 1];
}

String _compacto(double valor) {
  if (valor >= 1000000) {
    return '${(valor / 1000000).toStringAsFixed(1)}M';
  }
  if (valor >= 1000) {
    return '${(valor / 1000).toStringAsFixed(1)}k';
  }
  return valor.toStringAsFixed(0);
}

String _bs(double valor) {
  final negativo = valor < 0;
  final texto = valor.abs().toStringAsFixed(2);
  final partes = texto.split('.');
  final entero = partes[0];
  final buffer = StringBuffer();
  for (var i = 0; i < entero.length; i++) {
    if (i > 0 && (entero.length - i) % 3 == 0) buffer.write(',');
    buffer.write(entero[i]);
  }
  return '${negativo ? '-' : ''}Bs. $buffer.${partes[1]}';
}

String _fechaLinda(String? iso) {
  if (iso == null || iso.length < 10) return '';
  final partes = iso.substring(0, 10).split('-');
  if (partes.length != 3) return iso;
  return '${partes[2]}/${partes[1]}/${partes[0]}';
}

String _inicial(String nombre) {
  final limpio = nombre.trim();
  if (limpio.isEmpty) return '?';
  return limpio[0].toUpperCase();
}

Color _colorMetodo(String? metodo) {
  switch ((metodo ?? '').toLowerCase()) {
    case 'efectivo':
      return _kVerde;
    case 'qr':
      return _kAzul;
    case 'transferencia':
      return _kVioleta;
    default:
      return _kAmbar;
  }
}

IconData _iconoMetodo(String? metodo) {
  switch ((metodo ?? '').toLowerCase()) {
    case 'efectivo':
      return Icons.payments_rounded;
    case 'qr':
      return Icons.qr_code_rounded;
    case 'transferencia':
      return Icons.account_balance_rounded;
    default:
      return Icons.receipt_rounded;
  }
}

String _nombreMetodo(String? metodo) {
  switch ((metodo ?? '').toLowerCase()) {
    case 'efectivo':
      return 'Efectivo';
    case 'qr':
      return 'QR';
    case 'transferencia':
      return 'Transferencia';
    default:
      final m = (metodo ?? '').trim();
      if (m.isEmpty) return 'Otro';
      return m[0].toUpperCase() + m.substring(1);
  }
}
