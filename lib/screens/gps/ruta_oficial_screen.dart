import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../domain/ruta_continental.dart';
import '../../services/asistencia_repo.dart';
import '../../services/database_helper.dart';
import '../../services/gps_service.dart';
import '../../services/sesion_service.dart';
import '../../widgets/app_snackbar.dart';

const _kVerdeOscuro = Color(0xFF02634C);
const _kMintBg = Color(0xFFE6F4F0);
const _kAmbar = Color(0xFFD97706);
const _kAmbarBg = Color(0xFFFEF3C7);
const _kAzulRect = Color(0xFF2563EB);
const _kVerdeActivo = Color(0xFF10B981);

enum _EstiloMapaRuta { satelite, calles }

enum _ModoTramo { completo, soloIda, soloVuelta }

/// Vista fija e inmutable de la Ruta Oficial del Sindicato Continental
/// (Grupo Trufi 101 - 127), con Geocerca Rectangular orientada sobre la calle
/// de Cruce Villadela (Parada A) y Teleférico (Parada B).
/// Cuando el conductor pisa el rectángulo de Cruce Villadela, registra su
/// asistencia del día y su paso por la parada.
class RutaOficialScreen extends StatefulWidget {
  const RutaOficialScreen({super.key});

  @override
  State<RutaOficialScreen> createState() => _RutaOficialScreenState();
}

class _RutaOficialScreenState extends State<RutaOficialScreen> {
  final MapController _mapController = MapController();
  _EstiloMapaRuta _estiloMapa = _EstiloMapaRuta.satelite;
  _ModoTramo _modoTramo = _ModoTramo.completo;
  bool _mapaListo = false;

  LatLng? _miUbicacion;
  StreamSubscription<Position>? _subGps;

  bool _dentroRectanguloA = false;
  bool _dentroRectanguloB = false;
  bool _asistenciaMarcadaHoy = false;
  bool _pasoVilladelaRegistrado = false;
  bool _pasoTelefericoRegistrado = false;
  String? _horaUltimoPasoA;
  String? _nombreConductorActivo;
  String? _idConductorActivo;
  int _vueltasRegistradasHoy = 0;
  bool _procesandoEvento = false;

  @override
  void initState() {
    super.initState();
    _inicializarConductorYEstado();
    _iniciarGpsEnVivo();
  }

  @override
  void dispose() {
    _subGps?.cancel();
    super.dispose();
  }

  Future<void> _inicializarConductorYEstado() async {
    String? idCond = SesionService.instance.idConductor;
    String? nombreCond = SesionService.instance.nombre;

    if (idCond == null || idCond.isEmpty) {
      final lista = await DatabaseHelper.instance.conductoresConAuto();
      if (lista.isNotEmpty) {
        idCond = lista.first['id_conductor']?.toString();
        nombreCond = lista.first['nombre']?.toString();
      }
    }

    if (idCond != null && idCond.isNotEmpty) {
      final hoy = DateTime.now().toIso8601String().substring(0, 10);
      final asist =
          await AsistenciaRepo.instance.obtenerAsistenciaHoy(idCond, hoy);
      final vueltas = await DatabaseHelper.instance.vueltasDetalle(fecha: hoy);
      final misVueltas =
          vueltas.where((v) => v['id_conductor'] == idCond).length;

      if (mounted) {
        setState(() {
          _idConductorActivo = idCond;
          _nombreConductorActivo = nombreCond ?? 'Conductor';
          _asistenciaMarcadaHoy = asist != null;
          _pasoVilladelaRegistrado = asist != null;
          _horaUltimoPasoA = asist?['hora_llegada']?.toString();
          _vueltasRegistradasHoy = misVueltas;
        });
      }
    }
  }

  Future<void> _iniciarGpsEnVivo() async {
    final ok = await GpsService.instance.verificarPermisos();
    if (!ok || !mounted) return;
    _subGps = GpsService.instance
        .obtenerStreamPosicion(distanceFilterM: 2)
        .listen(
      (pos) {
        if (!mounted) return;
        final punto = LatLng(pos.latitude, pos.longitude);
        _evaluarPosicionEnRectangulos(punto, precisionM: pos.accuracy);
      },
      onError: (err) {
        debugPrint('⚠️ Error en stream GPS de Ruta Oficial: ');
      },
    );
  }

