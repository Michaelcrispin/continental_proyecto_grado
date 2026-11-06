import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../domain/reglas_asistencia.dart';

/// Resultado detallado de la verificación de ubicación del conductor.
class VerificacionGps {
  final bool exito;
  final Position? posicion;
  final double? distanciaPuntoMetros;
  final double? precisionMetros;
  final bool dentroDeGeocerca;
  final bool esMock;
  final bool horaSateliteConfiable;
  final bool senalDebil;
  final int muestrasPromediadas;
  final String? mensajeError;

  const VerificacionGps({
    required this.exito,
    this.posicion,
    this.distanciaPuntoMetros,
    this.precisionMetros,
    this.dentroDeGeocerca = false,
    this.esMock = false,
    this.horaSateliteConfiable = true,
    this.senalDebil = false,
    this.muestrasPromediadas = 1,
    this.mensajeError,
  });
}

/// Servicio singleton para el manejo del hardware GPS, permisos, promedio de muestras
/// y geocercas con tolerancia de precisión.
class GpsService {
  GpsService._internal();
  static final GpsService instance = GpsService._internal();

  /// Umbral máximo de error (accuracy) aceptado antes de considerar señal débil (60 m).
  static const double umbralSenalDebilMetros = 60.0;

  /// Permite alternar en vivo entre FusedLocationProvider (`false`, mejor bajo techo/Wi-Fi)
  /// y el LocationManager satelital nativo (`true`, útil a cielo abierto).
  bool forceLocationManager = false;

