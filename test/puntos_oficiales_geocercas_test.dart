// ============================================================================
// PRUEBAS ERROR 1 — "FUERA DE RADIO" por coordenadas desfasadas
//
// Garantías que se verifican:
//  1. Existe UNA ÚNICA fuente de coordenadas (PuntosOficiales) y
//     RutaContinental apunta al MISMO objeto que esa fuente.
//  2. La Parada A (Cruce Villadela) es la coordenada REAL capturada el
//     5 nov 2026 con Geo Tracker (-16.53454833, -68.191605), NO la del
//     circuito de prueba GPX (-16.57568833, -68.23764500).
//  3. Ningún archivo de lib/ contiene las coordenadas "quemadas" de la
//     prueba GPX desfasada.
//  4. Una posición GPS real a 45 m del centro queda DENTRO de la geocerca
//     circular (ya no existe rectángulo microscópico de 8 m).
// ============================================================================
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:continental/domain/puntos_oficiales.dart';
import 'package:continental/domain/reglas_asistencia.dart';
import 'package:continental/domain/ruta_continental.dart';

void main() {
  group('Fuente única de coordenadas oficiales', () {
    test('RutaContinental usa EXACTAMENTE PuntosOficiales (mismo objeto)', () {
      expect(identical(RutaContinental.paradaAVilladela,
          PuntosOficiales.paradaAVilladela), isTrue,
          reason:
              'paradaAVilladela debe ser la MISMA constante const que la fuente única');
      expect(identical(RutaContinental.paradaBTeleferico,
          PuntosOficiales.paradaBTeleferico), isTrue,
          reason:
              'paradaBTeleferico debe ser la MISMA constante const que la fuente única');
    });

    test('Parada A = Cruce Villadela real del GPX del 5 nov (−16.53454833, −68.191605)',
        () {
      final a = PuntosOficiales.paradaAVilladela;
      expect(a.latitude, closeTo(-16.53454833, 1e-9));
      expect(a.longitude, closeTo(-68.191605, 1e-9));
    });

    test('Parada B = Teleférico Amarillo real del GPX del 5 nov (−16.51834167, −68.15143667)',
        () {
      final b = PuntosOficiales.paradaBTeleferico;
      expect(b.latitude, closeTo(-16.51834167, 1e-9));
      expect(b.longitude, closeTo(-68.15143667, 1e-9));
    });

    test('NO existe la coordenada desfasada del GPX de prueba '
        '(−16.57568833, −68.23764500) en ninguna parte de lib/', () {
      final heridas = <String>[];
      for (final entidad in ['16.5756', '68.2376', '-16.5761', '68.2382']) {
        final res = Process.runSync(
          'powershell',
          [
            '-Command',
            "Get-ChildItem -Path lib -Recurse -Filter *.dart | "
                "Select-String -Pattern '$entidad' | Measure-Object | "
                "Select-Object -ExpandProperty Count",
          ],
        );
        final conteo = int.tryParse(res.stdout.toString().trim()) ?? -1;
        heridas.add('$entidad -> $conteo');
        expect(conteo, 0, reason: 'Aún hay coordenadas quemadas $entidad');
      }
      // Si algo falló al correr PowerShell, el mensaje del test lo muestra.
      // ignore: avoid_print
      print('Verificación de coordenadas quemadas: $heridas');
    });
  });

  group('Distancia real entre paradas (Haversine)', () {
    test('A→B distancia directa ≈ 4.2-5.2 km (ruta real ~7.15 km por vía)',
        () {
      final d = PuntosOficiales.distanciaABMetros;
      expect(d, greaterThan(4200), reason: 'ya no puede ser un circuito de 75 m');
      expect(d, lessThan(5200));
    });

    test('distanciaCircuitoKm es el doble del tramo A→B', () {
      final ida = RutaContinental.distanciaIdaKm;
      final vuelta = RutaContinental.distanciaVueltaKm;
      final circuito = RutaContinental.distanciaCircuitoKm;
      expect(circuito, closeTo(2 * ida, 1e-9));
      expect(vuelta, closeTo(ida, 1e-9));
      expect(circuito, greaterThan(8.0), reason: 'circuito real > 8 km');
    });
  });

  group('Geocerca circular Haversine (ya no rectángulo microscópico)', () {
    final centroA = PuntosOficiales.paradaAVilladela;

    test('radio mínimo de vueltas está entre 30 y 50 m', () {
      expect(PuntosOficiales.radioMinimoVueltasM, greaterThanOrEqualTo(30.0));
      expect(PuntosOficiales.radioMinimoVueltasM, lessThanOrEqualTo(50.0));
    });

    test('punto a 40 m del centro está DENTRO y a 200 m FUERA', () {
      final dentro = RutaContinental.anilloGeocerca(centroA, 40.0).first;
      final fuera = RutaContinental.anilloGeocerca(centroA, 200.0).first;

      expect(
        RutaContinental.estaDentroDeGeocercaCircular(dentro, centroA, 45.0),
        isTrue,
      );
      expect(
        RutaContinental.estaDentroDeGeocercaCircular(fuera, centroA, 45.0),
        isFalse,
      );
    });

    test('el margen de precisión del GPS absuelve desvíos de precisión (±accuracy)',
        () {
      final a46 = RutaContinental.anilloGeocerca(centroA, 46.0).first;
      expect(
        RutaContinental.estaDentroDeGeocercaCircular(
          a46,
          centroA,
          45.0,
          margenMetros: 10.0,
        ),
        isTrue,
        reason: '46-10 = 36 m ≤ 45: una lectura con ±10 m de error sigue válida',
      );
      expect(
        RutaContinental.estaDentroDeGeocercaCircular(
          a46,
          centroA,
          45.0,
          margenMetros: 0.0,
        ),
        isFalse,
        reason: '46 m > 45: sin margen, fuera del radio',
      );
    });

    test('el anillo dibujado en el mapa respeta el radio pedido (±2%)', () {
      final anillo = RutaContinental.anilloGeocerca(centroA, 45.0, lados: 12);
      expect(anillo.length, 12);
      for (final p in anillo) {
        final d = ReglasAsistencia.calcularDistanciaMetros(
          lat1: p.latitude,
          lon1: p.longitude,
          lat2: centroA.latitude,
          lon2: centroA.longitude,
        );
        expect(d, closeTo(45.0, 1.0));
      }
    });

    test('radioEfectivoVueltas nunca permite radios de 8-20 m', () {
      expect(RutaContinental.radioEfectivoVueltas(0), 45.0);
      expect(RutaContinental.radioEfectivoVueltas(8), 45.0);
      expect(RutaContinental.radioEfectivoVueltas(20), 45.0);
      expect(RutaContinental.radioEfectivoVueltas(80), 80.0);
      expect(RutaContinental.radioEfectivoVueltas(400), 300.0);
    });
  });

  group('Caso de uso real: chofer llega a Cruce Villadela', () {
    test('un GPS con ±12 m de error a 30 m del centro marca DENTRO '
        '(ERROR 1 resuelto: fue el desfasaje de 6 km lo que lo bloqueaba)', () {
      final puntoBueno =
          RutaContinental.anilloGeocerca(PuntosOficiales.paradaAVilladela, 30).first;      // Con radio de asistencia 100 m y margen ±12 m
      expect(
        ReglasAsistencia.estaDentroDeGeocerca(
          latUsuario: puntoBueno.latitude,
          lonUsuario: puntoBueno.longitude,
          latPunto: PuntosOficiales.paradaAVilladela.latitude,
          lonPunto: PuntosOficiales.paradaAVilladela.longitude,
          radioMetros: 100.0,
          accuracyMetros: 12.0,
        ),
        isTrue,
      );
    });

    test('la distancia desde el registro del circuito de prueba (−16.5757) a la '
        'Parada A real es ≈ 6 km: por eso antes SIEMPRE daba FUERA DEL RADIO',
        () {
      final puntoAntes = const LatLng(-16.57568833, -68.23764500);
      final d = ReglasAsistencia.calcularDistanciaMetros(
        lat1: puntoAntes.latitude,
        lon1: puntoAntes.longitude,
        lat2: PuntosOficiales.paradaAVilladela.latitude,
        lon2: PuntosOficiales.paradaAVilladela.longitude,
      );
      expect(d, greaterThan(5500), reason:
          'el desfasaje histórico ronda los 6 km y es lo que hoy ESTÁ corregido');
    });
  });
}