  Future<void> _evaluarPosicionEnRectangulos(
    LatLng punto, {
    double precisionM = 5.0,
    bool esSimulacion = false,
  }) async {
    final enA = RutaContinental.estaDentroDeRectangulo(
      punto,
      RutaContinental.rectanguloParadaA,
      margenMetros: (precisionM * 0.4).clamp(2.0, 8.0),
    );
    final enB = RutaContinental.estaDentroDeRectangulo(
      punto,
      RutaContinental.rectanguloParadaB,
      margenMetros: (precisionM * 0.4).clamp(2.0, 8.0),
    );

    final entroRecienA = enA && !_dentroRectanguloA;
    final entroRecienB = enB && !_dentroRectanguloB;

    setState(() {
      _miUbicacion = punto;
      _dentroRectanguloA = enA;
      _dentroRectanguloB = enB;
    });

    if (entroRecienA) {
      await _alPisarRectanguloVilladela(
        punto: punto,
        precisionM: precisionM,
        esSimulacion: esSimulacion,
      );
    } else if (entroRecienB) {
      await _alPisarRectanguloTeleferico(
        punto: punto,
        precisionM: precisionM,
        esSimulacion: esSimulacion,
      );
    }
  }

  /// Se ejecuta automáticamente cuando el conductor pisa el rectángulo de Cruce Villadela (Parada A)
  Future<void> _alPisarRectanguloVilladela({
    required LatLng punto,
    required double precisionM,
    required bool esSimulacion,
  }) async {
    if (_procesandoEvento) return;
    _procesandoEvento = true;

    try {
      HapticFeedback.heavyImpact();
      SystemSound.play(SystemSoundType.click);

      final ahora = DateTime.now();
      final horaStr =
          '${ahora.hour.toString().padLeft(2, '0')}:${ahora.minute.toString().padLeft(2, '0')}';

      String mensajeEvento =
          '¡Pasó por Parada A (Cruce Villadela) a las $horaStr!';

      if (_idConductorActivo != null && _idConductorActivo!.isNotEmpty) {
        // 1. Si aún no marcó asistencia hoy, se la registra automáticamente al pisar el rectángulo
        if (!_asistenciaMarcadaHoy) {
          final puntoOficial =
              await DatabaseHelper.instance.obtenerPuntoAsistencia();
          final idPunto = puntoOficial?['id_punto']?.toString() ?? '';

          if (idPunto.isNotEmpty) {
            final res = await AsistenciaRepo.instance.registrarAsistenciaGps(
              idConductor: _idConductorActivo!,
              idPunto: idPunto,
              latitud: punto.latitude,
              longitud: punto.longitude,
              precisionM: precisionM,
              distanciaM: 0.0,
              esMock: false,
              horaSateliteConfiable: true,
              horaManual: esSimulacion ? horaStr : null,
            );
            if (res.exito) {
              _asistenciaMarcadaHoy = true;
              final est = res.asistencia?['estado']?.toString().toUpperCase() ??
                  'PRESENTE';
              mensajeEvento =
                  '¡Asistencia registrada ($est) y paso por Parada Cruce Villadela confirmado!';
            }
          }
        }

        // 2. Si ya había pasado por Teleférico (Parada B), completa la vuelta automáticamente
        if (_pasoTelefericoRegistrado) {
          await DatabaseHelper.instance.registrarVuelta(
            idConductor: _idConductorActivo!,
            tipo: 'normal',
          );
          _pasoTelefericoRegistrado = false;
          _vueltasRegistradasHoy++;
          mensajeEvento =
              '¡Vuelta #$_vueltasRegistradasHoy completada al pisar el rectángulo de Cruce Villadela!';
        }
      }

      if (mounted) {
        setState(() {
          _pasoVilladelaRegistrado = true;
          _horaUltimoPasoA = horaStr;
        });
        AppSnackBar.exito(context, mensajeEvento);
      }
    } finally {
      _procesandoEvento = false;
    }
  }

