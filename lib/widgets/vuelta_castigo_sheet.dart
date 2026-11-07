// lib/widgets/vuelta_castigo_sheet.dart
//
// Hoja de monitoreo GPS en vivo exclusivo para CUMPLIR VUELTAS DE CASTIGO:
//  - Independiente de la vista de Asistencia (no mezcla vistas).
//  - Muestra alerta en tiempo real del Punto A y Punto B (igual que en Asistencia).
//  - Actualiza en vivo los botones "Vuelta 1" y "Vuelta 2" (Pendiente -> En curso -> Cumplida)
//    usando las coordenadas de vuelta uno y vuelta dos (A -> B -> A = 1 vuelta, A -> B -> A = 2 vueltas).

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../domain/reglas_asistencia.dart';
import '../domain/ruta_continental.dart';
import '../services/database_helper.dart';
import '../services/gps_service.dart';
import '../services/sesion_service.dart';
import 'avatar_conductor.dart';
import 'ubicacion_azul.dart';

const _kVerde = Color(0xFF02634C);
const _kVerdeClaro = Color(0xFFE6F4F0);
const _kAzul = Color(0xFF1D4ED8);
const _kAzulClaro = Color(0xFFEFF6FF);
const _kAmbar = Color(0xFFD97706);
const _kRojo = Color(0xFFDC2626);
const _kRojoClaro = Color(0xFFFEE2E2);
const _kTexto = Color(0xFF0F172A);
const _kMuted = Color(0xFF64748B);

enum _EstadoVuelta { cumplida, enCurso, pendiente }

class _VueltaInfo {
  final int numero;
  final _EstadoVuelta estado;
  final int? salida;
  final int? pasoB;
  final int? llegada;
  final bool estimada;
  final bool fueraHorario;
  final double progreso;

  const _VueltaInfo({
    required this.numero,
    required this.estado,
    this.salida,
    this.pasoB,
    this.llegada,
    this.estimada = false,
    this.fueraHorario = false,
    this.progreso = 0,
  });
}

class VueltaCastigoSheet extends StatefulWidget {
  final Map<String, dynamic> datos;

  const VueltaCastigoSheet({super.key, required this.datos});

  static Future<void> mostrar(
    BuildContext context,
    Map<String, dynamic> datos,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => VueltaCastigoSheet(datos: datos),
    );
  }

  @override
  State<VueltaCastigoSheet> createState() => _VueltaCastigoSheetState();
}

class _VueltaCastigoSheetState extends State<VueltaCastigoSheet> {
  final MapController _mapController = MapController();
  bool _mapaListo = false;
  bool _satelite = true;
  bool _seguirGps = true;

  late int _hechas;
  late int _meta;
  late List<String> _horasCierre;
  late List<_VueltaInfo> _vueltas;
  int _seleccion = 0;

  // Estado GPS en vivo para completar las vueltas (A -> B -> A)
  StreamSubscription<Position>? _subGps;
  StreamSubscription<CompassEvent>? _subBrujula;
  Timer? _timerGps;
  Position? _posActual;
  LatLng? _posFiltrada;
  final List<LatLng> _rastroGps = [];
  double _velocidadKmh = 0.0;
  double _distanciaRecorridaM = 0.0;
  double _rumboGrados = 0.0;
  final ValueNotifier<double> _rumboNotifier = ValueNotifier<double>(0.0);
  bool _rumboValido = false;
  bool _brujulaDisponible = false;

  bool _enA = false;
  bool _enB = false;
  double? _distA;
  double? _distB;

  /// Control de etapa de la vuelta actual:
  /// null = aún no pisó A
  /// 'A'  = ya pisó Punto A (en camino hacia Punto B)
  /// 'B'  = ya pisó Punto B (en camino de regreso a Punto A para sumar la vuelta)
  String? _ladoActual;
  DateTime? _ultimaVueltaTime;
  bool _guardandoVuelta = false;

  /// Cuando se completa la Vuelta 1 (1/2), se pausa y espera a que el conductor
  /// presione el botón "Comenzar Vuelta 2" para iniciar el conteo de la segunda vuelta.
  bool _esperandoComenzarVuelta2 = false;

  String get _idConductor =>
      widget.datos['id_conductor']?.toString() ??
      SesionService.instance.idConductor ??
      '';

  @override
  void initState() {
    super.initState();
    _hechas = (widget.datos['vueltas_hechas'] as num?)?.toInt() ??
        (widget.datos['vueltas_cumplidas'] as num?)?.toInt() ??
        0;
    _meta = (widget.datos['vueltas_meta'] as num?)?.toInt() ??
        (widget.datos['vueltas_asignadas'] as num?)?.toInt() ??
        2;
    if (_meta <= 0) _meta = 2;
    _horasCierre = ((widget.datos['horas_cierre'] as List?) ?? const [])
        .map((e) => e?.toString() ?? '')
        .where((s) => s.isNotEmpty)
        .toList();
    _esperandoComenzarVuelta2 = _hechas > 0 && _hechas < _meta;

    _recalcularListaVueltas();
    _iniciarBrujula();
    _iniciarGpsVueltas();
    _sincronizarDesdeBd();
  }

  @override
  void dispose() {
    _subGps?.cancel();
    _subBrujula?.cancel();
    _timerGps?.cancel();
    _rumboNotifier.dispose();
    super.dispose();
  }

