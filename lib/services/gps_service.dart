import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../domain/reglas_asistencia.dart';

/// Resultado detallado de la verificación de ubicación del conductor.
class VerificacionGps {
  final bool exito;
  final Position? posicion;
  final double? distanciaPuntoMetros;
  final bool dentroDeGeocerca;
  final bool esMock;
  final bool horaSateliteConfiable;
  final String? mensajeError;

  const VerificacionGps({
    required this.exito,
    this.posicion,
    this.distanciaPuntoMetros,
    this.dentroDeGeocerca = false,
    this.esMock = false,
    this.horaSateliteConfiable = true,
    this.mensajeError,
  });
}

/// Servicio singleton para el manejo del hardware GPS, permisos y geocercas de alta precisión.
class GpsService {
  GpsService._internal();
  static final GpsService instance = GpsService._internal();

  /// Configuración nativa de máxima precisión (actualización continua cada 800ms y filtro 0m)
  /// ideal para detectar movimientos cortos (ej. radios de 2m, 3m o 5m en demostraciones).
  LocationSettings _construirAjustesGps({
    LocationAccuracy accuracy = LocationAccuracy.bestForNavigation,
    int distanceFilterM = 0,
    Duration? timeLimit,
  }) {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilterM,
        intervalDuration: const Duration(milliseconds: 800),
        timeLimit: timeLimit,
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

  /// Solicita explícitamente los permisos y devuelve un mensaje explicativo si fallan.
  Future<String?> asegurarPermisos() async {
    final servicioHabilitado = await Geolocator.isLocationServiceEnabled();
    if (!servicioHabilitado) {
      return 'El GPS de tu dispositivo está apagado. Actívalo para continuar.';
    }

    var permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
      if (permiso == LocationPermission.denied) {
        return 'Permiso de ubicación denegado. Se requiere GPS para registrar asistencia.';
      }
    }
    if (permiso == LocationPermission.deniedForever) {
      return 'Permiso de ubicación bloqueado permanentemente. Habilítalo en los Ajustes de la app.';
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

  /// Retorna un stream continuo en tiempo real (distanceFilter = 0m, bestForNavigation)
  /// para detectar incluso 1 o 2 pasos de desplazamiento.
  Stream<Position> obtenerStreamPosicion({
    int distanceFilterM = 0,
    LocationAccuracy accuracy = LocationAccuracy.bestForNavigation,
  }) {
    return Geolocator.getPositionStream(
      locationSettings: _construirAjustesGps(
        accuracy: accuracy,
        distanceFilterM: distanceFilterM,
      ),
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

  /// Verifica si la posición actual se encuentra dentro del radio del punto de control
  /// e inspecciona anti-fraude (mock GPS y desfase de reloj).
  Future<VerificacionGps> verificarUbicacionEnPunto({
    required double latPunto,
    required double lonPunto,
    required double radioMetros,
    double precisionMaximaMetros = 150.0,
  }) async {
    try {
      final errorPermiso = await asegurarPermisos();
      if (errorPermiso != null) {
        return VerificacionGps(exito: false, mensajeError: errorPermiso);
      }

      final pos = await obtenerPosicionActual();
      if (pos == null) {
        return const VerificacionGps(
          exito: false,
          mensajeError: 'No se pudo obtener señal GPS. Intenta nuevamente.',
        );
      }

      // 1. Detección de Fake GPS / Ubicaciones simuladas
      final esMock = pos.isMocked;

      // 2. Verificación de reloj satelital vs reloj del dispositivo
      final horaSatelite = pos.timestamp;
      final ahoraLocal = DateTime.now();
      final desfaseMin = ahoraLocal.difference(horaSatelite).inMinutes.abs();
      final horaSateliteConfiable = desfaseMin <= 10;

      // 3. Cálculo de distancia Haversine con precisión completa
      final distancia = ReglasAsistencia.calcularDistanciaMetros(
        lat1: pos.latitude,
        lon1: pos.longitude,
        lat2: latPunto,
        lon2: lonPunto,
      );

      final dentro = distancia <= radioMetros;

      return VerificacionGps(
        exito: true,
        posicion: pos,
        distanciaPuntoMetros: distancia,
        dentroDeGeocerca: dentro,
        esMock: esMock,
        horaSateliteConfiable: horaSateliteConfiable,
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