  Future<void> _alPisarRectanguloTeleferico({
    required LatLng punto,
    required double precisionM,
    required bool esSimulacion,
  }) async {
    if (_procesandoEvento) return;
    _procesandoEvento = true;
    try {
      HapticFeedback.mediumImpact();
      SystemSound.play(SystemSoundType.click);

      final ahora = DateTime.now();
      final horaStr =
          '${ahora.hour.toString().padLeft(2, '0')}:${ahora.minute.toString().padLeft(2, '0')}';

      String mensaje =
          '¡Paso por Parada B (Teleférico) registrado! Al retornar al rectángulo de Cruce Villadela sumará la vuelta.';

      if (_idConductorActivo != null &&
          _idConductorActivo!.isNotEmpty &&
          !_asistenciaMarcadaHoy) {
        final puntos = await DatabaseHelper.instance.obtenerPuntosControl(
          soloActivos: false,
        );
        final puntoB = puntos.firstWhere(
          (p) => !p['nombre'].toString().contains('Villadela'),
          orElse: () => puntos.isNotEmpty ? puntos.last : <String, dynamic>{},
        );
        final idPunto = puntoB['id_punto']?.toString() ?? '';
        if (idPunto.isNotEmpty) {
          final res = await AsistenciaRepo.instance.registrarAsistenciaGps(
            idConductor: _idConductorActivo!,
            idPunto: idPunto,
            latitud: punto.latitude,
            longitud: punto.longitude,
            precisionM: precisionM,
            distanciaM: 0.0,
            esMock: false,
            horaSateliteConfiable: true,
            horaManual: esSimulacion ? horaStr : null,
          );
          if (res.exito) {
            _asistenciaMarcadaHoy = true;
            final est = res.asistencia?['estado']?.toString().toUpperCase() ??
                'PRESENTE';
            mensaje =
                '¡Asistencia registrada ($est) y parada confirmada en el rectángulo de Teleférico (Parada B)!';
          }
        }
      }

      if (mounted) {
        setState(() {
          _pasoTelefericoRegistrado = true;
        });
        AppSnackBar.exito(context, mensaje);
      }
    } finally {
      _procesandoEvento = false;
    }
  }

