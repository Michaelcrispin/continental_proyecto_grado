import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../domain/puntos_oficiales.dart';
import '../domain/reglas_asistencia.dart';
import '../domain/ruta_continental.dart';
import 'asistencia_repo.dart';
import 'database_helper.dart';
import 'gps_service.dart';

/// Estado del circuito de vueltas A → B → A.
enum EstadoCircuito {
  /// Aún no se pisa ninguna parada (o cambió el día).
  sinTramo,

  /// Se pisó Parada A; se espera que el conductor pase por Parada B.
  esperandoRetornoB,

  /// Ya pasó por Parada B; se espera que regrese a Parada A para COMPLETAR la vuelta.
  completandoA,
}

extension EstadoCircuitoX on EstadoCircuito {
  /// Nombre estable para guardar en la tabla `configuracion`.
  String get clave {
    switch (this) {
      case EstadoCircuito.esperandoRetornoB:
        return 'esperando_retorno_B';
      case EstadoCircuito.completandoA:
        return 'completando_A';
      case EstadoCircuito.sinTramo:
        return '';
    }
  }

  static EstadoCircuito desdeClave(String? valor) {
    switch (valor) {
      case 'esperando_retorno_B':
        return EstadoCircuito.esperandoRetornoB;
      case 'completando_A':
        return EstadoCircuito.completandoA;
      default:
        return EstadoCircuito.sinTramo;
    }
  }

  String get descripcion {
    switch (this) {
      case EstadoCircuito.sinTramo:
        return 'Pisa Parada A para arrancar el circuito';
      case EstadoCircuito.esperandoRetornoB:
        return 'Rumbo a Parada B (Teleférico)';
      case EstadoCircuito.completandoA:
        return 'Parada B pisada • Regresa a Parada A para completar la vuelta';
    }
  }
}

/// Estado persistente completo del circuito.
class EstadoCircuitoPersistente {
  final EstadoCircuito estado;
  final String fecha; // yyyy-MM-dd
  final String? idConductor;

  const EstadoCircuitoPersistente({
    required this.estado,
    required this.fecha,
    this.idConductor,
  });
}

/// Contrato de persistencia del estado del circuito (SQLite en producción).
abstract class EstadoCircuitoRepositorio {
  Future<EstadoCircuitoPersistente?> cargar();
  Future<void> guardar(EstadoCircuitoPersistente estado);
}

/// Implementación real sobre la tabla `configuracion` de SQLite.
class EstadoCircuitoRepositorioSqlite implements EstadoCircuitoRepositorio {
  const EstadoCircuitoRepositorioSqlite();

  static const _kEstado = 'estado_circuito';
  static const _kFecha = 'estado_circuito_fecha';
  static const _kConductor = 'estado_circuito_conductor';

  @override
  Future<EstadoCircuitoPersistente?> cargar() async {
    final estado =
        await DatabaseHelper.instance.getConfig(_kEstado, '');
    if (EstadoCircuitoX.desdeClave(estado) == EstadoCircuito.sinTramo) {
      return null;
    }
    final fecha = await DatabaseHelper.instance.getConfig(_kFecha, '') ?? '';
    final conductor = await DatabaseHelper.instance.getConfig(_kConductor, '');
    if (fecha.isEmpty) return null;
    return EstadoCircuitoPersistente(
      estado: EstadoCircuitoX.desdeClave(estado),
      fecha: fecha,
      idConductor: conductor?.isEmpty == true ? null : conductor,
    );
  }

  @override
  Future<void> guardar(EstadoCircuitoPersistente estado) async {
    await DatabaseHelper.instance.setConfig(
      _kEstado,
      estado.estado.clave,
      'Máquina de estados del circuito A→B→A',
    );
    await DatabaseHelper.instance.setConfig(
      _kFecha,
      estado.fecha,
      'Fecha del estado del circuito',
    );
    await DatabaseHelper.instance.setConfig(
      _kConductor,
      estado.idConductor ?? '',
      'Conductor dueño del estado del circuito',
    );
  }
}

