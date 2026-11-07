// ============================================================================
// PRUEBAS ERROR 2 — Conteo automático de vueltas A → B → A
//
// Se prueban sobre GpsTrackingService (el servicio singleton que YA NO vive
// en el State de una pantalla):
//  1. Ciclo completo A → B → A = 1 vuelta registrada.
//  2. El estado del tramo se PERSISTE (SQLite en producción) y se RECUPERA:
//     'completando_A' sigue pendiente de volver a A.
//  3. Los rebotes del GPS (entrar/salir 46 m) NO generan dobles eventos.
//  4. Geocerca circular de diámetro ≥ 90 m: a 40 km/h con lecturas cada 2 s
//     (salto ~22 m) es imposible "saltarse" la parada sin registrar el paso.
//  5. La recapitulación inválida (día distinto / otro conductor) arranca limpia.
// ============================================================================
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';import 'package:continental/domain/puntos_oficiales.dart';
import 'package:continental/domain/ruta_continental.dart';
import 'package:continental/services/gps_tracking_service.dart';

/// Repositorio en memoria para aislar la máquina de estados de SQLite real.
class RepositorioFalso implements EstadoCircuitoRepositorio {
  EstadoCircuitoPersistente? _guardado;
  int escrituras = 0;

  @override
  Future<EstadoCircuitoPersistente?> cargar() async => _guardado;

  @override
  Future<void> guardar(EstadoCircuitoPersistente estado) async {
    _guardado = estado;
    escrituras++;
  }
}

/// Repositorio que devuelve SIEMPRE un estado fijo (simula datos guardados).
class RepositorioViejo implements EstadoCircuitoRepositorio {
  final EstadoCircuitoPersistente estado;
  const RepositorioViejo(this.estado);

  @override
  Future<EstadoCircuitoPersistente?> cargar() async => estado;

  @override
  Future<void> guardar(EstadoCircuitoPersistente e) async {}
}

/// Punto a [metros] del centro (vértice del anillo dibujable del mapa).
LatLng aMetro(LatLng centro, double metros) =>
    RutaContinental.anilloGeocerca(centro, metros, lados: 8)[5];