  void _encuadrarRuta({_ModoTramo? modo}) {
    if (!_mapaListo) return;
    final m = modo ?? _modoTramo;
    final puntos = switch (m) {
      _ModoTramo.soloIda => RutaContinental.puntosIda,
      _ModoTramo.soloVuelta => RutaContinental.puntosVuelta,
      _ModoTramo.completo => RutaContinental.circuitoCompleto,
    };
    final bounds = LatLngBounds.fromPoints(puntos);
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.symmetric(horizontal: 42, vertical: 65),
      ),
    );
  }

  void _enfocarParada(LatLng coord) {
    if (!_mapaListo) return;
    _mapController.move(coord, 18.0);
  }

  void _centrarEnMiGps() {
    if (_miUbicacion != null && _mapaListo) {
      _mapController.move(_miUbicacion!, 17.8);
    } else {
      AppSnackBar.info(context, 'Obteniendo ubicación GPS del dispositivo...');
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final esSat = _estiloMapa == _EstiloMapaRuta.satelite;

    final mostrarIda =
        _modoTramo == _ModoTramo.completo || _modoTramo == _ModoTramo.soloIda;
    final mostrarVuelta = _modoTramo == _ModoTramo.completo ||
        _modoTramo == _ModoTramo.soloVuelta;

    double? distARectanguloA;
    double? distARectanguloB;
    if (_miUbicacion != null) {
      distARectanguloA = RutaContinental.distanciaAlRectanguloMetros(
        _miUbicacion!,
        RutaContinental.rectanguloParadaA,
      );
      distARectanguloB = RutaContinental.distanciaAlRectanguloMetros(
        _miUbicacion!,
        RutaContinental.rectanguloParadaB,
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // 1. ENCABEZADO CURVO VERDE CORPORATIVO
          _buildCurvedHeader(topPadding),

          // 2. SELECTOR DE TRAMO (CIRCUITO COMPLETO / IDA / VUELTA)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: _buildChipTramo(
                    titulo: 'Circuito Total',
                    subtitulo: '${RutaContinental.distanciaCircuitoKm} km',
                    activo: _modoTramo == _ModoTramo.completo,
                    colorActivo: _kVerdeOscuro,
                    bgActivo: _kMintBg,
                    icono: Icons.loop_rounded,
                    onTap: () {
                      setState(() => _modoTramo = _ModoTramo.completo);
                      _encuadrarRuta(modo: _ModoTramo.completo);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildChipTramo(
                    titulo: 'Ida (A → B)',
                    subtitulo: '${RutaContinental.distanciaIdaKm} km',
                    activo: _modoTramo == _ModoTramo.soloIda,
                    colorActivo: _kVerdeOscuro,
                    bgActivo: _kMintBg,
                    icono: Icons.trending_flat_rounded,
                    onTap: () {
                      setState(() => _modoTramo = _ModoTramo.soloIda);
                      _encuadrarRuta(modo: _ModoTramo.soloIda);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildChipTramo(
                    titulo: 'Vuelta (B → A)',
                    subtitulo: '${RutaContinental.distanciaVueltaKm} km',
                    activo: _modoTramo == _ModoTramo.soloVuelta,
                    colorActivo: _kAmbar,
                    bgActivo: _kAmbarBg,
                    icono: Icons.keyboard_return_rounded,
                    onTap: () {
                      setState(() => _modoTramo = _ModoTramo.soloVuelta);
                      _encuadrarRuta(modo: _ModoTramo.soloVuelta);
                    },
                  ),
                ),
              ],
            ),
          ),

          // 3. MAPA CON TRAZADO VIAL Y RECTÁNGULOS DE PARADA
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: RutaContinental.paradaAVilladela,
                    initialZoom: 17.5,
                    maxZoom: 21.0,
                    onMapReady: () {
                      _mapaListo = true;
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          _enfocarParada(RutaContinental.paradaAVilladela);
                        }
                      });
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: esSat
                          ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
                          : 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                      subdomains: const ['a', 'b', 'c', 'd'],
                      userAgentPackageName: 'com.example.continental',
                      maxNativeZoom: 19,
                      maxZoom: 21,
                    ),
                    if (esSat)
                      TileLayer(
                        urlTemplate:
                            'https://services.arcgisonline.com/ArcGIS/rest/services/Reference/World_Boundaries_and_Places/MapServer/tile/{z}/{y}/{x}',
                        userAgentPackageName: 'com.example.continental',
                        maxNativeZoom: 19,
                        maxZoom: 21,
                      ),

                    // Trazado Fijo de Calles (Geo Tracker)
                    PolylineLayer(
                      polylines: [
                        if (mostrarVuelta)
                          Polyline(
                            points: RutaContinental.puntosVuelta,
                            strokeWidth:
                                _modoTramo == _ModoTramo.soloVuelta ? 5.0 : 4.0,
                            color: _kAmbar,
                            borderStrokeWidth: 1.8,
                            borderColor: Colors.white,
                          ),
                        if (mostrarIda)
                          Polyline(
                            points: RutaContinental.puntosIda,
                            strokeWidth:
                                _modoTramo == _ModoTramo.soloIda ? 5.0 : 4.5,
                            color: _kVerdeOscuro,
                            borderStrokeWidth: 1.8,
                            borderColor: Colors.white,
                          ),
                      ],
                    ),

                    // GEOCERCAS RECTANGULARES ORIENTADAS EN LA CALLE (NO REDONDAS)
                    PolygonLayer(
                      polygons: [
                        // Rectángulo Parada A: Cruce Villadela
                        Polygon(
                          points: RutaContinental.rectanguloParadaA,
                          color: (_dentroRectanguloA
                                  ? _kVerdeActivo
                                  : _kAzulRect)
                              .withValues(alpha: 0.28),
                          borderColor:
                              _dentroRectanguloA ? _kVerdeActivo : _kAzulRect,
                          borderStrokeWidth: 3.2,
                        ),
                        // Rectángulo Parada B: Teleférico
                        Polygon(
                          points: RutaContinental.rectanguloParadaB,
                          color: (_dentroRectanguloB ? _kVerdeActivo : _kAmbar)
                              .withValues(alpha: 0.26),
                          borderColor:
                              _dentroRectanguloB ? _kVerdeActivo : _kAmbar,
                          borderStrokeWidth: 3.0,
                        ),
                      ],
                    ),

                    // Marcadores de Parada A, Parada B y GPS actual
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: RutaContinental.paradaAVilladela,
                          width: 155,
                          height: 62,
                          child: _buildPinOficial(
                            letra: 'A',
                            nombre: 'Cruce Villadela',
                            color: _dentroRectanguloA
                                ? _kVerdeActivo
                                : _kVerdeOscuro,
                            onTap: () => _enfocarParada(
                                RutaContinental.paradaAVilladela),
                          ),
                        ),
                        Marker(
                          point: RutaContinental.paradaBTeleferico,
                          width: 150,
                          height: 62,
                          child: _buildPinOficial(
                            letra: 'B',
                            nombre: 'Teleférico',
                            color: _kAmbar,
                            onTap: () => _enfocarParada(
                                RutaContinental.paradaBTeleferico),
                          ),
                        ),
                        if (_miUbicacion != null)
                          Marker(
                            point: _miUbicacion!,
                            width: 28,
                            height: 28,
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _dentroRectanguloA
                                    ? _kVerdeActivo
                                    : const Color(0xFF2563EB),
                                border:
                                    Border.all(color: Colors.white, width: 3),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black38,
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.directions_car_rounded,
                                size: 15,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),

                // Leyenda flotante arriba a la izquierda
                Positioned(
                  top: 12,
                  left: 14,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 12,
                              height: 4,
                              decoration: BoxDecoration(
                                color: _kVerdeOscuro,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Ida A → B (${RutaContinental.distanciaIdaKm} km)',
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 12,
                              height: 4,
                              decoration: BoxDecoration(
                                color: _kAmbar,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Vuelta B → A (${RutaContinental.distanciaVueltaKm} km)',
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Selector Satélite / Calles arriba a la derecha
                Positioned(
                  top: 12,
                  right: 14,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildBotonCapa(
                          icono: Icons.satellite_alt_rounded,
                          texto: 'Satélite',
                          activo: esSat,
                          onTap: () => setState(
                              () => _estiloMapa = _EstiloMapaRuta.satelite),
                        ),
                        _buildBotonCapa(
                          icono: Icons.map_outlined,
                          texto: 'Calles',
                          activo: !esSat,
                          onTap: () => setState(
                              () => _estiloMapa = _EstiloMapaRuta.calles),
                        ),
                      ],
                    ),
                  ),
                ),

                // Controles rápidos a la derecha
                Positioned(
                  top: 60,
                  right: 14,
                  child: Column(
                    children: [
                      _buildMiniFab(
                        icon: Icons.alt_route_rounded,
                        tooltip: 'Ver todo el circuito',
                        onTap: () => _encuadrarRuta(),
                      ),
                      const SizedBox(height: 8),
                      _buildMiniFab(
                        icon: Icons.my_location_rounded,
                        tooltip: 'Mi ubicación GPS',
                        onTap: _centrarEnMiGps,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 4. PANEL INFERIOR CON ESTADO DE PASO POR RECTÁNGULO Y ASISTENCIA
          _buildPanelFichaRuta(distARectanguloA, distARectanguloB),
        ],
      ),
    );
  }

  Widget _buildCurvedHeader(double topPadding) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: _kVerdeOscuro,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(32),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, topPadding + 8, 16, 16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  tooltip: 'Volver',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => Navigator.pop(context),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.zoom_out_map_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      tooltip: 'Ver circuito completo',
                      onPressed: () => _encuadrarRuta(),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(13),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Tooltip(
                        message:
                            SesionService.instance.nombre ?? 'Usuario actual',
                        child: const Icon(
                          Icons.person_rounded,
                          color: _kVerdeOscuro,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ruta Oficial de Vueltas',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.3,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Geocerca Rectangular en Parada Cruce Villadela (A) y Teleférico (B)',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPanelFichaRuta(double? distA, double? distB) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        16,
        10,
        16,
        MediaQuery.of(context).padding.bottom > 0
            ? MediaQuery.of(context).padding.bottom + 6
            : 14,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFCBD5E1),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 8),

          // Banner de estado en vivo de Asistencia + Paso por Rectángulo Cruce Villadela
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _pasoVilladelaRegistrado
                  ? const Color(0xFFECFDF5)
                  : const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _pasoVilladelaRegistrado
                    ? const Color(0xFF10B981)
                    : const Color(0xFF93C5FD),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _pasoVilladelaRegistrado
                      ? Icons.verified_rounded
                      : Icons.crop_landscape_rounded,
                  color: _pasoVilladelaRegistrado
                      ? const Color(0xFF059669)
                      : _kAzulRect,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _pasoVilladelaRegistrado
                            ? 'Asistió y pasó por Parada Cruce Villadela (${_horaUltimoPasoA ?? "Hoy"})'
                            : 'Zona Rectangular Cruce Villadela Activa',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: _pasoVilladelaRegistrado
                              ? const Color(0xFF065F46)
                              : const Color(0xFF1E3A8A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _pasoVilladelaRegistrado
                            ? 'Conductor: ${_nombreConductorActivo ?? "Activo"} • Vueltas hoy: $_vueltasRegistradasHoy'
                            : 'Al pisar el rectángulo azul se marca asistencia y paso por Parada A',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: _pasoVilladelaRegistrado
                              ? const Color(0xFF047857)
                              : const Color(0xFF1D4ED8),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Tarjetas de Parada A y Parada B fijas (tocables para enfocar)
          Row(
            children: [
              Expanded(
                child: _buildTarjetaParadaFija(
                  letra: 'A',
                  titulo: 'Cruce Villadela',
                  subtitulo: _dentroRectanguloA
                      ? '¡DENTRO DEL RECTÁNGULO!'
                      : 'Rectángulo 26×17 m',
                  coordenadas: '-16.57569, -68.23765',
                  distanciaActual: distA,
                  color: _dentroRectanguloA ? _kVerdeActivo : _kAzulRect,
                  bgColor: _kMintBg,
                  onTap: () =>
                      _enfocarParada(RutaContinental.paradaAVilladela),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildTarjetaParadaFija(
                  letra: 'B',
                  titulo: 'Teleférico',
                  subtitulo: _dentroRectanguloB
                      ? '¡DENTRO DEL RECTÁNGULO!'
                      : 'Rectángulo 26×17 m',
                  coordenadas: '-16.57618, -68.23820',
                  distanciaActual: distB,
                  color: _kAmbar,
                  bgColor: _kAmbarBg,
                  onTap: () =>
                      _enfocarParada(RutaContinental.paradaBTeleferico),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTarjetaParadaFija({
    required String letra,
    required String titulo,
    required String subtitulo,
    required String coordenadas,
    required double? distanciaActual,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: bgColor.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.45), width: 1.2),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(7),
              ),
              alignment: Alignment.center,
              child: Text(
                letra,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    titulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    distanciaActual != null && distanciaActual > 0
                        ? 'A ${GpsService.formatearDistancia(distanciaActual)}'
                        : subtitulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  Text(
                    coordenadas,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 9.5,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChipTramo({
    required String titulo,
    required String subtitulo,
    required bool activo,
    required Color colorActivo,
    required Color bgActivo,
    required IconData icono,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        decoration: BoxDecoration(
          color: activo ? bgActivo : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: activo ? colorActivo : const Color(0xFFE2E8F0),
            width: activo ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icono,
                  size: 14,
                  color: activo ? colorActivo : const Color(0xFF64748B),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    titulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: activo ? FontWeight.w800 : FontWeight.w600,
                      color: activo ? colorActivo : const Color(0xFF475569),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 1),
            Text(
              subtitulo,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: activo ? colorActivo : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPinOficial({
    required String letra,
    required String nombre,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color, width: 1.8),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 8,
                  backgroundColor: color,
                  child: Text(
                    letra,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    nombre,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.location_on_rounded,
            color: color,
            size: 30,
          ),
        ],
      ),
    );
  }

  Widget _buildBotonCapa({
    required IconData icono,
    required String texto,
    required bool activo,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: activo ? _kMintBg : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(
              icono,
              size: 14,
              color: activo ? _kVerdeOscuro : const Color(0xFF64748B),
            ),
            const SizedBox(width: 4),
            Text(
              texto,
              style: TextStyle(
                color: activo ? _kVerdeOscuro : const Color(0xFF64748B),
                fontWeight: activo ? FontWeight.w800 : FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniFab({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 3,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Tooltip(
          message: tooltip,
          child: SizedBox(
            width: 38,
            height: 38,
            child: Icon(icon, color: _kVerdeOscuro, size: 20),
          ),
        ),
      ),
    );
  }
}
