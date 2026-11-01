import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../domain/reglas_asistencia.dart';
import '../../services/asistencia_repo.dart';
import '../../services/database_helper.dart';
import '../../services/gps_service.dart';

/// Pantalla limpia e interactiva para elegir el punto (A: Cruce Villadela / B: Teleférico),
/// fijar tu ubicación GPS actual (ej. en tu casa o aula) y elegir el radio desde 1m / 2m.
class PuntosControlScreen extends StatefulWidget {
  const PuntosControlScreen({super.key});

  @override
  State<PuntosControlScreen> createState() => _PuntosControlScreenState();
}

class _PuntosControlScreenState extends State<PuntosControlScreen> {
  final MapController _mapController = MapController();
  List<Map<String, dynamic>> _puntos = [];
  Map<String, dynamic>? _puntoSeleccionado;
  double _radioM = 100.0;
  LatLng? _coordenadaTemp;
  LatLng? _miUbicacionActual;
  double? _distanciaActualM;
  bool _cargando = true;
  bool _guardando = false;
  StreamSubscription<Position>? _subGps;

  static const List<int> _radiosRapidos = [2, 3, 5, 10, 50, 100];

  @override
  void initState() {
    super.initState();
    _cargarPuntos();
    _iniciarEscuchaGpsEnVivo();
  }

  @override
  void dispose() {
    _subGps?.cancel();
    super.dispose();
  }

  Future<void> _iniciarEscuchaGpsEnVivo() async {
    final ok = await GpsService.instance.verificarPermisos();
    if (!ok || !mounted) return;

    _subGps?.cancel();
    _subGps = GpsService.instance.obtenerStreamPosicion(distanceFilterM: 0).listen((pos) {
      if (!mounted) return;
      setState(() {
        _miUbicacionActual = LatLng(pos.latitude, pos.longitude);
        _recalcularDistancia();
      });
    });
  }

  void _recalcularDistancia() {
    if (_miUbicacionActual == null || _coordenadaTemp == null) {
      _distanciaActualM = null;
      return;
    }
    _distanciaActualM = ReglasAsistencia.calcularDistanciaMetros(
      lat1: _miUbicacionActual!.latitude,
      lon1: _miUbicacionActual!.longitude,
      lat2: _coordenadaTemp!.latitude,
      lon2: _coordenadaTemp!.longitude,
    );
  }