/// Evento emitido por el servicio para que las pantallas activas muestren
/// avisos (snackbar / haptic) sin ownership del estado.
class EventoCircuito {
  final String tipo; // 'paso_A' | 'paso_B' | 'vuelta_completada' | 'asistencia'
  final String mensaje;
  final DateTime fecha;

  const EventoCircuito({required this.tipo, required this.mensaje, required this.fecha});
}

/// SERVICIO SINGLETON de conteo automático de vueltas A → B → A.
///
/// VIVE FUERA DE LA UI (no en el State de una pantalla):
///  - Procesa el stream de GPS con su propio ciclo de vida (aunque cambie de
///    pantalla, se bloqueen el teléfono o la app pase a segundo plano).
///  - Usa geocercas CIRCULARES por radio Haversine (mínimo 30-50 m).
///  - PERSISTE el estado del tramo en SQLite (`estado_circuito`), así que al
///    cerrar/reabrir la app retoma el circuito donde quedó.
///  - En Android activa el ForegroundService de geolocator
///    (ForegroundNotificationConfig) para que el GPS siga escuchando con la
///    pantalla apagada (el teléfono está en el bolsillo / tablero).
class GpsTrackingService {
  GpsTrackingService._internal();

  static final GpsTrackingService instance = GpsTrackingService._internal();

  static String _hoy() => DateTime.now().toIso8601String().substring(0, 10);

  // --- Estado observable para las pantallas ---
  final ValueNotifier<EstadoCircuito> estadoCircuito =
      ValueNotifier<EstadoCircuito>(EstadoCircuito.sinTramo);
  final ValueNotifier<int> vueltasHoy = ValueNotifier<int>(0);
  final ValueNotifier<Position?> ultimaPosicion = ValueNotifier<Position?>(null);
  final ValueNotifier<bool> activo = ValueNotifier<bool>(false);

  final StreamController<EventoCircuito> _eventos =
      StreamController<EventoCircuito>.broadcast();
  Stream<EventoCircuito> get eventos => _eventos.stream;

  // --- Estado interno de la máquina ---
  EstadoCircuitoPersistente? _estadoPersistente;
  String? _idConductor;
  StreamSubscription<Position>? _subGps;
  Timer? _timerReintento;
  double _radioVueltasM = PuntosOficiales.radioMinimoVueltasM;

  bool _salioDeA = true; // exigir "haber salido" antes de contar un nuevo pisado
  bool _salioDeB = true;
  bool _procesando = false;


  EstadoCircuitoRepositorio repositorio = const EstadoCircuitoRepositorioSqlite();

  /// Inyectable para pruebas unitarias (en producción usa DatabaseHelper).
  Future<void> Function(String idConductor)? alCompletarVueltaOverride;

  String? get idConductor => _idConductor;
  double get radioVueltasM => _radioVueltasM;

  /// REGLA de recapitulación (pura, probada con tests):
  ///  - Estado de HOY y del MISMO conductor → se retoma tal cual.
  ///  - Estado de otro día o de otro conductor → arranca limpio (sin tramo).
  @visibleForTesting
  static EstadoCircuitoPersistente decidirEstadoInicial(
    EstadoCircuitoPersistente? guardado,
    String? idConductor,
    String hoy,
  ) {
    final esMismoConductor =
        guardado?.idConductor == null || guardado?.idConductor == idConductor;
    if (guardado != null &&
        guardado.estado != EstadoCircuito.sinTramo &&
        esMismoConductor &&
        guardado.fecha == hoy) {
      return guardado;
    }
    return EstadoCircuitoPersistente(
      estado: EstadoCircuito.sinTramo,
      fecha: hoy,
      idConductor: idConductor,
    );
  }

  /// Define el conductor directo (solo para pruebas / simulador).
  @visibleForTesting
  set idConductorParaPruebas(String? value) => _idConductor = value;