  Future<void> _sincronizarDesdeBd() async {
    if (_idConductor.isEmpty) return;
    try {
      final db = await DatabaseHelper.instance.database;
      final sanciones = await db.query(
        'sancion',
        where: 'id_conductor = ?',
        whereArgs: [_idConductor],
        orderBy:
            "CASE WHEN estado = 'pendiente' THEN 0 ELSE 1 END, fecha DESC, created_at DESC",
        limit: 1,
      );
      if (sanciones.isNotEmpty && mounted) {
        final s = sanciones.first;
        final asig = (s['vueltas_asignadas'] as num?)?.toInt() ?? 2;
        final cump = (s['vueltas_cumplidas'] as num?)?.toInt() ?? 0;
        final filasCierre = await db.query(
          'vueltas',
          columns: ['hora'],
          where: "id_conductor = ? AND tipo = 'sancion'",
          whereArgs: [_idConductor],
          orderBy: 'created_at ASC',
        );
        setState(() {
          _meta = asig > 0 ? asig : 2;
          _hechas = cump.clamp(0, _meta);
          if (_hechas > 0 && _hechas < _meta && _ladoActual == null) {
            _esperandoComenzarVuelta2 = true;
          } else if (_hechas >= _meta) {
            _esperandoComenzarVuelta2 = false;
          }
          _horasCierre = filasCierre
              .map((f) => f['hora']?.toString() ?? '')
              .where((h) => h.isNotEmpty)
              .toList();
          _recalcularListaVueltas();
        });
      }
    } catch (_) {}
  }

  void _recalcularListaVueltas() {
    _vueltas = _calcularVueltas();
    if (_esperandoComenzarVuelta2 && _hechas > 0) {
      // Mientras espera el botón "Comenzar Vuelta 2", mantener seleccionada la Vuelta 1 Cumplida
      _seleccion = (_hechas - 1).clamp(0, _vueltas.length - 1);
      return;
    }
    final idxEnCurso = _vueltas.indexWhere(
      (v) => v.estado == _EstadoVuelta.enCurso,
    );
    if (idxEnCurso >= 0) {
      _seleccion = idxEnCurso;
    } else if (_hechas >= _meta) {
      _seleccion = (_meta - 1).clamp(0, _vueltas.length - 1);
    } else {
      _seleccion = _hechas.clamp(0, _vueltas.length - 1);
    }
  }

  void _comenzarVuelta2() {
    HapticFeedback.mediumImpact();
    SystemSound.play(SystemSoundType.click);
    setState(() {
      _esperandoComenzarVuelta2 = false;
      _rastroGps.clear();
      if (_posFiltrada != null) {
        _rastroGps.add(_posFiltrada!);
      }
      _distanciaRecorridaM = 0.0;
      // Al presionar "Comenzar Vuelta 2" desde el Punto A, iniciar de inmediato en 'A'
      _ladoActual = (_enA || (_distA != null && _distA! <= 40.0)) ? 'A' : null;
      _recalcularListaVueltas();
      _seleccion = _hechas.clamp(0, _vueltas.length - 1);
    });
  }

  void _iniciarBrujula() {
    try {
      final stream = FlutterCompass.events;
      if (stream == null) return;
      _subBrujula = stream.listen(
        (event) {
          final heading = event.heading;
          if (heading == null || heading.isNaN || !mounted) return;
          _brujulaDisponible = true;
          final delta = ((heading - _rumboGrados + 540) % 360) - 180;
          _rumboGrados = (_rumboGrados + delta * 0.30 + 360) % 360;
          _rumboNotifier.value = _rumboGrados;
          if (!_rumboValido) setState(() => _rumboValido = true);
        },
        onError: (_) => _brujulaDisponible = false,
      );
    } catch (_) {}
  }