LatLng get paradaA => PuntosOficiales.paradaAVilladela;
LatLng get paradaB => PuntosOficiales.paradaBTeleferico;
LatLng get puntoMedio => LatLng(
      (paradaA.latitude + paradaB.latitude) / 2,
      (paradaA.longitude + paradaB.longitude) / 2,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late RepositorioFalso repo;
  late GpsTrackingService servicio;
  final vueltasRegistradas = <String>[];

  setUp(() {
    repo = RepositorioFalso();
    vueltasRegistradas.clear();
    servicio = GpsTrackingService.instance;
    servicio.reiniciarParaPruebas();
    servicio.repositorio = repo;
    servicio.alCompletarVueltaOverride = (idConductor) async {
      vueltasRegistradas.add(idConductor);
    };
    servicio.idConductorParaPruebas = 'conductor-test';
    servicio.setRadioVueltasParaPruebas(45.0);
  });

  test('Ciclo completo A → B → A registra UNA vuelta y persiste el estado',
      () async {
    // 1. El chofer entra a la Parada A
    final evA = await servicio.procesarPosicion(paradaA);
    expect(evA?.tipo, 'paso_A');
    expect(servicio.estadoCircuito.value, EstadoCircuito.esperandoRetornoB);
    expect(repo.escrituras, 1);

    // 1b. Repetir la lectura (rebote a 35 m) NO genera otro paso_A
    final evA2 = await servicio.procesarPosicion(aMetro(paradaA, 35));
    expect(evA2, isNull);
    expect(repo.escrituras, 1);

    // 2. Cruzar la mitad del tramo: sin eventos
    final evMedio = await servicio.procesarPosicion(puntoMedio);
    expect(evMedio, isNull);

    // 3. Llega a la Parada B
    final evB = await servicio.procesarPosicion(paradaB);
    expect(evB?.tipo, 'paso_B');
    expect(servicio.estadoCircuito.value, EstadoCircuito.completandoA);

    // 3b. Rebote en B: sin otro evento
    final evB2 = await servicio.procesarPosicion(aMetro(paradaB, 35));
    expect(evB2, isNull);

    // 4. Regresa a la Parada A → ¡VUELTA COMPLETA!
    final evVuelta = await servicio.procesarPosicion(paradaA);
    expect(evVuelta?.tipo, 'vuelta_completada');
    expect(vueltasRegistradas, ['conductor-test']);
    expect(servicio.vueltasHoy.value, 1);

    // 5. La máquina queda lista inmediatamente para la siguiente vuelta
    expect(servicio.estadoCircuito.value, EstadoCircuito.esperandoRetornoB);
  });

  test('rebotes pequeños del GPS (46 m < 1.5x radio = 67.5 m) no duplican',
      () async {
    await servicio.procesarPosicion(paradaA); // paso_A
    // "Salto" de señal a 46 m y regreso al centro:
    await servicio.procesarPosicion(aMetro(paradaA, 46));
    final ev = await servicio.procesarPosicion(paradaA);
    expect(ev, isNull);
    expect(servicio.estadoCircuito.value, EstadoCircuito.esperandoRetornoB);
  });

  test('sonarse A↔B alternadamente SIN cruzar el tramo no suma vueltas',
      () async {
    // En producción A y B están a ~4.6 km; con el estado esperandoRetornoB un
    // A fantasma no suma: sólo B suma el tramo y sólo A-cerrada suma vuelta.
    await servicio.procesarPosicion(paradaA);
    // Intentar "completar vuelta" pisando A sin haber pasado por B:
    final ev = await servicio.procesarPosicion(aMetro(paradaA, 35));
    expect(ev, isNull);
    expect(vueltasRegistradas, isEmpty);
  });

  test('geocerca circular ≥ 90 m de diámetro es insaltable a 40 km/h', () {
    const velocidadKmh = 40.0;
    const intervaloLecturasS = 2.0;
    final saltoMaximoM = velocidadKmh / 3.6 * intervaloLecturasS;
    expect(saltoMaximoM, lessThan(2 * PuntosOficiales.radioMinimoVueltasM));
    expect(2 * PuntosOficiales.radioMinimoVueltasM, greaterThanOrEqualTo(90.0));
  });

  test('el estado "completando_A" sobrevive el cierre/reinicio de la app',
      () async {
    // Chofer pisó A y B (luego cerró la app / bloqueó el teléfono)
    await servicio.procesarPosicion(paradaA);
    await servicio.procesarPosicion(paradaB);
    expect(servicio.estadoCircuito.value, EstadoCircuito.completandoA);
    final persistido = await repo.cargar();
    expect(persistido!.estado.clave, 'completando_A');
    expect(persistido.idConductor, 'conductor-test');

    // REINICIO: la máquina carga del repositorio (situación real de iniciar())
    final cargado = await repo.cargar();
    final hoy = DateTime.now().toIso8601String().substring(0, 10);
    final restaurado = GpsTrackingService.decidirEstadoInicial(
        cargado, 'conductor-test', hoy);
    expect(restaurado.estado, EstadoCircuito.completandoA);

    // Al volver a Parada A se cierra la vuelta pendiente
    final ev = await servicio.procesarPosicion(paradaA);
    expect(ev?.tipo, 'vuelta_completada');
    expect(vueltasRegistradas, ['conductor-test']);
  });

  test('decidirEstadoInicial: estado de OTRO DÍA reinicia a sinTramo', () {
    // (Es la regla que usa iniciar() para no arrastrar circuitos de ayer.)
    final deAyer = EstadoCircuitoPersistente(
      estado: EstadoCircuito.completandoA,
      fecha: '2020-01-01',
      idConductor: 'conductor-test',
    );
    final hoy = DateTime.now().toIso8601String().substring(0, 10);
    final decidido =
        GpsTrackingService.decidirEstadoInicial(deAyer, 'conductor-test', hoy);
    expect(decidido.estado, EstadoCircuito.sinTramo);
    expect(decidido.fecha, hoy);
  });

  test('decidirEstadoInicial: estado de OTRO CONDUCTOR reinicia a sinTramo',
      () {
    final deOtro = EstadoCircuitoPersistente(
      estado: EstadoCircuito.completandoA,
      fecha: DateTime.now().toIso8601String().substring(0, 10),
      idConductor: 'otro-conductor',
    );
    final hoy = DateTime.now().toIso8601String().substring(0, 10);
    final decidido =
        GpsTrackingService.decidirEstadoInicial(deOtro, 'conductor-test', hoy);
    expect(decidido.estado, EstadoCircuito.sinTramo);
  });

  test('decidirEstadoInicial: estado del MISMO conductor y de HOY se retoma',
      () {
    final hoy = DateTime.now().toIso8601String().substring(0, 10);
    final deHoy = EstadoCircuitoPersistente(
      estado: EstadoCircuito.esperandoRetornoB,
      fecha: hoy,
      idConductor: 'conductor-test',
    );
    final decidido =
        GpsTrackingService.decidirEstadoInicial(deHoy, 'conductor-test', hoy);
    expect(decidido.estado, EstadoCircuito.esperandoRetornoB);
  });

  test('la clave estable persistida es "esperando_retorno_B" / "completando_A"',
      () {
    expect(EstadoCircuito.esperandoRetornoB.clave, 'esperando_retorno_B');
    expect(EstadoCircuito.completandoA.clave, 'completando_A');
    expect(EstadoCircuito.sinTramo.clave, '');
    expect(
      EstadoCircuitoX.desdeClave('esperando_retorno_B'),
      EstadoCircuito.esperandoRetornoB,
    );
    expect(
      EstadoCircuitoX.desdeClave('completando_A'),
      EstadoCircuito.completandoA,
    );
    expect(EstadoCircuitoX.desdeClave('loquesea'), EstadoCircuito.sinTramo);
  });
}
