import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../domain/reglas_asistencia.dart';
import '../../domain/ruta_continental.dart';
import '../../services/asistencia_repo.dart';
import '../../services/database_helper.dart';
import '../../services/gps_service.dart';
import '../../services/sesion_service.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/ubicacion_azul.dart';

const _kVerdeOscuro = Color(0xFF02634C);
const _kMintBg = Color(0xFFE6F4F0);

enum _EstiloMapa { satelite, calles }

/// Pantalla para calibrar y configurar Parada A (Cruce Villadela) y Parada B (Teleférico Amarillo)
/// Rediseñada fielmente al sistema de diseño corporativo verde con cabecera curva y tarjetas modulares.
class PuntosControlScreen extends StatefulWidget {
  const PuntosControlScreen({super.key});

  @override
  State<PuntosControlScreen> createState() => _PuntosControlScreenState();
}

class _PuntosControlScreenState extends State<PuntosControlScreen> {
  final MapController _mapController = MapController();
  final EstadoGeocerca _estadoGeocerca = EstadoGeocerca();

  _EstiloMapa _estiloMapa = _EstiloMapa.satelite;
  List<Map<String, dynamic>> _puntos = [];
  Map<String, dynamic>? _puntoSeleccionado;
  double _radioM = 100.0;
  LatLng? _coordenadaTemp;
  LatLng? _miUbicacionActual;
  double? _precisionActual;
  double? _distanciaActualM;
  bool _dentroConfirmado = false;
  bool _senalDebil = false;
  bool _cargando = true;
  bool _guardando = false;
  bool _guardado = true; // true = no hay cambios pendientes de guardar
  bool _promediando = false;
  int _muestrasPromedio = 0;
  int _segundosRestantesPromedio = 0;
  StreamSubscription<Position>? _subGps;
  StreamSubscription<CompassEvent>? _subBrujula;

  /// Rumbo actual en grados (0 = norte). Se usa para el visor del punto azul.
  double _rumboGrados = 0;
  final ValueNotifier<double> _rumboNotifier = ValueNotifier<double>(0);
  bool _rumboValido = false;
  bool _brujulaDisponible = false;

  static const List<int> _radiosRapidos = [2, 5, 10, 30, 50, 100, 150];

  @override
  void initState() {
    super.initState();
    _cargarPuntos();
    _iniciarEscuchaGpsEnVivo();
    _iniciarBrujula();
  }

  @override
  void dispose() {
    _subGps?.cancel();
    _subBrujula?.cancel();
    _rumboNotifier.dispose();
    super.dispose();
  }

  /// Escucha la brújula del celular para saber hacia dónde mira el usuario.
  /// Si el dispositivo no tiene brújula (escritorio, emulador), se usa el
  /// rumbo del GPS cuando hay movimiento.
  void _iniciarBrujula() {
    try {
      final stream = FlutterCompass.events;
      if (stream == null) {
        _brujulaDisponible = false;
        return;
      }
      _subBrujula = stream.listen(
        (event) {
          final heading = event.heading;
          if (heading == null || heading.isNaN) return;
          _brujulaDisponible = true;
          _aplicarRumbo(heading);
        },
        onError: (_) {
          _brujulaDisponible = false;
        },
        cancelOnError: false,
      );
    } catch (_) {
      _brujulaDisponible = false;
    }
  }

  /// Suaviza el rumbo de forma circular (evita el salto 359° → 0°).
  void _aplicarRumbo(double nuevo) {
    if (!mounted) return;
    final delta = ((nuevo - _rumboGrados + 540) % 360) - 180;
    _rumboGrados = (_rumboGrados + delta * 0.30 + 360) % 360;
    _rumboNotifier.value = _rumboGrados;
    if (!_rumboValido) {
      setState(() => _rumboValido = true);
    }
  }

  Future<void> _iniciarEscuchaGpsEnVivo() async {
    final ok = await GpsService.instance.verificarPermisos();
    if (!ok || !mounted) return;

    await _subGps?.cancel();
    _subGps = GpsService.instance.obtenerStreamPosicion(distanceFilterM: 0).listen((
      pos,
    ) {
      if (!mounted) return;
      setState(() {
        // Punto azul estilo Google Maps, suavizado para que no tiemble quieto.
        _miUbicacionActual = _filtrarUbicacion(pos);
        _precisionActual = pos.accuracy;
        _senalDebil = pos.accuracy > GpsService.umbralSenalDebilMetros;

        // Sin brújula (escritorio/emulador) se usa el rumbo de avance del GPS,
        // solo cuando hay movimiento real; quieto se queda con el último rumbo.
        if (!_brujulaDisponible && pos.speed > 1.2 && pos.heading >= 0) {
          final delta = ((pos.heading - _rumboGrados + 540) % 360) - 180;
          _rumboGrados = (_rumboGrados + delta * 0.35 + 360) % 360;
          _rumboNotifier.value = _rumboGrados;
          _rumboValido = true;
        }

        if (!_senalDebil) {
          _recalcularDistancia(confirmarConsecutivas: true);
        } else if (_coordenadaTemp != null) {
          _distanciaActualM = ReglasAsistencia.calcularDistanciaMetros(
            lat1: _miUbicacionActual!.latitude,
            lon1: _miUbicacionActual!.longitude,
            lat2: _coordenadaTemp!.latitude,
            lon2: _coordenadaTemp!.longitude,
          );
        }
      });
    });
  }

