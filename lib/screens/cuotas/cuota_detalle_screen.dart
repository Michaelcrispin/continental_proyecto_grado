import 'package:flutter/material.dart';
import '../../core/permisos.dart';
import '../../services/economia_repo.dart';
import '../../services/recibo_pdf_service.dart';
import '../../services/sesion_service.dart';
import '../../widgets/avatar_conductor.dart';
import 'widgets/detalle_conductor_cuotas_sheet.dart';
import 'widgets/dialogo_informe_whatsapp.dart';
import 'widgets/dialogo_nueva_cuota.dart';

const _kVerdeOscuro = Color(0xFF02634C);

/// Pantalla de Detalle de una Cuota específica con diseño corporativo verde.
/// Muestra los indicadores clave (recaudado vs falta), resumen de la cuota,
/// opciones de informe PDF, edición y la lista de todos los choferes con su estado de pago.
class CuotaDetalleScreen extends StatefulWidget {
  final Map<String, dynamic> cuota;

  const CuotaDetalleScreen({super.key, required this.cuota});

  @override
  State<CuotaDetalleScreen> createState() => _CuotaDetalleScreenState();
}

class _CuotaDetalleScreenState extends State<CuotaDetalleScreen> {
  late Map<String, dynamic> _cuotaActual;
  List<Map<String, dynamic>> _conductores = [];
  List<Map<String, dynamic>> _conductoresFiltrados = [];
  bool _isLoading = true;

