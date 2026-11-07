import 'dart:math' as math;
import 'package:latlong2/latlong.dart';

/// Coordenadas y trazado vial real del Sindicato Mixto de Transporte Continental
/// Extraído de las grabaciones satelitales Geo Tracker:
/// - Ida (vuelta uno): 7_nov_2026,_10_24_27.gpx (75.5 m)
/// - Vuelta (vuelta dos): 7_nov_2026,_10_26_04.gpx (85.6 m)
class RutaContinental {
  RutaContinental._();

  /// Parada A: Cruce Villadela / Inicio de Ruta (Elevación: 3977.8 m)
  static const LatLng paradaAVilladela = LatLng(-16.57568833, -68.23764500);

  /// Parada B: Teleférico / Punto de Retorno (Elevación: 3976.3 m)
  static const LatLng paradaBTeleferico = LatLng(-16.57617500, -68.23820333);

  /// Distancia oficial del circuito completo en kilómetros (161 m = 0.16 km)
  static const double distanciaCircuitoKm = 0.16;
  static const double distanciaIdaKm = 0.08;
  static const double distanciaVueltaKm = 0.09;

  /// Trazado real de IDA (vuelta uno): Parada A -> Parada B
  static const List<LatLng> puntosIda = [
    LatLng(-16.57568833, -68.23764500),
    LatLng(-16.57570375, -68.23766542),
    LatLng(-16.57571916, -68.23768584),
    LatLng(-16.57573458, -68.23770625),
    LatLng(-16.57575000, -68.23772667),
    LatLng(-16.57577000, -68.23774375),
    LatLng(-16.57579000, -68.23776084),
    LatLng(-16.57581000, -68.23777792),
    LatLng(-16.57583000, -68.23779500),
    LatLng(-16.57584458, -68.23781542),
    LatLng(-16.57585917, -68.23783583),
    LatLng(-16.57587375, -68.23785625),
    LatLng(-16.57588833, -68.23787667),
    LatLng(-16.57590417, -68.23789584),
    LatLng(-16.57592000, -68.23791500),
    LatLng(-16.57593583, -68.23793416),
    LatLng(-16.57595167, -68.23795333),
    LatLng(-16.57596792, -68.23797250),
    LatLng(-16.57598417, -68.23799166),
    LatLng(-16.57600042, -68.23801083),
    LatLng(-16.57601667, -68.23803000),
    LatLng(-16.57603167, -68.23804875),
    LatLng(-16.57604667, -68.23806750),
    LatLng(-16.57606167, -68.23808625),
    LatLng(-16.57607667, -68.23810500),
    LatLng(-16.57609125, -68.23812292),
    LatLng(-16.57610583, -68.23814083),
    LatLng(-16.57612042, -68.23815875),
    LatLng(-16.57613500, -68.23817667),
    LatLng(-16.57614500, -68.23818334),
    LatLng(-16.57615500, -68.23819000),
    LatLng(-16.57616500, -68.23819667),
    LatLng(-16.57617500, -68.23820333),
  ];

  /// Trazado real de VUELTA (vuelta dos): Parada B -> Parada A
  static const List<LatLng> puntosVuelta = [
    LatLng(-16.57617500, -68.23820333),
    LatLng(-16.57615750, -68.23818667),
    LatLng(-16.57614000, -68.23817000),
    LatLng(-16.57612250, -68.23815334),
    LatLng(-16.57610500, -68.23813667),
    LatLng(-16.57608583, -68.23812209),
    LatLng(-16.57606666, -68.23810750),
    LatLng(-16.57604750, -68.23809291),
    LatLng(-16.57602833, -68.23807833),
    LatLng(-16.57601250, -68.23806041),
    LatLng(-16.57599666, -68.23804250),
    LatLng(-16.57598083, -68.23802459),
    LatLng(-16.57596500, -68.23800667),
    LatLng(-16.57594833, -68.23798750),
    LatLng(-16.57593166, -68.23796834),
    LatLng(-16.57591500, -68.23794917),
    LatLng(-16.57589833, -68.23793000),
    LatLng(-16.57588292, -68.23791208),
    LatLng(-16.57586750, -68.23789417),
    LatLng(-16.57585209, -68.23787625),
    LatLng(-16.57583667, -68.23785833),
    LatLng(-16.57581875, -68.23784000),
    LatLng(-16.57580084, -68.23782166),
    LatLng(-16.57578292, -68.23780333),
    LatLng(-16.57576500, -68.23778500),
    LatLng(-16.57574917, -68.23776542),
    LatLng(-16.57573334, -68.23774583),
    LatLng(-16.57571750, -68.23772625),
    LatLng(-16.57570167, -68.23770667),
    LatLng(-16.57568667, -68.23768667),
    LatLng(-16.57567167, -68.23766667),
    LatLng(-16.57565667, -68.23764667),
    LatLng(-16.57564167, -68.23762667),
    LatLng(-16.57565333, -68.23763125),
    LatLng(-16.57566500, -68.23763583),
    LatLng(-16.57567666, -68.23764042),
    LatLng(-16.57568833, -68.23764500),
  ];

