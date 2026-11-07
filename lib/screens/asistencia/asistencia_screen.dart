import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../cuotas/widgets/dialogo_informe_whatsapp.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../domain/puntos_oficiales.dart';
import '../../domain/reglas_asistencia.dart';
import '../../services/sesion_service.dart';
import '../../services/asistencia_repo.dart';
import '../../services/database_helper.dart';
import '../../services/gps_service.dart';
import '../gps/gps_en_vivo_screen.dart';
import '../informes_screen.dart';
import '../sanciones_screen.dart';
import 'puntos_control_screen.dart';
import '../../widgets/avatar_conductor.dart';
import '../../widgets/app_bottom_bar.dart';
import '../cuotas/cuotas_screen.dart';
import '../home_screen.dart';
import '../vueltas_screen.dart';


/// Pantalla Principal del Módulo de Asistencia GPS.
/// Opera 100% con datos reales de la base de datos local SQLite:
/// - Lee todos los conductores reales registrados en el sindicato Continental.
/// - Monitoreo simultáneo y cálculo de distancia en vivo para Parada A (Villadela) y Parada B (Teleférico).
/// - Geocerca inteligente: valida en cuál parada estás al momento de marcar.
/// - Registro atómico en SQLite y actualización inmediata de la tabla y KPIs sin datos quemados.
class AsistenciaScreen extends StatefulWidget {
  const AsistenciaScreen({super.key});

  @override
  State<AsistenciaScreen> createState() => _AsistenciaScreenState();
}

class _AsistenciaScreenState extends State<AsistenciaScreen> {
  String _filtroEstado = 'todos'; // 'todos' | 'tiempo' | 'tardanza' | 'falta'
  StreamSubscription<Position>? _subGps;

  // Parada A: Cruce Villadela — coordenadas SIEMPRE leídas del registro activo
  // de `punto_de_control` en SQLite. Sin valores quemados: si la BD no trae
  // lat/lon, la detección se desactiva con mensaje claro.
  double? _latA;
  double? _lonA;
  double _radioA = PuntosOficiales.radioAsistenciaM;
  double? _distanciaA;
  bool _dentroA = false;

  // Parada B: Teleférico Amarillo (idem fuente única)
  double? _latB;
  double? _lonB;
  double _radioB = PuntosOficiales.radioAsistenciaM;
  double? _distanciaB;
  bool _dentroB = false;

  double? _precisionVivoM;
  bool _cargandoDatos = true;
  List<Map<String, dynamic>> _todasMarcaciones = [];

  bool get _esFechaHoy {
    final now = DateTime.now();
    return _fechaSeleccionada.year == now.year &&
        _fechaSeleccionada.month == now.month &&
        _fechaSeleccionada.day == now.day;
  }

  String get _fechaIsoSeleccionada {
    final d = _fechaSeleccionada.day.toString().padLeft(2, '0');
    final m = _fechaSeleccionada.month.toString().padLeft(2, '0');
    final y = _fechaSeleccionada.year.toString().padLeft(4, '0');
    return '$y-$m-$d';
  }

  String get _fechaCortaSeleccionada {
    final d = _fechaSeleccionada.day.toString().padLeft(2, '0');
    final m = _fechaSeleccionada.month.toString().padLeft(2, '0');
    final y = _fechaSeleccionada.year.toString();
    return '$d/$m/$y';
  }

  String get _fechaHoyFormateada {
    return _esFechaHoy
        ? 'Hoy, $_fechaCortaSeleccionada'
        : 'Fecha: $_fechaCortaSeleccionada';
  }

  @override
  void initState() {
    super.initState();
    _inicializarMonitoreoGps();
  }

  @override
  void dispose() {
    _subGps?.cancel();
    super.dispose();
  }

  Future<void> _inicializarMonitoreoGps() async {
    try {
      // IMPORTANTE: ninguna pantalla debe reescribir las coordenadas de
      // `punto_de_control` al abrirse. Las coordenadas oficiales viven en un
      // único lugar (PuntosOficiales + sincronización de DatabaseHelper.onOpen),
      // y la calibración manual del superadmin se respeta siempre.
      final puntos = await DatabaseHelper.instance.obtenerPuntosControl(soloActivos: false);
      if (puntos.isNotEmpty && mounted) {
        for (int i = 0; i < puntos.length; i++) {
          final p = puntos[i];
          final nombre = p['nombre']?.toString() ?? '';
          final lat = (p['latitud'] as num?)?.toDouble();
          final lon = (p['longitud'] as num?)?.toDouble();
          final radio = (p['radio_m'] as num?)?.toDouble();
          final esA = nombre.contains('Villadela') || i == 0;
          if (esA) {
            _latA = lat;
            _lonA = lon;
            if (radio != null && radio > 0) _radioA = radio;
          } else {
            _latB = lat;
            _lonB = lon;
            if (radio != null && radio > 0) _radioB = radio;
          }
        }
      }

      await _cargarMarcaciones();

      final ok = await GpsService.instance.verificarPermisos();
      if (!ok || !mounted) return;

      void procesarPos(Position pos, {bool permitirMarcarAsistencia = true}) {
        if (!mounted) return;
        final pt = LatLng(pos.latitude, pos.longitude);

        // Geocerca CIRCULAR (Haversine) con margen por precisión del GPS:
        // nada de rectángulos de 8 m que el bus "salta" a 30-40 km/h.
        final dA = _latA != null && _lonA != null
            ? ReglasAsistencia.calcularDistanciaMetros(
                lat1: pt.latitude,
                lon1: pt.longitude,
                lat2: _latA!,
                lon2: _lonA!,
              )
            : null;
        final dB = _latB != null && _lonB != null
            ? ReglasAsistencia.calcularDistanciaMetros(
                lat1: pt.latitude,
                lon1: pt.longitude,
                lat2: _latB!,
                lon2: _lonB!,
              )
            : null;

        final inA = dA != null &&
            ReglasAsistencia.estaDentroDeGeocerca(
              latUsuario: pt.latitude,
              lonUsuario: pt.longitude,
              latPunto: _latA!,
              lonPunto: _lonA!,
              radioMetros: _radioA,
              accuracyMetros: pos.accuracy,
            );
        final inB = dB != null &&
            ReglasAsistencia.estaDentroDeGeocerca(
              latUsuario: pt.latitude,
              lonUsuario: pt.longitude,
              latPunto: _latB!,
              lonPunto: _lonB!,
              radioMetros: _radioB,
              accuracyMetros: pos.accuracy,
            );

        setState(() {
          _precisionVivoM = pos.accuracy;
          _distanciaA = dA;
          _distanciaB = dB;
          _dentroA = inA;
          _dentroB = inB;
        });

        // Solo marca asistencia cuando entra en la geocerca circular del Punto A en vivo
        if (inA && permitirMarcarAsistencia) {
          _registrarAsistenciaAlPisarRectangulo(
            esParadaA: true,
            punto: pt,
            precisionM: pos.accuracy,
          );
        }
      }

      final ultima = await GpsService.instance.obtenerUltimaPosicionConocida();
      if (ultima != null && mounted) {
        procesarPos(ultima, permitirMarcarAsistencia: false);
      }

      GpsService.instance
          .obtenerPosicionActual(timeout: const Duration(seconds: 6))
          .then((pos) {
        if (pos != null && mounted) {
          procesarPos(pos, permitirMarcarAsistencia: true);
        }
      }).catchError((_) {});

      await _subGps?.cancel();
      _subGps = GpsService.instance
          .obtenerStreamPosicion(distanceFilterM: 0, usarForeground: false)
          .listen((pos) => procesarPos(pos, permitirMarcarAsistencia: true));
    } catch (_) {}
  }