  /// Filtra la deriva del GPS igual que en la vista "GPS en vivo":
  /// quieto ignora saltos menores a 6 m y caminando menores a 2.5 m.
  LatLng _filtrarUbicacion(Position pos) {
    final previa = _miUbicacionActual;
    final cruda = LatLng(pos.latitude, pos.longitude);
    if (previa == null) return cruda;

    final d = ReglasAsistencia.calcularDistanciaMetros(
      lat1: previa.latitude,
      lon1: previa.longitude,
      lat2: cruda.latitude,
      lon2: cruda.longitude,
    );
    final quieto = pos.speed >= 0 && pos.speed < 0.6;
    if (d < (quieto ? 6.0 : 2.5)) return previa;

    final alpha = d > 15 ? 0.85 : (d > 6 ? 0.6 : 0.35);
    return LatLng(
      previa.latitude + (cruda.latitude - previa.latitude) * alpha,
      previa.longitude + (cruda.longitude - previa.longitude) * alpha,
    );
  }

  void _alternarModoProveedorGps() {
    setState(() {
      GpsService.instance.forceLocationManager =
          !GpsService.instance.forceLocationManager;
    });
    _iniciarEscuchaGpsEnVivo();
    final modo = GpsService.instance.forceLocationManager
        ? 'LocationManager Nativo (Exterior / Satélites Directos)'
        : 'Google Fused Provider (Interior / Aula con Wi-Fi)';
    AppSnackBar.info(context, 'Modo GPS: $modo');
  }

  void _recalcularDistancia({bool confirmarConsecutivas = false}) {
    if (_miUbicacionActual == null || _coordenadaTemp == null) {
      _distanciaActualM = null;
      return;
    }

    // Geocerca CIRCULAR Haversine (misma lógica que detección de vueltas):
    // el centro es la coordenada calibrada y el radio el radio en BD.
    _distanciaActualM = ReglasAsistencia.calcularDistanciaMetros(
      lat1: _miUbicacionActual!.latitude,
      lon1: _miUbicacionActual!.longitude,
      lat2: _coordenadaTemp!.latitude,
      lon2: _coordenadaTemp!.longitude,
    );
    final acc = _precisionActual ?? 10.0;
    final enGeocerca = ReglasAsistencia.estaDentroDeGeocerca(
      latUsuario: _miUbicacionActual!.latitude,
      lonUsuario: _miUbicacionActual!.longitude,
      latPunto: _coordenadaTemp!.latitude,
      lonPunto: _coordenadaTemp!.longitude,
      radioMetros: _radioM,
      accuracyMetros: acc,
    );
    final estabaDentro = _dentroConfirmado;
    if (enGeocerca) {
      _dentroConfirmado = true;
    } else if (confirmarConsecutivas) {
      _dentroConfirmado = _estadoGeocerca.actualizar(
        distancia: _distanciaActualM!,
        accuracy: acc,
        radio: _radioM,
      );
    } else {
      _estadoGeocerca.forzarEstado(
        distancia: _distanciaActualM!,
        accuracy: acc,
        radio: _radioM,
      );
      _dentroConfirmado = _estadoGeocerca.dentro;
    }

    if (!estabaDentro && _dentroConfirmado) {
      _registrarAsistenciaAlEntrarGeocerca();
    }
  }

  Future<void> _registrarAsistenciaAlEntrarGeocerca() async {
    final idCond = SesionService.instance.idConductor;
    final idPunto = _puntoSeleccionado?['id_punto']?.toString() ?? '';
    if (idCond == null ||
        idCond.isEmpty ||
        idPunto.isEmpty ||
        _miUbicacionActual == null) {
      return;
    }
    try {
      final hoy = DateTime.now().toIso8601String().substring(0, 10);
      final asistHoy =
          await AsistenciaRepo.instance.obtenerAsistenciaHoy(idCond, hoy);
      if (asistHoy == null) {
        final res = await AsistenciaRepo.instance.registrarAsistenciaGps(
          idConductor: idCond,
          idPunto: idPunto,
          latitud: _miUbicacionActual!.latitude,
          longitud: _miUbicacionActual!.longitude,
          precisionM: _precisionActual ?? 5.0,
          distanciaM: 0.0,
          esMock: false,
          horaSateliteConfiable: true,
        );
        if (res.exito && mounted) {
          final nombreP =
              _puntoSeleccionado?['nombre']?.toString() ?? 'Parada';
          AppSnackBar.exito(
            context,
            '¡Asistencia registrada automáticamente al entrar en la geocerca de $nombreP!',
          );
        }
      }
    } catch (_) {}
  }

