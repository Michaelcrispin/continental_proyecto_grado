import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/economia_repo.dart';
import '../../services/recibo_pdf_service.dart';

/// Vista E12: Informe Económico (Recaudado vs. Pendiente por Tipo de Cuota y Período)
class InformeEconomicoScreen extends StatefulWidget {
  const InformeEconomicoScreen({super.key});

  @override
  State<InformeEconomicoScreen> createState() => _InformeEconomicoScreenState();
}

class _InformeEconomicoScreenState extends State<InformeEconomicoScreen> {
  DateTime? _fechaDesde;
  DateTime? _fechaHasta;

  Map<String, dynamic>? _informe;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Por defecto: Primer día del mes actual hasta hoy
    final now = DateTime.now();
    _fechaDesde = DateTime(now.year, now.month, 1);
    _fechaHasta = now;
    _cargarInforme();
  }

  Future<void> _cargarInforme() async {
    setState(() => _isLoading = true);
    try {
      final desdeStr = _fechaDesde != null ? DateFormat('yyyy-MM-dd').format(_fechaDesde!) : null;
      final hastaStr = _fechaHasta != null ? DateFormat('yyyy-MM-dd').format(_fechaHasta!) : null;

      final data = await EconomiaRepo.instance.informeEconomico(
        fechaDesde: desdeStr,
        fechaHasta: hastaStr,
      );

      if (mounted) {
        setState(() {
          _informe = data;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _seleccionarRangoFechas() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      initialDateRange: DateTimeRange(
        start: _fechaDesde ?? DateTime(DateTime.now().year, 1, 1),
        end: _fechaHasta ?? DateTime.now(),
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1E3A8A),
              onPrimary: Colors.white,
              onSurface: Color(0xFF1E293B),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _fechaDesde = picked.start;
        _fechaHasta = picked.end;
      });
      _cargarInforme();
    }
  }

  void _exportarPdf() {
    if (_informe == null) return;
    ReciboPdfService.mostrarVistaPreviaInforme(context, _informe!);
  }

  @override
  Widget build(BuildContext context) {
    final recaudado = (_informe?['gran_total_recaudado'] as num?)?.toDouble() ?? 0.0;
    final pendiente = (_informe?['gran_total_pendiente'] as num?)?.toDouble() ?? 0.0;
    final comprometido = recaudado + pendiente;
    final efectividad = comprometido > 0 ? (recaudado / comprometido) * 100 : 0.0;
    final tipos = (_informe?['comparativa_tipos'] as List<dynamic>?) ?? [];

    final desdeLabel = _fechaDesde != null ? DateFormat('dd/MM/yyyy').format(_fechaDesde!) : 'Inicio';
    final hastaLabel = _fechaHasta != null ? DateFormat('dd/MM/yyyy').format(_fechaHasta!) : 'Hoy';

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text('Informe Económico', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Exportar a PDF',
            onPressed: _exportarPdf,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Recargar',
            onPressed: _cargarInforme,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Selector de Período
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.calendar_month, color: Color(0xFF1E3A8A), size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Período de Análisis:', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                              Text(
                                '$desdeLabel  —  $hastaLabel',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
                              ),
                            ],
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: _seleccionarRangoFechas,
                          icon: const Icon(Icons.tune, size: 16),
                          label: const Text('Filtrar', style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF1E3A8A),
                            side: const BorderSide(color: Color(0xFFBFDBFE)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // 2. Tarjetas de Totales Generales
                  Row(
                    children: [
                      _buildMetricCard(
                        titulo: 'Recaudado',
                        monto: 'Bs. ${recaudado.toStringAsFixed(2)}',
                        icono: Icons.payments_outlined,
                        color: const Color(0xFF059669),
                        bgColor: const Color(0xFFECFDF5),
                        borderColor: const Color(0xFFA7F3D0),
                      ),
                      const SizedBox(width: 10),
                      _buildMetricCard(
                        titulo: 'Pendiente',
                        monto: 'Bs. ${pendiente.toStringAsFixed(2)}',
                        icono: Icons.hourglass_top,
                        color: const Color(0xFFDC2626),
                        bgColor: const Color(0xFFFEF2F2),
                        borderColor: const Color(0xFFFECACA),
                      ),
                      const SizedBox(width: 10),
                      _buildMetricCard(
                        titulo: 'Efectividad',
                        monto: '${efectividad.toStringAsFixed(1)}%',
                        icono: Icons.trending_up,
                        color: const Color(0xFF2563EB),
                        bgColor: const Color(0xFFEFF6FF),
                        borderColor: const Color(0xFFBFDBFE),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // 3. Botón de Descarga / Exportación PDF Prominente
                  ElevatedButton.icon(
                    onPressed: _exportarPdf,
                    icon: const Icon(Icons.print_outlined, color: Colors.white),
                    label: const Text(
                      'Descargar / Imprimir Informe en PDF',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // 4. Detalle Comparativo por Tipo de Cuota
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Desglose por Tipo de Cuota',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B)),
                      ),
                      Text(
                        '${tipos.length} conceptos',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  if (tipos.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: Text(
                          'No hay movimientos para el rango seleccionado.',
                          style: TextStyle(color: Color(0xFF64748B)),
                        ),
                      ),
                    )
                  else
                    ...tipos.map((t) => _buildItemTipoCuota(t)),
                ],
              ),
            ),
    );
  }

  Widget _buildMetricCard({
    required String titulo,
    required String monto,
    required IconData icono,
    required Color color,
    required Color bgColor,
    required Color borderColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
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
                  titulo,
                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
                  child: Icon(icono, color: color, size: 14),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              monto,
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: color),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemTipoCuota(dynamic t) {
    final nombre = t['tipo_nombre']?.toString() ?? 'Cuota';
    final rec = (t['recaudado'] as num?)?.toDouble() ?? 0.0;
    final pend = (t['pendiente'] as num?)?.toDouble() ?? 0.0;
    final total = (t['total_comprometido'] as num?)?.toDouble() ?? (rec + pend);
    final porcentaje = total > 0 ? (rec / total) : 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  nombre,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
                ),
                Text(
                  'Comprometido: Bs. ${total.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Barra de progreso
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: porcentaje.clamp(0.0, 1.0),
                backgroundColor: const Color(0xFFFEE2E2),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                minHeight: 7,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text(
                      'Recaudado: Bs. ${rec.toStringAsFixed(2)} (${(porcentaje * 100).toStringAsFixed(0)}%)',
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text(
                      'Pendiente: Bs. ${pend.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: pend > 0 ? const Color(0xFFDC2626) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
