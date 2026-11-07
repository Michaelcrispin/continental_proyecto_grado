import 'dart:math' as math;
import 'package:latlong2/latlong.dart';
import 'puntos_oficiales.dart';
import 'reglas_asistencia.dart';

/// Coordenadas y trazado del Sindicato Mixto de Transporte Continental.
///
/// Las coordenadas de las Paradas A (Cruce Villadela) y B (Teleférico Amarillo)
/// provienen ÚNICAMENTE de [PuntosOficiales] (fuente única de verdad, capturada
/// con Geo Tracker el 5 nov 2026). No hay coordenadas "quemadas" locales.
///
/// El tramo A → B es un enlace real de ~7.15 km, por lo que las geocercas son
/// CIRCULARES (radio Haversine, mínimo 30-50 m) y NO rectángulos de 8 m: a la
/// velocidad de un minibús (30-40 km/h ≈ 10 m/s) el GPS salta 10-20 m por
/// lectura y un polígono microscópico pierde colisiones.
class RutaContinental {
  RutaContinental._();

  /// Parada A: Cruce Villadela / Inicio de Ruta (fuente única PuntosOficiales)
  static const LatLng paradaAVilladela = PuntosOficiales.paradaAVilladela;

  /// Parada B: Teleférico Amarillo / Punto de Retorno (fuente única PuntosOficiales)
  static const LatLng paradaBTeleferico = PuntosOficiales.paradaBTeleferico;

  /// Radio mínimo (en metros) para las geocercas circulares de vueltas.
  static const double radioMinimoVueltasM = PuntosOficiales.radioMinimoVueltasM;

  // ---------------------------------------------------------------------------
  // TRAZADO ESQUEMÁTICO A → B (distancia real calculada por Haversine)
  // ---------------------------------------------------------------------------

  /// Tramo de IDA (Parada A → Parada B): línea entre los dos puntos oficiales.
  static const List<LatLng> puntosIda = [
    PuntosOficiales.paradaAVilladela,
    PuntosOficiales.paradaBTeleferico,
  ];

  /// Tramo de VUELTA (Parada B → Parada A).
  static const List<LatLng> puntosVuelta = [
    PuntosOficiales.paradaBTeleferico,
    PuntosOficiales.paradaAVilladela,
  ];

  /// Circuito completo continuo (Ida + Vuelta).
  static List<LatLng> get circuitoCompleto => [...puntosIda, ...puntosVuelta];

  /// Distancia real del circuito completo en km (ida + vuelta).
  static double get distanciaCircuitoKm =>
      (PuntosOficiales.distanciaABMetros * 2) / 1000.0;

  /// Distancia real del tramo A → B en km.
  static double get distanciaIdaKm =>
      PuntosOficiales.distanciaABMetros / 1000.0;

  /// Distancia real del tramo B → A en km.
  static double get distanciaVueltaKm =>
      PuntosOficiales.distanciaABMetros / 1000.0;

  // ---------------------------------------------------------------------------
  // GEOCERCAS CIRCULARES (Haversine)
  // ---------------------------------------------------------------------------

  /// Determina si [p] está dentro de la geocerca circular [centro] con radio
  /// [radioM] usando la fórmula Haversine. Opcionalmente desculpa hasta
  /// [margenMetros] de error generado por la imprecisión del GPS.
  static bool estaDentroDeGeocercaCircular(
    LatLng p,
    LatLng centro,
    double radioM, {
    double margenMetros = 0.0,
  }) {
    final d = ReglasAsistencia.calcularDistanciaMetros(
      lat1: p.latitude,
      lon1: p.longitude,
      lat2: centro.latitude,
      lon2: centro.longitude,
    );
    return (d - margenMetros) <= radioM;
  }

  /// Distancia en línea recta (Haversine) hasta el centro de una parada.
  static double distanciaAParadaMetros(LatLng p, LatLng centro) {
    return ReglasAsistencia.calcularDistanciaMetros(
      lat1: p.latitude,
      lon1: p.longitude,
      lat2: centro.latitude,
      lon2: centro.longitude,
    );
  }

  /// Radio efectivo para la detección de paso por parada en las vueltas:
  /// nunca menor al mínimo oficial (30-50 m) ni al radio calibrado en BD.
  static double radioEfectivoVueltas(double radioBdM) {
    final r = radioBdM <= 0 ? radioMinimoVueltasM : radioBdM;
    return r < radioMinimoVueltasM ? radioMinimoVueltasM : r.clamp(0.0, 300.0);
  }