  Future<void> _cargarPuntos() async {
    setState(() => _cargando = true);
    final pts = await DatabaseHelper.instance.obtenerPuntosControl(
      soloActivos: false,
    );
    if (!mounted) return;

    setState(() {
      _puntos = pts;
      if (pts.isNotEmpty) {
        _puntoSeleccionado = pts.firstWhere(
          (p) => (p['es_punto_asistencia'] as num?)?.toInt() == 1,
          orElse: () => pts.first,
        );
        final lat =
            (_puntoSeleccionado!['latitud'] as num?)?.toDouble() ??
            RutaContinental.paradaAVilladela.latitude;
        final lon =
            (_puntoSeleccionado!['longitud'] as num?)?.toDouble() ??
            RutaContinental.paradaAVilladela.longitude;
        _coordenadaTemp = LatLng(lat, lon);
        _radioM =
            ((_puntoSeleccionado!['radio_m'] as num?)?.toDouble() ?? 100.0)
                .clamp(1.0, 300.0);
        _guardado = true;
        _recalcularDistancia();
      }
      _cargando = false;
    });

    if (_coordenadaTemp != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _verAmbosPuntos();
      });
    }
  }

  void _seleccionarPunto(Map<String, dynamic> punto) {
    setState(() {
      _puntoSeleccionado = punto;
      final lat =
          (punto['latitud'] as num?)?.toDouble() ??
          RutaContinental.paradaAVilladela.latitude;
      final lon =
          (punto['longitud'] as num?)?.toDouble() ??
          RutaContinental.paradaAVilladela.longitude;
      _coordenadaTemp = LatLng(lat, lon);
      _radioM = ((punto['radio_m'] as num?)?.toDouble() ?? 100.0).clamp(
        1.0,
        300.0,
      );
      _guardado = true;
      _recalcularDistancia();
    });
    _mapController.move(_coordenadaTemp!, _radioM <= 15 ? 18.0 : 16.0);
  }

  /// Ajusta la cámara para ver simultáneamente Parada A y Parada B
  void _verAmbosPuntos() {
    final coords = <LatLng>[];
    for (int i = 0; i < _puntos.length; i++) {
      final p = _puntos[i];
      if (p['id_punto'] == _puntoSeleccionado?['id_punto'] &&
          _coordenadaTemp != null) {
        coords.add(_coordenadaTemp!);
      } else {
        final lat = (p['latitud'] as num?)?.toDouble();
        final lon = (p['longitud'] as num?)?.toDouble();
        if (lat != null && lon != null) coords.add(LatLng(lat, lon));
      }
    }
    if (coords.isEmpty) {
      if (_coordenadaTemp != null) {
        _mapController.move(_coordenadaTemp!, 16.0);
      }
      return;
    }
    if (coords.length == 1) {
      _mapController.move(coords.first, 16.5);
      return;
    }
    final bounds = LatLngBounds.fromPoints(coords);
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.symmetric(horizontal: 55, vertical: 85),
      ),
    );
  }

  void _centrarEnMiUbicacion() {
    if (_miUbicacionActual != null) {
      _mapController.move(_miUbicacionActual!, 18.0);
    } else {
      AppSnackBar.info(context, 'Esperando señal GPS del celular...');
    }
  }

  /// Captura rápida o promediada durante [segundosPromedio] (ej. 20s para centro de geocerca)
  Future<void> _capturarUbicacion({int segundosPromedio = 1}) async {
    if (_promediando) return;
    try {
      setState(() {
        _promediando = segundosPromedio > 1;
        _muestrasPromedio = 0;
        _segundosRestantesPromedio = segundosPromedio;
      });

      final Position? pos;
      if (segundosPromedio > 1) {
        pos = await GpsService.instance.capturarPuntoPromediado(
          duracion: Duration(seconds: segundosPromedio),
          onProgreso: (muestras, restantes, acc) {
            if (!mounted) return;
            setState(() {
              _muestrasPromedio = muestras;
              _segundosRestantesPromedio = restantes;
              if (acc != null) _precisionActual = acc;
            });
          },
        );
      } else {
        pos = await GpsService.instance.obtenerPosicionActual();
      }

      if (!mounted) return;
      setState(() => _promediando = false);

      if (pos == null) {
        AppSnackBar.error(
          context,
          'No se pudo obtener señal GPS. Acércate a una ventana o sal al exterior.',
        );
        return;
      }

      final Position posValida = pos;
      final nuevaCoord = LatLng(posValida.latitude, posValida.longitude);
      setState(() {
        _miUbicacionActual = nuevaCoord;
        _coordenadaTemp = nuevaCoord;
        _precisionActual = posValida.accuracy;
        _senalDebil = posValida.accuracy > GpsService.umbralSenalDebilMetros;
        _guardado = false;
        _recalcularDistancia(confirmarConsecutivas: false);
      });
      _mapController.move(nuevaCoord, 18.0);
      _iniciarEscuchaGpsEnVivo();

      AppSnackBar.exito(
        context,
        segundosPromedio > 1
            ? '¡Centro calibrado con promedio de $_muestrasPromedio lecturas (±${posValida.accuracy.toStringAsFixed(1)} m)! Pulsa Guardar.'
            : '¡Ubicación actual fijada (±${posValida.accuracy.toStringAsFixed(1)} m)! Pulsa Guardar.',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _promediando = false);
      AppSnackBar.error(context, 'Error GPS: $e');
    }
  }

  Future<void> _restablecerOriginales() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('¿Restablecer Paradas Oficiales?'),
        content: const Text(
          'Se restablecerán las coordenadas originales del Cruce Villadela y Teleférico Amarillo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _kVerdeOscuro,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Restablecer',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    for (final p in _puntos) {
      final esA = p['nombre'].toString().contains('Villadela');
      final oficial = esA
          ? RutaContinental.paradaAVilladela
          : RutaContinental.paradaBTeleferico;
      await AsistenciaRepo.instance.actualizarPuntoControl(
        idPunto: p['id_punto'].toString(),
        latitud: oficial.latitude,
        longitud: oficial.longitude,
        radioM: 100,
      );
    }
    await _cargarPuntos();
    if (mounted) {
      AppSnackBar.exito(context, 'Paradas restablecidas a valores oficiales.');
    }
  }

  Future<void> _guardarCambios() async {
    if (_puntoSeleccionado == null || _coordenadaTemp == null) return;
    // Un toque = un guardado. Si no hay cambios pendientes, no hace nada.
    if (_guardando || _guardado) return;

    final idPunto = _puntoSeleccionado!['id_punto']?.toString() ?? '';

    // Evitar geocercas superpuestas: si A y B se tocan, el GPS no puede
    // distinguir en qué parada está y el conteo de vueltas falla.
    for (final otro in _puntos) {
      if (otro['id_punto']?.toString() == idPunto) continue;
      final lat = (otro['latitud'] as num?)?.toDouble();
      final lon = (otro['longitud'] as num?)?.toDouble();
      if (lat == null || lon == null) continue;

      final radioOtro = (otro['radio_m'] as num?)?.toDouble() ?? 100.0;
      final distancia = ReglasAsistencia.calcularDistanciaMetros(
        lat1: _coordenadaTemp!.latitude,
        lon1: _coordenadaTemp!.longitude,
        lat2: lat,
        lon2: lon,
      );

      if (distancia <= _radioM + radioOtro + 5) {
        final separacionSugerida = (((_radioM + radioOtro + 15) / 5).ceil() * 5)
            .toDouble();
        final radioSugerido = ((distancia - 15) / 2).clamp(5.0, 300.0).round();

        final continuar = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Paradas muy juntas',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: Text(
              'La separación entre A y B es de ${distancia.round()} m y los '
              'radios suman ${(_radioM + radioOtro).round()} m. Los círculos '
              'se tocan y el GPS puede confundir la parada.\n\n'
              'Para una demo confiable: sepáralas al menos '
              '${separacionSugerida.round()} m o baja el radio a '
              '$radioSugerido m.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Corregir'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  'Guardar igual',
                  style: TextStyle(color: Color(0xFFD97706)),
                ),
              ),
            ],
          ),
        );
        if (continuar != true) return;
      }
      break;
    }

    setState(() => _guardando = true);

    await AsistenciaRepo.instance.actualizarPuntoControl(
      idPunto: idPunto,
      latitud: _coordenadaTemp!.latitude,
      longitud: _coordenadaTemp!.longitude,
      radioM: _radioM.round(),
    );

    await _cargarPuntos();
    if (!mounted) return;
    setState(() {
      _guardando = false;
      _guardado = true;
    });

    AppSnackBar.exito(
      context,
      '¡Geocerca guardada con éxito! Radio calibrado a ${_radioM.round()} m.',
    );
  }

  void _mostrarDialogoEditarNombre() {
    if (_puntoSeleccionado == null) return;
    final nombreCtrl = TextEditingController(
      text: _puntoSeleccionado!['nombre']?.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Editar Nombre de Parada',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: nombreCtrl,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: 'Nombre oficial',
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _kVerdeOscuro,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              final nuevo = nombreCtrl.text.trim();
              if (nuevo.isEmpty) return;
              Navigator.pop(ctx);
              final idPunto = _puntoSeleccionado!['id_punto']?.toString() ?? '';
              await AsistenciaRepo.instance.actualizarPuntoControl(
                idPunto: idPunto,
                nombre: nuevo,
              );
              await _cargarPuntos();
              if (mounted) {
                AppSnackBar.exito(context, 'Nombre actualizado a "$nuevo"');
              }
            },
            child: const Text('Guardar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  (String, Color) _calidadGps(double? acc) {
    if (acc == null) return ('Buscando GPS...', const Color(0xFF64748B));
    if (acc <= 5.0) {
      return (
        '±${acc.toStringAsFixed(1)} m (Excelente)',
        const Color(0xFF10B981),
      );
    }
    if (acc <= 10.0) {
      return ('±${acc.toStringAsFixed(1)} m (Buena)', const Color(0xFF02634C));
    }
    if (acc <= 20.0) {
      return (
        '±${acc.toStringAsFixed(1)} m (Aceptable)',
        const Color(0xFFD97706),
      );
    }
    return (
      '±${acc.toStringAsFixed(1)} m (Débil / Interior)',
      const Color(0xFFEF4444),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final esSat = _estiloMapa == _EstiloMapa.satelite;
    final nombrePunto =
        _puntoSeleccionado?['nombre']?.toString() ?? 'Punto de Control';
    final esVilladela = nombrePunto.contains('Villadela');
    final usarNativo = GpsService.instance.forceLocationManager;

    LatLng? coordA;
    LatLng? coordB;
    double radioA = 100.0;
    double radioB = 100.0;

    for (int i = 0; i < _puntos.length; i++) {
      final p = _puntos[i];
      final esA = p['nombre'].toString().contains('Villadela') || i == 0;
      final esSel = p['id_punto'] == _puntoSeleccionado?['id_punto'];
      final c = esSel && _coordenadaTemp != null
          ? _coordenadaTemp!
          : LatLng(
              (p['latitud'] as num?)?.toDouble() ??
                  (esA
                      ? RutaContinental.paradaAVilladela.latitude
                      : RutaContinental.paradaBTeleferico.latitude),
              (p['longitud'] as num?)?.toDouble() ??
                  (esA
                      ? RutaContinental.paradaAVilladela.longitude
                      : RutaContinental.paradaBTeleferico.longitude),
            );
      final r = esSel ? _radioM : ((p['radio_m'] as num?)?.toDouble() ?? 100.0);

      if (esA) {
        coordA = c;
        radioA = r;
      } else {
        coordB = c;
        radioB = r;
      }
    }

    final (calidadTexto, calidadColor) = _calidadGps(_precisionActual);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: _cargando
          ? const Center(child: CircularProgressIndicator(color: _kVerdeOscuro))
          : Column(
              children: [
                // 1. ENCABEZADO CURVO VERDE CORPORATIVO
                _buildCurvedHeader(topPadding, usarNativo),

                // 2. BARRA DE SELECCIÓN DE PARADA A Y PARADA B (TABS CORPORATIVAS)
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      // Botón Parada A
                      Expanded(
                        child: _buildSelectorParada(
                          letra: 'A',
                          nombre: 'Villadela',
                          activo: esVilladela,
                          onTap: () {
                            if (_puntos.isNotEmpty) {
                              final pA = _puntos.firstWhere(
                                (p) => p['nombre'].toString().contains(
                                  'Villadela',
                                ),
                                orElse: () => _puntos.first,
                              );
                              _seleccionarPunto(pA);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Botón Parada B
                      Expanded(
                        child: _buildSelectorParada(
                          letra: 'B',
                          nombre: 'Teleférico',
                          activo: !esVilladela,
                          onTap: () {
                            if (_puntos.isNotEmpty) {
                              final pB = _puntos.firstWhere(
                                (p) => !p['nombre'].toString().contains(
                                  'Villadela',
                                ),
                                orElse: () => _puntos.last,
                              );
                              _seleccionarPunto(pB);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // 3. MAPA INTERACTIVO CON CONTROLES FLOTANTES
                Expanded(
                  child: Stack(
                    children: [
                      FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter:
                              _coordenadaTemp ??
                              RutaContinental.paradaAVilladela,
                          initialZoom: 16.0,
                          maxZoom: 21.0,
                          onTap: (_, point) {
                            setState(() {
                              _coordenadaTemp = point;
                              _guardado = false;
                              _recalcularDistancia(
                                confirmarConsecutivas: false,
                              );
                            });
                          },
                        ),
                        children: [
                          // Capa Base: Satélite Esri o Calles CARTO Voyager
                          TileLayer(
                            urlTemplate: esSat
                                ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
                                : 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                            subdomains: const ['a', 'b', 'c', 'd'],
                            userAgentPackageName: 'com.example.continental',
                            maxNativeZoom: 19,
                            maxZoom: 21,
                          ),

                          // Capa de nombres y calles híbrida sobre el satélite
                          if (esSat)
                            TileLayer(
                              urlTemplate:
                                  'https://services.arcgisonline.com/ArcGIS/rest/services/Reference/World_Boundaries_and_Places/MapServer/tile/{z}/{y}/{x}',
                              userAgentPackageName: 'com.example.continental',
                              maxNativeZoom: 19,
                              maxZoom: 21,
                            ),

                          // Trazado vial oficial entre Parada A y Parada B
                          PolylineLayer(
                            polylines: [
                              Polyline(
                                points: RutaContinental.puntosVuelta,
                                strokeWidth: 3.8,
                                color: const Color(0xFFD97706),
                                borderStrokeWidth: 1.5,
                                borderColor: Colors.white,
                              ),
                              Polyline(
                                points: RutaContinental.puntosIda,
                                strokeWidth: 4.2,
                                color: _kVerdeOscuro,
                                borderStrokeWidth: 1.5,
                                borderColor: Colors.white,
                              ),
                            ],
                          ),

                          // Geocercas CIRCULARES con el radio real calibrado en la BD
                          PolygonLayer(
                            polygons: [
                              if (coordA != null)
                                Polygon(
                                  points: RutaContinental.anilloGeocerca(
                                    coordA,
                                    radioA.clamp(5.0, 300.0),
                                  ),
                                  color: (esVilladela && _dentroConfirmado
                                          ? const Color(0xFF10B981)
                                          : const Color(0xFF2563EB))
                                      .withValues(alpha: 0.28),
                                  borderColor: esVilladela && _dentroConfirmado
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFF2563EB),
                                  borderStrokeWidth: esVilladela ? 3.4 : 2.5,
                                ),
                              if (coordB != null)
                                Polygon(
                                  points: RutaContinental.anilloGeocerca(
                                    coordB,
                                    radioB.clamp(5.0, 300.0),
                                  ),
                                  color: (!esVilladela && _dentroConfirmado
                                          ? const Color(0xFF10B981)
                                          : const Color(0xFFD97706))
                                      .withValues(alpha: 0.26),
                                  borderColor: !esVilladela && _dentroConfirmado
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFFD97706),
                                  borderStrokeWidth: !esVilladela ? 3.2 : 2.4,
                                ),
                            ],
                          ),

                          // Círculo de precisión del GPS (como Google Maps)
                          if (_miUbicacionActual != null)
                            CircleLayer(
                              circles: [
                                CircleMarker(
                                  point: _miUbicacionActual!,
                                  radius: (_precisionActual ?? 10).clamp(
                                    5.0,
                                    120.0,
                                  ),
                                  useRadiusInMeter: true,
                                  color: const Color(
                                    0xFF1A73E8,
                                  ).withValues(alpha: 0.10),
                                  borderColor: const Color(
                                    0xFF1A73E8,
                                  ).withValues(alpha: 0.45),
                                  borderStrokeWidth: 1,
                                ),
                              ],
                            ),

                          // Marcadores de Paradas
                          MarkerLayer(
                            markers: [
                              if (coordA != null)
                                Marker(
                                  point: coordA,
                                  width: 140,
                                  height: 60,
                                  child: _buildPinParada(
                                    letra: 'A',
                                    nombre: 'Villadela',
                                    color: _kVerdeOscuro,
                                    esSeleccionado: esVilladela,
                                    radio: radioA,
                                    onTap: () {
                                      final pA = _puntos.firstWhere(
                                        (p) => p['nombre'].toString().contains(
                                          'Villadela',
                                        ),
                                        orElse: () => _puntos.first,
                                      );
                                      _seleccionarPunto(pA);
                                    },
                                  ),
                                ),
                              if (coordB != null)
                                Marker(
                                  point: coordB,
                                  width: 140,
                                  height: 60,
                                  child: _buildPinParada(
                                    letra: 'B',
                                    nombre: 'Teleférico',
                                    color: const Color(0xFFD97706),
                                    esSeleccionado: !esVilladela,
                                    radio: radioB,
                                    onTap: () {
                                      final pB = _puntos.firstWhere(
                                        (p) => !p['nombre'].toString().contains(
                                          'Villadela',
                                        ),
                                        orElse: () => _puntos.last,
                                      );
                                      _seleccionarPunto(pB);
                                    },
                                  ),
                                ),
                            ],
                          ),

                          // Punto azul de mi ubicación (estilo Google Maps) con
                          // visor que apunta hacia donde mira el usuario.
                          if (_miUbicacionActual != null)
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: _miUbicacionActual!,
                                  width: 100,
                                  height: 100,
                                  child: UbicacionAzul(
                                    rumboGrados: _rumboGrados,
                                    rumboListenable: _rumboNotifier,
                                    rumboValido: _rumboValido,
                                    tamano: 100,
                                    tamanoPunto: 20,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),

                      // Chip de precisión GPS flotante (arriba a la izquierda)
                      Positioned(
                        top: 12,
                        left: 14,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.12),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: calidadColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                calidadTexto,
                                style: const TextStyle(
                                  color: Color(0xFF0F172A),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Selector de capa de mapa: Satélite / Calles (arriba a la derecha)
                      Positioned(
                        top: 12,
                        right: 14,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.12),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildToggleTile(
                                titulo: 'Satélite',
                                icono: Icons.satellite_alt_rounded,
                                activo: esSat,
                                onTap: () => setState(
                                  () => _estiloMapa = _EstiloMapa.satelite,
                                ),
                              ),
                              _buildToggleTile(
                                titulo: 'Calles',
                                icono: Icons.map_rounded,
                                activo: !esSat,
                                onTap: () => setState(
                                  () => _estiloMapa = _EstiloMapa.calles,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Botones flotantes de mapa (lado derecho)
                      Positioned(
                        right: 14,
                        top: 62,
                        child: Column(
                          children: [
                            _buildBotonFlotanteRedondo(
                              icono: Icons.alt_route_rounded,
                              tooltip: 'Ver ambas paradas (Circuito A ↔ B)',
                              onPressed: _verAmbosPuntos,
                            ),
                            const SizedBox(height: 8),
                            _buildBotonFlotanteRedondo(
                              icono: Icons.my_location_rounded,
                              tooltip: 'Centrar en mi GPS',
                              onPressed: _centrarEnMiUbicacion,
                            ),
                          ],
                        ),
                      ),

                      // Botones de acción GPS (abajo a la derecha, sobre el panel)
                      Positioned(
                        right: 14,
                        bottom: 12,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // Botón Calibrar Promedio (20 s)
                            ElevatedButton.icon(
                              onPressed: _promediando
                                  ? null
                                  : () => _capturarUbicacion(
                                      segundosPromedio: 20,
                                    ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _kVerdeOscuro,
                                foregroundColor: Colors.white,
                                elevation: 4,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              icon: _promediando
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.timer_outlined, size: 18),
                              label: Text(
                                _promediando
                                    ? 'Calibrando ($_segundosRestantesPromedio s)...'
                                    : 'Calibrar Promedio (20 s)',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Botón Fijar en mi GPS actual
                            ElevatedButton.icon(
                              onPressed: _promediando
                                  ? null
                                  : () =>
                                        _capturarUbicacion(segundosPromedio: 1),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: _kVerdeOscuro,
                                elevation: 4,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: const BorderSide(
                                    color: Color(0xFFE2E8F0),
                                  ),
                                ),
                              ),
                              icon: const Icon(
                                Icons.gps_fixed_rounded,
                                size: 18,
                                color: _kVerdeOscuro,
                              ),
                              label: const Text(
                                'Fijar en mi GPS actual',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // 4. PANEL MODULAR INFERIOR DE CALIBRACIÓN Y GUARDADO
                _buildPanelInferior(nombrePunto, esVilladela),
              ],
            ),
    );
  }

  // ===========================================================================
  // ENCABEZADO CURVO VERDE CORPORATIVO
  // ===========================================================================
  Widget _buildCurvedHeader(double topPadding, bool usarNativo) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: _kVerdeOscuro,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, topPadding + 8, 16, 18),
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
                      icon: Icon(
                        usarNativo ? Icons.satellite_alt : Icons.wifi_tethering,
                        color: Colors.white,
                        size: 20,
                      ),
                      tooltip: usarNativo
                          ? 'Modo: Satélite Nativo'
                          : 'Modo: Fused (Wi-Fi/Interior)',
                      onPressed: _alternarModoProveedorGps,
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.restore_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      tooltip: 'Restablecer valores originales',
                      onPressed: _restablecerOriginales,
                    ),
                    const SizedBox(width: 4),
                    // Usuario activo en Squircle Blanco
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(13),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
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
            const SizedBox(height: 10),
            const Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Puntos de Parada (A y B)',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.3,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Calibración satelital del circuito de vueltas',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
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

  // ===========================================================================
  // PANEL MODULAR INFERIOR (BLANCO CON BORDES REDONDEADOS)
  // ===========================================================================
  Widget _buildPanelInferior(String nombrePunto, bool esVilladela) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 14,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        18,
        10,
        18,
        MediaQuery.of(context).padding.bottom > 0
            ? MediaQuery.of(context).padding.bottom + 4
            : 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Píldora superior de arrastre
          Center(
            child: Container(
              width: 44,
              height: 4.5,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Fila del punto activo y radio
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: _kMintBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  color: _kVerdeOscuro,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        '$nombrePunto (${esVilladela ? "Parada A" : "Parada B"})',
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(
                        Icons.edit_outlined,
                        size: 16,
                        color: Color(0xFF64748B),
                      ),
                      tooltip: 'Editar nombre',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: _mostrarDialogoEditarNombre,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _kMintBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _kVerdeOscuro.withOpacity(0.3),
                    width: 1.2,
                  ),
                ),
                child: Text(
                  'Radio: ${_radioM.round()} m',
                  style: const TextStyle(
                    color: _kVerdeOscuro,
                    fontWeight: FontWeight.w800,
                    fontSize: 11.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Coordenadas / Distancia actual
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.gps_fixed_rounded,
                  size: 14,
                  color: _dentroConfirmado
                      ? const Color(0xFF10B981)
                      : const Color(0xFF64748B),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _distanciaActualM != null
                        ? 'Distancia: ${GpsService.formatearDistancia(_distanciaActualM)} • Estado: ${_dentroConfirmado ? "¡DENTRO DE LA PARADA!" : "Fuera de la zona"}'
                        : (_coordenadaTemp != null
                              ? 'Lat: ${_coordenadaTemp!.latitude.toStringAsFixed(6)} | Lon: ${_coordenadaTemp!.longitude.toStringAsFixed(6)}'
                              : 'Toca en el mapa para posicionar la geocerca'),
                    style: TextStyle(
                      color: _distanciaActualM != null
                          ? (_dentroConfirmado
                                ? const Color(0xFF10B981)
                                : const Color(0xFFD97706))
                          : const Color(0xFF475569),
                      fontWeight: FontWeight.w700,
                      fontSize: 11.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Botones Rápidos de Radio: 2m, 5m, 10m, 30m, 50m, 100m, 150m
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: _radiosRapidos.map((r) {
                final sel = _radioM.round() == r;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _radioM = r.toDouble();
                        _guardado = false;
                        _recalcularDistancia(confirmarConsecutivas: false);
                      });
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: sel ? _kMintBg : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: sel ? _kVerdeOscuro : const Color(0xFFE2E8F0),
                          width: sel ? 1.5 : 1,
                        ),
                      ),
                      child: Text(
                        '$r m',
                        style: TextStyle(
                          color: sel ? _kVerdeOscuro : const Color(0xFF475569),
                          fontWeight: sel ? FontWeight.bold : FontWeight.w600,
                          fontSize: 11.5,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 6),

          // Slider de Radio fino (1m a 300m)
          Row(
            children: [
              const Text(
                '1m',
                style: TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8)),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: _kVerdeOscuro,
                    inactiveTrackColor: const Color(0xFFE2E8F0),
                    thumbColor: _kVerdeOscuro,
                    overlayColor: _kVerdeOscuro.withOpacity(0.18),
                    trackHeight: 3.5,
                  ),
                  child: Slider(
                    value: _radioM.clamp(1.0, 300.0),
                    min: 1.0,
                    max: 300.0,
                    divisions: 299,
                    onChanged: (v) {
                      setState(() {
                        _radioM = v;
                        _guardado = false;
                        _recalcularDistancia(confirmarConsecutivas: false);
                      });
                    },
                  ),
                ),
              ),
              const Text(
                '300m',
                style: TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Botón Guardar Calibración
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: (_guardando || _guardado) ? null : _guardarCambios,
              style: ElevatedButton.styleFrom(
                backgroundColor: _guardado ? _kMintBg : _kVerdeOscuro,
                foregroundColor: _guardado ? _kVerdeOscuro : Colors.white,
                disabledBackgroundColor: _guardando
                    ? _kVerdeOscuro.withValues(alpha: 0.6)
                    : _kMintBg,
                disabledForegroundColor: _guardando
                    ? Colors.white
                    : _kVerdeOscuro,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              icon: _guardando
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Icon(
                      _guardado
                          ? Icons.verified_rounded
                          : Icons.check_circle_rounded,
                      size: 20,
                    ),
              label: Text(
                _guardando
                    ? 'Guardando geocerca...'
                    : _guardado
                    ? 'Calibración guardada (${_radioM.round()} m)'
                    : 'Guardar Calibración de $nombrePunto (${_radioM.round()} m)',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Widgets Auxiliares ---

  Widget _buildSelectorParada({
    required String letra,
    required String nombre,
    required bool activo,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: activo ? _kMintBg : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: activo ? _kVerdeOscuro : const Color(0xFFE2E8F0),
            width: activo ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: activo ? _kVerdeOscuro : const Color(0xFFCBD5E1),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                letra,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 12.5,
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
                    'Parada $letra',
                    style: TextStyle(
                      color: activo ? _kVerdeOscuro : const Color(0xFF64748B),
                      fontWeight: FontWeight.w700,
                      fontSize: 10.5,
                    ),
                  ),
                  Text(
                    nombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: activo
                          ? const Color(0xFF0F172A)
                          : const Color(0xFF475569),
                      fontWeight: activo ? FontWeight.w900 : FontWeight.w700,
                      fontSize: 12.5,
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

  Widget _buildPinParada({
    required String letra,
    required String nombre,
    required Color color,
    required bool esSeleccionado,
    required double radio,
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
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: esSeleccionado ? color : const Color(0xFFE2E8F0),
                width: esSeleccionado ? 2 : 1,
              ),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 4),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 15,
                  height: 15,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    letra,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 9.5,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '$nombre (${radio.round()}m)',
                  style: TextStyle(
                    color: const Color(0xFF0F172A),
                    fontWeight: esSeleccionado
                        ? FontWeight.bold
                        : FontWeight.w600,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.location_on,
            color: color,
            size: esSeleccionado ? 34 : 26,
            shadows: const [Shadow(color: Colors.black45, blurRadius: 4)],
          ),
        ],
      ),
    );
  }

  Widget _buildToggleTile({
    required String titulo,
    required IconData icono,
    required bool activo,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: activo ? _kMintBg : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icono,
              size: 13,
              color: activo ? _kVerdeOscuro : const Color(0xFF64748B),
            ),
            const SizedBox(width: 4),
            Text(
              titulo,
              style: TextStyle(
                color: activo ? _kVerdeOscuro : const Color(0xFF64748B),
                fontSize: 11,
                fontWeight: activo ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBotonFlotanteRedondo({
    required IconData icono,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icono, color: _kVerdeOscuro, size: 20),
        tooltip: tooltip,
        padding: EdgeInsets.zero,
        onPressed: onPressed,
      ),
    );
  }
}
