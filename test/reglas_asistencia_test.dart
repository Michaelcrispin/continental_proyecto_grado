import 'package:flutter_test/flutter_test.dart';
import 'package:continental/domain/reglas_asistencia.dart';

void main() {
  group('ReglasAsistencia - Evaluación de Horario y Tardanza', () {
    test('Llegada a las 07:00 debe ser presente sin sanción', () {
      final res = ReglasAsistencia.evaluarLlegada(horaLlegada: '07:00');
      expect(res.esPresente, isTrue);
      expect(res.esTardanza, isFalse);
      expect(res.minutosRetraso, equals(0));
      expect(res.vueltasSancion, equals(0));
      expect(res.generaSancion, isFalse);
    });

    test('Llegada a las 07:59 debe ser presente sin sanción', () {
      final res = ReglasAsistencia.evaluarLlegada(horaLlegada: '07:59');
      expect(res.esPresente, isTrue);
      expect(res.minutosRetraso, equals(0));
      expect(res.vueltasSancion, equals(0));
    });

    test('Llegada exacta al límite 08:00 debe ser presente sin sanción', () {
      final res = ReglasAsistencia.evaluarLlegada(horaLlegada: '08:00');
      expect(res.esPresente, isTrue);
      expect(res.minutosRetraso, equals(0));
      expect(res.vueltasSancion, equals(0));
      expect(res.generaSancion, isFalse);
    });

    test('Llegada a las 08:01 debe ser tardanza con 1 min de retraso y 2 vueltas de castigo', () {
      final res = ReglasAsistencia.evaluarLlegada(horaLlegada: '08:01');
      expect(res.esPresente, isFalse);
      expect(res.esTardanza, isTrue);
      expect(res.minutosRetraso, equals(1));
      expect(res.vueltasSancion, equals(2));
      expect(res.generaSancion, isTrue);
      expect(res.motivoSancion, contains('1 min de retraso'));
    });

    test('Llegada a las 08:45 debe ser tardanza con 45 min de retraso y 2 vueltas de castigo', () {
      final res = ReglasAsistencia.evaluarLlegada(horaLlegada: '08:45');
      expect(res.esTardanza, isTrue);
      expect(res.minutosRetraso, equals(45));
      expect(res.vueltasSancion, equals(2));
      expect(res.generaSancion, isTrue);
    });
  });

  group('ReglasAsistencia - Geocercas y Distancia Haversine', () {
    // Coordenadas oficiales de Cruce Villadela
    const latVilladela = -16.53453;
    const lonVilladela = -68.19071;

    test('Distancia a las mismas coordenadas debe ser 0', () {
      final d = ReglasAsistencia.calcularDistanciaMetros(
        lat1: latVilladela,
        lon1: lonVilladela,
        lat2: latVilladela,
        lon2: lonVilladela,
      );
      expect(d, closeTo(0.0, 0.001));
      expect(
        ReglasAsistencia.estaDentroDeGeocerca(
          latUsuario: latVilladela,
          lonUsuario: lonVilladela,
          latPunto: latVilladela,
          lonPunto: lonVilladela,
          radioMetros: 100,
        ),
        isTrue,
      );
    });

    test('Ubicación a 40 metros debe estar dentro de geocerca de 100m', () {
      // Un desplazamiento de ~0.0003 grados en latitud son aprox 33 metros
      final latCerca = latVilladela + 0.0003;
      final d = ReglasAsistencia.calcularDistanciaMetros(
        lat1: latVilladela,
        lon1: lonVilladela,
        lat2: latCerca,
        lon2: lonVilladela,
      );
      expect(d, lessThan(100));
      expect(
        ReglasAsistencia.estaDentroDeGeocerca(
          latUsuario: latCerca,
          lonUsuario: lonVilladela,
          latPunto: latVilladela,
          lonPunto: lonVilladela,
          radioMetros: 100,
        ),
        isTrue,
      );
    });

    test('Teleférico Amarillo (-16.5050, -68.1635) está fuera de la geocerca de Cruce Villadela', () {
      const latTeleferico = -16.5050;
      const lonTeleferico = -68.1635;

      final d = ReglasAsistencia.calcularDistanciaMetros(
        lat1: latVilladela,
        lon1: lonVilladela,
        lat2: latTeleferico,
        lon2: lonTeleferico,
      );
      // Entre Cruce Villadela y Mirador hay aproximadamente 4 a 5 km
      expect(d, greaterThan(3500));
      expect(
        ReglasAsistencia.estaDentroDeGeocerca(
          latUsuario: latTeleferico,
          lonUsuario: lonTeleferico,
          latPunto: latVilladela,
          lonPunto: lonVilladela,
          radioMetros: 100,
        ),
        isFalse,
      );
    });
  });

  group('ReglasAsistencia - Ventana de Castigo Nocturno (21:00)', () {
    test('A las 20:59 no cuenta como castigo nocturno', () {
      expect(ReglasAsistencia.esHoraCastigo(horaActual: '20:59'), isFalse);
    });

    test('A las 21:00 en punto inicia el horario de castigo', () {
      expect(ReglasAsistencia.esHoraCastigo(horaActual: '21:00'), isTrue);
    });

    test('A las 22:30 es horario de castigo', () {
      expect(ReglasAsistencia.esHoraCastigo(horaActual: '22:30'), isTrue);
    });
  });
}
