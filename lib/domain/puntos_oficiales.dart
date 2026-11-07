import 'package:latlong2/latlong.dart';
import 'reglas_asistencia.dart';

/// FUENTE ÚNICA DE COORDENADAS OFICIALES DEL SINDICATO CONTINENTAL.
///
/// Estas constantes provienen del registro satelital real Geo Tracker
/// ("cordenadas gps/5_nov_2026,_14_30_16.gpx"), donde:
///   - Parada A = Cruce Villadela (inicio del recorrido)
///   - Parada B = Teleférico Amarillo - Mirador (punto de retorno, a ~7.15 km)
///
/// REGLA: ninguna otra parte del proyecto debe escribir coordenadas de
/// Villadela/Teleférico a mano. La semilla de SQLite, la migración,
/// RutaContinental y todas las pantallas leen ÚNICAMENTE estas constantes.
class PuntosOficiales {
  PuntosOficiales._();

  /// Parada A: Cruce Villadela / Inicio de Ruta (GPX real 5 nov 2026, elev. 4061 m)
  static const LatLng paradaAVilladela = LatLng(-16.53454833, -68.191605);

  /// Parada B: Teleférico Amarillo - Mirador / Punto de Retorno (elev. 4111 m)
  static const LatLng paradaBTeleferico = LatLng(-16.51834167, -68.15143667);

  /// Radio por defecto de la geocerca de asistencia (coincide con la
  /// configuración radio_defecto_m de la tabla configuracion).
  static const double radioAsistenciaM = 100.0;

  /// Radio mínimo de las geocercas circulares de detección de parada
  /// (vueltas A → B → A). A 30-40 km/h el GPS lee cada 1-2 s (~10-20 m por
  /// lectura); con un diámetro de 90 m es imposible "saltarse" la geocerca.
  static const double radioMinimoVueltasM = 45.0;

  /// Distancia real entre Parada A y Parada B en metros (Haversine).
  static double get distanciaABMetros => ReglasAsistencia.calcularDistanciaMetros(
        lat1: paradaAVilladela.latitude,
        lon1: paradaAVilladela.longitude,
        lat2: paradaBTeleferico.latitude,
        lon2: paradaBTeleferico.longitude,
      );
}