  /// Circuito completo continuo (Ida + Vuelta)
  static List<LatLng> get circuitoCompleto => [...puntosIda, ...puntosVuelta];

  /// Coordenadas exactas grabadas en "vuelta uno" (7_nov_2026,_10_24_27.gpx): A -> B
  static const List<LatLng> puntosCrudosVueltaUno = [
    LatLng(-16.57568833, -68.23764500),
    LatLng(-16.57575000, -68.23772667),
    LatLng(-16.57583000, -68.23779500),
    LatLng(-16.57588833, -68.23787667),
    LatLng(-16.57595167, -68.23795333),
    LatLng(-16.57601667, -68.23803000),
    LatLng(-16.57607667, -68.23810500),
    LatLng(-16.57613500, -68.23817667),
  ];

  /// Coordenadas exactas grabadas en "vuelta dos" (7_nov_2026,_10_26_04.gpx): B -> A
  static const List<LatLng> puntosCrudosVueltaDos = [
    LatLng(-16.57617500, -68.23820333),
    LatLng(-16.57610500, -68.23813667),
    LatLng(-16.57602833, -68.23807833),
    LatLng(-16.57596500, -68.23800667),
    LatLng(-16.57589833, -68.23793000),
    LatLng(-16.57583667, -68.23785833),
    LatLng(-16.57576500, -68.23778500),
    LatLng(-16.57570167, -68.23770667),
    LatLng(-16.57564167, -68.23762667),
  ];

  /// Geocerca Rectangular Oficial de Parada A (cubre inicio de vuelta uno y cierre de vuelta dos sobre la calle,
  /// manteniéndose alejada del interior de la vivienda en -16.575788, -68.237622).
  static const List<LatLng> rectanguloParadaA = [
    LatLng(-16.575595, -68.237625),
    LatLng(-16.575650, -68.237575),
    LatLng(-16.575735, -68.237685),
    LatLng(-16.575680, -68.237735),
  ];

  /// Geocerca Rectangular Oficial de Parada B (cubre el final de vuelta uno [-16.576135, -68.23817667]
  /// y el inicio de vuelta dos [-16.576175, -68.23820333] / [-16.576105, -68.23813667]).
  static const List<LatLng> rectanguloParadaB = [
    LatLng(-16.576065, -68.238145),
    LatLng(-16.576125, -68.238085),
    LatLng(-16.576230, -68.238210),
    LatLng(-16.576170, -68.238270),
  ];

  /// Verifica si [p] está en el Punto A usando el rectángulo y las coordenadas finales/iniciales
  /// de vuelta uno y vuelta dos (excluyendo siempre la zona interior de la casa al sur de -16.575740).
  static bool estaEnZonaParadaA(LatLng p, [List<LatLng>? poligonoCustom]) {
    if (p.latitude < -16.575740) return false;
    final poly = poligonoCustom ?? rectanguloParadaA;
    if (estaDentroDeRectangulo(p, poly, margenMetros: 0.0)) return true;
    const puntosClaveA = [
      LatLng(-16.57568833, -68.23764500), // Inicio vuelta uno
      LatLng(-16.57570167, -68.23770667), // Llegada vuelta dos (penúltimo punto)
      LatLng(-16.57564167, -68.23762667), // Cierre vuelta dos (último punto)
    ];
    for (final pa in puntosClaveA) {
      if (_distanciaMetros(p, pa) <= 5.0) return true;
    }
    return false;
  }