  /// Genera un anillo geodésico de [radioM] metros alrededor de [centro]
  /// (usado para DIBUJAR las geocercas circulares en el mapa).
  static List<LatLng> anilloGeocerca(
    LatLng centro,
    double radioM, {
    int lados = 24,
  }) {
    final anillo = <LatLng>[];
    const metrosAGradosLat = 1.0 / 111320.0; // grados de latitud por metro
    for (int i = 0; i < lados; i++) {
      final t = (2 * math.pi * i) / lados;
      // Componente Este/Oeste escalada por cos(latitud)
      final dx = math.sin(t) * radioM;
      final dy = math.cos(t) * radioM;
      final dLat = dy * metrosAGradosLat;
      final dLon = (dx * metrosAGradosLat) /
          math.cos(centro.latitude * math.pi / 180.0);
      anillo.add(LatLng(centro.latitude + dLat, centro.longitude + dLon));
    }
    return anillo;
  }

  // ---------------------------------------------------------------------------
  // COMPATIBILIDAD: los "rectángulos" oficiales ahora SON ANILLOS CIRCULARES
  // centrados en las paradas. El ray-casting sobre un anillo de 24 vértices
  // funciona igual que un polígono, así que toda pantalla que dibuja o valida
  // con rectanguloParadaA/B sigue operando con geocercas circulares de radio
  // >= 30-50 m (diámetro >= 90 m), imposibles de saltarse en vehículo.
  // ---------------------------------------------------------------------------

  /// Anillo circular de Parada A (Cruce Villadela).
  static List<LatLng> get rectanguloParadaA =>
      anilloGeocerca(paradaAVilladela, radioDibujoM);

  /// Anillo circular de Parada B (Teleférico).
  static List<LatLng> get rectanguloParadaB =>
      anilloGeocerca(paradaBTeleferico, radioDibujoM);

  /// Radio que se dibuja en los mapas (≥ radio mínimo de detección).
  static const double radioDibujoM = radioMinimoVueltasM;

  /// Anillo de Parada A trasladado si [centroCustom] difiere del oficial.
  static List<LatLng> obtenerRectanguloParadaA([LatLng? centroCustom]) {
    return anilloGeocerca(
      centroCustom ?? paradaAVilladela,
      radioDibujoM,
    );
  }

  /// Anillo de Parada B trasladado si [centroCustom] difiere del oficial.
  static List<LatLng> obtenerRectanguloParadaB([LatLng? centroCustom]) {
    return anilloGeocerca(
      centroCustom ?? paradaBTeleferico,
      radioDibujoM,
    );
  }

  /// Determina si el punto GPS [p] está dentro del polígono [poligono] con
  /// un margen [margenMetros] (distancia al borde). Se mantiene por
  /// compatibilidad, pero la detección recomendada es circular Haversine.
  static bool estaDentroDeRectangulo(
    LatLng p,
    List<LatLng> poligono, {
    double margenMetros = 0.0,
  }) {
    if (_puntoEnPoligono(p, poligono)) return true;
    if (margenMetros <= 0) return false;
    return distanciaAlRectanguloMetros(p, poligono) <= margenMetros;
  }

  /// Algoritmo Ray-Casting para verificar si [p] cae dentro de [poligono].
  static bool _puntoEnPoligono(LatLng p, List<LatLng> poligono) {
    bool dentro = false;
    for (int i = 0, j = poligono.length - 1; i < poligono.length; j = i++) {
      final xi = poligono[i].longitude;
      final yi = poligono[i].latitude;
      final xj = poligono[j].longitude;
      final yj = poligono[j].latitude;

      final intersecta = ((yi > p.latitude) != (yj > p.latitude)) &&
          (p.longitude <
              (xj - xi) * (p.latitude - yi) / ((yj - yi) == 0 ? 1e-12 : (yj - yi)) +
                  xi);
      if (intersecta) dentro = !dentro;
    }
    return dentro;
  }

  /// Calcula la distancia en metros desde el punto [p] hasta el borde más
  /// cercano del polígono [poligono]. Si ya está adentro, devuelve 0.0.
  static double distanciaAlRectanguloMetros(LatLng p, List<LatLng> poligono) {
    if (_puntoEnPoligono(p, poligono)) return 0.0;

    const latScale = 111320.0;
    final lonScale = 111320.0 * math.cos(p.latitude * math.pi / 180.0);

    double minD = double.infinity;
    for (int i = 0; i < poligono.length; i++) {
      final a = poligono[i];
      final b = poligono[(i + 1) % poligono.length];

      final px = (p.longitude - a.longitude) * lonScale;
      final py = (p.latitude - a.latitude) * latScale;
      final bx = (b.longitude - a.longitude) * lonScale;
      final by = (b.latitude - a.latitude) * latScale;

      final len2 = bx * bx + by * by;
      final t = len2 == 0 ? 0.0 : ((px * bx + py * by) / len2).clamp(0.0, 1.0);
      final dx = px - t * bx;
      final dy = py - t * by;
      final dist = math.sqrt(dx * dx + dy * dy);
      if (dist < minD) minD = dist;
    }
    return minD;
  }
}
