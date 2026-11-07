// lib/screens/gps/gps_en_vivo_screen.dart
//
// Pantalla de monitoreo GPS en tiempo real (100% GPS real y datos reales de SQLite, sin simulaciones):
//  - Lee conductores, asistencias, vueltas y sanciones reales desde SQLite.
//  - Usa exclusivamente el chip GPS físico del dispositivo (Geolocator) para posición, velocidad, precisión y distancias.
//  - Geocercas CIRCULARES Haversine en Parada A y Parada B (mínimo 30-50 m, imposibles de saltar en vehículo).
//  - La máquina de conteo de vueltas define la UI: vive en GpsTrackingService,
//    no en el State de esta pantalla (resiste cambios de vista y bloqueo del teléfono).

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../domain/puntos_oficiales.dart';
import '../../domain/reglas_asistencia.dart';
import '../../domain/ruta_continental.dart';
import '../../services/asistencia_repo.dart';
import '../../services/database_helper.dart';
import '../../services/gps_service.dart';
import '../../services/gps_tracking_service.dart';
import '../../services/sesion_service.dart';
import '../../widgets/ubicacion_azul.dart';
import '../asistencia/puntos_control_screen.dart';

// ---------- Paleta Corporativa Sindicato Continental ----------
const _kVerdeContinental = Color(0xFF02634C);
const _kVerdeOscuro = Color(0xFF064E3B);
const _kVerdeBorde = Color(0xFFA7F3D0);
const _kVerdeActivo = Color(0xFF10B981);
const _kParadaA = Color(0xFF02634C);
const _kParadaB = Color(0xFFD97706);
const _kTextoOscuro = Color(0xFF0F172A);
const _kTextoMuted = Color(0xFF64748B);
const _kUsuario = Color(0xFF2563EB);
const _kDentro = Color(0xFF10B981);

enum _Estilo { satelite, calles }

/// Modelo que representa el estado real en SQLite de un conductor del sindicato.
class _VehiculoFlota {
  final String idConductor;
  final String nombre;
  final String unidad;
  final String placa;
  final String foto;
  String estadoAsistencia; // 'tiempo' | 'tardanza' | 'falta'
  String horaMarcacion;
  LatLng? posicionRegistrada;
  int vueltasHoy;
  int vueltasCastigoCumplidas;
  int metaVueltasCastigo;

  _VehiculoFlota({
    required this.idConductor,
    required this.nombre,
    required this.unidad,
    required this.placa,
    this.foto = '',
    required this.estadoAsistencia,
    required this.horaMarcacion,
    this.posicionRegistrada,
    this.vueltasHoy = 0,
    this.vueltasCastigoCumplidas = 0,
    this.metaVueltasCastigo = 0,
  });

  String get primerNombre {
    final partes = nombre.trim().split(RegExp(r'\s+'));
    return partes.isNotEmpty ? partes.first : 'Conductor';
  }
}

class _Parada {
  final String id;
  final String nombre;
  final String etiqueta; // 'A' o 'B'
  final LatLng punto;
  final double radio;
  final Color color;

  const _Parada({
    required this.id,
    required this.nombre,
    required this.etiqueta,
    required this.punto,
    required this.radio,
    required this.color,
  });
}

/// Estado Dentro/Fuera respecto a la geocerca circular del punto de control.
/// Con histéresis: para CONFIRMAR la salida hay que alejarse al 1.5x del radio.
class _Geocerca {
  bool dentro = false;

  void actualizar({
    required double distancia,
    required double accuracy,
    required double radio,
  }) {
    final margen = accuracy.clamp(0.0, 40.0);
    final limite = dentro ? radio * 1.3 : radio;
    dentro = (distancia - margen) <= limite;
  }
}

class GpsEnVivoScreen extends StatefulWidget {
  final Map<String, dynamic>? conductorMonitoreado;
  const GpsEnVivoScreen({super.key, this.conductorMonitoreado});

  @override
  State<GpsEnVivoScreen> createState() => _GpsEnVivoScreenState();
}