  /// Reapaga toda la máquina (solo para pruebas: estado, contadores e histéresis).
  @visibleForTesting
  void reiniciarParaPruebas() {
    _estadoPersistente = null;
    _salioDeA = true;
    _salioDeB = true;
    vueltasHoy.value = 0;
    estadoCircuito.value = EstadoCircuito.sinTramo;
  }

  // -------------------------------------------------------------------------
  // CICLO DE VIDA
  // -------------------------------------------------------------------------

  /// Arranca el conteo automático para [idConductor] (o el primer conductor
  /// activo de la BD). Recupera de SQLite el estado del tramo pendiente.
  Future<void> iniciar({String? idConductor}) async {
    _idConductor = idConductor?.isNotEmpty == true
        ? idConductor
        : await _resolverConductor();
    if (_idConductor == null) return;

    // 1. Recuperar estado persistido (si el conductor coincide y es de HOY)
    try {
      final guardado = await repositorio.cargar();
      _estadoPersistente = decidirEstadoInicial(
        guardado,
        _idConductor,
        _hoy(),
      );
      if (guardado == null ||
          guardado.fecha != _hoy() ||
          guardado.idConductor != _idConductor) {
        await repositorio.guardar(_estadoPersistente!);
      }
    } catch (_) {
      _estadoPersistente = EstadoCircuitoPersistente(
        estado: EstadoCircuito.sinTramo,
        fecha: _hoy(),
        idConductor: _idConductor,
      );
    }
    _aplicarEstado(_estadoPersistente!.estado);

    // 2. Contador de vueltas reales de hoy desde SQLite
    vueltasHoy.value = await _contarVueltasHoy();

    // 3. Radio de geocerca circular (mínimo oficial 30-50 m)
    _radioVueltasM = await _cargarRadioVueltas();

    // 4. Escucha GPS continua con ForegroundService (pantalla apagada).
    // El bloque es a prueba de entornos sin plugin (tests puros de Dart).
    _timerReintento?.cancel();
    _subGps?.cancel();
    try {
      _subGps = GpsService.instance
          .obtenerStreamPosicion(distanceFilterM: 0, usarForeground: true)
          .listen(
        (pos) {
          ultimaPosicion.value = pos;
          _consumirPosicion(pos, esSimulacion: false);
        },
        onError: (_) {
          _timerReintento?.cancel();
          _timerReintento =
              Timer.periodic(const Duration(seconds: 30), (_) async {
            final ok = await GpsService.instance.verificarPermisos();
            if (ok && activo.value) {
              _timerReintento?.cancel();
              _rehidratarStream();
            }
          });
        },
        cancelOnError: false,
      );
    } catch (_) {
      _subGps = null;
    }

    activo.value = true;
  }

  void _rehidratarStream() {
    final id = _idConductor;
    final EstadoCircuito estado = estadoCircuito.value;
    iniciar(idConductor: id).then((_) {
      _aplicarEstado(estado);
    });
  }

  /// Detiene la escucha GPS (no borra el estado en SQLite).
  void detener() {
    _subGps?.cancel();
    _subGps = null;
    _timerReintento?.cancel();
    activo.value = false;
  }

  /// Vuelve a sincronizar el contador de vueltas desde SQLite.
  Future<void> refrescarVueltas() async {
    vueltasHoy.value = await _contarVueltasHoy();
  }

