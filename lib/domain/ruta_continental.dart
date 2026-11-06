import 'dart:math' as math;
import 'package:latlong2/latlong.dart';

/// Coordenadas y trazado vial real del Sindicato Mixto de Transporte Continental
/// Extraído de la grabación satelital Geo Tracker (5_nov_2026,_14_30_16.gpx).
/// - Distancia total del circuito (1 vuelta completa): 14.69 km
/// - Tramo Ida (Parada A -> Parada B): 7.15 km
/// - Tramo Vuelta (Parada B -> Parada A): 7.54 km
class RutaContinental {
  RutaContinental._();

  /// Parada A: Cruce Villadela (Elevación: 4061 m)
  static const LatLng paradaAVilladela = LatLng(-16.53454833, -68.19160500);

  /// Parada B: Teleférico / Punto de Retorno (Elevación: 4111 m)
  static const LatLng paradaBTeleferico = LatLng(-16.51834167, -68.15143667);

  /// Distancia oficial del circuito completo en kilómetros
  static const double distanciaCircuitoKm = 14.69;
  static const double distanciaIdaKm = 7.15;
  static const double distanciaVueltaKm = 7.54;

  /// Trazado real de IDA: Parada A (Cruce Villadela) -> Parada B (Teleférico)
  static const List<LatLng> puntosIda = [
    LatLng(-16.5345483, -68.1916050),
    LatLng(-16.5344017, -68.1914067),
    LatLng(-16.5343583, -68.1914067),
    LatLng(-16.5344083, -68.1913733),
    LatLng(-16.5343867, -68.1913967),
    LatLng(-16.5342600, -68.1912517),
    LatLng(-16.5343083, -68.1912767),
    LatLng(-16.5341917, -68.1912100),
    LatLng(-16.5342683, -68.1910083),
    LatLng(-16.5343983, -68.1908583),
    LatLng(-16.5347167, -68.1908133),
    LatLng(-16.5348083, -68.1907617),
    LatLng(-16.5348617, -68.1906800),
    LatLng(-16.5348783, -68.1903500),
    LatLng(-16.5349867, -68.1901583),
    LatLng(-16.5377650, -68.1862767),
    LatLng(-16.5379000, -68.1861183),
    LatLng(-16.5383233, -68.1858983),
    LatLng(-16.5383967, -68.1857967),
    LatLng(-16.5384867, -68.1853383),
    LatLng(-16.5385783, -68.1851767),
    LatLng(-16.5429933, -68.1790250),
    LatLng(-16.5431800, -68.1788283),
    LatLng(-16.5435800, -68.1785700),
    LatLng(-16.5437417, -68.1781050),
    LatLng(-16.5442017, -68.1775350),
    LatLng(-16.5444667, -68.1771417),
    LatLng(-16.5452267, -68.1762300),
    LatLng(-16.5453317, -68.1761300),
    LatLng(-16.5454483, -68.1760933),
    LatLng(-16.5455717, -68.1761400),
    LatLng(-16.5456417, -68.1762667),
    LatLng(-16.5456167, -68.1764067),
    LatLng(-16.5455283, -68.1765000),
    LatLng(-16.5451833, -68.1764950),
    LatLng(-16.5416267, -68.1752450),
    LatLng(-16.5396417, -68.1746100),
    LatLng(-16.5390717, -68.1743750),
    LatLng(-16.5389083, -68.1742467),
    LatLng(-16.5383733, -68.1736200),
    LatLng(-16.5373567, -68.1725750),
    LatLng(-16.5368067, -68.1719050),
    LatLng(-16.5367833, -68.1717800),
    LatLng(-16.5368833, -68.1716783),
    LatLng(-16.5371033, -68.1715517),
    LatLng(-16.5371417, -68.1714533),
    LatLng(-16.5367883, -68.1711350),
    LatLng(-16.5340183, -68.1691117),
    LatLng(-16.5314517, -68.1671783),
    LatLng(-16.5308117, -68.1667433),
    LatLng(-16.5286617, -68.1651167),
    LatLng(-16.5274750, -68.1642833),
    LatLng(-16.5260067, -68.1631867),
    LatLng(-16.5258250, -68.1630150),
    LatLng(-16.5236400, -68.1614167),
    LatLng(-16.5235483, -68.1613317),
    LatLng(-16.5235517, -68.1612083),
    LatLng(-16.5240150, -68.1606183),
    LatLng(-16.5240617, -68.1605300),
    LatLng(-16.5240417, -68.1604250),
    LatLng(-16.5233167, -68.1598450),
    LatLng(-16.5233433, -68.1597300),
    LatLng(-16.5234700, -68.1595333),
    LatLng(-16.5239483, -68.1589033),
    LatLng(-16.5239167, -68.1587967),
    LatLng(-16.5237850, -68.1586517),
    LatLng(-16.5238017, -68.1585383),
    LatLng(-16.5243017, -68.1572883),
    LatLng(-16.5244000, -68.1569917),
    LatLng(-16.5244100, -68.1567917),
    LatLng(-16.5230383, -68.1561967),
    LatLng(-16.5221850, -68.1557767),
    LatLng(-16.5216217, -68.1556167),
    LatLng(-16.5213183, -68.1554767),
    LatLng(-16.5212583, -68.1553783),
    LatLng(-16.5212700, -68.1552450),
    LatLng(-16.5214483, -68.1547483),
    LatLng(-16.5221483, -68.1530200),
    LatLng(-16.5221200, -68.1529150),
    LatLng(-16.5211183, -68.1524117),
    LatLng(-16.5191167, -68.1516083),
    LatLng(-16.5178233, -68.1510150),
    LatLng(-16.5177133, -68.1510333),
    LatLng(-16.5177600, -68.1511300),
    LatLng(-16.5184017, -68.1514267),
    LatLng(-16.5183417, -68.1514367),
  ];