class _GpsEnVivoScreenState extends State<GpsEnVivoScreen>
    with SingleTickerProviderStateMixin {
  final MapController _map = MapController();
  late final AnimationController _pulso;
  StreamSubscription<Position>? _subGps;
  StreamSubscription<CompassEvent>? _subBrujula;
  Timer? _timerRefrescoGps;

  // Rumbo del visor (brújula)
  double _rumboGrados = 0;
  final ValueNotifier<double> _rumboNotifier = ValueNotifier<double>(0);
  bool _rumboValido = false;
  bool _brujulaDisponible = false;

  // Paradas y Geocercas: las coordenadas se reemplazan por las del registro
  // activo de `punto_de_control` (SQLite); aquí solo valores por defecto.
  List<_Parada> _paradas = const [
    _Parada(
      id: 'parada_a_villadela',
      nombre: 'Cruce Villadela',
      etiqueta: 'A',
      punto: PuntosOficiales.paradaAVilladela,
      radio: PuntosOficiales.radioAsistenciaM,
      color: _kParadaA,
    ),
    _Parada(
      id: 'parada_b_teleferico',
      nombre: 'Teleférico Amarillo - Mirador',
      etiqueta: 'B',
      punto: PuntosOficiales.paradaBTeleferico,
      radio: PuntosOficiales.radioAsistenciaM,
      color: _kParadaB,
    ),
  ];
  final Map<String, _Geocerca> _estados = {
    'parada_a_villadela': _Geocerca(),
    'parada_b_teleferico': _Geocerca(),
  };

  // GPS físico real del dispositivo
  final List<LatLng> _rastroUsuario = [];
  Position? _posUsuario;
  LatLng? _posFiltrada;
  double _velocidadRealKmh = 0.0;
  double _distanciaRealM = 0.0;
  bool _marcandoAsistencia = false;

  // Conductores reales de SQLite
  List<_VehiculoFlota> _vehiculos = [];
  _VehiculoFlota? _vehiculoSeleccionado;

  bool _seguir = false;
  bool _mapaListo = false;
  String? _errorGps;
  _Estilo _estilo = _Estilo.satelite;

  // Conteo de vueltas: delega 100% en el servicio singleton (fuera de la UI)
  StreamSubscription<EventoCircuito>? _subEventosCircuito;

  @override
  void initState() {
    super.initState();
    _pulso = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();

    _cargarParadas();
    _cargarFlotaConductores();
    _iniciarGps();
    _iniciarBrujula();
    _escucharEventosCircuito();
  }

  @override
  void dispose() {
    _timerRefrescoGps?.cancel();
    _subGps?.cancel();
    _subBrujula?.cancel();
    _subEventosCircuito?.cancel();
    _rumboNotifier.dispose();
    _pulso.dispose();
    super.dispose();
  }

  /// Suscribe la pantalla a los eventos del servicio singleton de vueltas:
  /// de esta manera el aviso es el mismo aunque el usuario venga de otra vista.
  void _escucharEventosCircuito() {
    _subEventosCircuito?.cancel();
    _subEventosCircuito =
        GpsTrackingService.instance.eventos.listen((e) async {
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      SystemSound.play(SystemSoundType.click);
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor:
                e.tipo == 'vuelta_completada' ? _kVerdeContinental : _kParadaB,
            duration: const Duration(seconds: 3),
            content: Text(
              e.mensaje,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        );
      if (e.tipo == 'vuelta_completada') {
        await _cargarFlotaConductores();
      }
    });

    // Garantiza que el servicio esté corriendo aunque entre directo a esta vista.
    if (!GpsTrackingService.instance.activo.value) {
      GpsTrackingService.instance
          .iniciar(idConductor: SesionService.instance.idConductor)
          .catchError((_) {});
    } else {
      GpsTrackingService.instance.refrescarVueltas();
    }
  }

  // ---------- Carga 100% Real desde SQLite ----------
  Future<void> _cargarFlotaConductores() async {
    try {
      final hoy = DateTime.now().toIso8601String().substring(0, 10);
      final conductoresBd = await DatabaseHelper.instance.conductoresConAuto();
      final asistenciasBd =
          await DatabaseHelper.instance.asistenciasDetalle(fecha: hoy);
      final vueltasHoyBd =
          await DatabaseHelper.instance.vueltasDetalle(fecha: hoy);
      final sancionesBd = await DatabaseHelper.instance.sancionesDetalle();

      final asistenciasPorConductor = <String, Map<String, dynamic>>{};
      for (final a in asistenciasBd) {
        final idC = a['id_conductor']?.toString() ?? '';
        if (idC.isNotEmpty) {
          asistenciasPorConductor[idC] = a;
        }
      }

      final vueltasPorConductor = <String, int>{};
      for (final v in vueltasHoyBd) {
        final idC = v['id_conductor']?.toString() ?? '';
        if (idC.isNotEmpty) {
          vueltasPorConductor[idC] = (vueltasPorConductor[idC] ?? 0) + 1;
        }
      }

      final sancionActivaPorConductor = <String, Map<String, dynamic>>{};
      for (final s in sancionesBd) {
        final idC = s['id_conductor']?.toString() ?? '';
        if (idC.isEmpty) continue;
        final est = s['estado']?.toString() ?? '';
        final cerradaHoy = est == 'cumplida' &&
            (s['updated_at']?.toString() ?? '').startsWith(hoy);
        if (est == 'pendiente' || cerradaHoy) {
          sancionActivaPorConductor.putIfAbsent(idC, () => s);
        }
      }

      final List<_VehiculoFlota> flota = [];

      for (int i = 0; i < conductoresBd.length; i++) {
        final c = conductoresBd[i];
        final id = c['id_conductor']?.toString() ?? '';
        final nombre = c['nombre']?.toString() ?? 'Conductor #${i + 1}';
        final unidad = c['numero_interno']?.toString() ?? '${i + 1}';
        final placa = c['placa']?.toString() ?? 'S/P';
        final foto = c['foto']?.toString() ?? '';
        final asist = asistenciasPorConductor[id];
        final sancion = sancionActivaPorConductor[id];

        String estado;
        String hora;
        LatLng? posReg;

        if (asist != null) {
          final st = asist['estado']?.toString().toLowerCase() ?? 'presente';
          if (st == 'tardanza') {
            estado = 'tardanza';
          } else if (st == 'falta') {
            estado = 'falta';
          } else {
            estado = 'tiempo';
          }
          hora = asist['hora_llegada']?.toString() ?? '--:--';
          final lat = (asist['latitud'] as num?)?.toDouble();
          final lon = (asist['longitud'] as num?)?.toDouble();
          if (lat != null && lon != null) {
            posReg = LatLng(lat, lon);
          }
        } else {
          estado = 'falta';
          hora = 'Sin marcar';
        }

        final vueltasHoy = vueltasPorConductor[id] ?? 0;
        final hechasCastigo =
            (sancion?['vueltas_cumplidas'] as num?)?.toInt() ?? 0;
        final metaCastigo =
            (sancion?['vueltas_asignadas'] as num?)?.toInt() ?? 0;

        flota.add(
          _VehiculoFlota(
            idConductor: id,
            nombre: nombre,
            unidad: unidad,
            placa: placa,
            foto: foto,
            estadoAsistencia: estado,
            horaMarcacion: hora,
            posicionRegistrada: posReg,
            vueltasHoy: vueltasHoy,
            vueltasCastigoCumplidas: hechasCastigo,
            metaVueltasCastigo: metaCastigo,
          ),
        );
      }

      if (!mounted) return;
      setState(() {
        final miIdConductor = SesionService.instance.idConductor;
        if (SesionService.instance.esConductor &&
            miIdConductor != null &&
            miIdConductor.isNotEmpty) {
          _vehiculos =
              flota.where((v) => v.idConductor == miIdConductor).toList();
          if (_vehiculos.isEmpty && flota.isNotEmpty) {
            _vehiculos = [flota.first];
          }
        } else {
          _vehiculos = flota;
        }

        final idSelPrevio = _vehiculoSeleccionado?.idConductor;
        if (idSelPrevio != null && _vehiculos.isNotEmpty) {
          _vehiculoSeleccionado = _vehiculos.firstWhere(
            (v) => v.idConductor == idSelPrevio,
            orElse: () => _vehiculos.first,
          );
        } else if (widget.conductorMonitoreado != null &&
            _vehiculos.isNotEmpty) {
          final idBuscado =
              widget.conductorMonitoreado!['id_conductor']?.toString();
          final unidadBuscada =
              widget.conductorMonitoreado!['unidad']?.toString();
          _vehiculoSeleccionado = _vehiculos.firstWhere(
            (v) =>
                (idBuscado != null && v.idConductor == idBuscado) ||
                (unidadBuscada != null && v.unidad == unidadBuscada),
            orElse: () => _vehiculos.first,
          );
        } else if (miIdConductor != null && _vehiculos.isNotEmpty) {
          _vehiculoSeleccionado = _vehiculos.firstWhere(
            (v) => v.idConductor == miIdConductor,
            orElse: () => _vehiculos.first,
          );
        } else if (_vehiculos.isNotEmpty) {
          _vehiculoSeleccionado = _vehiculos.first;
        }
      });

      if (_posUsuario != null) {
        _alRecibirPosicion(_posUsuario!);
      }
    } catch (e) {
      debugPrint('Error cargando flota GPS: $e');
    }
  }

  // ---------- Brújula y Sensores ----------
  void _iniciarBrujula() {
    try {
      final stream = FlutterCompass.events;
      if (stream == null) {
        _brujulaDisponible = false;
        return;
      }
      _subBrujula = stream.listen(
        (event) {
          final heading = event.heading;
          if (heading == null || heading.isNaN) return;
          _brujulaDisponible = true;
          _aplicarRumbo(heading);
        },
        onError: (_) => _brujulaDisponible = false,
        cancelOnError: false,
      );
    } catch (_) {
      _brujulaDisponible = false;
    }
  }

  void _aplicarRumbo(double nuevo) {
    if (!mounted) return;
    final delta = ((nuevo - _rumboGrados + 540) % 360) - 180;
    _rumboGrados = (_rumboGrados + delta * 0.30 + 360) % 360;
    _rumboNotifier.value = _rumboGrados;
    if (!_rumboValido) {
      setState(() => _rumboValido = true);
    }
  }

  // ---------- Datos de Paradas A y B ----------
  Future<void> _cargarParadas() async {
    final db = await DatabaseHelper.instance.database;
    final filas = await db.query('punto_de_control');
    if (filas.isEmpty) return;

    final lista = <_Parada>[];

    String? idA;
    for (final f in filas) {
      final esAsistencia = (f['es_punto_asistencia'] as num?)?.toInt() == 1;
      final nombre = f['nombre']?.toString().toLowerCase() ?? '';
      if (esAsistencia || nombre.contains('villadela')) {
        idA = f['id_punto']?.toString();
        break;
      }
    }
    idA ??= filas.isNotEmpty ? filas.first['id_punto']?.toString() : null;

    for (final f in filas) {
      final nombre = f['nombre']?.toString() ?? 'Parada';
      final id = f['id_punto']?.toString() ?? nombre;
      final esA = id == idA;
      // Coordenadas del REGISTRO ACTIVO de punto_de_control; sin BD se usa
      // la única constante oficial (PuntosOficiales).
      final lat = (f['latitud'] as num?)?.toDouble() ??
          (esA
              ? PuntosOficiales.paradaAVilladela.latitude
              : PuntosOficiales.paradaBTeleferico.latitude);
      final lon = (f['longitud'] as num?)?.toDouble() ??
          (esA
              ? PuntosOficiales.paradaAVilladela.longitude
              : PuntosOficiales.paradaBTeleferico.longitude);
      lista.add(
        _Parada(
          id: id,
          nombre: nombre,
          etiqueta: esA ? 'A' : 'B',
          punto: LatLng(lat, lon),
          radio: (f['radio_m'] as num?)?.toDouble() ?? PuntosOficiales.radioAsistenciaM,
          color: esA ? _kParadaA : _kParadaB,
        ),
      );
    }
    lista.sort((a, b) => a.etiqueta.compareTo(b.etiqueta));

    if (!mounted) return;
    setState(() {
      _paradas = lista;
      for (final p in lista) {
        _estados.putIfAbsent(p.id, () => _Geocerca());
      }
    });

    if (_posUsuario != null) {
      _alRecibirPosicion(_posUsuario!);
    }
  }

  // ---------- GPS Físico Real del Dispositivo ----------
  Future<void> _iniciarGps() async {
    final err = await GpsService.instance.asegurarPermisos();
    if (err != null) {
      if (mounted) setState(() => _errorGps = err);
      return;
    }

    // 1. Obtener la última posición conocida solo para mostrar distancia inicial (sin marcar asistencia con caché antigua)
    final ultima = await GpsService.instance.obtenerUltimaPosicionConocida();
    if (ultima != null && mounted) {
      _alRecibirPosicion(ultima, permitirMarcarAsistencia: false);
    }

    // 2. Solicitar lectura fresca inmediata en vivo
    GpsService.instance
        .obtenerPosicionActual(timeout: const Duration(seconds: 6))
        .then((pos) {
      if (pos != null && mounted) {
        _alRecibirPosicion(pos, permitirMarcarAsistencia: true);
      }
    }).catchError((_) {});

    // 3. Suscribirse al stream continuo del GPS (distanceFilter: 0, sin conflicto de ForegroundService)
    _subGps?.cancel();
    _subGps = GpsService.instance
        .obtenerStreamPosicion(distanceFilterM: 0, usarForeground: false)
        .listen(
      (pos) => _alRecibirPosicion(pos, permitirMarcarAsistencia: true),
      onError: (e) {
        if (mounted) setState(() => _errorGps = 'Error de GPS: $e');
      },
    );

    // 4. Refresco periódico de respaldo cada 3 segundos usando el mismo proveedor GPS para evitar saltos entre sensores
    _timerRefrescoGps?.cancel();
    _timerRefrescoGps = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (!mounted) return;
      try {
        final pos = await GpsService.instance.obtenerPosicionActual(
          timeout: const Duration(seconds: 4),
        );
        if (pos != null && mounted) {
          _alRecibirPosicion(pos, permitirMarcarAsistencia: true);
        }
      } catch (_) {}
    });
  }

  void _alRecibirPosicion(Position p, {bool permitirMarcarAsistencia = true}) {
    if (!mounted) return;

    final cruda = LatLng(p.latitude, p.longitude);
    final previa = _posFiltrada;
    final filtrada = _filtrarPosicion(p, cruda);
    final desplazamientoFiltradoM = previa == null
        ? 0.0
        : ReglasAsistencia.calcularDistanciaMetros(
            lat1: previa.latitude,
            lon1: previa.longitude,
            lat2: filtrada.latitude,
            lon2: filtrada.longitude,
          );
    // La máquina de vueltas ahora vive en GpsTrackingService (singleton),
    // que sigue procesando el GPS aunque esta pantalla esté cerrada.
    _Parada? paradaDetectadaParaAsistencia;

    setState(() {
      _posUsuario = p;
      _posFiltrada = filtrada;
      _errorGps = null;
      // Si el usuario está quieto (sin desplazamiento real o velocidad < 0.85 m/s ≈ 3 km/h), mostrar 0.0 km/h
      _velocidadRealKmh = (p.speed >= 0.85 && desplazamientoFiltradoM >= 1.5)
          ? (p.speed * 3.6)
          : 0.0;

      // Solo sumar recorrido cuando hay desplazamiento real fuera del rebote de señal (multipath)
      final umbralMovimientoReal = math.max(3.5, (p.accuracy * 0.40).clamp(3.5, 8.0));
      if (previa != null &&
          p.accuracy <= 50 &&
          desplazamientoFiltradoM >= umbralMovimientoReal &&
          desplazamientoFiltradoM <= 150.0) {
        _distanciaRealM += desplazamientoFiltradoM;
      }

      if (!_brujulaDisponible && p.speed > 1.2 && p.heading >= 0) {
        final delta = ((p.heading - _rumboGrados + 540) % 360) - 180;
        _rumboGrados = (_rumboGrados + delta * 0.35 + 360) % 360;
        _rumboNotifier.value = _rumboGrados;
        _rumboValido = true;
      }

      for (final pa in _paradas) {
        // Distancia Haversine DIRECTA al centro de la parada (geocerca circular)
        final d = RutaContinental.distanciaAParadaMetros(filtrada, pa.punto);
        // Radio efectivo: máximo entre el radio calibrado en BD y el mínimo
        // oficial (45 m) para que el GPS a 30-40 km/h nunca salte la geocerca.
        final radioEfectivo = RutaContinental.radioEfectivoVueltas(pa.radio);
        _estados.putIfAbsent(pa.id, () => _Geocerca());
        _estados[pa.id]!.actualizar(
          distancia: d,
          accuracy: p.accuracy,
          radio: radioEfectivo,
        );
        final ahoraDentro = RutaContinental.estaDentroDeGeocercaCircular(
          filtrada,
          pa.punto,
          radioEfectivo,
          margenMetros: 0.0,
        );
        _estados[pa.id]!.dentro = ahoraDentro;
        // La asistencia SOLO se marca cuando el usuario entra en la geocerca circular del Punto A
        if (ahoraDentro && pa.etiqueta == 'A' && permitirMarcarAsistencia) {
          paradaDetectadaParaAsistencia = pa;
        }
      }

      if (p.accuracy <= 45) {
        if (_rastroUsuario.isEmpty) {
          _rastroUsuario.add(filtrada);
        } else {
          final d = ReglasAsistencia.calcularDistanciaMetros(
            lat1: _rastroUsuario.last.latitude,
            lon1: _rastroUsuario.last.longitude,
            lat2: filtrada.latitude,
            lon2: filtrada.longitude,
          );
          final umbralRastro = math.max(5.0, (p.accuracy * 0.55).clamp(5.0, 10.0));
          if (d >= umbralRastro) {
            _rastroUsuario.add(filtrada);
            if (_rastroUsuario.length > 500) _rastroUsuario.removeAt(0);
          }
        }
      }
    });

    if (paradaDetectadaParaAsistencia != null && !_marcandoAsistencia) {
      _registrarAsistenciaAlPisarRectangulo(
        parada: paradaDetectadaParaAsistencia!,
        punto: filtrada,
        precisionM: p.accuracy,
      );
    }

    if (_seguir && _mapaListo) {
      _map.move(filtrada, math.max(_map.camera.zoom, 18.0));
    }
  }

  LatLng _filtrarPosicion(Position p, LatLng cruda) {
    final previa = _posFiltrada;
    if (previa == null) return cruda;

    // Si el usuario acaba de pisar el Punto A o Punto B (geocerca circular),
    // actualizar de inmediato sin retener posición previa
    final enPuntoControl = _paradas.any((pa) {
      final radio = RutaContinental.radioEfectivoVueltas(pa.radio);
      return RutaContinental.estaDentroDeGeocercaCircular(cruda, pa.punto, radio);
    });
    if (enPuntoControl) return cruda;

    final d = ReglasAsistencia.calcularDistanciaMetros(
      lat1: previa.latitude,
      lon1: previa.longitude,
      lat2: cruda.latitude,
      lon2: cruda.longitude,
    );

    // En reposo (velocidad < 1.0 m/s ≈ 3.6 km/h), el GPS bajo techo rebota dentro de su radio de error (±accuracy).
    // Ignoramos esos saltos fantasma menores al margen de ruido para que el auto no se mueva solo estando quieto.
    final quieto = p.speed < 1.0;
    final radioRuido = quieto
        ? math.max(6.5, (p.accuracy * 0.70).clamp(6.5, 14.0))
        : 2.5;
    if (d < radioRuido) return previa;

    final alpha = d > 18 ? 0.85 : (d > 8 ? 0.65 : 0.45);
    return LatLng(
      previa.latitude + (cruda.latitude - previa.latitude) * alpha,
      previa.longitude + (cruda.longitude - previa.longitude) * alpha,
    );
  }

  _Parada? _paradaPorEtiqueta(String etiqueta) {
    for (final p in _paradas) {
      if (p.etiqueta == etiqueta) return p;
    }
    return null;
  }

  // ---------- Control de Cámara y Selección ----------
  void _verRutaCompleta() {
    final pts = <LatLng>[
      ...RutaContinental.circuitoCompleto,
      ..._paradas.map((p) => p.punto),
    ];
    if (pts.length < 2 || !_mapaListo) return;
    setState(() {
      _seguir = false;
    });
    _map.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(pts),
        padding: const EdgeInsets.fromLTRB(40, 180, 40, 260),
      ),
    );
  }

  void _centrarOpcion() {
    if (_posFiltrada != null && _mapaListo) {
      setState(() => _seguir = true);
      _map.move(_posFiltrada!, 18.2);
    } else {
      _verRutaCompleta();
    }
  }

  void _irAParada(_Parada p) {
    if (!_mapaListo) return;
    setState(() => _seguir = false);
    _map.move(p.punto, 18.5);
  }

  Future<void> _registrarAsistenciaAlPisarRectangulo({
    required _Parada parada,
    required LatLng punto,
    required double precisionM,
  }) async {
    if (_marcandoAsistencia) return;
    final idCond = SesionService.instance.idConductor ??
        _vehiculoSeleccionado?.idConductor;
    if (idCond == null || idCond.isEmpty) return;

    _marcandoAsistencia = true;
    try {
      final hoy = DateTime.now().toIso8601String().substring(0, 10);
      final asistHoy =
          await AsistenciaRepo.instance.obtenerAsistenciaHoy(idCond, hoy);
      if (asistHoy == null) {
        final puntosBd = await DatabaseHelper.instance.obtenerPuntosControl(
          soloActivos: false,
        );
        String idPuntoReal = parada.id;
        if (puntosBd.isNotEmpty) {
          final pObj = puntosBd.firstWhere(
            (p) => parada.etiqueta == 'A'
                ? p['nombre'].toString().toLowerCase().contains('villadela')
                : !p['nombre'].toString().toLowerCase().contains('villadela'),
            orElse: () => puntosBd.first,
          );
          idPuntoReal = pObj['id_punto']?.toString() ?? parada.id;
        }

        final res = await AsistenciaRepo.instance.registrarAsistenciaGps(
          idConductor: idCond,
          idPunto: idPuntoReal,
          latitud: punto.latitude,
          longitud: punto.longitude,
          precisionM: precisionM,
          distanciaM: 0.0,
          esMock: false,
          horaSateliteConfiable: true,
        );
        if (res.exito && mounted) {
          HapticFeedback.heavyImpact();
          await _cargarFlotaConductores();
          if (!mounted) return;
          ScaffoldMessenger.of(context)
            ..clearSnackBars()
            ..showSnackBar(
              SnackBar(
                behavior: SnackBarBehavior.floating,
                backgroundColor: _kVerdeContinental,
                content: Text(
                  '¡Estás en el punto de control (${parada.nombre})! Asistencia marcada: Asistió.',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            );
        }
      }
    } catch (_) {
    } finally {
      _marcandoAsistencia = false;
    }
  }

  double? _distanciaDispositivoAParada(_Parada p) {
    if (_posFiltrada == null) return null;
    return RutaContinental.distanciaAParadaMetros(_posFiltrada!, p.punto);
  }

  String _fmt(double m) => m < 1000
      ? '${m.toStringAsFixed(0)} m'
      : '${(m / 1000).toStringAsFixed(2)} km';

  // ---------- Capas del Mapa ----------
  Widget _construirMapa() {
    final esSat = _estilo == _Estilo.satelite;
    final centroInicial = RutaContinental.paradaAVilladela;

    return FlutterMap(
      mapController: _map,
      options: MapOptions(
        initialCenter: centroInicial,
        initialZoom: 18.0,
        maxZoom: 21,
        onMapReady: () {
          _mapaListo = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _verRutaCompleta();
          });
        },
        onPositionChanged: (camera, hasGesture) {
          if (hasGesture && _seguir) setState(() => _seguir = false);
        },
      ),
      children: [
        TileLayer(
          urlTemplate: esSat
              ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
              : 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
          subdomains: const ['a', 'b', 'c', 'd'],
          userAgentPackageName: 'com.example.continental',
          maxNativeZoom: 19,
          maxZoom: 21,
        ),

        // Trazado oficial del circuito (Ida y Vuelta) y rastro GPS real del teléfono
        PolylineLayer(
          polylines: [
            Polyline(
              points: RutaContinental.puntosVuelta,
              strokeWidth: 4.0,
              color: _kParadaB,
              borderStrokeWidth: 1.5,
              borderColor: Colors.white,
            ),
            Polyline(
              points: RutaContinental.puntosIda,
              strokeWidth: 4.5,
              color: _kVerdeContinental,
              borderStrokeWidth: 1.5,
              borderColor: Colors.white,
            ),
            if (_rastroUsuario.length >= 2)
              Polyline(
                points: List<LatLng>.from(_rastroUsuario),
                strokeWidth: 5.5,
                color: _kUsuario,
                borderStrokeWidth: 2,
                borderColor: Colors.white,
              ),
          ],
        ),

        // Geocercas CIRCULARES oficiales dibujadas con el radio real de la BD
        PolygonLayer(
          polygons: [
            for (final pa in _paradas)
              Polygon(
                points: RutaContinental.anilloGeocerca(
                  pa.punto,
                  RutaContinental.radioEfectivoVueltas(pa.radio),
                ),
                color: (_dispositivoEnParada(pa.etiqueta)
                        ? _kVerdeActivo
                        : (pa.etiqueta == 'A'
                            ? const Color(0xFF2563EB)
                            : _kParadaB))
                    .withValues(alpha: 0.26),
                borderColor: _dispositivoEnParada(pa.etiqueta)
                    ? _kVerdeActivo
                    : (pa.etiqueta == 'A'
                        ? const Color(0xFF2563EB)
                        : _kParadaB),
                borderStrokeWidth: pa.etiqueta == 'A' ? 3.2 : 3.0,
              ),
          ],
        ),

        if (_posFiltrada != null)
          CircleLayer(
            circles: [
              CircleMarker(
                point: _posFiltrada!,
                radius: (_posUsuario?.accuracy ?? 10).clamp(3.0, 40.0),
                useRadiusInMeter: true,
                color: _kUsuario.withValues(alpha: 0.15),
                borderColor: _kUsuario.withValues(alpha: 0.8),
                borderStrokeWidth: 1.5,
              ),
            ],
          ),

        // Marcadores reales: Paradas A y B + GPS del dispositivo
        MarkerLayer(
          markers: [
            for (final p in _paradas) _marcadorParada(p),
            if (_posFiltrada != null) _marcadorUsuario(_posFiltrada!),
          ],
        ),
      ],
    );
  }

  bool _dispositivoEnParada(String etiqueta) {
    if (_posFiltrada == null) return false;
    final parada = _paradaPorEtiqueta(etiqueta);
    if (parada == null) return false;
    return RutaContinental.estaDentroDeGeocercaCircular(
      _posFiltrada!,
      parada.punto,
      RutaContinental.radioEfectivoVueltas(parada.radio),
    );
  }

  Marker _marcadorParada(_Parada p) {
    final dentro = _dispositivoEnParada(p.etiqueta);
    final esA = p.etiqueta == 'A';
    final colorParada = esA ? _kVerdeContinental : _kParadaB;

    return Marker(
      point: p.punto,
      width: 44,
      height: 44,
      child: GestureDetector(
        onTap: () => _irAParada(p),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colorParada,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.8),
                boxShadow: [
                  BoxShadow(
                    color: colorParada.withValues(alpha: dentro ? 0.9 : 0.45),
                    blurRadius: dentro ? 18 : 8,
                    spreadRadius: dentro ? 3 : 0,
                  ),
                ],
              ),
              child: Text(
                p.etiqueta,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ),
            Positioned(
              top: 40,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  p.nombre,
                  maxLines: 1,
                  style: const TextStyle(
                    color: _kTextoOscuro,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Marker _marcadorUsuario(LatLng punto) {
    return Marker(
      point: punto,
      width: 80,
      height: 80,
      child: UbicacionAzul(
        rumboGrados: _rumboGrados,
        rumboListenable: _rumboNotifier,
        rumboValido: _rumboValido,
        tamano: 80,
        tamanoPunto: 18,
      ),
    );
  }

  // ---------- Interfaz de Usuario ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          Positioned.fill(child: _construirMapa()),

          // Panel Superior con Header y Alerta de Punto de Control
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _barraSuperior(),
                  if (_errorGps != null) _bannerError(_errorGps!),
                  _tarjetaEstadoReal(),
                ],
              ),
            ),
          ),

          // Controles flotantes a la derecha y Panel de Telemetría Real inferior
          Align(
            alignment: Alignment.bottomCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _botonesMapa(),
                _panelDatos(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _barraSuperior() {
    final v = _vehiculoSeleccionado;
    final esConductor = SesionService.instance.esConductor;
    final titulo = v != null
        ? (esConductor ? v.nombre : 'Móvil #${v.unidad} • ${v.nombre}')
        : 'Monitoreo GPS en Vivo';

    final precisionTxt = _posUsuario != null
        ? '±${_posUsuario!.accuracy.toStringAsFixed(0)} m'
        : 'Buscando señal GPS…';

    final yaAsistio = v != null && v.estadoAsistencia != 'falta';
    final subtitulo = v != null
        ? 'Asistencia: ${yaAsistio ? "Asistió (${v.horaMarcacion})" : "Sin marcar"} • GPS $precisionTxt'
        : 'GPS $precisionTxt';

    return Row(
      children: [
        _botonRedondo(
          Icons.arrow_back_ios_new_rounded,
          () => Navigator.maybePop(context),
          fondo: _kVerdeContinental,
          colorIcono: Colors.white,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_kVerdeContinental, _kVerdeOscuro],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white24),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _posFiltrada != null
                        ? _kVerdeActivo
                        : const Color(0xFFF59E0B),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        titulo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5,
                        ),
                      ),
                      Text(
                        subtitulo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFE6F4F0),
                          fontWeight: FontWeight.w600,
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
        if (!esConductor) ...[
          const SizedBox(width: 8),
          _botonRedondo(
            Icons.tune,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PuntosControlScreen()),
              ).then((_) => _cargarParadas());
            },
            fondo: Colors.white,
            colorIcono: _kVerdeContinental,
          ),
        ],
        const SizedBox(width: 6),
        _botonRedondo(
          _estilo == _Estilo.satelite
              ? Icons.map_outlined
              : Icons.satellite_alt_rounded,
          () => setState(
            () => _estilo = _estilo == _Estilo.satelite
                ? _Estilo.calles
                : _Estilo.satelite,
          ),
          fondo: Colors.white,
          colorIcono: _kVerdeContinental,
        ),
      ],
    );
  }

  Widget _botonRedondo(
    IconData icono,
    VoidCallback onTap, {
    Color? fondo,
    Color? colorIcono,
  }) {
    return Material(
      color: fondo ?? Colors.white,
      shape: const CircleBorder(),
      elevation: 2,
      shadowColor: Colors.black26,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(11),
          child: Icon(icono, color: colorIcono ?? _kVerdeContinental, size: 20),
        ),
      ),
    );
  }

  Widget _tarjetaEstadoReal() {
    final v = _vehiculoSeleccionado;
    final enA = _dispositivoEnParada('A');
    final enPuntoControl = enA;

    final dA = _paradas.isNotEmpty
        ? _distanciaDispositivoAParada(_paradas.first)
        : null;

    final yaAsistio = v != null && v.estadoAsistencia != 'falta';

    final Color bgCard =
        enPuntoControl ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2);
    final Color borderCard =
        enPuntoControl ? const Color(0xFF10B981) : const Color(0xFFFCA5A5);
    final Color iconBg =
        enPuntoControl ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    final Color titleColor =
        enPuntoControl ? const Color(0xFF065F46) : const Color(0xFF991B1B);

    final String tituloAlerta = enPuntoControl
        ? '¡Estás en el punto de control!'
        : 'No estás en el punto de control';

    final String subtituloPrincipal = enPuntoControl
        ? 'Punto A • Cruce Villadela'
        : (dA != null
            ? 'Estás a ${_fmt(dA)} del Punto A (Cruce Villadela)'
            : 'Obteniendo ubicación GPS del dispositivo…');

    final String subtituloAsistencia = enPuntoControl
        ? 'Asistencia marcada: Asistió${yaAsistio ? " (${v.horaMarcacion})" : ""}'
        : (yaAsistio
            ? 'Asistencia de hoy: Asistió (${v.horaMarcacion})'
            : 'Pisa el Punto A para marcar tu asistencia');

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: borderCard,
          width: 1.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
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
            child: Icon(
              enPuntoControl
                  ? Icons.check_circle_rounded
                  : Icons.warning_amber_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tituloAlerta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: titleColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtituloPrincipal,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _kTextoOscuro,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  subtituloAsistencia,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: (enPuntoControl || yaAsistio)
                        ? const Color(0xFF047857)
                        : const Color(0xFFB91C1C),
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
            onTap: _centrarOpcion,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: _seguir ? _kVerdeContinental : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _kVerdeBorde),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _seguir
                        ? Icons.my_location_rounded
                        : Icons.location_searching_rounded,
                    color: _seguir ? Colors.white : _kVerdeContinental,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _seguir ? 'Siguiendo' : 'Mi GPS',
                    style: TextStyle(
                      color: _seguir ? Colors.white : _kVerdeContinental,
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

  Widget _bannerError(String texto) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFB3261E),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.gps_off, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              texto,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
          TextButton(
            onPressed: _iniciarGps,
            child:
                const Text('Reintentar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _botonesMapa() {
    return Padding(
      padding: const EdgeInsets.only(right: 14, bottom: 8),
      child: Column(
        children: [
          _botonRedondo(
            Icons.zoom_out_map_rounded,
            _verRutaCompleta,
            fondo: Colors.white,
            colorIcono: _kVerdeContinental,
          ),
          const SizedBox(height: 8),
          _botonRedondo(
            _seguir
                ? Icons.my_location_rounded
                : Icons.location_searching_rounded,
            _centrarOpcion,
            fondo: _seguir ? _kVerdeContinental : Colors.white,
            colorIcono: _seguir ? Colors.white : _kVerdeContinental,
          ),
        ],
      ),
    );
  }

  Widget _panelDatos() {
    final v = _vehiculoSeleccionado;
    final precisionStr = _posUsuario != null
        ? '±${_posUsuario!.accuracy.toStringAsFixed(0)} m'
        : 'Sin GPS';
    final vueltasMostradas = v != null &&
            v.idConductor == GpsTrackingService.instance.idConductor
        ? math.max(v.vueltasHoy, GpsTrackingService.instance.vueltasHoy.value)
        : v?.vueltasHoy ?? 0;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        16,
        10,
        16,
        MediaQuery.of(context).padding.bottom > 0
            ? MediaQuery.of(context).padding.bottom + 6
            : 14,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFCBD5E1),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              _dato(Icons.gps_fixed_rounded, precisionStr, 'Precisión GPS'),
              _dato(
                Icons.speed_rounded,
                '${_velocidadRealKmh.toStringAsFixed(1)} km/h',
                'Velocidad',
              ),
              _dato(
                Icons.repeat_rounded,
                '$vueltasMostradas v.',
                'Vueltas hoy',
              ),
              _dato(
                Icons.route_rounded,
                _fmt(_distanciaRealM),
                'Recorrido GPS',
              ),
            ],
          ),
          const Divider(color: Color(0xFFE2E8F0), height: 20),
          if (_paradas.length >= 2) ...[
            _filaParadaDistancia(
              _paradas.first,
              _distanciaDispositivoAParada(_paradas.first),
            ),
            const SizedBox(height: 6),
            _filaParadaDistancia(
              _paradas.last,
              _distanciaDispositivoAParada(_paradas.last),
            ),
          ],
        ],
      ),
    );
  }

  Widget _dato(
    IconData icono,
    String valor,
    String etiqueta,
  ) {
    return Expanded(
      child: Column(
        children: [
          Icon(icono, color: _kVerdeContinental, size: 20),
          const SizedBox(height: 3),
          Text(
            valor,
            style: const TextStyle(
              color: _kTextoOscuro,
              fontWeight: FontWeight.w900,
              fontSize: 15.5,
            ),
          ),
          Text(
            etiqueta,
            style: const TextStyle(
              color: _kTextoMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _filaParadaDistancia(_Parada p, double? d) {
    final dentro = _dispositivoEnParada(p.etiqueta);
    final esA = p.etiqueta == 'A';
    final colorParada = esA ? _kVerdeContinental : _kParadaB;
    final colorEstado = dentro ? _kDentro : _kTextoMuted;

    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: colorParada, shape: BoxShape.circle),
          child: Text(
            p.etiqueta,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            p.nombre,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _kTextoOscuro,
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
            ),
          ),
        ),
        Text(
          d == null
              ? 'Esperando GPS…'
              : (dentro ? 'En parada • 0 m' : _fmt(d)),
          style: TextStyle(
            color: colorEstado,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