  Future<void> _cargarPuntos() async {
    setState(() => _cargando = true);
    final pts = await DatabaseHelper.instance.obtenerPuntosControl(soloActivos: false);
    if (!mounted) return;

    setState(() {
      _puntos = pts;
      if (pts.isNotEmpty) {
        _puntoSeleccionado = pts.firstWhere(
          (p) => (p['es_punto_asistencia'] as num?)?.toInt() == 1,
          orElse: () => pts.first,
        );
        final lat = (_puntoSeleccionado!['latitud'] as num?)?.toDouble() ?? -16.53453;
        final lon = (_puntoSeleccionado!['longitud'] as num?)?.toDouble() ?? -68.19071;
        _coordenadaTemp = LatLng(lat, lon);
        _radioM = ((_puntoSeleccionado!['radio_m'] as num?)?.toDouble() ?? 100.0).clamp(1.0, 300.0);
        _recalcularDistancia();
      }
      _cargando = false;
    });

    if (_coordenadaTemp != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(_coordenadaTemp!, _radioM <= 15 ? 18.5 : 15.5);
      });
    }
  }

  void _seleccionarPunto(Map<String, dynamic> punto) {
    setState(() {
      _puntoSeleccionado = punto;
      final lat = (punto['latitud'] as num?)?.toDouble() ?? -16.53453;
      final lon = (punto['longitud'] as num?)?.toDouble() ?? -68.19071;
      _coordenadaTemp = LatLng(lat, lon);
      _radioM = ((punto['radio_m'] as num?)?.toDouble() ?? 100.0).clamp(1.0, 300.0);
      _recalcularDistancia();
    });
    _mapController.move(_coordenadaTemp!, _radioM <= 15 ? 18.5 : 15.5);
  }

  Future<void> _capturarUbicacionActual() async {
    try {
      final pos = await GpsService.instance.obtenerPosicionActual();
      if (pos == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo obtener la posición GPS actual.')),
        );
        return;
      }
      final nuevaCoord = LatLng(pos.latitude, pos.longitude);
      setState(() {
        _miUbicacionActual = nuevaCoord;
        _coordenadaTemp = nuevaCoord;
        _recalcularDistancia();
      });
      _mapController.move(nuevaCoord, 18.5);
      _iniciarEscuchaGpsEnVivo();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Ubicación actual capturada (0.0 m)! Ahora elige el radio y pulsa Guardar.'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al capturar GPS: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _restablecerOriginales() {
    if (_puntoSeleccionado == null) return;
    final esVilladela = _puntoSeleccionado!['nombre'].toString().contains('Villadela');
    final defCoord = esVilladela
        ? const LatLng(-16.53453, -68.19071)
        : const LatLng(-16.5050, -68.1635);

    setState(() {
      _coordenadaTemp = defCoord;
      _radioM = 100.0;
      _recalcularDistancia();
    });
    _mapController.move(defCoord, 15.5);
  }

  Future<void> _guardarCambios() async {
    if (_puntoSeleccionado == null || _coordenadaTemp == null) return;
    setState(() => _guardando = true);

    final idPunto = _puntoSeleccionado!['id_punto']?.toString() ?? '';
    await AsistenciaRepo.instance.actualizarPuntoControl(
      idPunto: idPunto,
      latitud: _coordenadaTemp!.latitude,
      longitud: _coordenadaTemp!.longitude,
      radioM: _radioM.round(),
    );

    await _cargarPuntos();
    if (!mounted) return;
    setState(() => _guardando = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('¡Guardado! Punto fijado con radio de ${_radioM.round()} metros.'),
        backgroundColor: const Color(0xFF10B981),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nombrePunto = _puntoSeleccionado?['nombre']?.toString() ?? 'Punto de Control';
    final esAsistencia = (_puntoSeleccionado?['es_punto_asistencia'] as num?)?.toInt() == 1;
    final colorPunto = esAsistencia ? const Color(0xFF10B981) : const Color(0xFF3B82F6);
    final dentroAhora = _distanciaActualM != null && _distanciaActualM! <= _radioM;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F9FD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E3A8A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Elegir Punto y Radio GPS',
          style: TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold, fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.restore, color: Color(0xFF64748B)),
            tooltip: 'Restablecer coordenadas originales',
            onPressed: _restablecerOriginales,
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 1. Selector de Punto arriba (A: Cruce Villadela / B: Teleférico Amarillo)
                Container(
                  width: double.infinity,
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _puntos.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final p = entry.value;
                        final sel = p['id_punto'] == _puntoSeleccionado?['id_punto'];
                        final letra = idx == 0 ? 'Parada A' : 'Parada B';
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text('$letra: ${p['nombre']}'),
                            selected: sel,
                            selectedColor: const Color(0xFF3B82F6),
                            labelStyle: TextStyle(
                              color: sel ? Colors.white : const Color(0xFF1E3A8A),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            onSelected: (_) => _seleccionarPunto(p),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

                // 2. Mapa interactivo con el botón flotante "Usar mi GPS actual"
                Expanded(
                  child: Stack(
                    children: [
                      FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: _coordenadaTemp ?? const LatLng(-16.53453, -68.19071),
                          initialZoom: _radioM <= 15 ? 18.5 : 15.5,
                          maxZoom: 20.0,
                          onTap: (_, point) {
                            setState(() {
                              _coordenadaTemp = point;
                              _recalcularDistancia();
                            });
                          },
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.example.continental',
                            maxZoom: 20,
                          ),
                          if (_coordenadaTemp != null) ...[
                            CircleLayer(
                              circles: [
                                CircleMarker(
                                  point: _coordenadaTemp!,
                                  radius: _radioM,
                                  useRadiusInMeter: true,
                                  color: colorPunto.withValues(alpha: 0.22),
                                  borderColor: colorPunto,
                                  borderStrokeWidth: 2.5,
                                ),
                              ],
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: _coordenadaTemp!,
                                  width: 44,
                                  height: 44,
                                  child: Icon(Icons.location_on, color: colorPunto, size: 40),
                                ),
                                if (_miUbicacionActual != null)
                                  Marker(
                                    point: _miUbicacionActual!,
                                    width: 20,
                                    height: 20,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF2563EB),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 3),
                                        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ],
                      ),

                      // Botón flotante para fijar el punto en tu ubicación actual (casa / aula)
                      Positioned(
                        right: 16,
                        bottom: 16,
                        child: FloatingActionButton.extended(
                          onPressed: _capturarUbicacionActual,
                          backgroundColor: Colors.white,
                          icon: const Icon(Icons.my_location, color: Color(0xFF3B82F6)),
                          label: const Text(
                            'Usar mi GPS actual',
                            style: TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold, fontSize: 12.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 3. Panel inferior sencillo para elegir el Radio (desde 1m / 2m) y Guardar
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -3)),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            esAsistencia ? Icons.verified : Icons.route,
                            color: colorPunto,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              nombrePunto,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E3A8A)),
                            ),
                          ),
                          Text(
                            'Radio: ${_radioM.round()} m',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF3B82F6)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _distanciaActualM != null
                            ? 'Tu distancia al punto: ${GpsService.formatearDistancia(_distanciaActualM)} (${dentroAhora ? "DENTRO DEL RADIO" : "FUERA DEL RADIO"})'
                            : (_coordenadaTemp != null
                                ? 'Lat: ${_coordenadaTemp!.latitude.toStringAsFixed(6)}, Lon: ${_coordenadaTemp!.longitude.toStringAsFixed(6)}'
                                : 'Toca "Usar mi GPS actual" o toca el mapa'),
                        style: TextStyle(
                          color: _distanciaActualM != null
                              ? (dentroAhora ? const Color(0xFF10B981) : const Color(0xFFD97706))
                              : const Color(0xFF64748B),
                          fontSize: 11.5,
                          fontWeight: _distanciaActualM != null ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Botones rápidos de radio: 2m, 3m, 5m, 10m, 50m, 100m
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _radiosRapidos.map((r) {
                            final sel = _radioM.round() == r;
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: OutlinedButton(
                                onPressed: () => setState(() => _radioM = r.toDouble()),
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: sel ? const Color(0xFF3B82F6) : const Color(0xFFF8FAFC),
                                  side: BorderSide(color: sel ? const Color(0xFF3B82F6) : const Color(0xFFCBD5E1)),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  minimumSize: const Size(0, 32),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                child: Text(
                                  '$r m',
                                  style: TextStyle(
                                    color: sel ? Colors.white : const Color(0xFF1E3A8A),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                      // Barra deslizadora de Radio (1m a 300m)
                      Row(
                        children: [
                          const Text('1m', style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                          Expanded(
                            child: Slider(
                              value: _radioM.clamp(1.0, 300.0),
                              min: 1.0,
                              max: 300.0,
                              divisions: 299,
                              activeColor: const Color(0xFF3B82F6),
                              onChanged: (v) => setState(() => _radioM = v),
                            ),
                          ),
                          const Text('300m', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                        ],
                      ),

                      // Botón Guardar
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton.icon(
                          onPressed: _guardando ? null : _guardarCambios,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3B82F6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: _guardando
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Icon(Icons.save, color: Colors.white, size: 18),
                          label: Text(
                            _guardando ? 'Guardando...' : 'Guardar Calibración (${_radioM.round()} m)',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