  String _busqueda = '';
  String _filtroEstado = 'todos'; // 'todos' | 'pagados' | 'deben'
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cuotaActual = Map<String, dynamic>.from(widget.cuota);
    _cargarConductores();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarConductores() async {
    setState(() => _isLoading = true);
    try {
      final idTipo = _cuotaActual['id_tipo_cuota'].toString();
      final lista = await EconomiaRepo.instance.estadoConductoresPorCuota(idTipo);

      // Actualizar también los datos actuales de la cuota desde la BD
      final tipos = await EconomiaRepo.instance.listarCuotasConResumen();
      final actualizada = tipos.firstWhere(
        (t) => t['id_tipo_cuota'].toString() == idTipo,
        orElse: () => _cuotaActual,
      );

      final matriz = await EconomiaRepo.instance.obtenerMatrizCronogramaPorCuota(idTipo);

      // Fechas únicas ordenadas del cronograma
      final fechasSet = <String>{};
      for (final r in matriz) {
        final f = r['fecha_programada']?.toString().trim() ?? '';
        if (f.isNotEmpty) fechasSet.add(f);
      }
      final fechasOrdenadas = fechasSet.toList()..sort();
      final esPeriodica = fechasOrdenadas.length > 1;

      // Detectar periodicidad: mensual vs semanal
      final desc = (actualizada['descripcion'] ?? '').toString().toLowerCase();
      final nombreC = (actualizada['nombre'] ?? '').toString().toLowerCase();
      bool esMensual = desc.contains('mensual') || desc.contains('mes') || nombreC.contains('mensual');
      if (!esMensual && fechasOrdenadas.length >= 2) {
        try {
          final d1 = DateTime.parse(fechasOrdenadas[0]);
          final d2 = DateTime.parse(fechasOrdenadas[1]);
          if (d2.difference(d1).inDays >= 20) {
            esMensual = true;
          }
        } catch (_) {}
      }

      // Determinar la fecha límite del periodo actual (esta semana o este mes)
      String fechaPeriodoActual = '';
      if (esPeriodica) {
        if (esMensual) {
          final ahora = DateTime.now();
          final limiteMes = DateTime(ahora.year, ahora.month + 1, 0)
              .toIso8601String()
              .substring(0, 10);
          fechaPeriodoActual = fechasOrdenadas.first;
          for (final f in fechasOrdenadas) {
            if (f.compareTo(limiteMes) <= 0) {
              fechaPeriodoActual = f;
            } else {
              break;
            }
          }
        } else {
          fechaPeriodoActual = DialogoInformeWhatsapp.determinarFechaSemanaActual(fechasOrdenadas);
        }
      }

      // Agrupar filas del cronograma por conductor
      final Map<String, List<Map<String, dynamic>>> matrizPorConductor = {};
      for (final r in matriz) {
        final idCond = r['id_conductor']?.toString() ?? '';
        if (idCond.isNotEmpty) {
          matrizPorConductor.putIfAbsent(idCond, () => []).add(r);
        }
      }

      // Enriquecer cada conductor con su estado respecto a este periodo (sin computar fechas futuras)
      final List<Map<String, dynamic>> listaEnriquecida = [];
      for (final c in lista) {
        final cMod = Map<String, dynamic>.from(c);
        final faltaTotal = (cMod['monto_falta'] as num?)?.toDouble() ?? 0.0;
        final todoPagado = faltaTotal <= 0.001;

        if (esPeriodica) {
          final idCond = cMod['id_conductor']?.toString() ?? '';
          final cuotasChofer = matrizPorConductor[idCond] ?? [];

          double deudaPeriodo = 0.0;
          int cuotasPendientesPeriodo = 0;
          String? proxFechaPeriodo;

          for (final q in cuotasChofer) {
            final f = q['fecha_programada']?.toString().trim() ?? '';
            final monto = (q['monto'] as num?)?.toDouble() ?? 0.0;
            final pagadoQ = (q['monto_pagado'] as num?)?.toDouble() ?? 0.0;
            final faltaQ = monto - pagadoQ;

            // Solo evaluar fechas que ya vencieron o que corresponden a este periodo
            if (f.isNotEmpty && f.compareTo(fechaPeriodoActual) <= 0) {
              if (faltaQ > 0.001) {
                deudaPeriodo += faltaQ;
                cuotasPendientesPeriodo++;
                proxFechaPeriodo ??= f;
              }
            }
          }

          final alDiaPeriodo = deudaPeriodo <= 0.001;
          cMod['es_periodica'] = true;
          cMod['es_mensual'] = esMensual;
          cMod['etiqueta_periodo'] = esMensual ? 'este mes' : 'esta semana';
          cMod['al_dia_periodo'] = alDiaPeriodo;
          cMod['todo_pagado'] = todoPagado;
          cMod['deuda_periodo'] = deudaPeriodo;
          cMod['cuotas_pendientes_periodo'] = cuotasPendientesPeriodo;
          if (proxFechaPeriodo != null) {
            cMod['proxima_fecha_pago'] = proxFechaPeriodo;
          }
        } else {
          final alDia = faltaTotal <= 0.001;
          cMod['es_periodica'] = false;
          cMod['es_mensual'] = false;
          cMod['etiqueta_periodo'] = 'cuota';
          cMod['al_dia_periodo'] = alDia;
          cMod['todo_pagado'] = alDia;
          cMod['deuda_periodo'] = faltaTotal;
          cMod['cuotas_pendientes_periodo'] = alDia ? 0 : 1;
        }

        listaEnriquecida.add(cMod);
      }

      if (mounted) {
        setState(() {
          _cuotaActual = Map<String, dynamic>.from(actualizada);
          _conductores = listaEnriquecida;
          _filtrar(_busqueda);
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filtrar(String query) {
    _busqueda = query;
    final q = query.toLowerCase().trim();
    setState(() {
      _conductoresFiltrados = _conductores.where((c) {
        final alDia = (c['al_dia_periodo'] as bool?) ?? false;

        if (_filtroEstado == 'pagados' && !alDia) return false;
        if (_filtroEstado == 'deben' && alDia) return false;

        if (q.isNotEmpty) {
          final nombre = (c['conductor_nombre'] ?? '').toString().toLowerCase();
          final ci = (c['conductor_ci'] ?? '').toString().toLowerCase();
          final auto = (c['conductor_numero_interno'] ?? c['numero_interno'] ?? '')
              .toString()
              .toLowerCase();
          if (!nombre.contains(q) && !ci.contains(q) && !auto.contains(q)) {
            return false;
          }
        }

        return true;
      }).toList();
    });
  }

  void _cambiarFiltro(String nuevoFiltro) {
    setState(() => _filtroEstado = nuevoFiltro);
    _filtrar(_busqueda);
  }

  Future<void> _editarCuota() async {
    final cambiado = await DialogoNuevaCuota.mostrar(
      context,
      cuotaAEditar: _cuotaActual,
    );
    if (cambiado == true) {
      _cargarConductores();
    }
  }

  Future<void> _eliminarCuota() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Eliminar Cuota', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          ],
        ),
        content: Text(
          '¿Estás seguro de eliminar la cuota "${_cuotaActual['nombre']}"? Se borrarán los registros asociados.',
          style: const TextStyle(fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await EconomiaRepo.instance.eliminarTipoCuota(_cuotaActual['id_tipo_cuota'].toString());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cuota eliminada correctamente.')),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al eliminar cuota: $e')),
          );
        }
      }
    }
  }

  void _generarInformePdf() {
    if (_conductores.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay datos suficientes para generar el informe.')),
      );
      return;
    }

    final nombreCuota = _cuotaActual['nombre']?.toString() ?? 'Cuota General';
    final montoSugerido = (_cuotaActual['monto_sugerido'] as num?)?.toDouble() ?? 0.0;

    int cantPagados = 0;
    int cantDeben = 0;
    double totalRecaudado = 0;
    double totalFalta = 0;
    for (final c in _conductores) {
      final pagado = (c['monto_pagado'] as num?)?.toDouble() ?? 0.0;
      final falta = (c['monto_falta'] as num?)?.toDouble() ?? 0.0;
      totalRecaudado += pagado;
      totalFalta += falta;
      final alDia = (c['al_dia_periodo'] as bool?) ?? (falta <= 0.001);
      if (alDia) {
        cantPagados++;
      } else {
        cantDeben++;
      }
    }

    ReciboPdfService.mostrarVistaPreviaInformeCuotas(
      context,
      tituloCuota: nombreCuota,
      motivoCuota: _cuotaActual['descripcion']?.toString(),
      montoSugerido: montoSugerido,
      conductores: _conductores,
      totalRecaudado: totalRecaudado,
      totalFalta: totalFalta,
      totalConductores: _conductores.length,
      cantPagados: cantPagados,
      cantDeben: cantDeben,
      idTipoCuota: _cuotaActual['id_tipo_cuota']?.toString(),
      categoria: _cuotaActual['categoria']?.toString(),
    );
  }

  Future<void> _generarInformeWhatsapp({bool forzarVistaPrevia = false}) async {
    if (_conductores.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay datos suficientes para generar el informe.'),
        ),
      );
      return;
    }
    await DialogoInformeWhatsapp.abrirInforme(
      context,
      cuota: _cuotaActual,
      conductores: _conductores,
      forzarVistaPrevia: forzarVistaPrevia,
    );
  }

  Future<void> _configurarWhatsapp() async {
    await DialogoInformeWhatsapp.mostrarConfiguracion(
      context,
      cuota: _cuotaActual,
      conductores: _conductores,
    );
  }

  Future<void> _abrirDetalleConductor(Map<String, dynamic> c) async {
    await DetalleConductorCuotasSheet.mostrar(
      context,
      conductor: c,
      cuota: _cuotaActual,
      onActualizado: _cargarConductores,
    );
  }

  String _formatearFechaCorta(dynamic fecha) {
    if (fecha == null || fecha.toString().trim().isEmpty) return '';
    try {
      final f = DateTime.parse(fecha.toString().trim());
      const meses = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
      return '${f.day.toString().padLeft(2, '0')} ${meses[f.month - 1]} ${f.year}';
    } catch (_) {
      return fecha.toString();
    }
  }

  String _fmtMonto(double v) {
    if ((v - v.roundToDouble()).abs() < 0.005) {
      return v.round().toString();
    }
    return v.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final puedeEditar = Permisos.puedeEditar(
      SesionService.instance.rol,
      Permisos.moduloControlEconomico,
    );

    final nombre = _cuotaActual['nombre']?.toString() ?? 'Detalle de Cuota';
    final descripcion = _cuotaActual['descripcion']?.toString();
    final montoSugerido =
        (_cuotaActual['monto_sugerido'] as num?)?.toDouble() ?? 0.0;
    final categoria = _cuotaActual['categoria']?.toString().toLowerCase();

    int cantPagados = 0;
    int cantDeben = 0;
    double totalRecaudado = 0;
    double totalFalta = 0;
    for (final c in _conductores) {
      final pagado = (c['monto_pagado'] as num?)?.toDouble() ?? 0.0;
      final falta = (c['monto_falta'] as num?)?.toDouble() ?? 0.0;
      totalRecaudado += pagado;
      totalFalta += falta;
      final alDia = (c['al_dia_periodo'] as bool?) ?? (falta <= 0.001);
      if (alDia) {
        cantPagados++;
      } else {
        cantDeben++;
      }
    }
    final totalMeta = totalRecaudado + totalFalta;
    final porcentaje =
        totalMeta > 0 ? (totalRecaudado / totalMeta).clamp(0.0, 1.0) : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // 1. ENCABEZADO CURVO VERDE CORPORATIVO
          _buildHeader(
            context: context,
            nombre: nombre,
            montoSugerido: montoSugerido,
            categoria: categoria,
            puedeEditar: puedeEditar,
          ),

          Expanded(
            child: RefreshIndicator(
              onRefresh: _cargarConductores,
              color: _kVerdeOscuro,
              child: ListView(
                padding: EdgeInsets.zero,
                physics: const BouncingScrollPhysics(),
                children: [
                  const SizedBox(height: 12),

                  // 2. TARJETA DE RESUMEN FINANCIERO CON BOTONES DE PDF Y WHATSAPP
                  _buildResumenFinanciero(
                    descripcion: descripcion,
                    porcentaje: porcentaje,
                    totalRecaudado: totalRecaudado,
                    totalFalta: totalFalta,
                    cantPagados: cantPagados,
                    totalConductores: _conductores.length,
                  ),

                  const SizedBox(height: 12),

                  // 3. SUB-FILTROS HORIZONTALES (Todos, Al día, Deben)
                  _buildFiltrosBar(
                    total: _conductores.length,
                    pagados: cantPagados,
                    deben: cantDeben,
                  ),

                  const SizedBox(height: 10),

                  // 4. LISTADO DE CONDUCTORES O ESTADO VACÍO
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: CircularProgressIndicator(color: _kVerdeOscuro),
                      ),
                    )
                  else if (_conductoresFiltrados.isEmpty)
                    _buildEmptyState()
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: _conductoresFiltrados.length,
                      itemBuilder: (context, index) {
                        final c = _conductoresFiltrados[index];
                        return _buildConductorCard(c, index + 1);
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Encabezado verde curvo corporativo con título, subtítulo, logo y buscador
  Widget _buildHeader({
    required BuildContext context,
    required String nombre,
    required double montoSugerido,
    required String? categoria,
    required bool puedeEditar,
  }) {
    final padding = MediaQuery.of(context).padding;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: _kVerdeOscuro,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(32),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, padding.top + 8, 16, 20),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                  tooltip: 'Volver',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nombre,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Text(
                            'Bs. ${montoSugerido.toStringAsFixed(0)} / chofer',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (categoria == 'multa' ||
                              nombre.toLowerCase().contains('multa'))
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.white60),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.gavel_rounded,
                                      size: 11, color: Colors.white),
                                  SizedBox(width: 3),
                                  Text(
                                    'Multa por Asamblea',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Logo Continental en círculo blanco
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(4),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.local_taxi_rounded,
                        color: _kVerdeOscuro,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Buscador blanco y botón squircle de opciones
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF1E293B),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Buscar conductor por nombre o CI...',
                        hintStyle: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF94A3B8),
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: Color(0xFF94A3B8),
                          size: 20,
                        ),
                        suffixIcon: _busqueda.isNotEmpty
                            ? IconButton(
                                icon: const Icon(
                                  Icons.clear,
                                  size: 18,
                                  color: Colors.grey,
                                ),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  _filtrar('');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onChanged: _filtrar,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                _buildBotonOpciones(puedeEditar),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Botón de opciones en squircle blanco
  Widget _buildBotonOpciones(bool puedeEditar) {
    return PopupMenuButton<String>(
      tooltip: 'Opciones de cuota',
      offset: const Offset(0, 52),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      icon: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: const Icon(
          Icons.tune_rounded,
          size: 22,
          color: _kVerdeOscuro,
        ),
      ),
      onSelected: (val) {
        if (val == 'config_whatsapp') _configurarWhatsapp();
        if (val == 'vista_whatsapp') {
          _generarInformeWhatsapp(forzarVistaPrevia: true);
        }
        if (val == 'editar') _editarCuota();
        if (val == 'eliminar') _eliminarCuota();
      },
      itemBuilder: (ctx) => [
        const PopupMenuItem(
          value: 'config_whatsapp',
          child: Row(
            children: [
              Icon(Icons.tune_rounded, color: Color(0xFF16A34A), size: 20),
              SizedBox(width: 8),
              Text('Configurar Informe WhatsApp'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'vista_whatsapp',
          child: Row(
            children: [
              Icon(Icons.chat_outlined, color: Color(0xFF15803D), size: 20),
              SizedBox(width: 8),
              Text('Vista Previa Mensaje WhatsApp'),
            ],
          ),
        ),
        if (puedeEditar) ...[
          const PopupMenuDivider(),
          const PopupMenuItem(
            value: 'editar',
            child: Row(
              children: [
                Icon(Icons.edit_outlined, color: _kVerdeOscuro, size: 20),
                SizedBox(width: 8),
                Text('Editar Cuota'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'eliminar',
            child: Row(
              children: [
                Icon(Icons.delete_outline, color: Colors.red, size: 20),
                SizedBox(width: 8),
                Text('Eliminar Cuota', style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// Tarjeta de Resumen Financiero con los botones de Informe PDF y WhatsApp
  Widget _buildResumenFinanciero({
    required String? descripcion,
    required double porcentaje,
    required double totalRecaudado,
    required double totalFalta,
    required int cantPagados,
    required int totalConductores,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (descripcion != null && descripcion.trim().isNotEmpty)
                  Expanded(
                    child: Text(
                      descripcion.trim(),
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  )
                else
                  const Spacer(),
                const SizedBox(width: 10),
                // Botones elegantes de acción: PDF y WhatsApp
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 34,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kVerdeOscuro,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: _generarInformePdf,
                        icon: const Icon(Icons.picture_as_pdf_rounded, size: 14),
                        label: const Text(
                          'Informe PDF',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    SizedBox(
                      height: 34,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF16A34A),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () => _generarInformeWhatsapp(),
                        icon: const Icon(Icons.chat_rounded, size: 14),
                        label: const Text(
                          'WhatsApp',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Barra de progreso verde
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: porcentaje,
                minHeight: 6,
                backgroundColor: const Color(0xFFF1F5F9),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
              ),
            ),
            const SizedBox(height: 12),
            // 3 Mini-Estadísticas
            Row(
              children: [
                Expanded(
                  child: _buildMiniStat(
                    'Recaudado',
                    'Bs. ${totalRecaudado.toStringAsFixed(0)}',
                    const Color(0xFF059669),
                  ),
                ),
                Container(width: 1, height: 28, color: const Color(0xFFF1F5F9)),
                Expanded(
                  child: _buildMiniStat(
                    'Por cobrar',
                    'Bs. ${totalFalta.toStringAsFixed(0)}',
                    const Color(0xFFDC2626),
                  ),
                ),
                Container(width: 1, height: 28, color: const Color(0xFFF1F5F9)),
                Expanded(
                  child: _buildMiniStat(
                    'Al día',
                    '$cantPagados de $totalConductores',
                    _kVerdeOscuro,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Sub-filtros horizontales estilo FiltroConductoresBar
  Widget _buildFiltrosBar({
    required int total,
    required int pagados,
    required int deben,
  }) {
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildChip('todos', 'Todos', total),
          _buildChip('pagados', 'Al día', pagados,
              color: const Color(0xFF059669)),
          _buildChip('deben', 'Deben', deben,
              color: const Color(0xFFDC2626)),
        ],
      ),
    );
  }

  Widget _buildChip(String key, String label, int count, {Color? color}) {
    final isSelected = _filtroEstado == key;
    final chipColor = color ?? _kVerdeOscuro;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () => _cambiarFiltro(key),
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? chipColor : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isSelected ? chipColor : const Color(0xFFE2E8F0),
              width: 1.2,
            ),
            boxShadow: isSelected
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
            '$label ($count)',
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF475569),
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              fontSize: 12.5,
            ),
          ),
        ),
      ),
    );
  }

  /// Tarjeta de Conductor siguiendo el diseño de ConductorCard
  Widget _buildConductorCard(Map<String, dynamic> c, int numeroLista) {
    final nombreChofer =
        c['conductor_nombre']?.toString() ?? 'Conductor';
    final ciChofer = c['conductor_ci']?.toString() ?? 'S/CI';
    final auto = c['conductor_numero_interno']?.toString() ??
        c['numero_interno']?.toString();
    final foto = c['conductor_foto']?.toString();
    final pagado = (c['monto_pagado'] as num?)?.toDouble() ?? 0.0;

    final esPeriodica = (c['es_periodica'] as bool?) ?? false;
    final esMensual = (c['es_mensual'] as bool?) ?? false;
    final alDiaPeriodo = (c['al_dia_periodo'] as bool?) ?? false;
    final todoPagado = (c['todo_pagado'] as bool?) ?? false;
    final deudaPeriodo = (c['deuda_periodo'] as num?)?.toDouble() ?? 0.0;
    final cuotasPendientesPeriodo =
        (c['cuotas_pendientes_periodo'] as num?)?.toInt() ?? 0;
    final proxFecha = c['proxima_fecha_pago']?.toString();

    final estadoColor =
        alDiaPeriodo ? const Color(0xFF059669) : const Color(0xFFDC2626);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
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
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => _abrirDetalleConductor(c),
            splashColor: _kVerdeOscuro.withOpacity(0.08),
            highlightColor: _kVerdeOscuro.withOpacity(0.04),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              child: Row(
                children: [
                  // 1. Avatar del conductor idéntico a ConductorCard
                  AvatarConductor(
                    foto: foto,
                    nombre: nombreChofer,
                    radio: 22,
                    fontSize: 12,
                  ),
                  const SizedBox(width: 14),

                  // 2. Información del conductor (Número de lista, Nombre, Auto/CI, Pagos)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Arribita de la columna: solo el número de lista ("solo número")
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1.5),
                          margin: const EdgeInsets.only(bottom: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5EF),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: _kVerdeOscuro.withOpacity(0.2),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            '$numeroLista',
                            style: const TextStyle(
                              color: _kVerdeOscuro,
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        Text(
                          nombreChofer,
                          style: const TextStyle(
                            color: Color(0xFF1E293B),
                            fontWeight: FontWeight.bold,
                            fontSize: 15.5,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(
                              Icons.directions_car_rounded,
                              size: 14,
                              color: Color(0xFF64748B),
                            ),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                (auto != null && auto.isNotEmpty)
                                    ? 'Auto N° $auto'
                                    : (ciChofer.isNotEmpty
                                        ? 'CI: $ciChofer'
                                        : 'Sin unidad asignada'),
                                style: const TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 6,
                          runSpacing: 2,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    color: estadoColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'Pagó: Bs. ${_fmtMonto(pagado)}',
                                  style: TextStyle(
                                    color: alDiaPeriodo
                                        ? const Color(0xFF059669)
                                        : const Color(0xFF64748B),
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            if (!alDiaPeriodo && deudaPeriodo > 0.001)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF2F2),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: const Color(0xFFEF4444)
                                        .withOpacity(0.3),
                                    width: 0.8,
                                  ),
                                ),
                                child: Text(
                                  'Falta: Bs. ${_fmtMonto(deudaPeriodo)}',
                                  style: const TextStyle(
                                    color: Color(0xFFDC2626),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        if (proxFecha != null &&
                            proxFecha.isNotEmpty &&
                            !todoPagado) ...[
                          const SizedBox(height: 3),
                          Text(
                            'Próx. pago: ${_formatearFechaCorta(proxFecha)}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: _kVerdeOscuro,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Badge de Estado: "Al día" o "Debe"
                  if (alDiaPeriodo)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD1FAE5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: const Color(0xFF10B981).withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle_rounded,
                              color: Color(0xFF059669), size: 13),
                          const SizedBox(width: 4),
                          Text(
                            todoPagado
                                ? 'Al día'
                                : (esPeriodica
                                    ? (esMensual
                                        ? 'Al día (mes)'
                                        : 'Al día (sem)')
                                    : 'Al día'),
                            style: const TextStyle(
                              color: Color(0xFF065F46),
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: const Color(0xFFEF4444).withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.schedule_rounded,
                              color: Color(0xFFDC2626), size: 13),
                          const SizedBox(width: 4),
                          Text(
                            cuotasPendientesPeriodo > 1
                                ? 'Debe ($cuotasPendientesPeriodo)'
                                : 'Debe',
                            style: const TextStyle(
                              color: Color(0xFF991B1B),
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right_rounded,
                      color: Color(0xFF94A3B8), size: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String valor, Color color) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
        const SizedBox(height: 2),
        Text(
          valor,
          style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline_rounded,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            const Text(
              'No hay conductores encontrados',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Intenta con otro filtro o término de búsqueda.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