  // -------------------------------------------------------------------------
  // ENTRADA PRINCIPAL: cada posición cruda del GPS entra por aquí.
  // (Es idempotente: se puede llamar tanto desde el stream interno del
  //  servicio como desde simuladores.)
  // -------------------------------------------------------------------------
  Future<EventoCircuito?> procesarPosicion(LatLng punto,
      {double accuracy = 5.0, bool esSimulacion = false}) async {
    if (_procesando) return null;
    _procesando = true;
    try {
      final hoy = _hoy();
      if (_estadoPersistente?.fecha != hoy) {
        _estadoPersistente = EstadoCircuitoPersistente(
          estado: EstadoCircuito.sinTramo,
          fecha: hoy,
          idConductor: _idConductor,
        );
        _aplicarEstado(EstadoCircuito.sinTramo);
      }

      final dA = RutaContinental.distanciaAParadaMetros(
          punto, PuntosOficiales.paradaAVilladela);
      final dB = RutaContinental.distanciaAParadaMetros(
          punto, PuntosOficiales.paradaBTeleferico);

      final radio = _radioVueltasM;
      final enA = dA <= radio;
      final enB = dB <= radio;

      // Histeresis: para revolver "pisado" hay que haber SALIDO con margen
      // (1.5x radio). Así los rebotes del GPS jamás generan doble evento.
      if (_salioDeA == false && dA > radio * 1.5) _salioDeA = true;
      if (_salioDeB == false && dB > radio * 1.5) _salioDeB = true;

      final ahora = DateTime.now();

      EventoCircuito? evento;

      // --- PISÓ PARADA A ---
      if (enA && _salioDeA) {
        final estadoAnterior =
            _estadoPersistente?.estado ?? EstadoCircuito.sinTramo;
        _estadoPersistente = EstadoCircuitoPersistente(
          estado: EstadoCircuito.esperandoRetornoB,
          fecha: hoy,
          idConductor: _idConductor,
        );
        _aplicarEstado(EstadoCircuito.esperandoRetornoB);
        _salioDeA = false;

        if (estadoAnterior == EstadoCircuito.completandoA) {
          // A → B → A = VUELTA COMPLETA
          await _registrarVuelta();
          evento = EventoCircuito(
            tipo: 'vuelta_completada',
            mensaje:
                '¡Vuelta #${vueltasHoy.value} completada (A → B → A)!',
            fecha: ahora,
          );
          _emitir(evento);
        } else {
          // Primera pisada del día en Parada A: beneficia Asistencia por GPS
          // (idempotente: AsistenciaRepo descarta si ya existe).
          await _registrarAsistenciaEnPunto(punto);
          evento = EventoCircuito(
            tipo: 'paso_A',
            mensaje: 'Paso por Parada A (Cruce Villadela) registrado',
            fecha: ahora,
          );
          _emitir(evento);
        }
        await _persistir();
        return evento;
      }

      // --- PISÓ PARADA B ---
      if (enB && _salioDeB) {
        _estadoPersistente = EstadoCircuitoPersistente(
          estado: EstadoCircuito.completandoA,
          fecha: hoy,
          idConductor: _idConductor,
        );
        _aplicarEstado(EstadoCircuito.completandoA);
        _salioDeB = false;

        evento = EventoCircuito(
          tipo: 'paso_B',
          mensaje:
              'Paso por Parada B (Teleférico) registrado • Al volver a Parada A suma la vuelta',
          fecha: ahora,
        );
        _emitir(evento);
        await _persistir();
        return evento;
      }

      return null;
    } finally {
      _procesando = false;
    }
  }

  void _consumirPosicion(Position pos, {required bool esSimulacion}) =>
      procesarPosicion(
        LatLng(pos.latitude, pos.longitude),
        accuracy: pos.accuracy,
        esSimulacion: esSimulacion,
      );

  // -------------------------------------------------------------------------
  // PERSISTENCIA Y ACCIONES
  // -------------------------------------------------------------------------

  Future<void> _persistir() async {
    final e = _estadoPersistente;
    if (e == null) return;
    try {
      await repositorio.guardar(e);
    } catch (_) {}
  }