  /// Trazado real de VUELTA: Parada B (Teleférico) -> Parada A (Cruce Villadela)
  static const List<LatLng> puntosVuelta = [
    LatLng(-16.5183417, -68.1514367),
    LatLng(-16.5178217, -68.1509950),
    LatLng(-16.5177283, -68.1509967),
    LatLng(-16.5177350, -68.1510983),
    LatLng(-16.5181333, -68.1512983),
    LatLng(-16.5190100, -68.1516733),
    LatLng(-16.5192033, -68.1517100),
    LatLng(-16.5193150, -68.1516933),
    LatLng(-16.5208900, -68.1524783),
    LatLng(-16.5220483, -68.1529633),
    LatLng(-16.5221283, -68.1530483),
    LatLng(-16.5221183, -68.1531850),
    LatLng(-16.5216767, -68.1541783),
    LatLng(-16.5212200, -68.1553300),
    LatLng(-16.5212567, -68.1554300),
    LatLng(-16.5215650, -68.1556017),
    LatLng(-16.5241167, -68.1566917),
    LatLng(-16.5243017, -68.1568017),
    LatLng(-16.5243633, -68.1569100),
    LatLng(-16.5237517, -68.1585100),
    LatLng(-16.5237483, -68.1586500),
    LatLng(-16.5237983, -68.1587433),
    LatLng(-16.5238967, -68.1588117),
    LatLng(-16.5239050, -68.1589200),
    LatLng(-16.5235500, -68.1594283),
    LatLng(-16.5233250, -68.1598650),
    LatLng(-16.5234067, -68.1599633),
    LatLng(-16.5240117, -68.1604133),
    LatLng(-16.5240533, -68.1605200),
    LatLng(-16.5235617, -68.1612683),
    LatLng(-16.5235683, -68.1613883),
    LatLng(-16.5306367, -68.1666383),
    LatLng(-16.5307350, -68.1667167),
    LatLng(-16.5308450, -68.1668983),
    LatLng(-16.5314317, -68.1674033),
    LatLng(-16.5328267, -68.1684000),
    LatLng(-16.5344817, -68.1696650),
    LatLng(-16.5369017, -68.1714383),
    LatLng(-16.5369283, -68.1715300),
    LatLng(-16.5368333, -68.1716200),
    LatLng(-16.5352650, -68.1725817),
    LatLng(-16.5348117, -68.1727750),
    LatLng(-16.5345067, -68.1730317),
    LatLng(-16.5347350, -68.1731717),
    LatLng(-16.5377500, -68.1742883),
    LatLng(-16.5413517, -68.1754850),
    LatLng(-16.5437300, -68.1763417),
    LatLng(-16.5439117, -68.1764333),
    LatLng(-16.5440050, -68.1765283),
    LatLng(-16.5441183, -68.1767350),
    LatLng(-16.5441767, -68.1771367),
    LatLng(-16.5441367, -68.1773567),
    LatLng(-16.5440317, -68.1775767),
    LatLng(-16.5435933, -68.1781050),
    LatLng(-16.5432233, -68.1782417),
    LatLng(-16.5431400, -68.1783750),
    LatLng(-16.5431000, -68.1786933),
    LatLng(-16.5430033, -68.1789167),
    LatLng(-16.5420867, -68.1801983),
    LatLng(-16.5405967, -68.1821767),
    LatLng(-16.5400983, -68.1829433),
    LatLng(-16.5384183, -68.1852950),
    LatLng(-16.5383183, -68.1853650),
    LatLng(-16.5380683, -68.1854133),
    LatLng(-16.5379467, -68.1854833),
    LatLng(-16.5378683, -68.1856117),
    LatLng(-16.5378200, -68.1860650),
    LatLng(-16.5375100, -68.1865650),
    LatLng(-16.5354583, -68.1894600),
    LatLng(-16.5348700, -68.1902583),
    LatLng(-16.5346583, -68.1903617),
    LatLng(-16.5345367, -68.1903700),
    LatLng(-16.5344417, -68.1904617),
    LatLng(-16.5344517, -68.1906883),
    LatLng(-16.5345133, -68.1907883),
    LatLng(-16.5354517, -68.1916900),
    LatLng(-16.5359583, -68.1921067),
    LatLng(-16.5360483, -68.1922850),
    LatLng(-16.5360267, -68.1923900),
    LatLng(-16.5357150, -68.1927033),
    LatLng(-16.5348000, -68.1918650),
    LatLng(-16.5346017, -68.1916167),
  ];

