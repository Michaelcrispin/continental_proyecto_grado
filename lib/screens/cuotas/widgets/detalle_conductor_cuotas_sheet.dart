import 'package:flutter/material.dart';
import '../../../core/permisos.dart';
import '../../../services/economia_repo.dart';
import '../../../services/sesion_service.dart';
import '../../../widgets/avatar_conductor.dart';
import 'dialogo_cobro.dart';
import 'dialogo_recibo_modal.dart';
import 'dialogo_informe_whatsapp.dart';

const _kVerdeOscuro = Color(0xFF02634C);

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
  State<DetalleConductorCuotasSheet> createState() =>
      _DetalleConductorCuotasSheetState();
}

class _DetalleConductorCuotasSheetState
    extends State<DetalleConductorCuotasSheet> {
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
      final todos = await EconomiaRepo.instance.estadoConductoresPorCuota(
        idTipo,
      );
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
    double? montoMaximo,
    String? idCuotaEspecifica,
    String? conceptoCuota,
  }) async {
    final cobrado = await DialogoCobro.mostrar(
      context,
      conductor: _conductorActual,
      idTipoCuota: widget.cuota['id_tipo_cuota'].toString(),
      cuotaNombre: widget.cuota['nombre']?.toString() ?? 'Cuota',
      montoInicial: montoEspecifico,
      montoMaximo: montoMaximo,
      idCuotaEspecifica: idCuotaEspecifica,
      conceptoCuota: conceptoCuota,
    );

    if (cobrado == true) {
      widget.onActualizado();
      _cargarCronograma();
    }
  }

  Future<void> _verRecibo(String? idPago, String? idCuota) async {
    if (idPago == null && idCuota == null) return;
    try {
      final datosRecibo = await EconomiaRepo.instance.obtenerDatosReciboPorPago(
        idPago: idPago,
        idCuota: idCuota,
      );
      if (datosRecibo != null && mounted) {
        await DialogoReciboModal.mostrar(context, datosRecibo);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se encontró el comprobante de este pago.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al abrir recibo: $e')));
      }
    }
  }

  String _formatearFechaTexto(String? fechaIso) {
    if (fechaIso == null || fechaIso.trim().isEmpty) return 'Sin fecha';
    try {
      final f = DateTime.parse(fechaIso.trim());
      const dias = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
      const meses = [
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
      final diaSemana = dias[f.weekday - 1];
      final mes = meses[f.month - 1];
      return '$diaSemana, ${f.day.toString().padLeft(2, '0')} $mes ${f.year}';
    } catch (_) {
      return fechaIso;
    }
  }

  String _formatearFechaLarga(String? fechaIso) {
    if (fechaIso == null || fechaIso.trim().isEmpty) {
      return 'Sin fecha programada';
    }
    try {
      final f = DateTime.parse(fechaIso.trim());
      const dias = [
        'Lunes',
        'Martes',
        'Miércoles',
        'Jueves',
        'Viernes',
        'Sábado',
        'Domingo',
      ];
      const meses = [
        'Enero',
        'Febrero',
        'Marzo',
        'Abril',
        'Mayo',
        'Junio',
        'Julio',
        'Agosto',
        'Septiembre',
        'Octubre',
        'Noviembre',
        'Diciembre',
      ];
      final diaSemana = dias[f.weekday - 1];
      final mes = meses[f.month - 1];
      return '$diaSemana, ${f.day} de $mes de ${f.year}';
    } catch (_) {
      return fechaIso;
    }
  }

  String _nombreMesAnio(String claveYm) {
    const meses = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];
    final partes = claveYm.split('-');
    if (partes.length >= 2) {
      final anio = partes[0];
      final mesNum = int.tryParse(partes[1]) ?? 1;
      if (mesNum >= 1 && mesNum <= 12) {
        return '${meses[mesNum - 1]} $anio';
      }
    }
    return claveYm;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final puedeEditar = Permisos.puedeEditar(
      SesionService.instance.rol,
      Permisos.moduloControlEconomico,
    );

    final nombre =
        _conductorActual['conductor_nombre']?.toString() ?? 'Conductor';
    final ci = _conductorActual['conductor_ci']?.toString() ?? 'S/CI';
    final foto = _conductorActual['conductor_foto']?.toString();
    final telefono = _conductorActual['conductor_telefono']?.toString();

    final total = (_conductorActual['monto_total'] as num?)?.toDouble() ?? 0.0;
    final pagado =
        (_conductorActual['monto_pagado'] as num?)?.toDouble() ?? 0.0;
    final falta =
        (_conductorActual['monto_falta'] as num?)?.toDouble() ??
        (total - pagado);
    final alDia = falta <= 0.001;

    final proximaFecha = _conductorActual['proxima_fecha_pago']?.toString();
    final proximoMonto =
        (_conductorActual['proximo_monto_pago'] as num?)?.toDouble() ?? 0.0;
    final proximaIdCuota = _conductorActual['proxima_id_cuota']?.toString();
    final esCuotaUnica = _cronograma.length <= 1;

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

    final categoria =
        (widget.cuota['categoria'] ?? _conductorActual['categoria'])
            ?.toString()
            .toLowerCase();
    final esCanaston = categoria == 'canaston';
    final descCuota = (widget.cuota['descripcion'] ?? '')
        .toString()
        .toLowerCase();
    final nombreCuota = (widget.cuota['nombre'] ?? '').toString().toLowerCase();
    final esMensual =
        descCuota.contains('mensual') ||
        descCuota.contains('mes') ||
        nombreCuota.contains('mensual');
    final periodoNombre = esMensual ? 'este mes' : 'esta semana';
    final periodoMayus = esMensual ? 'ESTE MES' : 'ESTA SEMANA';

    // 1. Fechas únicas del cronograma
    final fechasProgramadas =
        _cronograma
            .map(
              (it) =>
                  (it['fecha_vencimiento'] ?? it['fecha'])?.toString().trim() ??
                  '',
            )
            .where((f) => f.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    // 2. Determinar la fecha de ESTA SEMANA para Canastón (sin avanzar a fechas futuras)
    final fechaSemanaActual = esCanaston
        ? DialogoInformeWhatsapp.determinarFechaSemanaActual(fechasProgramadas)
        : '';

    // 3. Evaluar cuotas vencidas o de esta semana (fecha <= fechaSemanaActual)
    Map<String, dynamic>? cuotaPendienteSemanaActual;
    double deudaHastaEstaSemana = 0.0;
    int cuotasPendientesHastaEstaSemana = 0;

    for (final item in _cronograma) {
      final f =
          (item['fecha_vencimiento'] ?? item['fecha'])?.toString().trim() ?? '';
      final mFalta = (item['monto_falta'] as num?)?.toDouble() ?? 0.0;

      if (esCanaston) {
        if (f.isNotEmpty && f.compareTo(fechaSemanaActual) <= 0) {
          if (mFalta > 0.001) {
            deudaHastaEstaSemana += mFalta;
            cuotasPendientesHastaEstaSemana++;
            cuotaPendienteSemanaActual ??= item;
          }
        }
      } else {
        if (mFalta > 0.001) {
          deudaHastaEstaSemana += mFalta;
          cuotasPendientesHastaEstaSemana++;
          cuotaPendienteSemanaActual ??= item;
        }
      }
    }

    final alDiaEstaSemana = esCanaston
        ? cuotasPendientesHastaEstaSemana == 0
        : alDia;

    final fechaAMostrar = esCanaston
        ? ((cuotaPendienteSemanaActual?['fecha_vencimiento'] ??
                  cuotaPendienteSemanaActual?['fecha'])
              ?.toString())
        : proximaFecha;

    final montoAMostrar = esCanaston
        ? ((cuotaPendienteSemanaActual?['monto_falta'] as num?)?.toDouble() ??
              proximoMonto)
        : proximoMonto;

    final idCuotaAMostrar = esCanaston
        ? (cuotaPendienteSemanaActual?['id_cuota']?.toString())
        : proximaIdCuota;

    // Agrupación de fechas por mes (YYYY-MM) para Canastón
    final Map<String, List<Map<String, dynamic>>> gruposPorMes = {};
    if (esCanaston) {
      for (final item in listaFiltrada) {
        final f =
            (item['fecha_vencimiento'] ?? item['fecha'])?.toString().trim() ??
            '';
        final claveMes = f.length >= 7 ? f.substring(0, 7) : 'GENERAL';
        gruposPorMes.putIfAbsent(claveMes, () => []).add(item);
      }
    }

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
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    Text(
                      widget.cuota['nombre']?.toString() ?? 'Cuota',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: _kVerdeOscuro),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. TARJETA DE PERFIL DEL CONDUCTOR
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFFE2E8F0),
                              width: 1.1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              AvatarConductor(
                                foto: foto,
                                nombre: nombre,
                                radio: 32,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      nombre,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 17.5,
                                        color: Color(0xFF1E293B),
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      'CI: $ci ${telefono != null && telefono.isNotEmpty ? ' • Cel: $telefono' : ''}',
                                      style: const TextStyle(
                                        fontSize: 13.5,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                    const SizedBox(height: 7),
                                    // Badge de estado general
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 11,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: alDiaEstaSemana
                                            ? const Color(0xFFD1FAE5)
                                            : const Color(0xFFFEF3C7),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            alDiaEstaSemana
                                                ? Icons.check_circle_rounded
                                                : Icons.schedule_rounded,
                                            size: 15,
                                            color: alDiaEstaSemana
                                                ? const Color(0xFF059669)
                                                : const Color(0xFFD97706),
                                          ),
                                          const SizedBox(width: 6),
                                          Flexible(
                                            child: Text(
                                              alDiaEstaSemana
                                                  ? (alDia
                                                        ? 'Al día con todas las cuotas'
                                                        : 'Al día con esta semana ($pagadasCount pagadas)')
                                                  : (esCanaston
                                                        ? 'Pendiente · Debe cuota de esta semana'
                                                        : 'Pendiente · Debe Bs. ${falta.toStringAsFixed(0)}'),
                                              style: TextStyle(
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.bold,
                                                color: alDiaEstaSemana
                                                    ? const Color(0xFF065F46)
                                                    : const Color(0xFF92400E),
                                              ),
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

                        // TARJETA DESTACADA: PRÓXIMA FECHA A PAGAR (SOLO DE ESTA SEMANA)
                        if (!alDiaEstaSemana && fechaAMostrar != null) ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFBEB),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFFFDE68A),
                                width: 1.2,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFD97706),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.event_available_rounded,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            esCuotaUnica
                                                ? 'FECHA DE PAGO'
                                                : (fechaAMostrar ==
                                                          fechaSemanaActual
                                                      ? 'CUOTA DE ESTA SEMANA'
                                                      : 'CUOTA PENDIENTE (RETRASADA)'),
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFFB45309),
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            _formatearFechaLarga(fechaAMostrar),
                                            style: const TextStyle(
                                              fontSize: 16.5,
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xFF1E293B),
                                              height: 1.2,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Monto: Bs. ${montoAMostrar.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15.5,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                    if (puedeEditar)
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: _kVerdeOscuro,
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 10,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                        onPressed: () => _cobrarCuota(
                                          montoEspecifico: montoAMostrar > 0
                                              ? montoAMostrar
                                              : null,
                                          montoMaximo: montoAMostrar > 0
                                              ? montoAMostrar
                                              : null,
                                          idCuotaEspecifica: idCuotaAMostrar,
                                          conceptoCuota: esCuotaUnica
                                              ? null
                                              : 'Cuota · ${_formatearFechaTexto(fechaAMostrar)}',
                                        ),
                                        icon: const Icon(
                                          Icons.payments_outlined,
                                          size: 18,
                                        ),
                                        label: Text(
                                          esCuotaUnica
                                              ? 'Pagar Cuota'
                                              : 'Pagar Esta Cuota',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13.5,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ] else if (alDiaEstaSemana) ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFFA7F3D0),
                                width: 1.2,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: _kVerdeOscuro,
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: [
                                      BoxShadow(
                                        color: _kVerdeOscuro.withOpacity(0.25),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.verified_rounded,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        alDia
                                            ? 'CONDUCTOR AL DÍA'
                                            : 'AL DÍA ($periodoMayus)',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF059669),
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        alDia
                                            ? '¡Conductor al día!'
                                            : '¡Conductor al día $periodoNombre!',
                                        style: const TextStyle(
                                          fontSize: 16.5,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF065F46),
                                          height: 1.2,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        alDia
                                            ? 'No tiene pagos pendientes para esta cuota.'
                                            : 'Ya pagó la cuota correspondiente a esta fecha.',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF047857),
                                        ),
                                      ),
                                    ],
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
                                color: Color(0xFF1E293B),
                                letterSpacing: 0.4,
                              ),
                            ),
                            Text(
                              '${_cronograma.length} cuotas',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Chips de filtrado de fechas
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildChip(
                                'todas',
                                'Todas (${_cronograma.length})',
                              ),
                              const SizedBox(width: 8),
                              _buildChip(
                                'pagadas',
                                'Pagó ($pagadasCount)',
                                color: const Color(0xFF059669),
                              ),
                              const SizedBox(width: 8),
                              _buildChip(
                                'no_pagadas',
                                'No pagó ($noPagadasCount)',
                                color: const Color(0xFFDC2626),
                              ),
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
                              style: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 13,
                              ),
                            ),
                          )
                        else if (esCanaston)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (final entry in gruposPorMes.entries) ...[
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: 14,
                                    bottom: 8,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4.5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE8F5EF),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: const Color(0xFFE8F5EF),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.calendar_month_rounded,
                                              size: 14,
                                              color: _kVerdeOscuro,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              _nombreMesAnio(
                                                entry.key,
                                              ).toUpperCase(),
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w800,
                                                color: _kVerdeOscuro,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      const Expanded(
                                        child: Divider(
                                          color: Color(0xFFE2E8F0),
                                          thickness: 1,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${entry.value.length} ${entry.value.length == 1 ? 'cuota' : 'cuotas'}',
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          color: Color(0xFF64748B),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: entry.value.length,
                                  separatorBuilder: (_, _) =>
                                      const SizedBox(height: 8),
                                  itemBuilder: (context, idx) =>
                                      _buildItemCuota(
                                        entry.value[idx],
                                        idx,
                                        hoyStr,
                                        puedeEditar,
                                      ),
                                ),
                              ],
                            ],
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: listaFiltrada.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, idx) => _buildItemCuota(
                              listaFiltrada[idx],
                              idx,
                              hoyStr,
                              puedeEditar,
                            ),
                          ),
                      ],
                    ),
                  ),
          ),

          // BARRA INFERIOR DE ACCIÓN (REGISTRAR PAGO DE ESTA SEMANA)
          if (!alDiaEstaSemana && puedeEditar)
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
                    backgroundColor: _kVerdeOscuro,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () => _cobrarCuota(
                    montoEspecifico:
                        esCanaston && cuotaPendienteSemanaActual != null
                        ? (cuotaPendienteSemanaActual['monto_falta'] as num?)
                              ?.toDouble()
                        : null,
                    montoMaximo:
                        esCanaston && cuotaPendienteSemanaActual != null
                        ? (cuotaPendienteSemanaActual['monto_falta'] as num?)
                              ?.toDouble()
                        : null,
                    idCuotaEspecifica:
                        esCanaston && cuotaPendienteSemanaActual != null
                        ? cuotaPendienteSemanaActual['id_cuota']?.toString()
                        : null,
                    conceptoCuota:
                        esCanaston && cuotaPendienteSemanaActual != null
                        ? 'Cuota · ${_formatearFechaTexto(fechaAMostrar)}'
                        : null,
                  ),
                  icon: const Icon(Icons.payments_rounded, size: 20),
                  label: Text(
                    esCanaston
                        ? 'Pagar Cuota de Esta Semana (Bs. ${deudaHastaEstaSemana.toStringAsFixed(0)})'
                        : 'Registrar Pago (Falta Bs. ${falta.toStringAsFixed(0)})',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChip(String filtro, String texto, {Color? color}) {
    final activo = _filtroFechas == filtro;
    final chipColor = color ?? _kVerdeOscuro;
    return GestureDetector(
      onTap: () => setState(() => _filtroFechas = filtro),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 6.5),
        decoration: BoxDecoration(
          color: activo ? chipColor : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: activo ? chipColor : const Color(0xFFE2E8F0),
            width: 1.2,
          ),
          boxShadow: activo
              ? [
                  BoxShadow(
                    color: chipColor.withOpacity(0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: Text(
          texto,
          style: TextStyle(
            fontSize: 12,
            fontWeight: activo ? FontWeight.w700 : FontWeight.w600,
            color: activo ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  Widget _buildItemCuota(
    Map<String, dynamic> item,
    int idx,
    String hoyStr,
    bool puedeEditar,
  ) {
    final idCuota = item['id_cuota']?.toString() ?? '';
    final idPago = item['id_pago']?.toString();
    final monto = (item['monto'] as num?)?.toDouble() ?? 0.0;
    final pagadoItem = (item['monto_pagado'] as num?)?.toDouble() ?? 0.0;
    final saldoItem =
        (item['monto_falta'] as num?)?.toDouble() ?? (monto - pagadoItem);
    final estaPagada = saldoItem <= 0.001;

    final fVencStr = item['fecha_vencimiento']?.toString();
    final esVencida =
        !estaPagada && fVencStr != null && fVencStr.compareTo(hoyStr) < 0;
    final fechaPago = item['fecha_pago']?.toString();
    final metodoPago = item['metodo_pago']?.toString() ?? 'efectivo';
    final concepto = item['concepto']?.toString() ?? 'Cuota ${idx + 1}';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: estaPagada ? () => _verRecibo(idPago, idCuota) : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: estaPagada
                  ? const Color(0xFFD1FAE5)
                  : (esVencida
                        ? const Color(0xFFFECACA)
                        : const Color(0xFFE2E8F0)),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x041E293B),
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
                      : (esVencida
                            ? const Color(0xFFFEF2F2)
                            : const Color(0xFFFFFBEB)),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  estaPagada
                      ? Icons.check_circle_rounded
                      : (esVencida
                            ? Icons.error_outline_rounded
                            : Icons.schedule_rounded),
                  size: 20,
                  color: estaPagada
                      ? const Color(0xFF10B981)
                      : (esVencida
                            ? const Color(0xFFEF4444)
                            : const Color(0xFFF59E0B)),
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
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ),
                        Text(
                          'Bs. ${monto.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: _kVerdeOscuro,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      concepto,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF64748B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Estado descriptivo
                    if (estaPagada) ...[
                      Row(
                        children: [
                          const Icon(
                            Icons.check_rounded,
                            size: 13,
                            color: Color(0xFF059669),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Pagó: ${_formatearFechaTexto(fechaPago)} (${metodoPago.toUpperCase()})',
                              style: const TextStyle(
                                fontSize: 11.5,
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
                          const Icon(
                            Icons.warning_amber_rounded,
                            size: 12,
                            color: Color(0xFFDC2626),
                          ),
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
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 11,
                            color: Color(0xFFD97706),
                          ),
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
                InkWell(
                  onTap: () => _verRecibo(idPago, idCuota),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5EF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Color(0x3302634C)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.visibility_outlined,
                          size: 14,
                          color: Color(0xFFB45309),
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Recibo',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFB45309),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else if (puedeEditar)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kVerdeOscuro,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    minimumSize: Size.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => _cobrarCuota(
                    montoEspecifico: saldoItem,
                    montoMaximo: saldoItem,
                    idCuotaEspecifica: idCuota,
                    conceptoCuota: concepto,
                  ),
                  child: const Text(
                    'Cobrar',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11.5,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