  /// Configuración nativa de máxima precisión (actualización continua cada 800ms y filtro 0m)
  /// con ForegroundNotificationConfig activo para evitar que Android congele el stream.
  LocationSettings _construirAjustesGps({
    LocationAccuracy accuracy = LocationAccuracy.bestForNavigation,
    int distanceFilterM = 0,
    Duration? timeLimit,
    bool activarForegroundService = false,
  }) {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilterM,
        intervalDuration: const Duration(milliseconds: 800),
        forceLocationManager: forceLocationManager,
        timeLimit: timeLimit,
        foregroundNotificationConfig: activarForegroundService
            ? const ForegroundNotificationConfig(
                notificationTitle: 'Continental Trufi 101 - 127',
                notificationText:
                    'Registrando ubicación del recorrido en tiempo real',
                enableWakeLock: false,
              )
            : null,
      );
    }
    return LocationSettings(
      accuracy: accuracy,
      distanceFilter: distanceFilterM,
      timeLimit: timeLimit,
    );
  }

  /// Comprueba si los servicios de ubicación están activados y si se cuentan con permisos.
  Future<bool> verificarPermisos() async {
    final servicioHabilitado = await Geolocator.isLocationServiceEnabled();
    if (!servicioHabilitado) return false;

    var permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
      if (permiso == LocationPermission.denied) return false;
    }
    if (permiso == LocationPermission.deniedForever) return false;

    return true;
  }

  /// Solicita explícitamente los permisos y devuelve un mensaje claro si fallan.
  Future<String?> asegurarPermisos() async {
    final servicioHabilitado = await Geolocator.isLocationServiceEnabled();
    if (!servicioHabilitado) {
      return 'El GPS de tu celular está apagado. Enciéndelo en modo "Alta precisión" para continuar.';
    }

    var permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
      if (permiso == LocationPermission.denied) {
        return 'Permiso de ubicación denegado. Activa el permiso en "Ubicación precisa" para registrar asistencia.';
      }
    }
    if (permiso == LocationPermission.deniedForever) {
      return 'Permiso de ubicación bloqueado permanentemente. Abre Ajustes → Aplicaciones → Continental y activa "Ubicación precisa".';
    }
    return null;
  }

  /// Obtiene la posición actual con precisión de navegación (bestForNavigation).
  Future<Position?> obtenerPosicionActual({
    Duration timeout = const Duration(seconds: 12),
  }) async {
    final errorPermiso = await asegurarPermisos();
    if (errorPermiso != null) throw Exception(errorPermiso);

    return Geolocator.getCurrentPosition(
      locationSettings: _construirAjustesGps(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilterM: 0,
        timeLimit: timeout,
      ),
    );
  }

  /// Retorna un stream continuo en tiempo real (distanceFilter = 0m, bestForNavigation).
  Stream<Position> obtenerStreamPosicion({
    int distanceFilterM = 0,
    LocationAccuracy accuracy = LocationAccuracy.bestForNavigation,
    bool usarForeground = true,
  }) {
    return Geolocator.getPositionStream(
      locationSettings: _construirAjustesGps(
        accuracy: accuracy,
        distanceFilterM: distanceFilterM,
        activarForegroundService: usarForeground,
      ),
    );
  }

  /// Captura y promedia lecturas GPS durante [duracion] (ej. 20 s al calibrar y 5 s al marcar).
  /// Descarta lecturas malas (`accuracy > 60 m`) si existen lecturas confiables y pondera
  /// cada coordenada por el inverso de su margen de error (`1 / accuracy`).
  Future<Position?> capturarPuntoPromediado({
    Duration duracion = const Duration(seconds: 5),
    double maxAccuracyM = umbralSenalDebilMetros,
    void Function(int muestras, int segundosRestantes, double? ultimaPrecision)?
    onProgreso,
  }) async {
    final errorPermiso = await asegurarPermisos();
    if (errorPermiso != null) throw Exception(errorPermiso);

    final List<Position> todasMuestras = [];
    StreamSubscription<Position>? sub;
    Timer? ticker;
    final inicio = DateTime.now();

    try {
      sub = obtenerStreamPosicion(distanceFilterM: 0, usarForeground: false)
          .listen((pos) {
            todasMuestras.add(pos);
            final transcurrido = DateTime.now().difference(inicio).inSeconds;
            final restantes = (duracion.inSeconds - transcurrido).clamp(
              0,
              duracion.inSeconds,
            );
            onProgreso?.call(todasMuestras.length, restantes, pos.accuracy);
          });

      ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        final transcurrido = DateTime.now().difference(inicio).inSeconds;
        final restantes = (duracion.inSeconds - transcurrido).clamp(
          0,
          duracion.inSeconds,
        );
        final ultAcc = todasMuestras.isNotEmpty
            ? todasMuestras.last.accuracy
            : null;
        onProgreso?.call(todasMuestras.length, restantes, ultAcc);
      });

      await Future.delayed(duracion);
    } finally {
      await sub?.cancel();
      ticker?.cancel();
    }

    if (todasMuestras.isEmpty) {
      return obtenerPosicionActual();
    }

    // Filtrar lecturas buenas (accuracy <= 60m); si todas superan 60m, usar las mejores disponibles
    final buenas = todasMuestras
        .where((p) => p.accuracy <= maxAccuracyM)
        .toList();
    final seleccionadas = buenas.isNotEmpty ? buenas : todasMuestras;

    double sumaPesos = 0.0;
    double sumaLat = 0.0;
    double sumaLon = 0.0;
    double sumaAcc = 0.0;
    bool algunMock = false;

    for (final p in seleccionadas) {
      final peso = 1.0 / (p.accuracy <= 1.0 ? 1.0 : p.accuracy);
      sumaPesos += peso;
      sumaLat += p.latitude * peso;
      sumaLon += p.longitude * peso;
      sumaAcc += p.accuracy;
      if (p.isMocked) algunMock = true;
    }

    final base = seleccionadas.last;
    return Position(
      latitude: sumaLat / sumaPesos,
      longitude: sumaLon / sumaPesos,
      timestamp: base.timestamp,
      accuracy: sumaAcc / seleccionadas.length,
      altitude: base.altitude,
      altitudeAccuracy: base.altitudeAccuracy,
      heading: base.heading,
      headingAccuracy: base.headingAccuracy,
      speed: base.speed,
      speedAccuracy: base.speedAccuracy,
      isMocked: algunMock,
    );
  }

  /// Formatea la distancia mostrando 1 decimal cuando es menor a 100 metros (ej. "1.4 m").
  static String formatearDistancia(double? metros) {
    if (metros == null) return 'Calculando...';
    if (metros < 100) {
      return '${metros.toStringAsFixed(1)} m';
    }
    if (metros < 1000) {
      return '${metros.toStringAsFixed(0)} m';
    }
    return '${(metros / 1000).toStringAsFixed(2)} km';
  }

  /// Verifica si la posición actual se encuentra dentro del radio del punto de control,
  /// promediando durante [segundosPromedio] (5 s por defecto al marcar) y aplicando anti-fraude.
  Future<VerificacionGps> verificarUbicacionEnPunto({
    required double latPunto,
    required double lonPunto,
    required double radioMetros,
    int segundosPromedio = 5,
    double precisionMaximaMetros = umbralSenalDebilMetros,
    void Function(int muestras, int segRestantes, double? accuracy)? onProgreso,
  }) async {
    try {
      final errorPermiso = await asegurarPermisos();
      if (errorPermiso != null) {
        return VerificacionGps(exito: false, mensajeError: errorPermiso);
      }

      final pos = segundosPromedio > 1
          ? await capturarPuntoPromediado(
              duracion: Duration(seconds: segundosPromedio),
              maxAccuracyM: precisionMaximaMetros,
              onProgreso: onProgreso,
            )
          : await obtenerPosicionActual();

      if (pos == null) {
        return const VerificacionGps(
          exito: false,
          mensajeError:
              'No se pudo obtener señal GPS. Acércate a una ventana o sal al patio e intenta nuevamente.',
        );
      }

      // 1. Detección de Fake GPS / Ubicaciones simuladas
      final esMock = pos.isMocked;

      // 2. Verificación de reloj satelital vs reloj del dispositivo
      final horaSatelite = pos.timestamp;
      final ahoraLocal = DateTime.now();
      final desfaseMin = ahoraLocal.difference(horaSatelite).inMinutes.abs();
      final horaSateliteConfiable = desfaseMin <= 10;

      // 3. Evaluación de calidad de señal (descartar lecturas malas > 60 m)
      final senalDebil = pos.accuracy > precisionMaximaMetros;

      // 4. Cálculo de distancia Haversine + margen de confianza por accuracy
      final distancia = ReglasAsistencia.calcularDistanciaMetros(
        lat1: pos.latitude,
        lon1: pos.longitude,
        lat2: latPunto,
        lon2: lonPunto,
      );

      final dentro = ReglasAsistencia.estaDentroDeGeocerca(
        latUsuario: pos.latitude,
        lonUsuario: pos.longitude,
        latPunto: latPunto,
        lonPunto: lonPunto,
        radioMetros: radioMetros,
        accuracyMetros: pos.accuracy,
      );

      String? mensajeAlerta;
      if (esMock) {
        mensajeAlerta =
            'Se detectó una aplicación de ubicación simulada (Fake GPS). Desactívala para marcar asistencia.';
      } else if (!horaSateliteConfiable) {
        mensajeAlerta =
            'La hora de tu celular está alterada respecto al satélite GPS. Configura fecha y hora automáticas.';
      } else if (senalDebil) {
        mensajeAlerta =
            'Señal GPS débil (±${pos.accuracy.toStringAsFixed(0)} m). Acércate a una ventana o sal al patio.';
      }

      return VerificacionGps(
        exito: true,
        posicion: pos,
        distanciaPuntoMetros: distancia,
        precisionMetros: pos.accuracy,
        dentroDeGeocerca: dentro && !senalDebil,
        esMock: esMock,
        horaSateliteConfiable: horaSateliteConfiable,
        senalDebil: senalDebil,
        mensajeError: mensajeAlerta,
      );
    } catch (e) {
      return VerificacionGps(
        exito: false,
        mensajeError: 'Error al consultar GPS: ${e.toString()}',
      );
    }
  }

  /// Abre los ajustes del sistema para que el usuario habilite el GPS.
  Future<bool> abrirAjustesUbicacion() => Geolocator.openLocationSettings();

  /// Abre los ajustes de la app para habilitar permisos de la aplicación.
  Future<bool> abrirAjustesApp() => Geolocator.openAppSettings();
}
