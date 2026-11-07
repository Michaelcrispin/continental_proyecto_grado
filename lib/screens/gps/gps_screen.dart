import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../domain/puntos_oficiales.dart';
import '../../domain/ruta_continental.dart';
import '../../services/database_helper.dart';
import '../../services/sesion_service.dart';
import '../asistencia/puntos_control_screen.dart';

class GpsScreen extends StatefulWidget {
  const GpsScreen({super.key});

  @override
  State<GpsScreen> createState() => _GpsScreenState();
}

class _GpsScreenState extends State<GpsScreen> {
  final MapController _mapController = MapController();
  List<Map<String, dynamic>> _conductores = [];
  List<Map<String, dynamic>> _puntos = [];
  Map<String, dynamic>? _conductorSeleccionado;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);
    try {
      final conductores = await DatabaseHelper.instance.conductoresConAuto();
      final puntos = await DatabaseHelper.instance.obtenerPuntosControl(soloActivos: false);

      if (mounted) {
        setState(() {
          _conductores = conductores;
          _puntos = puntos;
          if (conductores.isNotEmpty) {
            _conductorSeleccionado = conductores.first;
          }
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Radio de geocerca del punto A o B desde la BD (mínimo oficial).
  double _radioDe(List<Map<String, dynamic>> puntos, {required bool esParadaA}) {
    for (int i = 0; i < puntos.length; i++) {
      final nombre = puntos[i]['nombre']?.toString() ?? '';
      final esA = nombre.contains('Villadela') || i == 0;
      if (esA == esParadaA || puntos.length == 1) {
        final radio = (puntos[i]['radio_m'] as num?)?.toDouble();
        if (radio != null && radio > 0) {
          return RutaContinental.radioEfectivoVueltas(radio);
        }
      }
    }
    return RutaContinental.radioDibujoM;
  }

  void _centrarPunto(Map<String, dynamic> punto) {
    final lat = (punto['latitud'] as num?)?.toDouble() ??
        PuntosOficiales.paradaAVilladela.latitude;
    final lon = (punto['longitud'] as num?)?.toDouble() ??
        PuntosOficiales.paradaAVilladela.longitude;
    final radio = (punto['radio_m'] as num?)?.toDouble() ?? PuntosOficiales.radioAsistenciaM;
    _mapController.move(LatLng(lat, lon), radio <= 15 ? 18.5 : 15.0);
  }

  @override
  Widget build(BuildContext context) {
    final conductorTexto = _conductorSeleccionado != null
        ? '${_conductorSeleccionado!['placa'] ?? 'S/Placa'} • ${_conductorSeleccionado!['nombre']}'
        : 'Sin conductores registrados';
    final estadoTexto = _conductorSeleccionado != null
        ? 'Estado: ${_conductorSeleccionado!['estado']?.toString().toUpperCase() ?? 'ACTIVO'}'
        : 'Base de datos sin registros';

    // Puntos para polilínea de ruta oficial Continental (Cruce Villadela <-> Teleférico Mirador)
    final LatLng coordVilladela = LatLng(
      (_puntos.isNotEmpty ? (_puntos[0]['latitud'] as num?)?.toDouble() : null) ??
          RutaContinental.paradaAVilladela.latitude,
      (_puntos.isNotEmpty ? (_puntos[0]['longitud'] as num?)?.toDouble() : null) ??
          RutaContinental.paradaAVilladela.longitude,
    );

    final LatLng coordTeleferico = LatLng(
      (_puntos.length > 1 ? (_puntos[1]['latitud'] as num?)?.toDouble() : null) ??
          RutaContinental.paradaBTeleferico.latitude,
      (_puntos.length > 1 ? (_puntos[1]['longitud'] as num?)?.toDouble() : null) ??
          RutaContinental.paradaBTeleferico.longitude,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF4F9FD),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E3A8A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Monitoreo GPS - Ruta Continental',
          style: TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold, fontSize: 16),
        ),
        actions: [
          if (SesionService.instance.esSuperadmin)
            IconButton(
              icon: const Icon(Icons.tune, color: Color(0xFF3B82F6)),
              tooltip: 'Calibrar Puntos A y B',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PuntosControlScreen()),
                ).then((_) => _cargarDatos());
              },
            ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF1E3A8A)),
            tooltip: 'Actualizar',
            onPressed: _cargarDatos,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: coordVilladela,
              initialZoom: 14.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.continental',
              ),

              // Trazado vial oficial entre Cruce Villadela y Teleférico
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: RutaContinental.puntosVuelta,
                    color: const Color(0xFFD97706),
                    strokeWidth: 4.0,
                    borderStrokeWidth: 1.5,
                    borderColor: Colors.white,
                  ),
                  Polyline(
                    points: RutaContinental.puntosIda,
                    color: const Color(0xFF02634C),
                    strokeWidth: 4.5,
                    borderStrokeWidth: 1.5,
                    borderColor: Colors.white,
                  ),
                ],
              ),

              // Geocercas CIRCULARES oficiales (radio real de la BD, mínimo Haversine)
              PolygonLayer(
                polygons: [
                  Polygon(
                    points: RutaContinental.anilloGeocerca(
                      coordVilladela,
                      _radioDe(_puntos, esParadaA: true),
                    ),
                    color: const Color(0xFF2563EB).withValues(alpha: 0.28),
                    borderColor: const Color(0xFF2563EB),
                    borderStrokeWidth: 3.2,
                  ),
                  Polygon(
                    points: RutaContinental.anilloGeocerca(
                      coordTeleferico,
                      _radioDe(_puntos, esParadaA: false),
                    ),
                    color: const Color(0xFFD97706).withValues(alpha: 0.26),
                    borderColor: const Color(0xFFD97706),
                    borderStrokeWidth: 3.0,
                  ),
                ],
              ),

              // Marcadores de puntos de control
              MarkerLayer(
                markers: _puntos.map((p) {
                  final lat = (p['latitud'] as num?)?.toDouble() ??
                      PuntosOficiales.paradaAVilladela.latitude;
                  final lon = (p['longitud'] as num?)?.toDouble() ??
                      PuntosOficiales.paradaAVilladela.longitude;
                  final esAsistencia = (p['es_punto_asistencia'] as num?)?.toInt() == 1;
                  final color = esAsistencia ? const Color(0xFF10B981) : const Color(0xFF3B82F6);

                  return Marker(
                    point: LatLng(lat, lon),
                    width: 44,
                    height: 44,
                    child: GestureDetector(
                      onTap: () => _centrarPunto(p),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: color, width: 2),
                          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                        ),
                        child: Icon(
                          esAsistencia ? Icons.how_to_reg : Icons.directions_bus,
                          color: color,
                          size: 22,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          // Header Overlay con Conductor Seleccionado
          Positioned(
            top: 10,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 16,
                    backgroundColor: Color(0xFFEFF6FF),
                    child: Icon(Icons.person, color: Color(0xFF3B82F6), size: 16),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(conductorTexto, style: const TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis),
                        Text(estadoTexto, style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                        if (_isLoading)
                          const Padding(
                            padding: EdgeInsets.only(top: 4.0),
                            child: LinearProgressIndicator(minHeight: 2),
                          ),
                      ],
                    ),
                  ),
                  if (_conductores.length > 1)
                    PopupMenuButton<Map<String, dynamic>>(
                      icon: const Icon(Icons.swap_horiz, color: Color(0xFF3B82F6)),
                      tooltip: 'Cambiar conductor',
                      onSelected: (c) => setState(() => _conductorSeleccionado = c),
                      itemBuilder: (ctx) => _conductores.map((c) => PopupMenuItem(
                        value: c,
                        child: Text('${c['nombre']} (${c['placa'] ?? 'S/Placa'})'),
                      )).toList(),
                    ),
                ],
              ),
            ),
          ),

          // Controles de zoom
          Positioned(
            right: 16,
            bottom: 170,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
                  ),
                  child: Column(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.add, color: Color(0xFF1E3A8A)),
                        onPressed: () {
                          final currentZoom = _mapController.camera.zoom;
                          _mapController.move(_mapController.camera.center, currentZoom + 1);
                        },
                      ),
                      Container(height: 1, width: 30, color: const Color(0xFFF1F5F9)),
                      IconButton(
                        icon: const Icon(Icons.remove, color: Color(0xFF1E3A8A)),
                        onPressed: () {
                          final currentZoom = _mapController.camera.zoom;
                          _mapController.move(_mapController.camera.center, currentZoom - 1);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                FloatingActionButton.small(
                  onPressed: () => _mapController.move(coordVilladela, 15.0),
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.my_location, color: Color(0xFF3B82F6)),
                ),
              ],
            ),
          ),

          // Tarjeta inferior con Puntos de control y geocercas
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Puntos de Parada (A y B)',
                        style: TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      if (SesionService.instance.esSuperadmin)
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const PuntosControlScreen()),
                            ).then((_) => _cargarDatos());
                          },
                          child: const Text('Configurar A y B', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (_puntos.isEmpty)
                    const Text('No hay puntos en la base de datos.', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12))
                  else
                    Column(
                      children: _puntos.map((p) {
                        final esAsistencia = (p['es_punto_asistencia'] as num?)?.toInt() == 1;
                        final color = esAsistencia ? const Color(0xFF10B981) : const Color(0xFF3B82F6);
                        final radio = p['radio_m'] ?? 100;

                        return InkWell(
                          onTap: () => _centrarPunto(p),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              children: [
                                Icon(Icons.location_on, color: color, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${p['nombre']} (Radio $radio m)',
                                    style: const TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.w600, fontSize: 12),
                                  ),
                                ),
                                if (esAsistencia)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFECFDF5),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'ASISTENCIA',
                                      style: TextStyle(color: Color(0xFF10B981), fontSize: 9, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
