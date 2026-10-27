import 'package:flutter/material.dart';
import '../../../core/permisos.dart';
import '../../../services/economia_repo.dart';
import '../../../services/recibo_pdf_service.dart';
import '../../../services/sesion_service.dart';
import '../../../widgets/avatar_conductor.dart';
import 'dialogo_cobro.dart';

/// Modal Bottom Sheet que muestra el detalle completo de un conductor dentro de una cuota:
/// - Información personal del conductor (Avatar, nombre, CI, teléfono, estado).
/// - Resumen de importes (Total, pagado, saldo pendiente).
/// - Próxima fecha a pagar destacada.
/// - Cronograma de todas las fechas que pagó y no pagó, con acceso a ver recibos o cobrar.
class DetalleConductorCuotasSheet extends StatefulWidget {
  final Map<String, dynamic> conductor;
  final Map<String, dynamic> cuota;
  final VoidCallback onActualizado;

  const DetalleConductorCuotasSheet({
    super.key,
    required this.conductor,
    required this.cuota,
    required this.onActualizado,
  });

  static Future<void> mostrar(
    BuildContext context, {
    required Map<String, dynamic> conductor,
    required Map<String, dynamic> cuota,
    required VoidCallback onActualizado,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DetalleConductorCuotasSheet(
        conductor: conductor,
        cuota: cuota,
        onActualizado: onActualizado,
      ),
    );
  }

  @override
  State<DetalleConductorCuotasSheet> createState() => _DetalleConductorCuotasSheetState();
}

class _DetalleConductorCuotasSheetState extends State<DetalleConductorCuotasSheet> {
  late Map<String, dynamic> _conductorActual;
  List<Map<String, dynamic>> _cronograma = [];
  bool _isLoading = true;
  String _filtroFechas = 'todas'; // 'todas' | 'pagadas' | 'no_pagadas'

  @override
  void initState() {
    super.initState();
    _conductorActual = Map<String, dynamic>.from(widget.conductor);
    _cargarCronograma();
  }