  Future<void> _registrarVuelta() async {
    final idCond = _idConductor;
    if (idCond == null || idCond.isEmpty) return;
    try {
      if (alCompletarVueltaOverride != null) {
        await alCompletarVueltaOverride!(idCond);
      } else {
        final data =
            await DatabaseHelper.instance.registrarVuelta(
          idConductor: idCond,
          tipo: 'normal',
        );
        debugPrint('Vuelta registrada por GPS (servicio): ${data['id_vuelta']}');
      }
      vueltasHoy.value = vueltasHoy.value + 1; // se reconcilia con BD al refrescar
    } catch (_) {}
  }

  Future<void> _registrarAsistenciaEnPunto(LatLng punto) async {
    final idCond = _idConductor;
    if (idCond == null || idCond.isEmpty) return;
    try {
      final puntoA = await DatabaseHelper.instance.obtenerPuntoAsistencia();
      final idPunto = puntoA?['id_punto']?.toString() ?? '';
      if (idPunto.isEmpty) return;
      await AsistenciaRepo.instance.registrarAsistenciaGps(
        idConductor: idCond,
        idPunto: idPunto,
        latitud: punto.latitude,
        longitud: punto.longitude,
        precisionM: 5.0,
        distanciaM: RutaContinental.distanciaAParadaMetros(
            punto, PuntosOficiales.paradaAVilladela),
      );
    } catch (_) {}
  }

  void _aplicarEstado(EstadoCircuito e) {
    estadoCircuito.value = e;
  }

  void _emitir(EventoCircuito e) {
    _eventos.add(e);
    // Vibración: interacción física con el chofer aunque la pantalla esté apagada.
    if (e.tipo == 'vuelta_completada') {
      HapticFeedback.heavyImpact();
    } else if (e.tipo != 'asistencia') {
      HapticFeedback.mediumImpact();
    }
  }

  Future<int> _contarVueltasHoy() async {
    final idCond = _idConductor;
    if (idCond == null || idCond.isEmpty) return 0;
    try {
      final vueltas =
          await DatabaseHelper.instance.vueltasDetalle(fecha: _hoy());
      return vueltas.where((v) => v['id_conductor'] == idCond).length;
    } catch (_) {
      return 0;
    }
  }

  Future<double> _cargarRadioVueltas() async {
    try {
      final puntos =
          await DatabaseHelper.instance.obtenerPuntosControl(soloActivos: true);
      double menor = double.infinity;
      for (final p in puntos) {
        final lat = (p['latitud'] as num?)?.toDouble();
        final lon = (p['longitud'] as num?)?.toDouble();
        final radio = (p['radio_m'] as num?)?.toDouble();
        if (lat == null || lon == null || radio == null) continue;
        final esA = ReglasAsistencia.calcularDistanciaMetros(
              lat1: lat,
              lon1: lon,
              lat2: PuntosOficiales.paradaAVilladela.latitude,
              lon2: PuntosOficiales.paradaAVilladela.longitude,
            ) <
            100;
        final esB = ReglasAsistencia.calcularDistanciaMetros(
              lat1: lat,
              lon1: lon,
              lat2: PuntosOficiales.paradaBTeleferico.latitude,
              lon2: PuntosOficiales.paradaBTeleferico.longitude,
            ) <
            100;
        if (esA || esB) {
          if (radio < menor) menor = radio;
        }
      }
      if (menor.isInfinite) {
        return PuntosOficiales.radioMinimoVueltasM;
      }
      return RutaContinental.radioEfectivoVueltas(menor);
    } catch (_) {
      return PuntosOficiales.radioMinimoVueltasM;
    }
  }

  Future<String?> _resolverConductor() async {
    try {
      final lista = await DatabaseHelper.instance.conductoresConAuto();
      if (lista.isEmpty) return null;
      return lista.first['id_conductor']?.toString();
    } catch (_) {
      return null;
    }
  }

  /// Permite a las pruebas forzar el radio sin tocar la base de datos.
  @visibleForTesting
  void setRadioVueltasParaPruebas(double metros) => _radioVueltasM = metros;

  @visibleForTesting
  EstadoCircuitoPersistente? get estadoInternoParaPruebas => _estadoPersistente;
}