  /// Circuito completo continuo (Ida + Vuelta)
  static List<LatLng> get circuitoCompleto => [...puntosIda, ...puntosVuelta];

  /// Geocerca Rectangular Oficial de Parada A (Cruce Villadela)
  /// Orientada exactamente sobre la calzada de parada e inicio de ruta (75 m x 28 m),
  /// evitando invadir la autopista paralela.
  static const List<LatLng> rectanguloParadaA = [
    LatLng(-16.534705, -68.191620), // Esquina Sur-Este (abajo)
    LatLng(-16.534500, -68.191845), // Esquina Sur-Oeste (izquierda)
    LatLng(-16.534015, -68.191310), // Esquina Nor-Oeste (arriba)
    LatLng(-16.534220, -68.191085), // Esquina Nor-Este (derecha)
  ];

  /// Geocerca Rectangular Oficial de Parada B (Teleférico)
  /// Orientada sobre la cuadra de llegada y retorno en Teleférico (85 m x 28 m).
  static const List<LatLng> rectanguloParadaB = [
    LatLng(-16.518535, -68.151375),
    LatLng(-16.518415, -68.151615),
    LatLng(-16.517625, -68.151110),
    LatLng(-16.517745, -68.150870),
  ];

  /// Retorna el rectángulo de Parada A (Cruce Villadela), trasladándolo si
  /// [centroCustom] fue movido manualmente respecto a la coordenada oficial.
  static List<LatLng> obtenerRectanguloParadaA([LatLng? centroCustom]) {
    if (centroCustom == null) return rectanguloParadaA;
    final dLat = centroCustom.latitude - paradaAVilladela.latitude;
    final dLon = centroCustom.longitude - paradaAVilladela.longitude;
    if (dLat.abs() < 0.0005 && dLon.abs() < 0.0005) return rectanguloParadaA;
    return rectanguloParadaA
        .map((p) => LatLng(p.latitude + dLat, p.longitude + dLon))
        .toList();
  }

  /// Retorna el rectángulo de Parada B (Teleférico), trasladándolo si
  /// [centroCustom] fue movido manualmente respecto a la coordenada oficial.
  static List<LatLng> obtenerRectanguloParadaB([LatLng? centroCustom]) {
    if (centroCustom == null) return rectanguloParadaB;
    final dLat = centroCustom.latitude - paradaBTeleferico.latitude;
    final dLon = centroCustom.longitude - paradaBTeleferico.longitude;
    if (dLat.abs() < 0.0005 && dLon.abs() < 0.0005) return rectanguloParadaB;
    return rectanguloParadaB
        .map((p) => LatLng(p.latitude + dLat, p.longitude + dLon))
        .toList();
  }

  /// Determina si el punto GPS [p] está dentro del polígono/rectángulo [poligono]
  /// (incluyendo un margen de tolerancia GPS [margenMetros] respecto a los bordes).
  static bool estaDentroDeRectangulo(
    LatLng p,
    List<LatLng> poligono, {
    double margenMetros = 5.0,
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
}