  Future<void> _iniciarGpsVueltas() async {
    final err = await GpsService.instance.asegurarPermisos();
    if (err != null || !mounted) return;

    final ultima = await GpsService.instance.obtenerUltimaPosicionConocida();
    if (ultima != null && mounted) {
      _procesarPosicionGps(ultima, permitirContarVuelta: false);
    }

    GpsService.instance
        .obtenerPosicionActual(timeout: const Duration(seconds: 5))
        .then((pos) {
      if (pos != null && mounted) {
        _procesarPosicionGps(pos, permitirContarVuelta: true);
      }
    }).catchError((_) {});

    _subGps?.cancel();
    _subGps = GpsService.instance
        .obtenerStreamPosicion(distanceFilterM: 0, usarForeground: false)
        .listen(
      (pos) => _procesarPosicionGps(pos, permitirContarVuelta: true),
      onError: (_) {},
    );

    _timerGps?.cancel();
    _timerGps = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (!mounted) return;
      try {
        final pos = await GpsService.instance.obtenerPosicionActual(
          timeout: const Duration(seconds: 4),
        );
        if (pos != null && mounted) {
          _procesarPosicionGps(pos, permitirContarVuelta: true);
        }
      } catch (_) {}
    });
  }

  LatLng _filtrarPosicion(Position p, LatLng cruda) {
    final previa = _posFiltrada;
    if (previa == null) return cruda;

    final enPuntoControl = RutaContinental.estaEnZonaParadaA(cruda) ||
        RutaContinental.estaEnZonaParadaB(cruda);
    if (enPuntoControl) return cruda;

    final d = ReglasAsistencia.calcularDistanciaMetros(
      lat1: previa.latitude,
      lon1: previa.longitude,
      lat2: cruda.latitude,
      lon2: cruda.longitude,
    );

    final enCorredor =
        RutaContinental.distanciaAlCorredorVueltasMetros(cruda) <= 8.5;
    final quieto = p.speed < (enCorredor ? 0.55 : 1.0);
    final radioRuido = quieto
        ? (enCorredor ? 4.0 : math.max(6.5, (p.accuracy * 0.70).clamp(6.5, 14.0)))
        : 2.0;
    if (d < radioRuido) return previa;

    final alpha = d > 18 ? 0.85 : (d > 8 ? 0.65 : 0.45);
    return LatLng(
      previa.latitude + (cruda.latitude - previa.latitude) * alpha,
      previa.longitude + (cruda.longitude - previa.longitude) * alpha,
    );
  }

  void _procesarPosicionGps(Position p, {required bool permitirContarVuelta}) {
    if (!mounted) return;

    final cruda = LatLng(p.latitude, p.longitude);
    final previa = _posFiltrada;
    final filtrada = _filtrarPosicion(p, cruda);
    final despM = previa == null
        ? 0.0
        : ReglasAsistencia.calcularDistanciaMetros(
            lat1: previa.latitude,
            lon1: previa.longitude,
            lat2: filtrada.latitude,
            lon2: filtrada.longitude,
          );

    final dA = RutaContinental.distanciaAlRectanguloMetros(
      filtrada,
      RutaContinental.rectanguloParadaA,
    );
    final dB = RutaContinental.distanciaAlRectanguloMetros(
      filtrada,
      RutaContinental.rectanguloParadaB,
    );

    final ahoraEnA = RutaContinental.estaEnZonaParadaA(filtrada) ||
        RutaContinental.estaEnZonaParadaA(cruda);
    final ahoraEnB = RutaContinental.estaEnZonaParadaB(filtrada) ||
        RutaContinental.estaEnZonaParadaB(cruda);

    bool completoVueltaAhora = false;

    setState(() {
      _posActual = p;
      _posFiltrada = filtrada;
      _distA = ahoraEnA ? 0.0 : dA;
      _distB = ahoraEnB ? 0.0 : dB;
      _enA = ahoraEnA;
      _enB = ahoraEnB;

      _velocidadKmh = (p.speed >= 0.85 && despM >= 1.5) ? (p.speed * 3.6) : 0.0;

      final umbralMov = math.max(3.5, (p.accuracy * 0.40).clamp(3.5, 8.0));
      if (previa != null &&
          p.accuracy <= 50 &&
          despM >= umbralMov &&
          despM <= 150.0) {
        _distanciaRecorridaM += despM;
      }

      if (!_brujulaDisponible && p.speed > 1.2 && p.heading >= 0) {
        final delta = ((p.heading - _rumboGrados + 540) % 360) - 180;
        _rumboGrados = (_rumboGrados + delta * 0.35 + 360) % 360;
        _rumboNotifier.value = _rumboGrados;
        _rumboValido = true;
      }

      if (p.accuracy <= 45) {
        if (_rastroGps.isEmpty) {
          _rastroGps.add(filtrada);
        } else {
          final distRastro = ReglasAsistencia.calcularDistanciaMetros(
            lat1: _rastroGps.last.latitude,
            lon1: _rastroGps.last.longitude,
            lat2: filtrada.latitude,
            lon2: filtrada.longitude,
          );
          final umbralRastro =
              math.max(5.0, (p.accuracy * 0.55).clamp(5.0, 10.0));
          if (distRastro >= umbralRastro) {
            _rastroGps.add(filtrada);
            if (_rastroGps.length > 400) _rastroGps.removeAt(0);
          }
        }
      }

      if (permitirContarVuelta && _hechas < _meta && !_esperandoComenzarVuelta2) {
        // Si acaba de abrir "Cumplir vueltas con GPS" estando en o junto al Punto A,
        // iniciar automáticamente la salida desde el Punto A
        if (_ladoActual == null && (ahoraEnA || dA <= 35.0)) {
          _ladoActual = 'A';
          HapticFeedback.selectionClick();
        } else if (ahoraEnA) {
          if (_ladoActual == 'B') {
            final ahora = DateTime.now();
            if (_ultimaVueltaTime == null ||
                ahora.difference(_ultimaVueltaTime!) >=
                    const Duration(seconds: 4)) {
              _ultimaVueltaTime = ahora;
              _ladoActual = null;
              completoVueltaAhora = true;
            }
          } else if (_ladoActual != 'A') {
            _ladoActual = 'A';
            HapticFeedback.selectionClick();
          }
        } else if (ahoraEnB) {
          if (_ladoActual != 'B') {
            _ladoActual = 'B';
            HapticFeedback.mediumImpact();
          }
        }
      }

      _recalcularListaVueltas();
    });

    if (_seguirGps && _mapaListo) {
      _mapController.move(filtrada, math.max(_mapController.camera.zoom, 18.2));
    }

    if (completoVueltaAhora) {
      _guardarVueltaEnSqlite();
    }
  }

  Future<void> _guardarVueltaEnSqlite() async {
    if (_guardandoVuelta || _hechas >= _meta) return;
    _guardandoVuelta = true;
    try {
      HapticFeedback.heavyImpact();
      SystemSound.play(SystemSoundType.click);

      final ahora = DateTime.now();
      final horaStr =
          '${ahora.hour.toString().padLeft(2, '0')}:${ahora.minute.toString().padLeft(2, '0')}';

      if (_idConductor.isNotEmpty) {
        await DatabaseHelper.instance.registrarVuelta(
          idConductor: _idConductor,
          tipo: 'sancion',
        );
      }

      if (!mounted) return;
      setState(() {
        _hechas = (_hechas + 1).clamp(0, _meta);
        _horasCierre.add(horaStr);
        _ladoActual = null;
        // Si completó la Vuelta 1 y aún falta la Vuelta 2, pausar y mostrar el botón "Comenzar Vuelta 2"
        _esperandoComenzarVuelta2 = _hechas > 0 && _hechas < _meta;
        _recalcularListaVueltas();
      });

      await _sincronizarDesdeBd();
    } catch (_) {
    } finally {
      _guardandoVuelta = false;
    }
  }

  // ---------------------------------------------------------------------------
  // Cálculo de vueltas
  // ---------------------------------------------------------------------------
  static int? _parseMin(String? s) {
    if (s == null) return null;
    final m = RegExp(r'(\d{1,2}):(\d{2})\s*(AM|PM|am|pm)?').firstMatch(s);
    if (m == null) return null;
    var h = int.parse(m.group(1)!);
    final mi = int.parse(m.group(2)!);
    final ap = m.group(3)?.toUpperCase();
    if (ap == 'PM' && h < 12) h += 12;
    if (ap == 'AM' && h == 12) h = 0;
    return h * 60 + mi;
  }

  static String _fmt(int m) {
    final x = ((m % 1440) + 1440) % 1440;
    return '${(x ~/ 60).toString().padLeft(2, '0')}:${(x % 60).toString().padLeft(2, '0')}';
  }

  static String _fmtMetros(double m) =>
      m >= 1000 ? '${(m / 1000).toStringAsFixed(2)} km' : '${m.round()} m';

  List<_VueltaInfo> _calcularVueltas() {
    final cierres = _horasCierre
        .map((e) => _parseMin(e))
        .whereType<int>()
        .toList();

    final ahora = DateTime.now();
    final ahoraMin = ahora.hour * 60 + ahora.minute;
    final lista = <_VueltaInfo>[];
    var cursor = cierres.isNotEmpty ? (cierres.first - 2) : (ahoraMin - 1);

    // Si está esperando que el usuario presione "Comenzar Vuelta 2", la Vuelta 2 sigue en Pendiente
    final enRecorridoActivo =
        !_esperandoComenzarVuelta2 && (_ladoActual != null || _hechas == 0);

    for (int i = 1; i <= _meta; i++) {
      if (i <= _hechas) {
        final registrada = cierres.length >= i;
        final llegada = registrada ? cierres[i - 1] : cursor + 2;
        final salida = llegada - 2;
        lista.add(
          _VueltaInfo(
            numero: i,
            estado: _EstadoVuelta.cumplida,
            salida: salida,
            pasoB: salida + 1,
            llegada: llegada,
            estimada: !registrada,
            fueraHorario: false,
            progreso: 1.0,
          ),
        );
        cursor = llegada + 1;
      } else if (i == _hechas + 1 && enRecorridoActivo) {
        final prog = _ladoActual == 'B' ? 0.65 : 0.25;
        lista.add(
          _VueltaInfo(
            numero: i,
            estado: _EstadoVuelta.enCurso,
            salida: ahoraMin,
            pasoB: ahoraMin,
            estimada: true,
            progreso: prog,
          ),
        );
      } else {
        lista.add(_VueltaInfo(numero: i, estado: _EstadoVuelta.pendiente));
      }
    }
    return lista;
  }

  // ---------------------------------------------------------------------------
  // Colores / textos por estado
  // ---------------------------------------------------------------------------
  Color _color(_EstadoVuelta e) => switch (e) {
    _EstadoVuelta.cumplida => _kVerde,
    _EstadoVuelta.enCurso => _kAzul,
    _EstadoVuelta.pendiente => _kRojo,
  };

  Color _fondo(_EstadoVuelta e) => switch (e) {
    _EstadoVuelta.cumplida => _kVerdeClaro,
    _EstadoVuelta.enCurso => _kAzulClaro,
    _EstadoVuelta.pendiente => _kRojoClaro,
  };

  String _texto(_EstadoVuelta e) => switch (e) {
    _EstadoVuelta.cumplida => 'Cumplida',
    _EstadoVuelta.enCurso => 'En curso',
    _EstadoVuelta.pendiente => 'Pendiente',
  };

  IconData _icono(_EstadoVuelta e) => switch (e) {
    _EstadoVuelta.cumplida => Icons.check_circle_rounded,
    _EstadoVuelta.enCurso => Icons.directions_car_filled_rounded,
    _EstadoVuelta.pendiente => Icons.schedule_rounded,
  };

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final v = widget.datos;
    final nombre =
        (v['conductor'] ?? v['conductor_nombre'] ?? 'Conductor').toString();
    final unidad = (v['unidad'] ?? v['numero_interno'] ?? '-').toString();
    final placa = (v['placa'] ?? 'S/P').toString();
    final esConductor = SesionService.instance.esConductor;

    final total = _hechas >= _meta
        ? _EstadoVuelta.cumplida
        : ((_hechas > 0 || _ladoActual != null)
            ? _EstadoVuelta.enCurso
            : _EstadoVuelta.pendiente);
    final sel = _vueltas[_seleccion.clamp(0, _vueltas.length - 1)];
    final bottom = MediaQuery.of(context).padding.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.93,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Row(
              children: [
                AvatarConductor(
                  foto: (v['foto'] ?? v['conductor_foto']) as String?,
                  nombre: nombre,
                  radio: 24,
                  fontSize: 14,
                ),
                const SizedBox(width: 12),
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
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        esConductor
                            ? 'Control de Vueltas de Castigo por GPS'
                            : 'Móvil #$unidad • Placa: $placa',
                        style: const TextStyle(color: _kMuted, fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _fondo(total),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$_hechas/$_meta vueltas',
                        style: TextStyle(
                          color: _color(total),
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        _texto(total),
                        style: TextStyle(
                          color: _color(total),
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          Flexible(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                20,
                12,
                20,
                bottom > 0 ? bottom + 16 : 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Alerta en vivo del Punto de Control para las Vueltas (igual que en Asistencia)
                  _tarjetaAlertaGpsVueltas(),
                  if (_esperandoComenzarVuelta2 && _hechas < _meta) ...[
                    const SizedBox(height: 12),
                    _botonComenzarVuelta2(),
                  ],
                  const SizedBox(height: 14),

                  // 2. Botones de Vuelta 1 y Vuelta 2 en vivo
                  const Text(
                    'Progreso de vueltas por GPS',
                    style: TextStyle(
                      color: _kTexto,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _selectorVueltas(),
                  const SizedBox(height: 10),

                  // 3. Mapa Satelital en vivo con el vehículo y los Puntos A y B
                  _mapa(sel),
                  const SizedBox(height: 8),
                  _leyenda(sel),
                  const SizedBox(height: 12),

                  // 4. Telemetría en tiempo real de las paradas A y B
                  _panelTelemetriaVueltas(),
                  const SizedBox(height: 12),

                  // 5. Línea de tiempo de la vuelta seleccionada
                  _lineaTiempo(sel),
                ],
              ),
            ),
          ),
          /*
          // Botones inferiores deshabilitados por solicitud para no mezclar la vista de Asistencia
          // con la vista de cumplimiento de vueltas de castigo:
          Container(
            padding: EdgeInsets.fromLTRB(
              20,
              12,
              20,
              bottom > 0 ? bottom + 8 : 18,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.satellite_alt_rounded, size: 20),
                  label: const Text('Ver ubicación en GPS en vivo'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.map_outlined, color: _kVerde, size: 20),
                  label: const Text('Ver circuito oficial (14.69 km)'),
                ),
              ],
            ),
          ),
          */
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Tarjeta de Alerta GPS en Vivo para Cumplir Vueltas (sin mezclar con Asistencia)
  // ---------------------------------------------------------------------------
  Widget _tarjetaAlertaGpsVueltas() {
    final cumplidasTodas = _hechas >= _meta;
    final vueltaActualNum = (_hechas + 1).clamp(1, _meta);

    Color bgCard;
    Color borderCard;
    Color iconBg;
    Color titleColor;
    IconData iconData;
    String titulo;
    String subtitulo1;
    String subtitulo2;

    if (cumplidasTodas) {
      bgCard = const Color(0xFFECFDF5);
      borderCard = const Color(0xFF10B981);
      iconBg = const Color(0xFF10B981);
      titleColor = const Color(0xFF065F46);
      iconData = Icons.verified_rounded;
      titulo = '¡Vueltas cumplidas ($_hechas/$_meta)!';
      subtitulo1 = 'Completaste las $_meta vueltas de castigo por GPS';
      subtitulo2 = 'Sanción cumplida y cerrada automáticamente';
    } else if (_esperandoComenzarVuelta2) {
      bgCard = const Color(0xFFECFDF5);
      borderCard = const Color(0xFF10B981);
      iconBg = const Color(0xFF10B981);
      titleColor = const Color(0xFF065F46);
      iconData = Icons.check_circle_rounded;
      titulo = '¡Vuelta $_hechas cumplida ($_hechas/$_meta)!';
      subtitulo1 = 'Completaste la Vuelta $_hechas en el Punto A';
      subtitulo2 =
          'Presiona "Comenzar Vuelta $vueltaActualNum" para iniciar la siguiente vuelta';
    } else if (_enA) {
      bgCard = const Color(0xFFECFDF5);
      borderCard = const Color(0xFF10B981);
      iconBg = const Color(0xFF10B981);
      titleColor = const Color(0xFF065F46);
      iconData = Icons.check_circle_rounded;
      titulo = '¡Estás en el Punto A (Cruce Villadela)!';
      subtitulo1 = 'Vuelta $vueltaActualNum iniciada • Progreso: $_hechas/$_meta vueltas';
      subtitulo2 = 'Ahora ve al Punto B (Teleférico) y regresa al Punto A';
    } else if (_enB) {
      bgCard = const Color(0xFFFFFBEB);
      borderCard = const Color(0xFFF59E0B);
      iconBg = const Color(0xFFD97706);
      titleColor = const Color(0xFF92400E);
      iconData = Icons.u_turn_left_rounded;
      titulo = '¡Estás en el Punto B (Retorno)!';
      subtitulo1 = 'Retorno de la Vuelta $vueltaActualNum registrado';
      subtitulo2 =
          'Ahora regresa al Punto A para completar la Vuelta $vueltaActualNum';
    } else if (_ladoActual == 'B') {
      bgCard = const Color(0xFFEFF6FF);
      borderCard = const Color(0xFF60A5FA);
      iconBg = const Color(0xFF2563EB);
      titleColor = const Color(0xFF1E40AF);
      iconData = Icons.directions_car_filled_rounded;
      titulo = 'Vuelta $vueltaActualNum en curso • Regresando al Punto A';
      subtitulo1 = _distA != null
          ? 'Faltan ${_fmtMetros(_distA!)} para llegar al Punto A'
          : 'Acércate al Punto A (Cruce Villadela)';
      subtitulo2 =
          'Pisa el Punto A para sumar la Vuelta $vueltaActualNum ($_hechas/$_meta)';
    } else if (_ladoActual == 'A') {
      bgCard = const Color(0xFFEFF6FF);
      borderCard = const Color(0xFF60A5FA);
      iconBg = const Color(0xFF2563EB);
      titleColor = const Color(0xFF1E40AF);
      iconData = Icons.directions_car_filled_rounded;
      titulo = 'Vuelta $vueltaActualNum en curso • Rumbo al Punto B';
      subtitulo1 = _distB != null
          ? 'Estás a ${_fmtMetros(_distB!)} del Punto B (Teleférico)'
          : 'Dirígete hacia el Punto B (Teleférico)';
      subtitulo2 = 'Pisa el Punto B y vuelve al Punto A ($_hechas/$_meta vueltas)';
    } else {
      bgCard = const Color(0xFFFEF2F2);
      borderCard = const Color(0xFFFCA5A5);
      iconBg = const Color(0xFFEF4444);
      titleColor = const Color(0xFF991B1B);
      iconData = Icons.warning_amber_rounded;
      titulo = 'No estás en el punto de control';
      subtitulo1 = _distA != null
          ? 'Estás a ${_fmtMetros(_distA!)} del Punto A (Cruce Villadela)'
          : 'Esperando señal GPS del dispositivo…';
      subtitulo2 =
          'Pisa el Punto A para iniciar la Vuelta $vueltaActualNum ($_hechas/$_meta)';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderCard, width: 1.6),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(iconData, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: titleColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitulo1,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _kTexto,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  subtitulo2,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () {
              setState(() => _seguirGps = true);
              if (_posFiltrada != null && _mapaListo) {
                _mapController.move(_posFiltrada!, 18.4);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: _seguirGps ? _kVerde : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFB7DFD5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _seguirGps
                        ? Icons.my_location_rounded
                        : Icons.location_searching_rounded,
                    color: _seguirGps ? Colors.white : _kVerde,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Mi GPS',
                    style: TextStyle(
                      color: _seguirGps ? Colors.white : _kVerde,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _botonComenzarVuelta2() {
    final numSiguiente = (_hechas + 1).clamp(1, _meta);
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _comenzarVuelta2,
        icon: const Icon(
          Icons.play_circle_fill_rounded,
          color: Colors.white,
          size: 22,
        ),
        label: Text(
          'Comenzar Vuelta $numSiguiente',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 15,
            letterSpacing: 0.2,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _kVerde,
          foregroundColor: Colors.white,
          elevation: 3,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Selector de vuelta (Vuelta 1 | Vuelta 2)
  // ---------------------------------------------------------------------------
  Widget _selectorVueltas() {
    return Row(
      children: [
        for (int i = 0; i < _vueltas.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(child: _chipVuelta(i)),
        ],
      ],
    );
  }

  Widget _chipVuelta(int i) {
    final info = _vueltas[i];
    final activo = _seleccion == i;
    final color = _color(info.estado);
    return GestureDetector(
      onTap: () => setState(() => _seleccion = i),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: activo ? color : _fondo(info.estado),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color,
            width: activo ? 1.8 : 1.2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _icono(info.estado),
              size: 16,
              color: activo ? Colors.white : color,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                'Vuelta ${info.numero} • ${_texto(info.estado)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: activo ? Colors.white : color,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Mapa Satelital con ruta oficial + GPS en vivo del conductor
  // ---------------------------------------------------------------------------
  Widget _mapa(_VueltaInfo vuelta) {
    final circuito = RutaContinental.circuitoCompleto;
    final color = _color(vuelta.estado);

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        height: 280,
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: RutaContinental.paradaAVilladela,
                initialZoom: 18.2,
                onMapReady: () {
                  _mapaListo = true;
                  if (_posFiltrada != null) {
                    _mapController.move(_posFiltrada!, 18.3);
                  } else {
                    _mapController.fitCamera(
                      CameraFit.bounds(
                        bounds: LatLngBounds.fromPoints([
                          ...circuito,
                          ...RutaContinental.rectanguloParadaA,
                          ...RutaContinental.rectanguloParadaB,
                        ]),
                        padding: const EdgeInsets.all(36),
                      ),
                    );
                  }
                },
                onPositionChanged: (_, hasGesture) {
                  if (hasGesture && _seguirGps) {
                    setState(() => _seguirGps = false);
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: _satelite
                      ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
                      : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.sindicato.continental.trufi',
                  maxNativeZoom: 19,
                  maxZoom: 21,
                ),
                // Trazado oficial de ida y vuelta + rastro GPS en vivo
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: RutaContinental.puntosIda,
                      strokeWidth: 4.5,
                      color: const Color(0xFF10B981).withValues(alpha: 0.85),
                    ),
                    Polyline(
                      points: RutaContinental.puntosVuelta,
                      strokeWidth: 4.5,
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.85),
                    ),
                    if (vuelta.estado == _EstadoVuelta.cumplida)
                      Polyline(
                        points: circuito,
                        strokeWidth: 6,
                        color: _kVerde,
                        borderStrokeWidth: 2,
                        borderColor: Colors.white,
                      ),
                    if (_rastroGps.length >= 2)
                      Polyline(
                        points: _rastroGps,
                        strokeWidth: 5,
                        color: const Color(0xFF2563EB),
                        borderStrokeWidth: 1.5,
                        borderColor: Colors.white,
                      ),
                  ],
                ),
                PolygonLayer(
                  polygons: [
                    Polygon(
                      points: RutaContinental.rectanguloParadaA,
                      color: (_enA ? const Color(0xFF10B981) : const Color(0xFF2563EB))
                          .withValues(alpha: 0.32),
                      borderColor:
                          _enA ? const Color(0xFF10B981) : const Color(0xFF2563EB),
                      borderStrokeWidth: 3.0,
                    ),
                    Polygon(
                      points: RutaContinental.rectanguloParadaB,
                      color: (_enB ? const Color(0xFF10B981) : _kAmbar)
                          .withValues(alpha: 0.30),
                      borderColor: _enB ? const Color(0xFF10B981) : _kAmbar,
                      borderStrokeWidth: 3.0,
                    ),
                  ],
                ),
                if (_posActual != null && _posFiltrada != null)
                  CircleLayer(
                    circles: [
                      CircleMarker(
                        point: _posFiltrada!,
                        radius: _posActual!.accuracy.clamp(3.0, 25.0),
                        useRadiusInMeter: true,
                        color: const Color(0xFF2563EB).withValues(alpha: 0.14),
                        borderColor:
                            const Color(0xFF2563EB).withValues(alpha: 0.45),
                        borderStrokeWidth: 1.2,
                      ),
                    ],
                  ),
                MarkerLayer(
                  markers: [
                    _marcadorParada(
                      RutaContinental.paradaAVilladela,
                      'A',
                      _kVerde,
                    ),
                    _marcadorParada(
                      RutaContinental.paradaBTeleferico,
                      'B',
                      _kAmbar,
                    ),
                    if (_posFiltrada != null)
                      Marker(
                        point: _posFiltrada!,
                        width: 76,
                        height: 76,
                        child: UbicacionAzul(
                          rumboGrados: _rumboGrados,
                          rumboListenable: _rumboNotifier,
                          rumboValido: _rumboValido,
                          tamano: 76,
                          tamanoPunto: 18,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            // Etiqueta de estado de la vuelta sobre el mapa
            Positioned(
              left: 10,
              top: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 6),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_icono(vuelta.estado), size: 14, color: color),
                    const SizedBox(width: 5),
                    Text(
                      'Vuelta ${vuelta.numero} • ${_texto(vuelta.estado)}',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Botones de satélite / encuadrar ruta
            Positioned(
              right: 10,
              top: 10,
              child: Column(
                children: [
                  Material(
                    color: Colors.white,
                    shape: const CircleBorder(),
                    elevation: 3,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => setState(() => _satelite = !_satelite),
                      child: Padding(
                        padding: const EdgeInsets.all(9),
                        child: Icon(
                          _satelite
                              ? Icons.map_outlined
                              : Icons.satellite_alt_rounded,
                          size: 18,
                          color: _kVerde,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Material(
                    color: Colors.white,
                    shape: const CircleBorder(),
                    elevation: 3,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () {
                        if (!_mapaListo) return;
                        setState(() => _seguirGps = false);
                        _mapController.fitCamera(
                          CameraFit.bounds(
                            bounds: LatLngBounds.fromPoints([
                              ...circuito,
                              ...RutaContinental.rectanguloParadaA,
                              ...RutaContinental.rectanguloParadaB,
                            ]),
                            padding: const EdgeInsets.all(36),
                          ),
                        );
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(9),
                        child: Icon(
                          Icons.zoom_out_map_rounded,
                          size: 18,
                          color: _kVerde,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Marker _marcadorParada(LatLng punto, String etiqueta, Color color) {
    return Marker(
      point: punto,
      width: 34,
      height: 34,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2.5),
          boxShadow: const [
            BoxShadow(
              color: Colors.black38,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          etiqueta,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _leyenda(_VueltaInfo vuelta) {
    return Row(
      children: [
        Container(
          width: 18,
          height: 5,
          decoration: BoxDecoration(
            color: const Color(0xFF10B981),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 5),
        const Text(
          'Ida (A → B)',
          style: TextStyle(
            color: _kMuted,
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 18,
          height: 5,
          decoration: BoxDecoration(
            color: _kAmbar,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 5),
        const Text(
          'Regreso (B → A)',
          style: TextStyle(
            color: _kMuted,
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 18,
          height: 5,
          decoration: BoxDecoration(
            color: const Color(0xFF2563EB),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 5),
        const Text(
          'Tu GPS',
          style: TextStyle(
            color: _kMuted,
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Telemetría en tiempo real de las vueltas
  // ---------------------------------------------------------------------------
  Widget _panelTelemetriaVueltas() {
    final precisionStr = _posActual != null
        ? '±${_posActual!.accuracy.toStringAsFixed(0)} m'
        : 'Sin GPS';
    final distAStr = _distA != null
        ? (_enA ? 'En Punto A' : _fmtMetros(_distA!))
        : '--';
    final distBStr = _distB != null
        ? (_enB ? 'En Punto B' : _fmtMetros(_distB!))
        : '--';

    return Column(
      children: [
        Row(
          children: [
            _stat('Precisión GPS', precisionStr, 'señal actual'),
            const SizedBox(width: 8),
            _stat(
              'Velocidad',
              '${_velocidadKmh.toStringAsFixed(1)} km/h',
              'Recorrido: ${_fmtMetros(_distanciaRecorridaM)}',
            ),
            const SizedBox(width: 8),
            _stat('Vueltas', '$_hechas / $_meta', 'A → B → A'),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: _kVerde,
                        shape: BoxShape.circle,
                      ),
                      child: const Text(
                        'A',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        'Punto A: $distAStr',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _enA ? _kVerde : _kTexto,
                          fontWeight: FontWeight.w800,
                          fontSize: 11.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 20, color: const Color(0xFFE2E8F0)),
              const SizedBox(width: 10),
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: _kAmbar,
                        shape: BoxShape.circle,
                      ),
                      child: const Text(
                        'B',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        'Punto B: $distBStr',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _enB ? _kAmbar : _kTexto,
                          fontWeight: FontWeight.w800,
                          fontSize: 11.5,
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
    );
  }

  Widget _stat(String label, String valor, String sub) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                color: _kMuted,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              valor,
              style: const TextStyle(
                color: _kVerde,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              sub,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 9.5),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Línea de tiempo de la vuelta elegida
  // ---------------------------------------------------------------------------
  Widget _lineaTiempo(_VueltaInfo vuelta) {
    final color = _color(vuelta.estado);
    final pasoBHecho = vuelta.estado == _EstadoVuelta.cumplida ||
        (vuelta.estado == _EstadoVuelta.enCurso && _ladoActual == 'B');

    final pasos = <Widget>[];
    switch (vuelta.estado) {
      case _EstadoVuelta.cumplida:
        pasos.addAll([
          _paso(
            'Salida Parada A (Cruce Villadela)',
            'Inicio de vuelta registrado por GPS',
            _fmt(vuelta.salida!),
            true,
            _kVerde,
          ),
          _paso(
            'Retorno en Parada B (Teleférico)',
            'Punto B alcanzado correctamente',
            _fmt(vuelta.pasoB!),
            true,
            _kAzul,
          ),
          _paso(
            'Llegada Parada A • Vuelta completada',
            'Vuelta registrada en base de datos SQLite',
            _fmt(vuelta.llegada!),
            true,
            _kVerde,
            ultimo: true,
          ),
        ]);
      case _EstadoVuelta.enCurso:
        pasos.addAll([
          _paso(
            'Salida Parada A (Cruce Villadela)',
            'Punto A confirmado por GPS',
            'Confirmado',
            true,
            _kVerde,
          ),
          _paso(
            pasoBHecho
                ? 'Retorno en Parada B (Teleférico)'
                : 'En camino hacia Punto B (Teleférico)',
            pasoBHecho
                ? 'Punto B alcanzado • Regresa al Punto A'
                : 'Camina hacia el Punto B para registrar retorno',
            pasoBHecho ? 'Confirmado' : 'En curso',
            pasoBHecho,
            _kAzul,
          ),
          _paso(
            'Regreso a Parada A (Cruce Villadela)',
            'Pisa el Punto A para cerrar esta vuelta',
            '--:--',
            false,
            const Color(0xFF94A3B8),
            ultimo: true,
          ),
        ]);
      case _EstadoVuelta.pendiente:
        pasos.add(
          _paso(
            'Aún no inició esta vuelta',
            'Pisa el Punto A (Cruce Villadela), ve al Punto B y regresa al Punto A',
            'Pendiente GPS',
            false,
            _kRojo,
            ultimo: true,
          ),
        );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Vuelta ${vuelta.numero} • ${_texto(vuelta.estado)}',
                style: const TextStyle(
                  color: _kTexto,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              Text(
                '$_hechas/$_meta completadas',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...pasos,
        ],
      ),
    );
  }

  Widget _paso(
    String titulo,
    String subtitulo,
    String hora,
    bool hecho,
    Color color, {
    bool ultimo = false,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 20,
            child: Column(
              children: [
                Icon(
                  hecho
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 16,
                  color: color,
                ),
                if (!ultimo)
                  Expanded(
                    child: Container(
                      width: 1.5,
                      color: const Color(0xFFCBD5E1),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: ultimo ? 0 : 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          titulo,
                          style: const TextStyle(
                            color: Color(0xFF1E293B),
                            fontWeight: FontWeight.w700,
                            fontSize: 11.5,
                          ),
                        ),
                        Text(
                          subtitulo,
                          style: const TextStyle(color: _kMuted, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    hora,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