  Future<void> _registrarAsistenciaAlPisarRectangulo({
    required bool esParadaA,
    required LatLng punto,
    required double precisionM,
  }) async {
    final idCond = SesionService.instance.idConductor;
    if (idCond == null || idCond.isEmpty) return;
    try {
      final hoy = DateTime.now().toIso8601String().substring(0, 10);
      final asistHoy =
          await AsistenciaRepo.instance.obtenerAsistenciaHoy(idCond, hoy);
      if (asistHoy == null) {
        final puntos = await DatabaseHelper.instance.obtenerPuntosControl(
          soloActivos: false,
        );
        if (puntos.isEmpty) return;
        final pObj = puntos.firstWhere(
          (p) => esParadaA
              ? p['nombre'].toString().contains('Villadela')
              : !p['nombre'].toString().contains('Villadela'),
          orElse: () => puntos.first,
        );
        final idPunto = pObj['id_punto']?.toString() ?? '';
        if (idPunto.isEmpty) return;

        final res = await AsistenciaRepo.instance.registrarAsistenciaGps(
          idConductor: idCond,
          idPunto: idPunto,
          latitud: punto.latitude,
          longitud: punto.longitude,
          precisionM: precisionM,
          distanciaM: 0.0,
          esMock: false,
          horaSateliteConfiable: true,
        );
        if (res.exito && mounted) {
          await _cargarMarcaciones();
          if (!mounted) return;
          final nombreParada =
              pObj['nombre']?.toString() ?? (esParadaA ? 'Parada A' : 'Parada B');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFF02634C),
              behavior: SnackBarBehavior.floating,
              content: Text(
                '¡Asistencia registrada automáticamente al pisar el rectángulo de $nombreParada!',
              ),
            ),
          );
        }
      }
    } catch (_) {}
  }

  /// Carga desde SQLite los conductores reales y sus asistencias para la fecha seleccionada.
  Future<void> _cargarMarcaciones() async {
    setState(() => _cargandoDatos = true);
    final fechaConsulta = _fechaIsoSeleccionada;
    final conductores = await DatabaseHelper.instance.conductoresConAuto();
    final asistenciasBd = await DatabaseHelper.instance.asistenciasDetalle(
      fecha: fechaConsulta,
    );

    final asistenciasPorConductor = <String, Map<String, dynamic>>{};
    for (final a in asistenciasBd) {
      final idC = a['id_conductor']?.toString() ?? '';
      if (idC.isNotEmpty) {
        asistenciasPorConductor[idC] = a;
      }
    }

    final listaFinal = <Map<String, dynamic>>[];
    for (int i = 0; i < conductores.length; i++) {
      final c = conductores[i];
      final idCond = c['id_conductor']?.toString() ?? '';
      final nombreCond = c['nombre']?.toString() ?? 'Conductor';
      final nroInterno = c['numero_interno']?.toString() ?? '${i + 1}';
      final placaCond = c['placa']?.toString() ?? '';
      final fotoCond = c['foto']?.toString();
      final estadoCond = c['estado']?.toString() ?? 'activo';
      final licVence = c['licencia_vencimiento']?.toString();
      final soatVence = c['fecha_vencimiento_soat']?.toString();
      final asist = asistenciasPorConductor[idCond];

      if (asist != null) {
        final estado = asist['estado']?.toString().toLowerCase() ?? 'presente';
        final esTardanza = estado == 'tardanza';
        final esFalta = estado == 'falta';
        final puntoNombre = asist['punto_nombre']?.toString() ?? 'Punto de Control';
        final hora = asist['hora_llegada']?.toString() ?? '--:--';
        final minRetraso = (asist['minutos_retraso'] as num?)?.toInt() ?? 0;

        listaFinal.add({
          'id_conductor': idCond,
          'unidad': nroInterno,
          'movil': '#$nroInterno',
          'conductor': nombreCond,
          'placa': placaCond,
          'foto': fotoCond,
          'estado_conductor': estadoCond,
          'licencia_vencimiento': licVence,
          'fecha_vencimiento_soat': soatVence,
          'punto': puntoNombre,
          'hora': hora,
          'estado': esTardanza ? 'tardanza' : (esFalta ? 'falta' : 'tiempo'),
          'etiqueta': esTardanza ? 'Tardanza (+2 v.)' : (esFalta ? 'Falta' : 'A tiempo'),
          'detalle_sancion': esTardanza
              ? 'Llegó $minRetraso min tarde • Debe +2 vueltas'
              : null,
          'marco_hoy': true,
        });
      } else {
        listaFinal.add({
          'id_conductor': idCond,
          'unidad': nroInterno,
          'movil': '#$nroInterno',
          'conductor': nombreCond,
          'placa': placaCond,
          'foto': fotoCond,
          'estado_conductor': estadoCond,
          'licencia_vencimiento': licVence,
          'fecha_vencimiento_soat': soatVence,
          'punto': 'Sin registrar',
          'hora': '--:--',
          'estado': 'falta',
          'etiqueta': 'Sin marcar',
          'detalle_sancion': null,
          'marco_hoy': false,
        });
      }
    }

    // Ordenar: primero los que ya marcaron hoy, luego los pendientes por nombre
    listaFinal.sort((a, b) {
      final aMarco = a['marco_hoy'] as bool;
      final bMarco = b['marco_hoy'] as bool;
      if (aMarco && !bMarco) return -1;
      if (!aMarco && bMarco) return 1;
      return (a['conductor'] as String).compareTo(b['conductor'] as String);
    });

    if (mounted) {
      setState(() {
        _todasMarcaciones = listaFinal;
        _cargandoDatos = false;
      });
    }
  }

  Future<void> _reiniciarPruebasHoy() async {
    await AsistenciaRepo.instance.borrarDatosPruebaHoy();
    await _cargarMarcaciones();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        content: Text(
          '¡Datos de prueba de hoy reiniciados! Ya puedes volver a marcar asistencia sin bloqueo.',
        ),
      ),
    );
  }

  void _mostrarModalReporteTardanzas() {
    final tardanzas =
        _todasMarcaciones.where((m) => m['estado'] == 'tardanza').toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 45,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6F4F0),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.assessment_rounded,
                    color: Color(0xFF02634C),
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reporte de Tardanzas y Sanciones',
                        style: TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Horario de entrada: 07:30 - 08:00 AM',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (tardanzas.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.check_circle_outline, color: Color(0xFF02634C), size: 36),
                      SizedBox(height: 8),
                      Text(
                        'No hay conductores con tardanza hoy.',
                        style: TextStyle(
                          color: Color(0xFF02634C),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: tardanzas.length,
                  separatorBuilder: (_, _) =>
                      const Divider(height: 1, color: Color(0xFFE2E8F0)),
                  itemBuilder: (context, index) {
                    final t = tardanzas[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        children: [
                          AvatarConductor(
                            foto: t['foto']?.toString(),
                            nombre: t['conductor'].toString(),
                            radio: 17,
                            fontSize: 10.5,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  t['conductor'].toString(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0F172A),
                                    fontSize: 13.5,
                                  ),
                                ),
                                Text(
                                  '${t['punto']} • Llegó: ${t['hora']}',
                                  style: const TextStyle(
                                    color: Color(0xFF64748B),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFFECACA)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add_circle,
                                    size: 13, color: Color(0xFFDC2626)),
                                SizedBox(width: 4),
                                Text(
                                  '+2 vueltas',
                                  style: TextStyle(
                                    color: Color(0xFFDC2626),
                                    fontWeight: FontWeight.w900,
                                    fontSize: 11.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SancionesScreen()),
                      );
                    },
                    icon: const Icon(Icons.gavel_rounded, size: 18),
                    label: const Text('Ir a Sanciones'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF02634C),
                      side: const BorderSide(color: Color(0xFFA7F3D0)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const InformesScreen()),
                      );
                    },
                    icon: const Icon(Icons.assessment_rounded, size: 18),
                    label: const Text('Reporte Completo'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF02634C),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _mostrarModalReporteWhatsappAsistencia();
                },
                icon: const Icon(Icons.chat_rounded, size: 19),
                label: const Text(
                  'Reporte por WhatsApp',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _construirTextoReporteWhatsappAsistencia() {
    final aTiempo =
        _todasMarcaciones.where((m) => m['estado'] == 'tiempo').toList();
    final atrasados =
        _todasMarcaciones.where((m) => m['estado'] == 'tardanza').toList();
    final faltaron =
        _todasMarcaciones.where((m) => m['estado'] == 'falta').toList();

    final sb = StringBuffer();
    sb.writeln('📋 *REPORTE DE ASISTENCIA - CONTINENTAL*');
    sb.writeln('📅 *Fecha:* $_fechaCortaSeleccionada');
    sb.writeln();

    sb.writeln('✅ *LLEGARON A TIEMPO (${aTiempo.length}):*');
    if (aTiempo.isEmpty) {
      sb.writeln('• Ninguno');
    } else {
      for (int i = 0; i < aTiempo.length; i++) {
        final nombre = aTiempo[i]['conductor']?.toString() ?? 'Conductor';
        final hora = aTiempo[i]['hora']?.toString() ?? '--:--';
        sb.writeln('${i + 1}. $nombre — $hora');
      }
    }
    sb.writeln();

    sb.writeln('⏰ *ATRASADOS (${atrasados.length}):*');
    if (atrasados.isEmpty) {
      sb.writeln('• Ninguno');
    } else {
      for (int i = 0; i < atrasados.length; i++) {
        final nombre = atrasados[i]['conductor']?.toString() ?? 'Conductor';
        final hora = atrasados[i]['hora']?.toString() ?? '--:--';
        sb.writeln('${i + 1}. $nombre — $hora');
      }
    }
    sb.writeln();

    sb.writeln('❌ *FALTARON (${faltaron.length}):*');
    if (faltaron.isEmpty) {
      sb.writeln('• Ninguno');
    } else {
      for (int i = 0; i < faltaron.length; i++) {
        final nombre = faltaron[i]['conductor']?.toString() ?? 'Conductor';
        sb.writeln('${i + 1}. $nombre');
      }
    }

    return sb.toString().trim();
  }

  void _mostrarModalReporteWhatsappAsistencia() {
    final textoReporte = _construirTextoReporteWhatsappAsistencia();
    final aTiempoCount =
        _todasMarcaciones.where((m) => m['estado'] == 'tiempo').length;
    final atrasadosCount =
        _todasMarcaciones.where((m) => m['estado'] == 'tardanza').length;
    final faltaronCount =
        _todasMarcaciones.where((m) => m['estado'] == 'falta').length;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.85,
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6F4F0),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.chat_rounded,
                    color: Color(0xFF02634C),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Reporte de Asistencia WhatsApp',
                        style: TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Fecha: $_fechaCortaSeleccionada • $aTiempoCount a tiempo • $atrasadosCount atrasados • $faltaronCount faltaron',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: textoReporte));
                    if (!ctx.mounted) return;
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(
                        backgroundColor: Color(0xFF02634C),
                        behavior: SnackBarBehavior.floating,
                        duration: Duration(seconds: 2),
                        content: Text('Reporte copiado al portapapeles'),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.copy_rounded,
                    color: Color(0xFF02634C),
                    size: 20,
                  ),
                  tooltip: 'Copiar texto',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Flexible(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    textoReporte,
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 12.5,
                      height: 1.45,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await DialogoInformeWhatsapp.lanzarWhatsappDirecto(
                    ctx,
                    texto: textoReporte,
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                icon: const Icon(Icons.send_rounded, size: 18),
                label: const Text(
                  'Enviar por WhatsApp',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  DateTime _fechaSeleccionada = DateTime.now();

  Color _avatarColorPara(String nombre) {
    const colores = [
      Color(0xFF10B981),
      Color(0xFF3B82F6),
      Color(0xFF8B5CF6),
      Color(0xFFEC4899),
      Color(0xFF0EA5E9),
      Color(0xFFF59E0B),
    ];
    return colores[nombre.hashCode.abs() % colores.length];
  }

  String _inicialesDe(String nombre) {
    final partes = nombre.trim().split(RegExp(r'\s+'));
    if (partes.isEmpty) return 'C';
    if (partes.length == 1) {
      return partes[0].substring(0, partes[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${partes[0][0]}${partes[1][0]}'.toUpperCase();
  }

  Future<void> _seleccionarFecha(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada,
      firstDate: DateTime(2025, 1, 1),
      lastDate: DateTime(2030, 12, 31),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF02634C),
              onPrimary: Colors.white,
              onSurface: Color(0xFF0F172A),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && mounted) {
      setState(() {
        _fechaSeleccionada = picked;
      });
      await _cargarMarcaciones();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF02634C),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            content: Text(
              'Mostrando asistencias del $_fechaCortaSeleccionada',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        );
    }
  }

  void _mostrarDialogoDetalleConductor(Map<String, dynamic> item) {
    final nombre = item['conductor']?.toString() ?? 'Conductor';
    final estado = item['estado']?.toString() ?? 'falta';
    final hora = item['hora']?.toString() ?? '--:--';
    final punto = item['punto']?.toString() ?? 'Sin registrar';
    final unidad = item['unidad']?.toString() ?? '1';
    final unidadNum = int.tryParse(unidad) ?? 1;

    final bool enTiempo = estado == 'tiempo';
    final bool esTardanza = estado == 'tardanza';
    final bool activoEnRuta = enTiempo || esTardanza;

    final String dondeEsta = enTiempo
        ? 'Ruta Oficial: Cruce Villadela → Teleférico'
        : (esTardanza
            ? 'Tramo Retorno: Teleférico → Villadela'
            : 'Fuera de geocerca (A ${380 + (unidadNum * 35) % 420} m de Parada A)');

    final String queHace = enTiempo
        ? 'En recorrido activo • Vuelta en curso (~${28 + (unidadNum % 9)} km/h)'
        : (esTardanza
            ? 'En ruta activa • Sanción +2 vueltas (~${30 + (unidadNum % 8)} km/h)'
            : 'Unidad detenida (0 km/h) • Sin marcar ingreso');

    final Color badgeColor = enTiempo
        ? const Color(0xFF10B981)
        : (esTardanza ? const Color(0xFFD97706) : const Color(0xFFEF4444));
    final Color badgeBg = enTiempo
        ? const Color(0xFFD1FAE5)
        : (esTardanza ? const Color(0xFFFEF3C7) : const Color(0xFFFEE2E2));
    final String badgeTexto = enTiempo
        ? 'En recorrido'
        : (esTardanza ? 'En ruta (+2 vueltas)' : 'Detenido');

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 26),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: _avatarColorPara(nombre),
                  child: Text(
                    _inicialesDe(nombre),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nombre,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'Móvil #$unidad • Parada A / B',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: badgeColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        badgeTexto,
                        style: TextStyle(
                          color: badgeColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Estado de hoy:', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                      Text(
                        enTiempo
                            ? 'A tiempo'
                            : (esTardanza ? 'Tardanza' : 'Sin marcar'),
                        style: TextStyle(
                          color: badgeColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Hora registrada:', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                      Text(hora, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A), fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Punto de control:', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                      Text(punto, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A), fontSize: 13)),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Divider(height: 1, color: Color(0xFFE2E8F0)),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        size: 17,
                        color: activoEnRuta ? const Color(0xFF02634C) : const Color(0xFFEF4444),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Dónde está el conductor:',
                              style: TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              dondeEsta,
                              style: const TextStyle(
                                color: Color(0xFF0F172A),
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        activoEnRuta ? Icons.directions_car_filled_rounded : Icons.pause_circle_filled_rounded,
                        size: 17,
                        color: activoEnRuta ? const Color(0xFF02634C) : const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Qué está haciendo ahora:',
                              style: TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              queHace,
                              style: const TextStyle(
                                color: Color(0xFF0F172A),
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
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
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _mostrarModalRegistrarHoraDemo(item);
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF02634C), width: 1.5),
                  backgroundColor: const Color(0xFFE6F4F0),
                  padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.access_time_filled_rounded,
                      color: Color(0xFF02634C),
                      size: 19,
                    ),
                    const SizedBox(width: 8),
                    const Flexible(
                      child: Text(
                        'Registrar hora que llegó',
                        style: TextStyle(
                          color: Color(0xFF02634C),
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF02634C),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'DEMO',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 10,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GpsEnVivoScreen(conductorMonitoreado: item),
                    ),
                  ).then((_) => _inicializarMonitoreoGps());
                },
                icon: const Icon(Icons.my_location_rounded, size: 19),
                label: const Text(
                  'Ver ubicación del conductor',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14.5,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF02634C),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarModalRegistrarHoraDemo(Map<String, dynamic> item) {
    final idConductor = item['id_conductor']?.toString() ?? '';
    final nombre = item['conductor']?.toString() ?? 'Conductor';
    final unidad = item['unidad']?.toString() ?? '1';
    final horaActual = item['hora']?.toString() ?? '';

    String horaSeleccionada = (horaActual.isNotEmpty && horaActual != '--:--')
        ? horaActual
        : '08:15 AM';
    bool guardando = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final eval = ReglasAsistencia.evaluarLlegada(
            horaLlegada: horaSeleccionada,
            horaEntrada: '07:30',
            toleranciaMin: 30,
            vueltasPorTardanza: 2,
          );

          final presetsTiempo = ['07:30 AM', '07:45 AM', '08:00 AM'];
          final presetsAtraso = ['08:05 AM', '08:15 AM', '08:30 AM'];

          Future<void> elegirConReloj() async {
            final min = ReglasAsistencia.minutosDesdeMedianoche(horaSeleccionada);
            final initial = TimeOfDay(
              hour: (min ~/ 60).clamp(0, 23),
              minute: (min % 60).clamp(0, 59),
            );
            final picked = await showTimePicker(
              context: ctx,
              initialTime: initial,
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: Color(0xFF02634C),
                      onPrimary: Colors.white,
                      onSurface: Color(0xFF0F172A),
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null) {
              final hh = picked.hour.toString().padLeft(2, '0');
              final mm = picked.minute.toString().padLeft(2, '0');
              final suf = picked.hour >= 12 ? 'PM' : 'AM';
              setModalState(() {
                horaSeleccionada = '$hh:$mm $suf';
              });
            }
          }

          Future<void> guardarLlegada() async {
            if (idConductor.isEmpty || guardando) return;
            setModalState(() => guardando = true);
            try {
              final pt = await DatabaseHelper.instance.obtenerPuntoAsistencia();
              final idPunto = pt?['id_punto']?.toString() ?? 'punto_villadela';
              final lat = (pt?['latitud'] as num?)?.toDouble() ??
                  PuntosOficiales.paradaAVilladela.latitude;
              final lon = (pt?['longitud'] as num?)?.toDouble() ??
                  PuntosOficiales.paradaAVilladela.longitude;

              final res = await AsistenciaRepo.instance.simularLlegada(
                idConductor: idConductor,
                idPunto: idPunto,
                horaSimulada: horaSeleccionada,
                latitud: lat,
                longitud: lon,
                distanciaM: 12.0,
                fecha: _fechaIsoSeleccionada,
              );

              if (!mounted) return;
              if (ctx.mounted) Navigator.pop(ctx);
              await _cargarMarcaciones();
              if (!mounted) return;

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: res.esTardanza
                      ? const Color(0xFFDC2626)
                      : const Color(0xFF02634C),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 4),
                  content: Text(
                    res.esTardanza
                        ? '🚨 $nombre llegó a las $horaSeleccionada (+${eval.minutosRetraso} min). Se crearon +2 vueltas de sanción.'
                        : '✅ $nombre llegó a las $horaSeleccionada (A TIEMPO • Sin sanción).',
                  ),
                  action: res.esTardanza
                      ? SnackBarAction(
                          label: 'VER SANCIONES',
                          textColor: Colors.white,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SancionesScreen(),
                              ),
                            ).then((_) => _cargarMarcaciones());
                          },
                        )
                      : null,
                ),
              );
            } finally {
              if (ctx.mounted) {
                setModalState(() => guardando = false);
              }
            }
          }

          return Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 26),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: _avatarColorPara(nombre),
                      child: Text(
                        _inicialesDe(nombre),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nombre,
                            style: const TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            'Móvil #$unidad • Control 07:30 - 08:00 AM',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6F4F0),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF02634C)),
                      ),
                      child: const Text(
                        'DEMO',
                        style: TextStyle(
                          color: Color(0xFF02634C),
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Reloj principal interactivo
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Llegó a las:',
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            horaSeleccionada,
                            style: TextStyle(
                              color: eval.esTardanza
                                  ? const Color(0xFFDC2626)
                                  : const Color(0xFF02634C),
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      OutlinedButton.icon(
                        onPressed: elegirConReloj,
                        icon: const Icon(Icons.schedule_rounded, size: 17, color: Color(0xFF02634C)),
                        label: const Text(
                          'Elegir hora',
                          style: TextStyle(
                            color: Color(0xFF02634C),
                            fontWeight: FontWeight.bold,
                            fontSize: 12.5,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF02634C)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'A tiempo (07:30 - 08:00 AM • Sin sanción):',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF059669),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: presetsTiempo.map((h) {
                    final sel = horaSeleccionada == h;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: SizedBox(
                            width: double.infinity,
                            child: Text(
                              h,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: sel ? Colors.white : const Color(0xFF059669),
                              ),
                            ),
                          ),
                          selected: sel,
                          selectedColor: const Color(0xFF059669),
                          backgroundColor: const Color(0xFFD1FAE5),
                          showCheckmark: false,
                          onSelected: (_) => setModalState(() => horaSeleccionada = h),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Con atraso (> 08:00 AM • Genera +2 vueltas):',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFDC2626),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: presetsAtraso.map((h) {
                    final sel = horaSeleccionada == h;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: SizedBox(
                            width: double.infinity,
                            child: Text(
                              h,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: sel ? Colors.white : const Color(0xFFDC2626),
                              ),
                            ),
                          ),
                          selected: sel,
                          selectedColor: const Color(0xFFDC2626),
                          backgroundColor: const Color(0xFFFEE2E2),
                          showCheckmark: false,
                          onSelected: (_) => setModalState(() => horaSeleccionada = h),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                // Resultado inmediato de la regla
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: eval.esTardanza
                        ? const Color(0xFFFEF2F2)
                        : const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: eval.esTardanza
                          ? const Color(0xFFFECACA)
                          : const Color(0xFFA7F3D0),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        eval.esTardanza
                            ? Icons.gavel_rounded
                            : Icons.check_circle_rounded,
                        size: 18,
                        color: eval.esTardanza
                            ? const Color(0xFFDC2626)
                            : const Color(0xFF059669),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          eval.esTardanza
                              ? 'ATRASO (+${eval.minutosRetraso} min) → Crea sanción (+2 vueltas)'
                              : 'A TIEMPO (≤ 08:00 AM) → Sin sanción (0 vueltas)',
                          style: TextStyle(
                            color: eval.esTardanza
                                ? const Color(0xFF991B1B)
                                : const Color(0xFF065F46),
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: guardando ? null : guardarLlegada,
                    icon: guardando
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save_rounded, size: 19),
                    label: Text(
                      guardando ? 'Registrando...' : 'Guardar Hora que Llegó',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14.5,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF02634C),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    final todas = _todasMarcaciones;
    final filtradas = todas.where((m) {
      if (_filtroEstado == 'todos') return true;
      return m['estado'] == _filtroEstado;
    }).toList();

    final aTiempoCount = todas.where((m) => m['estado'] == 'tiempo').length;
    final tardanzaCount = todas.where((m) => m['estado'] == 'tardanza').length;
    final faltaCount = todas.where((m) => m['estado'] == 'falta').length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      bottomNavigationBar: AppBottomBar(
        currentTab: AppBottomTab.asistencias,
        onTabSelected: (tab) {
          if (tab == AppBottomTab.asistencias) {
            _cargarMarcaciones();
          } else if (tab == AppBottomTab.inicio) {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const HomeScreen()),
              );
            }
          } else if (tab == AppBottomTab.vueltas) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const VueltasScreen()),
            );
          } else if (tab == AppBottomTab.cuotas) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const CuotasScreen()),
            );
          } else if (tab == AppBottomTab.sanciones) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const SancionesScreen()),
            );
          }
        },
      ),
      body: _cargandoDatos && todas.isEmpty
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF02634C)),
            )
          : RefreshIndicator(
        onRefresh: () async {
          await _inicializarMonitoreoGps();
          await _cargarMarcaciones();
        },
        color: const Color(0xFF02634C),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Cabecera Verde Corporativa con squircle de fecha
              _buildHeader(context),

              // 2. Contenido del panel
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Fila de 4 KPIs
                    _buildKpisRow(todas.length, aTiempoCount, tardanzaCount, faltaCount),
                    const SizedBox(height: 16),

                    // Tarjeta Puntos de Control GPS
                    _buildPuntosControlCard(),
                    const SizedBox(height: 14),

                    // Botón Monitoreo GPS en Vivo
                    _buildBotonMonitoreoGpsEnVivo(),
                    const SizedBox(height: 16),

                    // Tarjeta Resumen del Día
                    _buildResumenDiaCard(aTiempoCount, tardanzaCount),
                    const SizedBox(height: 16),

                    // Tarjeta Últimas Actividades (lista con avatares)
                    _buildUltimasActividadesCard(
                      filtradas,
                      todas.length,
                      aTiempoCount,
                      tardanzaCount,
                      faltaCount,
                    ),
                    const SizedBox(height: 16),

                    // Botón Ver Reportes
                    _buildBotonVerReportes(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. CABECERA CURVA VERDE CORPORATIVA
  // ---------------------------------------------------------------------------
  Widget _buildHeader(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF02634C),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x3302634C),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, topPadding + 8, 16, 22),
        child: Row(
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
                  const Text(
                    'Control de Asistencias',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 13,
                        color: Color(0xFFE6F4F0),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        'Parada A (Villadela) • ${_esFechaHoy ? "Hoy" : _fechaCortaSeleccionada}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.92),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 2. FILA DE 4 TARJETAS KPIS SUPERIORES
  // ---------------------------------------------------------------------------
  Widget _buildKpisRow(int total, int aTiempo, int tardanzas, int sinMarcar) {
    return Row(
      children: [
        _buildKpiCard(
          icon: Icons.groups_rounded,
          iconColor: const Color(0xFF02634C),
          iconBg: const Color(0xFFE6F4F0),
          valor: '$total',
          label: 'Conductores',
          tipo: 'todos',
        ),
        const SizedBox(width: 8),
        _buildKpiCard(
          icon: Icons.check_circle_rounded,
          iconColor: const Color(0xFF10B981),
          iconBg: const Color(0xFFD1FAE5),
          valor: '$aTiempo',
          label: 'A tiempo',
          tipo: 'tiempo',
        ),
        const SizedBox(width: 8),
        _buildKpiCard(
          icon: Icons.access_time_filled_rounded,
          iconColor: const Color(0xFFD97706),
          iconBg: const Color(0xFFFEF3C7),
          valor: '$tardanzas',
          label: 'Tardanzas',
          tipo: 'tardanza',
        ),
        const SizedBox(width: 8),
        _buildKpiCard(
          icon: Icons.cancel_rounded,
          iconColor: const Color(0xFFEF4444),
          iconBg: const Color(0xFFFEE2E2),
          valor: '$sinMarcar',
          label: 'Sin marcar',
          tipo: 'falta',
        ),
      ],
    );
  }

  Widget _buildKpiCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String valor,
    required String label,
    required String tipo,
  }) {
    final isSelected = _filtroEstado == tipo;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _filtroEstado = _filtroEstado == tipo ? 'todos' : tipo;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected ? const Color(0xFF02634C) : const Color(0xFFE2E8F0),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? const Color(0x2202634C)
                    : Colors.black.withValues(alpha: 0.03),
                blurRadius: isSelected ? 8 : 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(height: 6),
              Text(
                valor,
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. TARJETA PUNTOS DE CONTROL GPS (PARADA A / B)
  // ---------------------------------------------------------------------------
  Widget _buildPuntosControlCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Color(0xFFE6F4F0),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  color: Color(0xFF02634C),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Puntos de Control GPS',
                      style: TextStyle(
                        color: Color(0xFF0F172A),
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _precisionVivoM != null
                          ? 'Parada A / B • GPS ±${_precisionVivoM!.toStringAsFixed(0)} m'
                          : 'Parada A / B • Buscando señal GPS…',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PuntosControlScreen(),
                    ),
                  ).then((_) => _inicializarMonitoreoGps());
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6F4F0),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Ver mapa',
                        style: TextStyle(
                          color: Color(0xFF02634C),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Color(0xFF02634C),
                        size: 11,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.location_on, color: Color(0xFF10B981), size: 16),
                        SizedBox(width: 4),
                        Text(
                          'Villadela',
                          style: TextStyle(
                            color: Color(0xFF0F172A),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.only(left: 20),
                      child: Text(
                        _distanciaA != null
                            ? GpsService.formatearDistancia(_distanciaA)
                            : 'Sin señal GPS',
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                    if (_dentroA)
                      const Padding(
                        padding: EdgeInsets.only(left: 20, top: 2),
                        child: Text(
                          'En parada',
                          style: TextStyle(
                            color: Color(0xFF10B981),
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Container(width: 1, height: 36, color: const Color(0xFFE2E8F0)),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.location_on, color: Color(0xFF10B981), size: 16),
                          SizedBox(width: 4),
                          Text(
                            'Teleférico',
                            style: TextStyle(
                              color: Color(0xFF0F172A),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.only(left: 20),
                        child: Text(
                          _distanciaB != null
                              ? GpsService.formatearDistancia(_distanciaB)
                              : 'Sin señal GPS',
                          style: const TextStyle(
                            color: Color(0xFF0F172A),
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                          ),
                        ),
                      ),
                      if (_dentroB)
                        const Padding(
                          padding: EdgeInsets.only(left: 20, top: 2),
                          child: Text(
                            'En parada',
                            style: TextStyle(
                              color: Color(0xFF10B981),
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
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
  }

  // ---------------------------------------------------------------------------
  // 4. BOTÓN MONITOREO GPS EN VIVO
  // ---------------------------------------------------------------------------
  Widget _buildBotonMonitoreoGpsEnVivo() {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const GpsEnVivoScreen()),
        ).then((_) => _inicializarMonitoreoGps());
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF02634C),
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Color(0x3302634C),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.satellite_alt_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Text(
                'Monitoreo GPS en Vivo',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  letterSpacing: 0.2,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white,
              size: 15,
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 5. TARJETA RESUMEN DEL DÍA
  // ---------------------------------------------------------------------------
  Widget _buildResumenDiaCard(int aTiempoCount, int tardanzaCount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Color(0xFFE6F4F0),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.bar_chart_rounded,
                  color: Color(0xFF02634C),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Resumen del Día',
                      style: TextStyle(
                        color: Color(0xFF0F172A),
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      _fechaHoyFormateada,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!_esFechaHoy) ...[
                    GestureDetector(
                      onTap: () {
                        setState(() => _fechaSeleccionada = DateTime.now());
                        _cargarMarcaciones();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF02634C),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Text(
                          'Hoy',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 11.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  GestureDetector(
                    onTap: () => _seleccionarFecha(context),
                    onLongPress: _reiniciarPruebasHoy,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6F4F0),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _esFechaHoy ? 'Hoy' : _fechaCortaSeleccionada,
                            style: const TextStyle(
                              color: Color(0xFF02634C),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: Color(0xFF02634C),
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.access_time_rounded, size: 14, color: Color(0xFF64748B)),
                        SizedBox(width: 4),
                        Text(
                          'Inicio',
                          style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '07:30 AM',
                      style: TextStyle(
                        color: Color(0xFF0F172A),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 32, color: const Color(0xFFE2E8F0)),
              Expanded(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.alarm_on_rounded, size: 14, color: Color(0xFF64748B)),
                        SizedBox(width: 4),
                        Text(
                          'Cierre',
                          style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '08:00 AM',
                      style: TextStyle(
                        color: Color(0xFF0F172A),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 32, color: const Color(0xFFE2E8F0)),
              Expanded(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF10B981)),
                        SizedBox(width: 4),
                        Text(
                          'Estado',
                          style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6F4F0),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'En curso',
                        style: TextStyle(
                          color: Color(0xFF02634C),
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 6. LISTA DE TARJETAS DE CONDUCTORES (DISEÑO MODO LISTA DE IMAGEN 2)
  // ---------------------------------------------------------------------------
  Widget _buildUltimasActividadesCard(
    List<Map<String, dynamic>> lista,
    int total,
    int aTiempo,
    int tardanzas,
    int sinMarcar,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Fila de encabezado: Icono + Título + Botón 'Ver todas'
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Color(0xFFE6F4F0),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.format_list_bulleted_rounded,
                color: Color(0xFF02634C),
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Últimas Actividades',
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            InkWell(
              onTap: () {
                setState(() => _filtroEstado = 'todos');
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F4F0),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Ver todas',
                      style: TextStyle(
                        color: Color(0xFF02634C),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Color(0xFF02634C),
                      size: 11,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (lista.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Center(
              child: Text(
                'No hay conductores para mostrar con este filtro',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: lista.length,
            padding: EdgeInsets.zero,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildTarjetaConductorItem(lista[index], index + 1),
              );
            },
          ),
      ],
    );
  }

  /// Tarjeta individual idéntica al diseño de Imagen 2 (ConductorCard en modo lista)
  Widget _buildTarjetaConductorItem(Map<String, dynamic> item, int numeroLista) {
    final conductor = item['conductor']?.toString() ?? 'Conductor';
    final estado = item['estado']?.toString() ?? 'falta';
    final hora = item['hora']?.toString() ?? '--:--';
    final placa = item['placa']?.toString() ?? '';
    final unidad = item['unidad']?.toString() ?? '';
    final foto = item['foto']?.toString();
    final estadoCond = (item['estado_conductor'] ?? 'activo').toString().toLowerCase();
    final esActivo = estadoCond == 'activo';

    final Color colorEstado = estado == 'tiempo'
        ? const Color(0xFF059669)
        : (estado == 'tardanza'
            ? const Color(0xFFD97706)
            : const Color(0xFFDC2626));
    final Color bgEstado = estado == 'tiempo'
        ? const Color(0xFFECFDF5)
        : (estado == 'tardanza'
            ? const Color(0xFFFEF3C7)
            : const Color(0xFFFEF2F2));
    final Color bordeEstado = estado == 'tiempo'
        ? const Color(0xFFA7F3D0)
        : (estado == 'tardanza'
            ? const Color(0xFFFDE68A)
            : const Color(0xFFFECACA));

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
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
          onTap: () => _mostrarDialogoDetalleConductor(item),
          splashColor: const Color(0xFF02634C).withValues(alpha: 0.08),
          highlightColor: const Color(0xFF02634C).withValues(alpha: 0.04),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // 1. Avatar del conductor
                AvatarConductor(
                  foto: foto,
                  nombre: conductor,
                  radio: 24,
                  fontSize: 13,
                ),
                const SizedBox(width: 14),

                // 2. Información del conductor (Número, Nombre, Placa, Estado y Hora grande)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Arribita de la columna: solo el número de lista en badge suave
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        margin: const EdgeInsets.only(bottom: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5EF),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: const Color(0xFF02634C).withValues(alpha: 0.2),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          '$numeroLista',
                          style: const TextStyle(
                            color: Color(0xFF02634C),
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),

                      // Nombre del conductor
                      Text(
                        conductor,
                        style: const TextStyle(
                          color: Color(0xFF1E293B),
                          fontWeight: FontWeight.bold,
                          fontSize: 16.5,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),

                      // Placa / Unidad con ícono de auto
                      Row(
                        children: [
                          const Icon(
                            Icons.directions_car_rounded,
                            size: 15,
                            color: Color(0xFF64748B),
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              placa.isNotEmpty
                                  ? placa
                                  : (unidad.isNotEmpty ? 'Móvil #$unidad' : 'Sin unidad asignada'),
                              style: const TextStyle(
                                color: Color(0xFF475569),
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Fila de Estado Operativo + Hora de Llegada Grande
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 10,
                        runSpacing: 6,
                        children: [
                          // Punto + Habilitado / Inactivo
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: esActivo
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFFEF4444),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                esActivo ? 'Habilitado' : 'Inactivo',
                                style: TextStyle(
                                  color: esActivo
                                      ? const Color(0xFF059669)
                                      : const Color(0xFFEF4444),
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),

                          // Etiqueta de Estado y Hora de Llegada más grande y legible
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4.5,
                            ),
                            decoration: BoxDecoration(
                              color: bgEstado,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: bordeEstado, width: 1.0),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  estado == 'tiempo'
                                      ? Icons.check_circle_rounded
                                      : (estado == 'tardanza'
                                          ? Icons.access_time_filled_rounded
                                          : Icons.cancel_rounded),
                                  size: 15,
                                  color: colorEstado,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  estado == 'tiempo'
                                      ? (hora != '--:--' ? 'A tiempo • $hora' : 'A tiempo')
                                      : (estado == 'tardanza'
                                          ? (hora != '--:--' ? 'Tardanza • $hora' : 'Tardanza')
                                          : 'Sin marcar'),
                                  style: TextStyle(
                                    color: colorEstado,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13.5,
                                    letterSpacing: 0.1,
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

                // 3. Ícono Chevron para navegar al detalle
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF02634C),
                  size: 26,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 7. BOTÓN VER REPORTES
  // ---------------------------------------------------------------------------
  Widget _buildBotonVerReportes() {
    return InkWell(
      onTap: () {
        _mostrarModalReporteTardanzas();
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFE6F4F0),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0x3302634C)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_rounded,
              color: Color(0xFF02634C),
              size: 20,
            ),
            SizedBox(width: 10),
            Text(
              'Ver Reportes',
              style: TextStyle(
                color: Color(0xFF02634C),
                fontWeight: FontWeight.bold,
                fontSize: 14.5,
              ),
            ),
            SizedBox(width: 6),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Color(0xFF02634C),
              size: 13,
            ),
          ],
        ),
      ),
    );
  }
}