  Future<void> _cargarCronograma() async {
    setState(() => _isLoading = true);
    try {
      final idTipo = widget.cuota['id_tipo_cuota'].toString();
      final idConductor = _conductorActual['id_conductor'].toString();

      final lista = await EconomiaRepo.instance.obtenerCronogramaConductor(
        idTipoCuota: idTipo,
        idConductor: idConductor,
      );

      // Actualizar los datos acumulados del chofer
      final todos = await EconomiaRepo.instance.estadoConductoresPorCuota(idTipo);
      final actualizado = todos.firstWhere(
        (c) => c['id_conductor'].toString() == idConductor,
        orElse: () => _conductorActual,
      );

      if (mounted) {
        setState(() {
          _cronograma = lista;
          _conductorActual = Map<String, dynamic>.from(actualizado);
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _cobrarCuota({
    double? montoEspecifico,
    String? idCuotaEspecifica,
    String? conceptoCuota,
  }) async {
    final cobrado = await DialogoCobro.mostrar(
      context,
      conductor: _conductorActual,
      idTipoCuota: widget.cuota['id_tipo_cuota'].toString(),
      cuotaNombre: widget.cuota['nombre']?.toString() ?? 'Cuota',
      montoInicial: montoEspecifico,
      idCuotaEspecifica: idCuotaEspecifica,
      conceptoCuota: conceptoCuota,
    );

    if (cobrado == true) {
      widget.onActualizado();
      _cargarCronograma();
    }
  }

  Future<void> _verReciboPdf(String? idPago, String? idCuota) async {
    if (idPago == null && idCuota == null) return;
    try {
      final datosRecibo = await EconomiaRepo.instance.obtenerDatosReciboPorPago(
        idPago: idPago,
        idCuota: idCuota,
      );
      if (datosRecibo != null && mounted) {
        ReciboPdfService.mostrarVistaPrevia(context, datosRecibo);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se encontró el comprobante de este pago.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al abrir recibo: $e')),
        );
      }
    }
  }

  String _formatearFechaTexto(String? fechaIso) {
    if (fechaIso == null || fechaIso.trim().isEmpty) return 'Sin fecha';
    try {
      final f = DateTime.parse(fechaIso.trim());
      const dias = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
      const meses = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
      final diaSemana = dias[f.weekday - 1];
      final mes = meses[f.month - 1];
      return '$diaSemana, ${f.day.toString().padLeft(2, '0')} $mes ${f.year}';
    } catch (_) {
      return fechaIso;
    }
  }

  String _formatearFechaLarga(String? fechaIso) {
    if (fechaIso == null || fechaIso.trim().isEmpty) return 'Sin fecha programada';
    try {
      final f = DateTime.parse(fechaIso.trim());
      const dias = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
      const meses = ['Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'];
      final diaSemana = dias[f.weekday - 1];
      final mes = meses[f.month - 1];
      return '$diaSemana, ${f.day} de $mes de ${f.year}';
    } catch (_) {
      return fechaIso;
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final puedeEditar = Permisos.puedeEditar(
      SesionService.instance.rol,
      Permisos.moduloControlEconomico,
    );

    final nombre = _conductorActual['conductor_nombre']?.toString() ?? 'Conductor';
    final ci = _conductorActual['conductor_ci']?.toString() ?? 'S/CI';
    final foto = _conductorActual['conductor_foto']?.toString();
    final telefono = _conductorActual['conductor_telefono']?.toString();

    final total = (_conductorActual['monto_total'] as num?)?.toDouble() ?? 0.0;
    final pagado = (_conductorActual['monto_pagado'] as num?)?.toDouble() ?? 0.0;
    final falta = (_conductorActual['monto_falta'] as num?)?.toDouble() ?? (total - pagado);
    final alDia = falta <= 0.001;

    final proximaFecha = _conductorActual['proxima_fecha_pago']?.toString();
    final proximoMonto = (_conductorActual['proximo_monto_pago'] as num?)?.toDouble() ?? 0.0;
    final proximaIdCuota = _conductorActual['proxima_id_cuota']?.toString();

    // Contadores para chips
    int pagadasCount = 0;
    int noPagadasCount = 0;
    final hoyStr = DateTime.now().toIso8601String().substring(0, 10);

    for (final item in _cronograma) {
      final mFalta = (item['monto_falta'] as num?)?.toDouble() ?? 0.0;
      if (mFalta <= 0.001) {
        pagadasCount++;
      } else {
        noPagadasCount++;
      }
    }

    // Filtrado de cronograma
    final listaFiltrada = _cronograma.where((item) {
      final mFalta = (item['monto_falta'] as num?)?.toDouble() ?? 0.0;
      final estaPagada = mFalta <= 0.001;
      if (_filtroFechas == 'pagadas') return estaPagada;
      if (_filtroFechas == 'no_pagadas') return !estaPagada;
      return true;
    }).toList();

    return Container(
      height: size.height * 0.90,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: Column(
        children: [
          // Tirador de arrastre superior
          const SizedBox(height: 10),
          Center(
            child: Container(
              width: 44,
              height: 4.5,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // CABECERA DEL MODAL: Título y botón cerrar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Detalle del Conductor',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F2B5B),
                      ),
                    ),
                    Text(
                      widget.cuota['nombre']?.toString() ?? 'Cuota',
                      style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF1E3A8A)))
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. TARJETA DE PERFIL DEL CONDUCTOR
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            children: [
                              AvatarConductor(
                                foto: foto,
                                nombre: nombre,
                                radio: 26,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      nombre,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Color(0xFF0F2B5B),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'CI: $ci ${telefono != null && telefono.isNotEmpty ? ' • Cel: $telefono' : ''}',
                                      style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                                    ),
                                    const SizedBox(height: 6),
                                    // Badge de estado general
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: alDia ? const Color(0xFFD1FAE5) : const Color(0xFFFEF3C7),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            alDia ? Icons.check_circle_rounded : Icons.schedule_rounded,
                                            size: 13,
                                            color: alDia ? const Color(0xFF059669) : const Color(0xFFD97706),
                                          ),
                                          const SizedBox(width: 5),
                                          Text(
                                            alDia
                                                ? 'Al día con todas las cuotas'
                                                : 'Pendiente · Debe $noPagadasCount de ${_cronograma.length} cuotas',
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.bold,
                                              color: alDia ? const Color(0xFF065F46) : const Color(0xFF92400E),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // 2. INDICADORES FINANCIEROS (3 CAJAS)
                        Row(
                          children: [
                            Expanded(
                              child: _buildKpiBox(
                                'Total Cuota',
                                'Bs. ${total.toStringAsFixed(0)}',
                                const Color(0xFF0F2B5B),
                                const Color(0xFFF8FAFC),
                                const Color(0xFFE2E8F0),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildKpiBox(
                                'Total Pagado',
                                'Bs. ${pagado.toStringAsFixed(0)}',
                                const Color(0xFF059669),
                                const Color(0xFFECFDF5),
                                const Color(0xFFA7F3D0),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildKpiBox(
                                'Saldo Falta',
                                'Bs. ${falta.toStringAsFixed(0)}',
                                const Color(0xFFDC2626),
                                const Color(0xFFFEF2F2),
                                const Color(0xFFFECACA),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // 3. TARJETA DESTACADA: PRÓXIMA FECHA A PAGAR
                        if (!alDia && proximaFecha != null) ...[
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFEFF6FF), Color(0xFFDBEAFE)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: const Color(0xFFBFDBFE)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF2563EB),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(Icons.event_available_rounded, color: Colors.white, size: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'PRÓXIMA FECHA A PAGAR',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF1D4ED8),
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            _formatearFechaLarga(proximaFecha),
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF0F2B5B),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Monto: Bs. ${proximoMonto > 0 ? proximoMonto.toStringAsFixed(2) : (widget.cuota['monto_sugerido'] ?? 50).toString()}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: Color(0xFF1E3A8A),
                                      ),
                                    ),
                                    if (puedeEditar)
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF10B981),
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                        onPressed: () => _cobrarCuota(
                                          montoEspecifico: proximoMonto > 0 ? proximoMonto : null,
                                          idCuotaEspecifica: proximaIdCuota,
                                          conceptoCuota: 'Próxima Cuota · ${_formatearFechaTexto(proximaFecha)}',
                                        ),
                                        icon: const Icon(Icons.payments_outlined, size: 16),
                                        label: const Text('Pagar Esta Cuota', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ] else if (alDia) ...[
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: const Color(0xFFA7F3D0)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.verified_rounded, color: Color(0xFF059669), size: 24),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    '¡Conductor al día! No tiene pagos pendientes para este ahorro/cuota.',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF065F46)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // 4. CRONOGRAMA DE FECHAS (LISTADO PAGÓ VS NO PAGÓ)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'CRONOGRAMA DE FECHAS',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F2B5B),
                                letterSpacing: 0.4,
                              ),
                            ),
                            Text(
                              '${_cronograma.length} cuotas',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Chips de filtrado de fechas
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildChip('todas', 'Todas (${_cronograma.length})'),
                              const SizedBox(width: 8),
                              _buildChip('pagadas', 'Pagó ($pagadasCount)', color: const Color(0xFF059669)),
                              const SizedBox(width: 8),
                              _buildChip('no_pagadas', 'No pagó ($noPagadasCount)', color: const Color(0xFFDC2626)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Listado de cuotas programadas
                        if (listaFiltrada.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(24),
                            alignment: Alignment.center,
                            child: const Text(
                              'No hay fechas para mostrar en esta categoría.',
                              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: listaFiltrada.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 8),
                            itemBuilder: (context, idx) {
                              final item = listaFiltrada[idx];
                              final idCuota = item['id_cuota']?.toString() ?? '';
                              final idPago = item['id_pago']?.toString();
                              final nroRecibo = item['nro_recibo']?.toString();
                              final monto = (item['monto'] as num?)?.toDouble() ?? 0.0;
                              final pagadoItem = (item['monto_pagado'] as num?)?.toDouble() ?? 0.0;
                              final saldoItem = (item['monto_falta'] as num?)?.toDouble() ?? (monto - pagadoItem);
                              final estaPagada = saldoItem <= 0.001;

                              final fVencStr = item['fecha_vencimiento']?.toString();
                              final esVencida = !estaPagada && fVencStr != null && fVencStr.compareTo(hoyStr) < 0;
                              final fechaPago = item['fecha_pago']?.toString();
                              final metodoPago = item['metodo_pago']?.toString() ?? 'efectivo';
                              final concepto = item['concepto']?.toString() ?? 'Cuota ${idx + 1}';

                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: estaPagada
                                        ? const Color(0xFFD1FAE5)
                                        : (esVencida ? const Color(0xFFFECACA) : const Color(0xFFE2E8F0)),
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x040F2B5B),
                                      blurRadius: 6,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    // Icono de estado
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: estaPagada
                                            ? const Color(0xFFECFDF5)
                                            : (esVencida ? const Color(0xFFFEF2F2) : const Color(0xFFFFFBEB)),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        estaPagada
                                            ? Icons.check_circle_rounded
                                            : (esVencida ? Icons.error_outline_rounded : Icons.schedule_rounded),
                                        size: 20,
                                        color: estaPagada
                                            ? const Color(0xFF10B981)
                                            : (esVencida ? const Color(0xFFEF4444) : const Color(0xFFF59E0B)),
                                      ),
                                    ),
                                    const SizedBox(width: 12),

                                    // Contenido de la cuota
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  _formatearFechaTexto(fVencStr),
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13.5,
                                                    color: Color(0xFF0F2B5B),
                                                  ),
                                                ),
                                              ),
                                              Text(
                                                'Bs. ${monto.toStringAsFixed(0)}',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                  color: Color(0xFF1E3A8A),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            concepto,
                                            style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),

                                          // Estado descriptivo
                                          if (estaPagada) ...[
                                            Row(
                                              children: [
                                                const Icon(Icons.check, size: 12, color: Color(0xFF059669)),
                                                const SizedBox(width: 3),
                                                Expanded(
                                                  child: Text(
                                                    'Pagó: ${_formatearFechaTexto(fechaPago)} ${nroRecibo != null ? '· $nroRecibo' : ''} (${metodoPago.toUpperCase()})',
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      color: Color(0xFF059669),
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ] else if (esVencida) ...[
                                            Row(
                                              children: [
                                                const Icon(Icons.warning_amber_rounded, size: 12, color: Color(0xFFDC2626)),
                                                const SizedBox(width: 3),
                                                const Text(
                                                  'NO PAGÓ · Vencida',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: Color(0xFFDC2626),
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ] else ...[
                                            Row(
                                              children: [
                                                const Icon(Icons.calendar_today_outlined, size: 11, color: Color(0xFFD97706)),
                                                const SizedBox(width: 3),
                                                const Text(
                                                  'Pendiente a pagar',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: Color(0xFFD97706),
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),

                                    // Acción: Ver recibo (si pagada) o botón Cobrar (si pendiente)
                                    if (estaPagada)
                                      IconButton(
                                        icon: const Icon(Icons.receipt_long_rounded, color: Color(0xFF1E3A8A), size: 20),
                                        tooltip: 'Ver Recibo PDF',
                                        onPressed: () => _verReciboPdf(idPago, idCuota),
                                      )
                                    else if (puedeEditar)
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF10B981),
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          minimumSize: Size.zero,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                        onPressed: () => _cobrarCuota(
                                          montoEspecifico: saldoItem,
                                          idCuotaEspecifica: idCuota,
                                          conceptoCuota: concepto,
                                        ),
                                        child: const Text('Cobrar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5)),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
          ),

          // BARRA INFERIOR DE ACCIÓN (REGISTRAR PAGO GENERAL)
          if (!alDia && puedeEditar)
            Container(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  onPressed: () => _cobrarCuota(),
                  icon: const Icon(Icons.payments_rounded, size: 20),
                  label: Text(
                    'Registrar Pago (Falta Bs. ${falta.toStringAsFixed(0)})',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildKpiBox(String label, String valor, Color color, Color bg, Color border) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          const SizedBox(height: 3),
          Text(
            valor,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String filtro, String texto, {Color? color}) {
    final activo = _filtroFechas == filtro;
    return GestureDetector(
      onTap: () => setState(() => _filtroFechas = filtro),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: activo ? const Color(0xFF1E3A8A) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: activo ? const Color(0xFF1E3A8A) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          texto,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: activo ? FontWeight.bold : FontWeight.normal,
            color: activo ? Colors.white : (color ?? const Color(0xFF475569)),
          ),
        ),
      ),
    );
  }
}