  /// Verifica si [p] está en el Punto B usando el rectángulo y las coordenadas de retorno
  /// de vuelta uno y vuelta dos.
  static bool estaEnZonaParadaB(LatLng p, [List<LatLng>? poligonoCustom]) {
    final poly = poligonoCustom ?? rectanguloParadaB;
    if (estaDentroDeRectangulo(p, poly, margenMetros: 4.0)) return true;
    const puntosClaveB = [
      LatLng(-16.57613500, -68.23817667), // Fin vuelta uno
      LatLng(-16.57607667, -68.23810500), // Penúltimo vuelta uno
      LatLng(-16.57617500, -68.23820333), // Inicio vuelta dos
      LatLng(-16.57610500, -68.23813667), // Segundo punto vuelta dos
    ];
    for (final pb in puntosClaveB) {
      if (_distanciaMetros(p, pb) <= 7.5) return true;
    }
    return false;
  }

  /// Retorna la distancia mínima en metros desde [p] a cualquiera de las coordenadas
  /// grabadas en vuelta uno y vuelta dos.
  static double distanciaAlCorredorVueltasMetros(LatLng p) {
    double minD = double.infinity;
    for (final pt in [...puntosCrudosVueltaUno, ...puntosCrudosVueltaDos]) {
      final d = _distanciaMetros(p, pt);
      if (d < minD) minD = d;
    }
    return minD;
  }

  /// Retorna el rectángulo de Parada A, trasladándolo si [centroCustom] fue movido
  /// manualmente respecto a la coordenada oficial.
  static List<LatLng> obtenerRectanguloParadaA([LatLng? centroCustom]) {
    if (centroCustom == null) return rectanguloParadaA;
    final dLat = centroCustom.latitude - paradaAVilladela.latitude;
    final dLon = centroCustom.longitude - paradaAVilladela.longitude;
    if (dLat.abs() < 0.0002 && dLon.abs() < 0.0002) return rectanguloParadaA;
    // Si viene una coordenada antigua de la BD previa, usar el rectángulo oficial nuevo
    if ((centroCustom.latitude - (-16.53454833)).abs() < 0.01) {
      return rectanguloParadaA;
    }
    return rectanguloParadaA
        .map((p) => LatLng(p.latitude + dLat, p.longitude + dLon))
        .toList();
  }

  /// Retorna el rectángulo de Parada B, trasladándolo si [centroCustom] fue movido
  /// manualmente respecto a la coordenada oficial.
  static List<LatLng> obtenerRectanguloParadaB([LatLng? centroCustom]) {
    if (centroCustom == null) return rectanguloParadaB;
    final dLat = centroCustom.latitude - paradaBTeleferico.latitude;
    final dLon = centroCustom.longitude - paradaBTeleferico.longitude;
    if (dLat.abs() < 0.0002 && dLon.abs() < 0.0002) return rectanguloParadaB;
    // Si viene una coordenada antigua de la BD previa, usar el rectángulo oficial nuevo
    if ((centroCustom.latitude - (-16.51834167)).abs() < 0.02) {
      return rectanguloParadaB;
    }
    return rectanguloParadaB
        .map((p) => LatLng(p.latitude + dLat, p.longitude + dLon))
        .toList();
  }

  /// Determina si el punto GPS [p] está estrictamente dentro del polígono/rectángulo [poligono].
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

  /// Calcula la distancia en metros desde el punto [p] hasta el borde más cercano
  /// del rectángulo [poligono]. Si ya está adentro, devuelve 0.0.
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

  static double _distanciaMetros(LatLng a, LatLng b) {
    const latScale = 111320.0;
    final lonScale = 111320.0 * math.cos(a.latitude * math.pi / 180.0);
    final dx = (b.longitude - a.longitude) * lonScale;
    final dy = (b.latitude - a.latitude) * latScale;
    return math.sqrt(dx * dx + dy * dy);
  }
}
